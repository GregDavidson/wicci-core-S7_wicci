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

-- We're using bigint everywhere for the size of the body data;
-- is this really necessary or would integer do as well??

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
		SELECT text_value || E'\n\n' FROM http_small_text_response_rows
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
		$1, $2, '_status', http_small_text_response_rows_ref('404')
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
FUNCTION wicci_serve_lo_body(
	doc_refs,
	_bin_ http_response_name_refs = '_body_bin', -- currently ignored
	OUT _body http_response_refs, OUT _len bigint,
	OUT _lang doc_lang_name_refs
) AS $$
	SELECT get_http_response('_body_lo', oid::text), length__, lang
	FROM large_object_doc_rows, debug_enter_pairs(
		'wicci_serve_lo_body(doc_refs,	http_response_name_refs)',
		name_value_pair('env_doc_page', $1)
	) WHERE ref = $1
$$ LANGUAGE sql;

COMMENT ON FUNCTION wicci_serve_lo_body(
	doc_refs,	http_response_name_refs
) IS 'Serve any static page internalized as a PostgreSQL
large object.  Currently we only know how to serve such
using _body_lo, so the second argument is ignored!!  Unless
and until this can be fixed, PostgreSQL Large Objects are
Deprecated!!';

CREATE OR REPLACE
FUNCTION wicci_serve_blob_body(
	page_uri_refs,
	_bin_ http_response_name_refs = '_body_bin', -- currently ignored
	OUT _body http_response_refs, OUT _len bigint,
	OUT _lang doc_lang_name_refs
) AS $$
	SELECT CASE _bin_
		WHEN '_body_bin'::http_response_name_refs
			THEN get_http_response(_bin_, _bytes_ := bytes)
		WHEN '_body_hex'::http_response_name_refs
			THEN get_http_response(_bin_, _text_ := encode( bytes, 'hex') )
	END, length__, lang
	FROM
		blob_doc_rows,
		LATERAL blob_bytes(blob_) bytes,
		debug_enter_pairs(
			'wicci_serve_blob_body(page_uri_refs, http_response_name_refs)',
			name_value_pair('env_doc_page', $1)
	) WHERE page_uri_ = $1
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION wicci_text_body_header(
	body_value text,
	_lang doc_lang_name_refs,
	OUT _body http_response_refs, OUT _len bigint,
	OUT _lang doc_lang_name_refs
) AS $$
	SELECT get_http_response('_body', body_value), octet_length(body_value)::bigint, _lang
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION wicci_binary_body_header(
	body_value bytea,
	_lang doc_lang_name_refs,
	_header_ http_response_name_refs,
	OUT _body http_response_refs,
	OUT _len bigint,
	OUT _lang doc_lang_name_refs
) AS $$
	SELECT CASE _header_
	WHEN '_body_hex'
		THEN get_http_response(_header_, encode(body_value, 'hex'))
	WHEN '_body_bin'
		THEN get_http_response(_header_, _bytes_ := body_value)
	END, octet_length(body_value)::bigint, _lang
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION wicci_serve_file_body(
	doc_refs,
	_bin_ http_response_name_refs = '_body_bin',
	OUT _body http_response_refs,
	OUT _len bigint,
	OUT _lang doc_lang_name_refs
) AS $$
	SELECT CASE
		WHEN in_doc_lang_family(lang, 'text') THEN
			wicci_text_body_header(pg_read_file(_path), lang)
	ELSE
			wicci_binary_body_header(pg_read_binary_file(_path), lang, _bin_)
	END
	FROM
		file_doc_rows,
		LATERAL page_uri_xfiles_path(page_uri_) _path,
		debug_enter_pairs(
			'wicci_serve_file_body(doc_refs, http_response_name_refs)',
			name_value_pair('env_doc_page', $1)
		)
	WHERE ref = $1
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION wicci_serve_blob_body(
	doc_refs,
	_bin_ http_response_name_refs = '_body_bin',
	OUT _body http_response_refs,
	OUT _len bigint,
	OUT _lang doc_lang_name_refs
) AS $$
	SELECT CASE
		WHEN in_doc_lang_family(lang, 'text') THEN
			wicci_text_body_header(blob_text(blob_), lang)
	ELSE
			wicci_binary_body_header(blob_bytes(blob_), lang, _bin_)
	END
	FROM
		blob_doc_rows d,
		blob_rows b,								-- needed???
		debug_enter_pairs(
			'wicci_serve_blob_body(doc_refs, http_response_name_refs)',
			name_value_pair('env_doc_page', $1)
		)
	WHERE d.ref = $1 AND d.blob_ = b.ref
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION wicci_serve_static_body(
	page_uri_refs,
	_bin_ http_response_name_refs = '_body_bin',
	OUT _body http_response_refs,
	OUT _len bigint,
	OUT _lang doc_lang_name_refs
) AS $$
	SELECT CASE ref_table(doc)
		WHEN 'blob_doc_rows'::regclass THEN wicci_serve_blob_body(doc, _bin_)
		WHEN 'file_doc_rows'::regclass THEN wicci_serve_file_body(doc, _bin_)
		WHEN 'large_object_doc_rows'::regclass THEN wicci_serve_lo_body(doc, _bin_)
	END FROM doc_page_rows WHERE uri = $1
