-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('wicci-page-code.sql', '$Id');

-- Code to Serve a Wicci Page
-- Functions to support serving Wicci pages

-- ** Copyright

/*
Copyright (c) 2005-2012, J. Greg Davidson, all rights
reserved.  Although it is my intention to make this code
available under a Free Software license when it is
ready, this code is currently not to be copied nor shown
to anyone without my permission in writing.
*/

-- * wicci_serve

CREATE OR REPLACE FUNCTION try_wicci_serve_ajax(
	_env env_refs, _xfer http_transfer_refs,
	_user wicci_user_refs, _cookies uri_query_refs,
	_url uri_refs, page_uri page_uri_refs, doc_uri doc_page_refs,
	_doc doc_refs, ajax_action text,
	OUT _body http_response_refs, OUT bigint,
	OUT _lang doc_lang_name_refs
) AS $$
	SELECT
		get_http_response('_body', _body),
		octet_length(_body)::bigint,
		'ajax'::doc_lang_name_refs
	FROM COALESCE(
		'"' || try_uri_query_value(_url, 'type') || '"',
		'"No type!"'::text
	) _body,
		wicci_enter( 'try_wicci_serve_ajax(
			env_refs, http_transfer_refs, wicci_user_refs, uri_query_refs,
			uri_refs, page_uri_refs, doc_page_refs, doc_refs, text
		)', _env )
$$ LANGUAGE sql STRICT;

COMMENT ON FUNCTION try_wicci_serve_ajax(
	env_refs, http_transfer_refs, wicci_user_refs, uri_query_refs,
	uri_refs, page_uri_refs, doc_page_refs,
	doc_refs, ajax_action text)
IS 'Process ajax action for given document, etc. Prototype!!';

CREATE OR REPLACE
FUNCTION fix_wicci_body(text) RETURNS text AS $$
	SELECT replace( replace(
		$1, 'xmlns="http://www.w3.org/1999/xhtml"', ''
	), E'\n', E'\r\n')
$$ LANGUAGE sql;

COMMENT ON FUNCTION fix_wicci_body(text)
IS 'Kludge to suppress default namespace for html!!! ';

CREATE OR REPLACE
FUNCTION wicci_doctype(doc_lang_name_refs)
RETURNS text AS $$
	SELECT COALESCE( (
		SELECT value_ || E'\n\n' FROM http_response_rows
		WHERE ref = wicci_response_default($1, '_doctype')
	), '' )
$$ LANGUAGE sql;

COMMENT ON FUNCTION wicci_doctype(doc_lang_name_refs)
IS 'Return the proper doctype or empty string';

CREATE OR REPLACE FUNCTION try_wicci_serve_body(
	_env env_refs,	_user wicci_user_refs, _cookies uri_query_refs,
	doc_uri doc_page_refs, _doc doc_refs,
	doc_lang doc_lang_name_refs,
	OUT _body http_response_refs, OUT _len bigint,
	OUT _lang doc_lang_name_refs
) AS $$
	SELECT
		get_http_response('_body', body_text),
		octet_length(body_text)::bigint, doc_lang
	FROM wicci_enter( 'try_wicci_serve_body(
		env_refs, wicci_user_refs, uri_query_refs,
		doc_page_refs, doc_refs, doc_lang_name_refs
	)', _env ),
	( SELECT wicci_doctype(doc_lang) || CASE
		WHEN is_nil(_user) THEN
			fix_wicci_body( ref_env_crefs_text_op( _doc, _env, crefs_nil() ) )
		ELSE (
			SELECT fix_wicci_body( oftd_ref_env_crefs_text_op(
				'ref_env_crefs_text_op(refs, env_refs, crefs)',
				_from, _to, _doc, _doc, _env, crefs_nil()
			) ) FROM wicci_grafts_from_to(doc_uri, _user) AS foo(_from, _to)
		)
	END ) AS foo(body_text)
$$ LANGUAGE sql STRICT;

COMMENT ON FUNCTION try_wicci_serve_body(
	env_refs, wicci_user_refs, uri_query_refs,
	doc_page_refs, doc_refs, doc_lang_name_refs
) IS 'Render a document using the Wicci process.';

CREATE OR REPLACE FUNCTION try_wicci_serve_body(
	_env env_refs, _xfer http_transfer_refs,
	_user wicci_user_refs, _cookies uri_query_refs, _url uri_refs,
	page_uri page_uri_refs, doc_uri doc_page_refs,
	OUT _body http_response_refs, OUT _len bigint,
	OUT _lang doc_lang_name_refs
) AS $$
	SELECT ( SELECT COALESCE(
		try_wicci_serve_ajax(
			_env_, $2, $3, $4, $5, $6, $7, _doc_, $4^'ajax'
		),
		try_wicci_serve_body(
			_env_, _user, _cookies, doc_uri, _doc_, doc_lang_name(_doc_)
		)
	) FROM COALESCE( ( env_doc( _env,  _doc_) ).env ) _env_ -- destructor???
	) FROM doc_page_doc(doc_uri) _doc_
