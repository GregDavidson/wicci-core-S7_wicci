-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('wicci-page-simple-test.sql', '$Id');

-- Wicci Page Test Data
-- Data to support testing the Wicci System

-- ** Copyright

-- Copyright (c) 2005-2012, J. Greg Davidson.
-- You may use this file under the terms of the
-- GNU AFFERO GENERAL PUBLIC LICENSE 3.0
-- as specified in the file LICENSE.md included with this distribution.
-- All other use requires my permission in writing.

CREATE OR REPLACE
FUNCTION wicci_serve(http_transfer_refs)
RETURNS http_transfer_refs  AS $$
	SELECT wicci_serve(
		$1, 
	 	get_http_requests_url(request), -- will kill the query if this is null!!!
		get_http_requests_cookies(request)
	) FROM http_transfer_rows WHERE ref = $1
$$ LANGUAGE sql SET search_path FROM CURRENT;

COMMENT ON FUNCTION wicci_serve(http_transfer_refs)
IS 'only for testing';

SELECT http_requests_text(
	http_transfer_requests(http_transfer_rows_ref('simple'))
);

SELECT debug_on(
	'wicci_serve(http_transfer_refs,uri_refs,uri_query_refs,http_response_name_refs)',
	true
);

SELECT debug_on(
	'try_wicci_serve_responses(
		env_refs, http_transfer_refs,
		wicci_user_refs, uri_refs,	uri_query_refs,
		http_response_refs,  bigint, doc_lang_name_refs
	)',
	true
);

SELECT test_func(
	'drop_http_response(http_transfer_refs)',
	fresh_http_transfer('simple') IS NOT NULL
);

SELECT test_func(
	'blob_length(blob_refs)',
	blob_length(request_body),
	hubba_length()
) FROM http_transfer_rows tr
WHERE tr.ref = http_transfer_rows_ref('simple');

SELECT test_func(
	'blob_bytes(blob_refs)',
	blob_bytes(request_body),
	hubba_bytes()
) FROM http_transfer_rows tr
WHERE tr.ref = http_transfer_rows_ref('simple');

SELECT test_func(
	'try_get_http_requests_url(http_request_refs[])',
	try_get_http_requests_url(request),
	'wicci.org/simple.html'
) FROM http_transfer_rows
WHERE ref = http_transfer_rows_ref('simple');

SELECT test_func(
	'get_http_requests_cookies(http_request_refs[])',
	get_http_requests_cookies(request),
	''
) FROM http_transfer_rows
WHERE ref = http_transfer_rows_ref('simple');

SELECT test_func(
	'get_http_requests_url(http_request_refs[])',
	get_http_requests_url(request),
	'wicci.org/simple.html'
) FROM http_transfer_rows
WHERE ref = http_transfer_rows_ref('simple');

SELECT test_func(
	'try_wicci_user(uri_refs, uri_query_refs)',
	try_wicci_user( try_get_http_requests_url(request), get_http_requests_cookies(request) ) IS NULL
) FROM http_transfer_rows
WHERE ref = http_transfer_rows_ref('simple');

SELECT test_func(
	'get_http_requests_url(http_request_refs[])',
	uri_text( get_http_requests_url(request) ),
	'wicci.org/simple.html'
) FROM	http_transfer_rows htr
WHERE htr.ref = http_transfer_rows_ref('simple');

SELECT test_func(
	'get_http_requests_cookies(http_request_refs[])',
	is_nil( get_http_requests_cookies(request) )
) FROM http_transfer_rows htr
WHERE htr.ref = http_transfer_rows_ref('simple');

SELECT test_func(
	'wicci_user_or_nil(uri_refs, uri_query_refs)',
	is_nil( wicci_user_or_nil( _url, _cookies ) )
) FROM
	http_transfer_rows htr,
	get_http_requests_url(request) _url,
	get_http_requests_cookies(request) _cookies
WHERE htr.ref = http_transfer_rows_ref('simple');

SELECT test_func(
	'wicci_user_or_nil(uri_refs, uri_query_refs)',
	wicci_user_or_nil( _url, _cookies ),
	'user:greg@wicci.org'
) FROM
	http_transfer_rows htr,
	get_http_requests_url(request) _url,
	get_http_requests_cookies(request) _cookies
WHERE htr.ref = http_transfer_rows_ref('simple-greg');