$$ LANGUAGE sql;

COMMENT ON FUNCTION wicci_serve_static_body(
	page_uri_refs,	http_response_name_refs
) IS '
	If the document is static, serve it.
	If a static document is binary, serve it in the preferred manner.
';

CREATE OR REPLACE FUNCTION wicci_serve_body(
	_env env_refs, _xfer http_transfer_refs,
	_user wicci_user_refs, _url uri_refs,
	_cookies uri_query_refs,	page_uri page_uri_refs,
	_bin_ http_response_name_refs = '_body_bin',
	OUT _body http_response_refs,
	OUT bigint, OUT _lang doc_lang_name_refs
) AS $$
	SELECT COALESCE(
		wicci_serve_static_body(page_uri, _bin_),
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
	uri_query_refs,	page_uri_refs, http_response_name_refs
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
	uri_refs, uri_query_refs,
	_bin_ http_response_name_refs = '_body_bin'
) RETURNS http_response_refs[]  AS $$
	SELECT try_wicci_serve_responses(
		$1,$2,$3,$4,$5, _body, _len, _lang
	) FROM
		wicci_serve_body($1,$2,$3,$4,$5, find_page_uri($4),_bin_)
			foo(_body, _len, _lang),
		debug_enter_pairs(
			'try_wicci_serve_responses(
				env_refs, http_transfer_refs, wicci_user_refs,
				uri_refs, uri_query_refs, http_response_name_refs
			)'
			,	name_value_pair('env_http_url', $4)
			,	name_value_pair('env_wicci_user', $3)
		)
	WHERE $2 ^ '_type' = 'GET'	-- case significance???
$$ LANGUAGE sql STRICT;

COMMENT ON FUNCTION try_wicci_serve_responses(
	env_refs, http_transfer_refs,	wicci_user_refs,
	uri_refs, uri_query_refs,  http_response_name_refs
) IS '
Get the body, then the response headers.
';

CREATE OR REPLACE FUNCTION wicci_serve(
	_xfer http_transfer_refs,
	_url uri_refs,
	_cookies uri_query_refs,
	_bin_ http_response_name_refs = '_body_bin'
) RETURNS http_transfer_refs  AS $$
	SELECT drop_env_give_value(
		_env,
		set_http_transfer_responses(
			CASE WHEN is_nil(_user) THEN _xfer ELSE
				( get_wicci_transfers_users(_xfer, _user ) ).xfer_
			END,		-- in passing, associate xfer with the user
			VARIADIC try_wicci_serve_responses(
				_env, _xfer, _user, _url, _cookies, _bin_
	) ) ) FROM
	make_user_env() _env,
	try_wicci_user(_url, _cookies) _user,
	debug_enter_pairs(
		'wicci_serve(http_transfer_refs,uri_refs,uri_query_refs,http_response_name_refs)'
		, name_value_pair('env_http_url', _url)
		, name_value_pair('env_cookies', _cookies)
	)
