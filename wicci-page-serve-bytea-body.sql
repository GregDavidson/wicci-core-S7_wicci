-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('wicci-page-serve-bytea-body.sql', '$Id');

-- Code to Serve a Wicci Page
-- Functions to support serving Wicci pages
-- Now Obsolete Experimental Branch separating out Response Body

-- ** Copyright

-- Copyright (c) 2005-2015, J. Greg Davidson.
-- You may use this file under the terms of the
-- GNU AFFERO GENERAL PUBLIC LICENSE 3.0
-- as specified in the file LICENSE.md included with this distribution.
-- All other use requires my permission in writing.

-- * wicci_serve

-- We're using bigint everywhere for the size of the body data;
-- is this really necessary or would integer do as well??

CREATE OR REPLACE FUNCTION try_wicci_serve_ajax(
	_env env_refs, _xfer http_transfer_refs,
	_user wicci_user_refs, _cookies uri_query_refs,
	_url uri_refs, page_uri page_uri_refs, doc_uri doc_page_refs,
	_doc doc_refs, ajax_action text,
	OUT _body bytea, OUT bigint,
	OUT _lang doc_lang_name_refs
) AS $$
	SELECT
		body_bytes, body_length::bigint,	'ajax'::doc_lang_name_refs
	FROM
		wicci_enter( 'try_wicci_serve_ajax(
			env_refs, http_transfer_refs, wicci_user_refs, uri_query_refs,
			uri_refs, page_uri_refs, doc_page_refs, doc_refs, text
		)', _env ) _this,
		COALESCE(
		'"' || try_uri_query_value(_url, 'type') || '"',
		'"No type!"'::text
		) body_text,
		convert_to(body_text, 'UTF8') body_bytes,
		octet_length(body_bytes) body_length,
		COALESCE( CASE
			WHEN body_length = octet_length(body_text) THEN true
			ELSE debug_warn(_this, false, 'byte_length = text_length')
		END ) _test_
$$ LANGUAGE sql STRICT;

COMMENT ON FUNCTION try_wicci_serve_ajax(
	env_refs, http_transfer_refs, wicci_user_refs, uri_query_refs,
	uri_refs, page_uri_refs, doc_page_refs,
	doc_refs, ajax_action text)
IS 'Process ajax action for given document, etc. Prototype!!
Need to return the correct language!!
Need to elegantly dispatch to handler!!';

CREATE OR REPLACE FUNCTION try_wicci_serve_body(
	_env env_refs,	_user wicci_user_refs, _cookies uri_query_refs,
	doc_uri doc_page_refs, _doc doc_refs,
	doc_lang doc_lang_name_refs,
	OUT _body bytea, OUT _len bigint,
	OUT _lang doc_lang_name_refs
) AS $$
	SELECT	body_bytes, body_length::bigint, doc_lang
	FROM wicci_enter( 'try_wicci_serve_body(
		env_refs, wicci_user_refs, uri_query_refs,
		doc_page_refs, doc_refs, doc_lang_name_refs
	)', _env ) _this,
	( SELECT wicci_doctype(doc_lang) || CASE
		WHEN is_nil(_user) THEN
			fix_wicci_body( ref_env_crefs_text_op( _doc, _env, crefs_nil() ) )
		ELSE (
			SELECT fix_wicci_body( oftd_ref_env_crefs_text_op(
				'ref_env_crefs_text_op(refs, env_refs, crefs)',
				_from, _to, _doc, _doc, _env, crefs_nil()
			) ) FROM wicci_grafts_from_to(doc_uri, _user) AS foo(_from, _to)
		)
	END ) AS foo(body_text),
	convert_to(body_text, 'UTF8') body_bytes,
	octet_length(body_bytes) body_length,
	COALESCE( CASE
		WHEN body_length = octet_length(body_text)	THEN true
		ELSE debug_warn(_this, false, 'byte_length = text_length')
	END ) _test_
$$ LANGUAGE sql STRICT;

COMMENT ON FUNCTION try_wicci_serve_body(
	env_refs, wicci_user_refs, uri_query_refs,
	doc_page_refs, doc_refs, doc_lang_name_refs
) IS 'Render a document using the Wicci process.';