SELECT drop_env_give_value(	_env_, (
	SELECT test_func(
		this, (
			uri_text(_url), uri_query_text(_cookies), wicci_user_text(_user), page_uri_text(page_uri),
			is_nil(env_xfer), is_nil(env_user), is_nil(env_login), is_nil(env_url), is_nil(env_page)
		) = ('wicci.org/simple.html','','','wicci.org/simple.html',false, false, false, false, false)
	) FROM
		get_http_requests_url(request) _url,
		get_http_requests_cookies(request) _cookies,
		wicci_user_or_nil(_url, _cookies) _user,
		find_page_uri(_url) page_uri,
		stati_env( this, env_http_transfer(_env_, htr.ref) ) env_xfer,
		stati_env( this, env_wicci_user( env_xfer, _user ) ) env_user,
		stati_env( this, env_wicci_login( env_user,	wicci_login_or_nil(_user)) ) env_login,
		stati_env( this, env_http_url( env_login, _url ) ) env_url,
		stati_env( this, env_page_url( env_url, page_uri ) ) env_page
)) FROM
		COALESCE('wicci_serve_body(env_refs,http_transfer_refs,wicci_user_refs,uri_refs,uri_query_refs,page_uri_refs,http_response_name_refs)'::regprocedure) this,
		http_transfer_rows htr,
		make_user_env() _env_
WHERE htr.ref = http_transfer_rows_ref('simple');

-- this is returning a 404 !!!
SELECT drop_env_give_value(	_env, http_response_text(_body) ) FROM
	http_transfer_rows htr,
	make_user_env() _env,
	get_http_requests_url(request) _url,
	get_http_requests_cookies(request) _cookies,
	wicci_user_or_nil(_url, _cookies) _user,
	wicci_serve_body( _env,htr.ref,_user,_url,_cookies,find_page_uri(_url) )
		bar(_body, body_len, _lang)
WHERE htr.ref = http_transfer_rows_ref('simple');

SELECT http_transfer_text(wicci_serve(request))
FROM http_transfer_rows_ref('simple') request;

SELECT http_transfer_responses(
	http_transfer_rows_ref('simple')
)^'_body';

SELECT test_func(
	'http_request_text(http_request_refs)',
	http_requests_text(request),
	E'_type: GET\n_url: simple.html\n_protocol: HTTP/1.1\nHost: wicci.org\n'
) FROM http_transfer_rows
WHERE ref =http_transfer_rows_ref('simple');

SELECT test_func(
	'http_request_text(http_request_refs)',
	http_requests_text(request),
	E'_type: GET\n_url: simple.html\n_protocol: HTTP/1.1\nHost: wicci.org\n'
) FROM http_transfer_rows
WHERE ref =http_transfer_rows_ref('simple');

-- make tests of the rest of these!!!

SELECT http_responses_text( http_transfer_responses(
	http_transfer_rows_ref('simple')
) );

SELECT CASE WHEN _env IS NOT NULL THEN drop_env( _env ) END
FROM try_env('simple-nobody') _env;

SELECT env_rows_ref('simple-nobody', make_user_env());
SELECT fresh_http_transfer('simple');
SELECT http_responses_text(try_wicci_serve_responses(
	_env,	ref, _user, _url, _cookies,
	_body, body_len, _lang
)), _body
FROM http_transfer_rows,
	env_rows_ref('simple-nobody') _env,
	wicci_user_nil() _user,
	get_http_requests_url(request) _url,
	get_http_requests_cookies(request) _cookies,
	wicci_serve_body(_env, ref, _user, _url, _cookies, find_page_uri(_url))
		bar(_body, body_len, _lang)
WHERE ref = http_transfer_rows_ref('simple');

SELECT wicci_grafts_from_to(
	find_doc_page('simple.html'),
	find_wicci_user('user:greg@wicci.org')
);

SELECT CASE WHEN _env IS NOT NULL THEN drop_env( _env ) END
FROM try_env( 'simple-greg' ) _env;

SELECT env_rows_ref('simple-greg', make_user_env());

SELECT fresh_http_transfer('simple');

SELECT http_responses_text(try_wicci_serve_responses(
	env_rows_ref('simple-greg'), ref,
	find_wicci_user('user:greg@wicci.org'),
	get_http_requests_url(request),
	get_http_requests_cookies(request),
	http_small_text_response_nil(), 0, doc_lang_name_nil()
)) FROM http_transfer_rows
WHERE ref = http_transfer_rows_ref('simple');

-- Test wicci_serve as it will be called from Shim:

SELECT refs_ready();

-- this is returning a big mess of a 404!!!
-- SELECT test_func(
-- 	'wicci_serve(bytea,bytea,text)',
-- 	( SELECT array_agg(el)
-- 		FROM
-- 			(	SELECT ARRAY[h, v, latin1(b)]
-- 				FROM wicci_serve(
-- 					latin1(E'GET /simple.html?host=wicci.org&user=greg@wicci.org HTTP/1.1\r\nMIME-Version: 1.0\r\nConnection: keep-alive\r\nExtension: Security/Digest Security/SSL\r\nHost: localhost:8080\r\nAccept-encoding: gzip\r\nAccept: */*\r\nUser-Agent: URL/Emacs\r\n'),
-- 					latin1(''),
-- 					'_body_bin'
-- 				) AS foo(h,v,b)
-- 			) foo(ra),
-- 			unnest(ra) el
-- 		),
-- ARRAY[

-- 	]
-- );