$$ LANGUAGE sql;

COMMENT ON FUNCTION wicci_serve(
	http_transfer_refs, uri_refs, uri_query_refs,  http_response_name_refs
) IS
'Pass the buck with some additional parameters,
including a temporary environment context.
Set the resulting transfer responses into
the http transfer object which we return and
drop the environment at the same time.';

CREATE OR REPLACE
FUNCTION wicci_serve_responses(text, _bin_ http_response_name_refs = '_body_bin')
RETURNS SETOF http_response_refs AS $$
	SELECT unnest( http_transfer_responses(
		wicci_serve( _xfer, _url, _cookies, _bin_ )
	) ) FROM
		new_http_transfer($1) foo(_xfer, _url, _cookies),
		debug_enter('wicci_serve_responses(text, http_response_name_refs)', $1)
$$ LANGUAGE sql;

COMMENT ON
FUNCTION wicci_serve_responses(text, http_response_name_refs) IS '
	Convert an http request in text form into a
	new http_transfer object.  Have wicci_serve
	fill in the response headers which we
	extract and hand back as an ordered set.';

CREATE OR REPLACE
FUNCTION public.wicci_serve(text, _bin_ http_response_name_refs = '_body_bin')
RETURNS TABLE("name" text, text_value text, binary_value bytea)  AS $$
	SELECT http_response_name_text(name_), text_value, binary_value FROM
  	http_response_rows _row,
		wicci_serve_responses($1) response,
		debug_enter('wicci_serve(text,http_response_name_refs)', $1),
		supported_binary_doc_formats
	WHERE ref = response
	AND storage_policy = static_doc_storage_policy()
	AND request_format = $2
$$ LANGUAGE sql SET search_path FROM CURRENT;

COMMENT ON
FUNCTION public.wicci_serve(text, http_response_name_refs, OUT text, OUT text) IS '
Given an http request as text, serve the response as an
ordered set of response headers.  Header names starting
with _ are to be handled in special ways by the proxy server:
	_body*:
		1st time, send a blank line then the value,
		any additional times, just send the value
		--> Currently we are only allowing 1 _body* header!!
	_body: send text value
	_body_hex:
		decode hex-encoded text into binary value to send
	_body_bin: send binary value
	_body_lo:	-- No longer working - fix or remove!!
		this must be last header (can close query results)
		value is the oid of a large object
		fetch and send large object -- as binary???
Argument _bin_ specifies preferred way to receive binary bodies
	Only a few methods will be supported!
';

-- NEED TO CATCH ANY EXCEPTIONS AND PRODUCE
-- AN ERROR STATUS - MAYBE shim CAN DO THIS?

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

CREATE OR REPLACE
FUNCTION public.wicci_sneak(text)
RETURNS TABLE("name" text, "value" text)  AS $$
	SELECT http_request_name_text(req_row.name_), req_row.value_
	FROM unnest(parse_http_requests($1)) req_ref, http_request_rows req_row
	WHERE req_row.ref = req_ref
$$ LANGUAGE sql SET search_path FROM CURRENT;

CREATE OR REPLACE
FUNCTION public.wicci_return_array(text[])
RETURNS TABLE("name" text, "value" text)  AS $$
	SELECT i::text, x FROM array_to_set($1) foo(i INTEGER, x TEXT)
$$ LANGUAGE sql SET search_path FROM CURRENT;

CREATE OR REPLACE
FUNCTION public.wicci_get_file_text(text) RETURNS text  AS $$
	SELECT pg_read_file($1)
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION public.wicci_return_file_bytea(text) RETURNS bytea  AS $$
	SELECT pg_read_binary_file($1)
$$ LANGUAGE sql;