$$ LANGUAGE sql STRICT;

COMMENT ON FUNCTION try_wicci_serve_body(
	_env env_refs, _xfer http_transfer_refs,
	_user wicci_user_refs, uri_query_refs, _url uri_refs,
	page_uri page_uri_refs, doc_uri doc_page_refs
) IS 'Return ajax or document body.';

CREATE OR REPLACE FUNCTION try_wicci_serve_404(
	env_refs, http_transfer_refs, wicci_user_refs,
	uri_query_refs, uri_refs, page_uri_refs,
	OUT _body http_response_refs, OUT _len bigint,
	OUT _lang doc_lang_name_refs
) AS $$
	SELECT try_wicci_serve_body(
		_env, $2, $3, $4, $5, $6, find_doc_page('404.html')
	) FROM wicci_env_add_association(
		$1, $2, '_status', http_response_rows_ref('404')
	) _env
$$ LANGUAGE sql STRICT;

CREATE OR REPLACE FUNCTION wicci_serve_404(
	env_refs, http_transfer_refs, wicci_user_refs,
	uri_query_refs, uri_refs, page_uri_refs,
	OUT _body http_response_refs, OUT _len bigint,
	OUT _lang doc_lang_name_refs
) AS $$
	SELECT non_null(
		try_wicci_serve_404($1,$2,$3,$4,$5,$6),
		'wicci_serve_404(
			env_refs,http_transfer_refs,wicci_user_refs,
			uri_query_refs, uri_refs,page_uri_refs
		)'
	)
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION wicci_serve_large_body_oid(
	page_uri_refs,
	OUT _body http_response_refs, OUT _len bigint,
	OUT _lang doc_lang_name_refs
) AS $$
	SELECT get_http_response('_body_lo', lo_::text), length_, lang_
	FROM large_object_docs, debug_enter_pairs(
		'wicci_serve_large_body_oid(page_uri_refs)',
		name_value_pair('env_page_url', $1)
	) WHERE uri_ = $1
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION wicci_serve_body(
	_env env_refs, _xfer http_transfer_refs,
	_user wicci_user_refs, _url uri_refs,
	_cookies uri_query_refs,	page_uri page_uri_refs,
	OUT _body http_response_refs,
	OUT bigint, OUT _lang doc_lang_name_refs
) AS $$
	SELECT COALESCE(
		wicci_serve_large_body_oid(page_uri),
		try_wicci_serve_body(
			_env, _xfer, _user, _cookies, _url, page_uri,
			try_doc_page(page_uri)
		),
		wicci_serve_404(_env, _xfer, _user, _cookies, _url, page_uri)
	) FROM
	stati_env( env_page_url(
		stati_env( env_http_url(
			stati_env( env_wicci_login(
				stati_env( env_wicci_user(
					stati_env( env_http_transfer(_env, _xfer) ),
				_user ) ),
			wicci_login(_user)) ),
		_url ) ),
	page_uri ) ) _env
$$ LANGUAGE sql;

COMMENT ON FUNCTION wicci_serve_body(
	env_refs, http_transfer_refs, wicci_user_refs, uri_refs,
	uri_query_refs,	page_uri_refs
) IS 'Serve the body of whatever kind, including a 404';

CREATE OR REPLACE FUNCTION try_wicci_serve_responses(
	_env env_refs, _xfer http_transfer_refs,
	_user wicci_user_refs, _uri uri_refs,	_cookies uri_query_refs,
	_body http_response_refs, _len bigint, _lang doc_lang_name_refs
) RETURNS http_response_refs[] AS $$
	SELECT array_non_nulls( ARRAY(
		SELECT COALESCE(
			CASE name_								-- try_ --> find_ !! just below:
				WHEN try_http_response_name('Date') THEN wicci_date()
				WHEN try_http_response_name('Set-Cookie') THEN
					try_wicci_cookie(_env, _xfer, _user, _cookies, _uri)
				WHEN try_http_response_name('_body') THEN _body
				WHEN try_http_response_name('Content-Length') THEN
					get_http_response('Content-Length', _len::text)
			END,
			try_http_response( env_obj_feature_value(_env, _xfer, name_) ),
			wicci_response_default(_lang, name_)
		) FROM wicci_response_names	-- a simple list
	) ) FROM debug_enter( 'try_wicci_serve_responses(
		env_refs, http_transfer_refs, wicci_user_refs,
		uri_refs,	uri_query_refs, http_response_refs,
		bigint, doc_lang_name_refs
		)', _body
	)
$$ LANGUAGE sql STRICT;

COMMENT ON FUNCTION try_wicci_serve_responses(
	env_refs, http_transfer_refs, wicci_user_refs,
	uri_refs, uri_query_refs, http_response_refs,
	bigint, doc_lang_name_refs
) IS 'Generate the response headers.';