CREATE OR REPLACE FUNCTION try_wicci_serve_body(
	_env env_refs, _xfer http_transfer_refs,
	_user wicci_user_refs, _cookies uri_query_refs, _url uri_refs,
	page_uri page_uri_refs, doc_uri doc_page_refs,
	OUT _body bytea, OUT _len bigint,
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
*/

CREATE OR REPLACE FUNCTION try_wicci_serve_404(
	env_refs, http_transfer_refs, wicci_user_refs,
	uri_query_refs, uri_refs, page_uri_refs,
	OUT _body bytea, OUT _len bigint,
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
	OUT _body bytea, OUT _len bigint,
	OUT _lang doc_lang_name_refs
) AS $$
	SELECT
		non_null(_body_, this, 'body'),
		non_null(_len_, this, 'len'),
		non_null(_lang_, this, 'lang')
	FROM
		debug_enter('wicci_serve_404(
			env_refs,http_transfer_refs,wicci_user_refs,
			uri_query_refs, uri_refs,page_uri_refs
		)') this,
		try_wicci_serve_404($1,$2,$3,$4,$5,$6) foo(_body_, _len_, _lang_)
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION wicci_serve_lo_body(
	doc_refs,
	_bin_ http_response_name_refs = '_body_bin', -- currently ignored
	OUT _body bytea, OUT _len bigint,
	OUT _lang doc_lang_name_refs
) AS $$
	SELECT lo_oid, octet_length(lo_oid)::bigint, lang
	FROM
		large_object_doc_rows,
		LATERAL CAST(oid::text AS bytea) lo_oid,
		debug_enter_pairs(
			'wicci_serve_lo_body(doc_refs,	http_response_name_refs)',
			name_value_pair('env_doc_page', $1)
		) WHERE ref = $1
$$ LANGUAGE sql;

COMMENT ON FUNCTION wicci_serve_lo_body(
	doc_refs,	http_response_name_refs
) IS 'Serve any static page internalized as a PostgreSQL
large object.  The second argument is ignored!!
It would be better to send the lo oid back as the
contents of a pseudo-response-header!!';


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

CREATE OR REPLACE
FUNCTION wicci_serve_file_body(
	doc_refs,
	_bin_ http_response_name_refs = '_body_bin',
	OUT _body bytea, OUT _len bigint,
	OUT _lang doc_lang_name_refs
) AS $$
	SELECT _bytes, octet_length(_bytes)::bigint, lang
	FROM
		file_doc_rows,
		LATERAL page_uri_xfiles_path(page_uri_) _path,
		LATERAL pg_read_binary_file(_path) _bytes,
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
	OUT _body bytea, OUT _len bigint,
	OUT _lang doc_lang_name_refs
) AS $$
	SELECT	_bytes_, octet_length(_bytes_)::bigint, lang
	FROM
		blob_doc_rows d,
		blob_rows b,								-- needed???
		LATERAL blob_bytes(blob_) _bytes_,
		debug_enter_pairs(
			'wicci_serve_blob_body(doc_refs, http_response_name_refs)',
			name_value_pair('env_doc_page', $1)
		)
	WHERE d.ref = $1 AND d.blob_ = b.ref
$$ LANGUAGE sql;

-- It should be the client's/Shim's responsibility to fetch
-- a lo body -- Let's provide a way for them to do so!!

CREATE OR REPLACE
FUNCTION wicci_serve_static_body(
	page_uri_refs,
	_bin_ http_response_name_refs = '_body_bin',
	OUT _body bytea,
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
  We used to try to serve large-object bodies.
';

CREATE OR REPLACE FUNCTION wicci_serve_body(
	_env env_refs, _xfer http_transfer_refs,
	_user wicci_user_refs, _url uri_refs,
	_cookies uri_query_refs,	page_uri page_uri_refs,
	_bin_ http_response_name_refs = '_body_bin',
	OUT _body bytea, OUT bigint, OUT _lang doc_lang_name_refs
) AS $$
	SELECT COALESCE(
		wicci_serve_static_body(page_uri, _bin_),
		try_wicci_serve_body(
			_env_, _xfer, _user, _cookies, _url, page_uri,
			try_doc_page(page_uri)
		),
		wicci_serve_404(_env_, _xfer, _user, _cookies, _url, page_uri)
	) FROM debug_enter(
		'wicci_serve_body(env_refs,http_transfer_refs,wicci_user_refs,uri_refs,uri_query_refs,page_uri_refs,http_response_name_refs)'
	) this,
	stati_env( this, env_http_transfer(_env, _xfer) ) env_xfer,
	stati_env( this, env_wicci_user(env_xfer, _user) ) env_user,
	stati_env( this, env_wicci_login(env_user, wicci_login_or_nil(_user)) ) env_login,
	stati_env( this, env_http_url(env_login, _url) ) env_url,
	stati_env( this, env_page_url(env_url, page_uri) ) _env_
	-- stati_env( this, env_page_url(
	-- 	stati_env( this, env_http_url(
	-- 		stati_env( this, try_env_wicci_login(
	-- 			stati_env( this, try_env_wicci_user(
	-- 				stati_env( this, env_http_transfer(_env, _xfer) ),
	-- 			_user ) ),
	-- 		wicci_login(_user)) ),
	-- 	_url ) ),
	-- page_uri ) ) _env_
$$ LANGUAGE sql;

COMMENT ON FUNCTION wicci_serve_body(
	env_refs, http_transfer_refs, wicci_user_refs, uri_refs,
	uri_query_refs,	page_uri_refs, http_response_name_refs
) IS 'Serve the body of whatever kind, including a 404';

CREATE OR REPLACE FUNCTION try_wicci_serve_responses(
	_env env_refs, _xfer http_transfer_refs,
	_user wicci_user_refs, _uri uri_refs,	_cookies uri_query_refs,
	body_len bigint, _lang doc_lang_name_refs
) RETURNS http_response_refs[] AS $$
	SELECT array_non_nulls( ARRAY(
		SELECT COALESCE(
			CASE name_								-- try_ --> find_ !! just below:
				WHEN try_http_response_name('Date') THEN wicci_date()
				WHEN try_http_response_name('Set-Cookie') THEN
					try_wicci_cookie(_env, _xfer, _user, _cookies, _uri)
				WHEN try_http_response_name('Content-Length') THEN
					get_http_response('Content-Length', body_len::text)
			END,
			try_http_response( env_obj_feature_value(_env, _xfer, name_) ),
			wicci_response_default(_lang, name_)
		) FROM wicci_response_names	-- a simple list
	) ) FROM debug_enter( 'try_wicci_serve_responses(
		env_refs, http_transfer_refs, wicci_user_refs,
		uri_refs,	uri_query_refs,	bigint, doc_lang_name_refs
		)', _xfer
	)
