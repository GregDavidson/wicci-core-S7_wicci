-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('wicci-page-code.sql', '$Id');

-- Wicci Page Code
-- Support for serving wicci-pages
-- Especially for managing Wicci Docs, Nodes & Kinds

-- ** Copyright

/*
Copyright (c) 2005-2012, J. Greg Davidson, all rights
reserved.  Although it is my intention to make this code
available under a Free Software license when it is
ready, this code is currently not to be copied nor shown
to anyone without my permission in writing.
*/

-- ** utility functions

-- debugging support

CREATE OR REPLACE
FUNCTION wicci_enter(regprocedure, env_refs)
RETURNS regprocedure AS $$
	SELECT debug_enter_pairs(
		$1,
		env_name_pair($2, 'env_wicci_user'),
		env_name_pair($2, 'env_http_url')
	)
$$ LANGUAGE sql;

-- * wicci httpi_transfer code

CREATE OR REPLACE FUNCTION try_wicci_user_(
	_url uri_refs, _cookies uri_query_refs
) RETURNS text AS $$
	SELECT COALESCE(
		try_uri_query_value(_url, 'user'),
		try_uri_query_value(_cookies, 'user')
	)
$$ LANGUAGE SQL STRICT;

CREATE OR REPLACE FUNCTION try_wicci_user(
	_url uri_refs, _cookies uri_query_refs
) RETURNS wicci_user_refs AS $$
	SELECT CASE WHEN user_text IS NULL THEN NULL
  ELSE try_wicci_user( try_entity_uri(
		CASE WHEN user_text ILIKE 'user:%'
		THEN user_text ELSE 'user:' || user_text
		END, 'user'
	) )
  END FROM try_wicci_user_($1,$2) user_text
$$ LANGUAGE SQL STRICT;

COMMENT ON FUNCTION try_wicci_user(
	uri_refs, uri_query_refs
) IS
'Given a request url and cookies, find wicci user from
cookie header (or URI query data as a test feature!!)';

CREATE OR REPLACE FUNCTION wicci_user_or_nil(
	_url uri_refs, _cookies uri_query_refs
) RETURNS wicci_user_refs AS $$
	SELECT COALESCE( try_wicci_user($1, $2), wicci_user_nil() )
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION find_wicci_user_or_nil(http_transfer_refs)
RETURNS wicci_user_refs AS $$
	SELECT COALESCE(try_wicci_user($1), wicci_user_nil())
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION find_wicci_user_or_nil(http_transfer_refs)
RETURNS wicci_user_refs AS $$
	SELECT non_null( try_wicci_user($1), 'find_wicci_user_or_nil(http_transfer_refs)' )
$$ LANGUAGE SQL;

COMMENT ON FUNCTION find_wicci_user_or_nil(http_transfer_refs)
IS 'when no wicci user specified, default to
unregistered user, i.e. wicci_user_nil()';

-- CREATE OR REPLACE
-- FUNCTION find_doc_page(http_transfer_refs)
-- RETURNS doc_page_refs AS $$
-- 	SELECT non_null(
-- 		try_doc_page(try_page_uri(url)),
-- 		'find_doc_page(http_transfer_refs)',
-- 		uri_text(url)
-- 	) FROM http_transfer_url($1) url
-- $$ LANGUAGE SQL;

-- ** print things nicely

-- * functions to turn web data into wicci info

CREATE OR REPLACE FUNCTION find_by_path(
	doc_refs, integer[], doc_page_refs, wicci_user_refs
) RETURNS doc_node_refs AS $$
	SELECT find_by_path( $1, $2, ARRAY(
		SELECT x FROM wicci_grafts($3, $4) x)
	)
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION find_by_path(
	doc_refs, text, doc_page_refs, wicci_user_refs
) RETURNS doc_node_refs AS $$
	SELECT CASE WHEN $2 ~ '^[0-9,]$' AND $2 !~ ',,'
		THEN	find_by_path($1, ('{' || $2 || '}')::int[], $3, $4)
		ELSE debug_fail(
			'find_by_path(doc_refs, text, doc_page_refs, wicci_user_refs)',
			NULL::doc_node_refs, 'illegal path', $2
		)
	END
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_wicci_text_graft(
	wicci_user_refs, uri_refs, 
 doc_page_refs, doc_refs, doc_node_refs
) RETURNS doc_node_refs AS $$
	SELECT
		try_graft_node($5, try_get_xml_text_kind(_text))
	FROM
		try_get_xml_text(try_uri_query_value($2,'new')) _text,
		debug_enter( 'get_wicci_text_graft(
			wicci_user_refs, uri_refs, 
			 doc_page_refs, doc_refs, doc_node_refs
		)', uri_text($2) )
$$ LANGUAGE sql STRICT;