CREATE OR REPLACE FUNCTION try_wicci_serve_responses(
	env_refs, http_transfer_refs, wicci_user_refs,
	uri_refs, uri_query_refs
) RETURNS http_response_refs[]  AS $$
	SELECT try_wicci_serve_responses(
		$1,$2,$3,$4,$5, _body, _len, _lang
	) FROM
		wicci_serve_body($1,$2,$3,$4,$5, find_page_uri($4))
			foo(_body, _len, _lang),
		debug_enter_pairs(
			'try_wicci_serve_responses(
				env_refs, http_transfer_refs, wicci_user_refs,
				uri_refs, uri_query_refs
			)'
			,	name_value_pair('env_http_url', $4)
			,	name_value_pair('env_wicci_user', $3)
		)
	WHERE $2 ^ '_type' = 'GET'	-- case significance???
$$ LANGUAGE sql STRICT;

COMMENT ON FUNCTION try_wicci_serve_responses(
	env_refs, http_transfer_refs,	wicci_user_refs,
	uri_refs, uri_query_refs
) IS '
Get the body, then the response headers.
';

CREATE OR REPLACE FUNCTION wicci_serve(
	_xfer http_transfer_refs,
	_url uri_refs,
	_cookies uri_query_refs
) RETURNS http_transfer_refs  AS $$
	SELECT drop_env_give_value(
		_env,
		set_http_transfer_responses(
			CASE WHEN is_nil(_user) THEN _xfer ELSE
				( get_wicci_transfers_users(_xfer, _user ) ).xfer_
			END,		-- in passing, associate xfer with the user
			VARIADIC try_wicci_serve_responses(
				_env, _xfer, _user, _url, _cookies
	) ) ) FROM
	make_user_env() _env,
	try_wicci_user(_url, _cookies) _user,
	debug_enter_pairs(
		'wicci_serve(http_transfer_refs,uri_refs,uri_query_refs)'
		, name_value_pair('env_http_url', _url)
		, name_value_pair('env_cookies', _cookies)
	)
$$ LANGUAGE sql;

COMMENT ON FUNCTION wicci_serve(
	http_transfer_refs, uri_refs, uri_query_refs
) IS
'Pass the buck with some additional parameters,
including a temporary environment context.
Set the resulting transfer responses into
the http transfer object which we return and
drop the environment at the same time.';

CREATE OR REPLACE
FUNCTION wicci_serve_responses(text)
RETURNS SETOF http_response_refs AS $$
	SELECT unnest( http_transfer_responses(
		wicci_serve( _xfer, _url, _cookies )
	) ) FROM
		new_http_transfer($1) foo(_xfer, _url, _cookies),
		debug_enter('wicci_serve_responses(text)')
$$ LANGUAGE sql;

COMMENT ON
FUNCTION wicci_serve_responses(text) IS '
	Convert an http request in text form into a
	new http_transfer object.  Have wicci_serve
	fill in the response headers which we
	extract and hand back as an ordered set.';

CREATE OR REPLACE
FUNCTION public.wicci_serve(text)
RETURNS TABLE("name" text, "value" text)  AS $$
	SELECT http_response_name_text(name_), value_ FROM
  	http_response_rows _row,
		wicci_serve_responses($1) response,
		debug_enter('wicci_serve(text)', $1)
	WHERE ref = response
$$ LANGUAGE sql SET search_path FROM CURRENT;

COMMENT ON
FUNCTION public.wicci_serve(text, OUT text, OUT text) IS '
Given an http request as text, serve the response as an
ordered set of response headers.  Header names starting
with _ are to be handled in special ways by the proxy server:
	_body: send a blank line then the body
	_body_lo: value is the oid of a large object to
		fetch and send - and this is the last header so
		the current query does not need to be retained.
	_*: any other header starting with _, just send the value
';

-- NEED TO CATCH ANY EXCEPTIONS AND PRODUCE
-- AN ERROR STATUS - MAYBE shim CAN DO THIS?
-- BUT WOULD BE BETTER TO DO IT 

-- I'm also not yet handling the language - I could pull it out
-- from the doc or the large object table and put it in the
-- environment, or return it with the body - let's see!


-- * unofficial public code:

CREATE OR REPLACE
FUNCTION public.blob_oid_uri_text(oid)
RETURNS text  AS $$
	SELECT s4_doc.page_uri_text(uri_)
	FROM s4_doc.large_object_docs
	WHERE lo_ = $1
$$ LANGUAGE sql SET search_path FROM CURRENT;

-- * for testing convenience:

CREATE OR REPLACE
FUNCTION public.wicci_serve(http_transfer_refs)
RETURNS http_transfer_refs  AS $$
	SELECT wicci_serve(
		$1, 
	 	try_get_http_requests_url(request), -- will kill the query if this is null!!!
		get_http_requests_cookies(request)
	) FROM http_transfer_rows WHERE ref = $1
$$ LANGUAGE sql SET search_path FROM CURRENT;

COMMENT ON FUNCTION public.wicci_serve(http_transfer_refs)
IS 'only for testing';