$$ LANGUAGE sql STRICT;

COMMENT ON FUNCTION try_wicci_serve_responses(
	env_refs, http_transfer_refs, wicci_user_refs,
	uri_refs, uri_query_refs,
	bigint, doc_lang_name_refs
) IS 'Generate the response headers.';

CREATE OR REPLACE FUNCTION wicci_serve(
	_xfer http_transfer_refs,
	_url uri_refs,
	_cookies uri_query_refs,
	_bin_ http_response_name_refs = '_body_bin'
) RETURNS http_transfer_refs  AS $$
	SELECT drop_env_give_value(
		_env,
		set_http_transfer_responses(
			CASE WHEN is_nil(_user) THEN $1 ELSE
				( get_wicci_transfers_users(_xfer, _user ) ).xfer_
			END,		-- in passing, associate xfer with the user
			response_refs  /* , _body */ )
	) FROM
	make_user_env() _env,
	wicci_user_or_nil(_url, _cookies) _user,
	set_wicci_transfer_user(_xfer, _user) foo(_xfer_, _user_),
	wicci_serve_body(_env,_xfer_,_user_,$2,$3,find_page_uri($2),_bin_)
		bar(_body, body_len, _lang),
	try_wicci_serve_responses(
		_env,_xfer_,_user_,$2,_cookies, body_len, _lang
	) response_refs,
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
FUNCTION wicci_serve_responses(
  headers bytea, body bytea, _bin_ http_response_name_refs = '_body_bin'
) RETURNS SETOF http_response_refs AS $$
	SELECT unnest( http_transfer_responses(
		wicci_serve( _xfer, _url, _cookies, _bin_ )
	) ) FROM
		new_http_transfer($1, $2) foo(_xfer, _url, _cookies),
		debug_enter('wicci_serve_responses(bytea, bytea, http_response_name_refs)', $1)
$$ LANGUAGE sql;

COMMENT ON
FUNCTION wicci_serve_responses(bytea, bytea, http_response_name_refs) IS '
	Convert an http request in headers bytea, body bytea form
	into a new http_transfer object.  Have wicci_serve fill in
	the response headers which we extract and hand back as an
	ordered set.';

CREATE OR REPLACE
FUNCTION public.wicci_serve(bytea, bytea, _bin_ text = '_body_bin')
RETURNS TABLE("name" text, text_value text, binary_value bytea)  AS $$
	SELECT http_response_name_text(name_), text_value, binary_value FROM
  	http_response_rows _row,
		debug_enter('wicci_serve(bytea,bytea,text)', $1, $3) _this,
		non_null(try_http_response_name(_bin_), _this) _bin,
		wicci_serve_responses($1, $2, _bin) response,
		supported_binary_doc_formats
	WHERE ref = response
	AND storage_policy = static_doc_storage_policy() -- ???
	AND request_format = _bin
$$ LANGUAGE sql SET search_path FROM CURRENT;

COMMENT ON FUNCTION public.wicci_serve(bytea, bytea, text) IS
'
Given http request headers as LATIN1-encoded bytes and the
body as bytes with an encoding TBD, serve the response as an
ordered set of response headers.  Header names starting with
_ are to be handled in special ways by the proxy server:
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
-- AN ERROR STATUS.  WHERE WE DON'T, shim MUST!!!