CREATE OR REPLACE FUNCTION get_wicci_swap_graft(
	wicci_user_refs, uri_refs,
 doc_page_refs, doc_refs, doc_node_refs
) RETURNS doc_node_refs AS $$
	SELECT (SELECT
		try_graft_node(_parent, kind,
			VARIADIC ARRAY( SELECT CASE
				WHEN x = _node1 THEN _node2
				WHEN x = _node2 THEN _node1
				ELSE x
			END FROM unnest(children) x )
		) FROM tree_doc_node_rows WHERE ref = _parent
	) FROM
		COALESCE($5) _node1,
		find_by_path($4, $2^'path1', $3, $1 ) _node2,
		doc_node_parent($5) _parent,
		debug_enter( 'get_wicci_swap_graft(
			wicci_user_refs, uri_refs,
			doc_page_refs, doc_refs, doc_node_refs
	 )', uri_text($2) )
$$ LANGUAGE sql STRICT;

COMMENT ON FUNCTION get_wicci_swap_graft(
	wicci_user_refs, uri_refs,
 doc_page_refs, doc_refs, doc_node_refs
) IS 'What could possibly go wrong???';

CREATE OR REPLACE FUNCTION get_wicci_del_graft(
	wicci_user_refs, uri_refs,
 doc_page_refs, doc_refs, doc_node_refs
) RETURNS doc_node_refs AS $$
	SELECT (SELECT
		try_graft_node(_parent, kind,
			VARIADIC ARRAY( SELECT c
			FROM unnest(children) c WHERE c != $5 )
		) FROM tree_doc_node_rows WHERE ref = _parent
	) FROM
		doc_node_parent($5) _parent,
		debug_enter( 'get_wicci_del_graft(
			wicci_user_refs, uri_refs,
		 doc_page_refs, doc_refs, doc_node_refs
		 )', uri_text($2) )
$$ LANGUAGE sql STRICT;

CREATE OR REPLACE FUNCTION try_wicci_make_graft(
	env_refs, http_transfer_refs, wicci_user_refs,
	uri_refs, page_uri_refs, doc_page_refs,
	doc_refs, ajax_action text
) RETURNS doc_node_refs AS $$
	SELECT CASE $4^'type'
		WHEN 'text' THEN get_wicci_text_graft($3,$4,$6,$7,_node1)
		WHEN 'swap'  THEN get_wicci_swap_graft($3,$4,$6,$7,_node1)
		-- WHEN 'before'  THEN get_wicci_before_graft($3,$4,$6,$7,_node1)
		-- WHEN 'after'  THEN get_wicci_after_graft($3,$4,$6,$7,_node1)
		WHEN 'del' THEN get_wicci_del_graft($3,$4,$6,$7,_node1)
	END FROM
		try_uri_query_value($4,'type') _type,
		find_by_path($7, $4^'path1', $6, $3 ) _node1
		-- try_uri_query_value($4,'tag2') _tag2,
		-- try_uri_query_value($4,'path2') _path2,
		-- try_uri_query_value($4,'dir') _dir,
		-- try_uri_query_value($4,'que_len') que_len,
		-- try_uri_query_value($4,'euq_len') euq_len,
$$ LANGUAGE sql STRICT;

COMMENT ON FUNCTION 
try_wicci_make_graft(env_refs, http_transfer_refs, wicci_user_refs,
	uri_refs, page_uri_refs, doc_page_refs,
	doc_refs, ajax_action text)
IS 'Incomplete!!!';

CREATE OR REPLACE FUNCTION wicci_date()
RETURNS http_response_refs AS $$
	SELECT get_http_response(
		'Date',  http_cookie_time(CURRENT_TIMESTAMP)::text
	)
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION try_wicci_cookie(
	_env env_refs, _xfer http_transfer_refs, _user wicci_user_refs,
	_cookies uri_query_refs, _uri uri_refs
) RETURNS http_response_refs AS $$
	SELECT CASE
		WHEN is_nil(_user) THEN NULL
		ELSE get_http_response(
				'Set-Cookie',
				try_http_cookie_text(
				_url := $5,
				_pairs := ARRAY[
					'user'::text, _user::text,
					'session'::text,
					COALESCE( $4 ^ 'session', new_wicci_trans(_user)::text )
				]
			)
		)
	END
$$ LANGUAGE sql;

COMMENT ON FUNCTION try_wicci_cookie(
	_env env_refs, _xfer http_transfer_refs,
	_user wicci_user_refs, uri_query_refs, uri_refs
) IS '
	Returns applicable ''Set-Cookie'' response header or NULL.
	Only considers ''user'' and ''session'' cookies.
	Maybe use s6_http.http_cookie_names ??
	Or maybe only use ''session'' ??
	And what is a wicci session anyway ??
	Do we want to use a wicci_transaction for a session ??
	How will we clean up unused transactions?
	Consider reusing transactions on same page
	and on same domain !!
';
