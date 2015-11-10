-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('wicci-page-test.sql', '$Id');

-- Wicci Page Test
-- Test Serving Pages with the Wicci System

-- ** Copyright

-- Copyright (c) 2005 - 2012, J. Greg Davidson.
-- You may use this file under the terms of the
-- GNU AFFERO GENERAL PUBLIC LICENSE 3.0
-- as specified in the file LICENSE.md included with this distribution.
-- All other use requires my permission in writing.

-- *
-- put in some more tests here!!!

CREATE OR REPLACE FUNCTION public.wicci_debug_on() RETURNS void AS $$
				SELECT debug_on( 'wicci_serve(bytea, bytea, text)', true);
				SELECT debug_on( 'wicci_serve(http_transfer_refs,uri_refs,uri_query_refs,http_response_name_refs)', true);
				-- SELECT debug_on( 'wicci_serve(env_refs, http_transfer_refs)', true);
				SELECT debug_on( 'try_wicci_serve_responses(
					env_refs, http_transfer_refs, wicci_user_refs,
					uri_refs, uri_query_refs, http_response_refs, bigint, doc_lang_name_refs
				)', true );
				SELECT debug_on( 'wicci_serve_responses(bytea, bytea, http_response_name_refs)', true );
				SELECT debug_on('wicci_serve_file_body(doc_refs, http_response_name_refs)', true);
				SELECT debug_on( 'try_wicci_serve_responses(
						env_refs, http_transfer_refs, wicci_user_refs, uri_refs,
						uri_query_refs,	http_response_refs, bigint, doc_lang_name_refs
				)', true );
				SELECT debug_on( 'try_wicci_serve_ajax(
					env_refs, http_transfer_refs, wicci_user_refs, uri_query_refs,
					uri_refs, page_uri_refs, doc_page_refs,
					doc_refs, text
				)', true );
				SELECT debug_on( 'try_wicci_serve_body(
					env_refs, wicci_user_refs, uri_query_refs,
					doc_page_refs, doc_refs, doc_lang_name_refs
				)', true );
				SELECT debug_on( 'try_wicci_serve_body(
					env_refs, http_transfer_refs,
					wicci_user_refs, uri_query_refs, uri_refs,
					page_uri_refs, doc_page_refs
				)', true );
				SELECT debug_on(
					'wicci_serve_static_body(page_uri_refs,	http_response_name_refs)', true
				);
				SELECT debug_on( 'try_parse_http_requests(bytea)', true );
				SELECT debug_on( 'new_http_transfer(bytea, bytea)', true );
				SELECT debug_on( 'try_new_http_transfer(bytea, bytea)', true );
				SELECT debug_on( 'try_parse_http_requests(bytea)', true );
$$ LANGUAGE sql SET search_path FROM CURRENT;

SELECT wicci_debug_on();

-- these things need to be tests!!!

SELECT doc_page_doc( find_doc_page('simple.html') );

SELECT tree_doc_text(simple)
FROM find_page_doc('simple.html') simple;

SELECT http_requests_text(http_transfer_requests(http_transfer_rows_ref('simple-greg')));

SELECT http_transfer_rows_ref('simple-greg')^'_url';

SELECT * FROM uri_rows
WHERE ref = try_get_uri(http_transfer_rows_ref('simple-greg')
^'_url');

SELECT try_get_uri( http_transfer_rows_ref('simple-greg')
^'_url')^'user';

SELECT try_get_uri(
	http_transfer_rows_ref('simple-greg')^'_url'
)^'user';

-- returns NULL!!!
SELECT try_entity_uri( try_get_uri(
	http_transfer_rows_ref('simple-greg')^'_url'
)^'user', 'user');

SELECT try_wicci_user( try_entity_uri(try_get_uri(
	http_transfer_rows_ref('simple-greg')^'_url'
)^'user', 'user') );

-- SELECT wicci_serve( http_transfer_rows_ref('simple-greg') );

CREATE OR REPLACE
FUNCTION real_transfer_(text, text, text = NULL, text = 'wicci.org')
RETURNS text AS $$
SELECT
	'GET ' || $2 || COALESCE(
		'?user=user:' || $3 || '@' || $4, ''
	) || ' HTTP/1.1' || E'\n' ||
	'Host: ' || $1 || ':8080' || E'\n' ||
	'User-Agent: Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.9.2.6) '
		|| 'Gecko/20100626 SUSE/3.6.6-1.1 Firefox/3.6.6' || E'\n' ||
	'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
		|| E'\n' ||
	'Accept-Language: en-us,en;q=0.5' || E'\n' ||
	'Accept-Encoding: gzip,deflate' || E'\n' ||
	'Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7' || E'\n' ||
	'Keep-Alive: 115' || E'\n' ||
	'Connection: keep-alive Cache-Control: max-age=0' || E'\n' ||
	COALESCE('Cookie: user=user:' || $3 || '@' || $4 || E'\n', '')
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION real_transfer(text, text, text = NULL, text = 'wicci.org')
RETURNS bytea AS $$
	SELECT latin1(real_transfer_($1, $2, $3, $4))
$$ LANGUAGE sql;

COMMENT ON FUNCTION real_transfer(text, text, text, text)
IS 'returns all but the body of a real transfer';

SELECT real_transfer_('wicci.org', '/simple', 'greg');

SELECT COALESCE(
	http_transfer_rows_ref('real-simple'),
	http_transfer_rows_ref('real-simple',
		new_http_xfer( real_transfer_('wicci.org', '/simple', 'greg'), '' )
	)
);

SELECT get_uri(
	COALESCE(simple^'host', '') || simple^'_url'
) FROM http_transfer_rows_ref('real-simple') simple;

-- SELECT get_page_uri( get_uri(
-- 	COALESCE( simple^'host' '')
--	|| simple^'_url'
-- ) ) FROM http_transfer_rows_ref('real-simple') simple;

-- SELECT doc_page_refs(simple), wicci_user_refs(simple)
-- FROM http_transfer_rows_ref('real-simple') simple;

-- SELECT drop_env_give_value(
-- 	env,
-- 	E'\n' || wicci_serve(
-- 		env,
-- 		doc_page_refs(simple),
-- 		wicci_user_refs(simple),
-- 		simple
-- 	)
-- ) FROM
-- 	make_user_env() env,
-- 	http_transfer_rows_ref('real-simple') simple;


SELECT http_requests_text(http_transfer_requests(
	http_transfer_rows_ref('real-simple')
));

SELECT find_wicci_user_or_nil( http_transfer_rows_ref('real-simple') );

SELECT fresh_http_transfer('real-simple');

SELECT try_get_http_requests_url(request)
FROM http_transfer_rows WHERE ref=http_transfer_rows_ref('real-simple');

SELECT get_http_requests_cookies(request)
FROM http_transfer_rows WHERE ref=http_transfer_rows_ref('real-simple');

SELECT array( select http_request_text(r) from unnest(request) r )
FROM http_transfer_rows WHERE ref=http_transfer_rows_ref('real-simple');

-- blob_length of request_body gives NULL error!!!  patched in http_transfer_text for now!!!
SELECT http_transfer_text(ref)
FROM http_transfer_rows WHERE ref=http_transfer_rows_ref('real-simple');

-- IS NULL!!!
SELECT http_transfer_text(wicci_serve(http_transfer_rows_ref('real-simple')));

-- STILL NULL!!!
SELECT http_transfer_text(x) IS NULL
FROM
	http_transfer_rows,
	wicci_serve(ref, get_http_requests_url(request), get_http_requests_cookies(request)) x
WHERE ref = http_transfer_rows_ref('real-simple');

SELECT http_transfer_rows_ref('real-simple');

-- x is NULL!
SELECT _url, _cookies, x::text, http_transfer_text(x)
FROM
	http_transfer_rows,
	get_http_requests_url(request) _url,
	get_http_requests_cookies(request) _cookies,
	wicci_serve(ref, _url, _cookies) x
WHERE ref = http_transfer_rows_ref('real-simple');

-- works great!
SELECT wicci_serve( xfer, '' )
FROM real_transfer('wicci.org', '/simple', 'greg') xfer;

SELECT COALESCE(
	http_transfer_rows_ref('real-fancy-greg'),
	http_transfer_rows_ref(
		'real-fancy-greg',
		 new_http_xfer( real_transfer_('wicci.org', '/fancy', 'greg'), '')
) );

SELECT fresh_http_transfer('real-fancy-greg');

SELECT http_transfer_text(wicci_serve(ref))
FROM http_transfer_rows
WHERE ref = http_transfer_rows_ref('real-fancy-greg');

SELECT COALESCE(
	http_transfer_rows_ref('real-fancy-sher'),
	http_transfer_rows_ref(
		'real-fancy-sher',
		new_http_xfer( real_transfer_('wicci.org', '/fancy', 'sher'), '' )
) );

SELECT fresh_http_transfer('real-fancy-sher');

SELECT http_transfer_text(wicci_serve(ref))
FROM http_transfer_rows
WHERE ref=http_transfer_rows_ref('real-fancy-sher');

SELECT COALESCE(
	http_transfer_rows_ref('favicon'),
	http_transfer_rows_ref('favicon', new_http_xfer(
'GET /favicon.ico HTTP/1.1' || E'\n' ||
'Host: localhost:8080' || E'\n' ||
'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:7.0.1) Gecko/20100101 Firefox/7.0.1' || E'\n' ||
'Accept: image/png,image/*;q=0.8,*/*;q=0.5' || E'\n' ||
'Accept-Language: en-us,en;q=0.5' || E'\n' ||
'Accept-Encoding: gzip, deflate' || E'\n' ||
'Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7' || E'\n' ||
'Connection: keep-alive' || E'\n' ||
E'\n'
) ) );

SELECT fresh_http_transfer('favicon');

SELECT http_transfer_text(fresh_http_transfer('favicon'));

SELECT http_transfer_text(wicci_serve(ref))
FROM http_transfer_rows
WHERE ref = http_transfer_rows_ref('favicon');

SELECT latin1(latin1('GET /hello.html?host=wicci.org,user=greg@wicci.org HTTP/1.1
Host: localhost:8080
User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:7.0.1) Gecko/20100101 Firefox/7.0.1
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: en-us,en;q=0.5
Accept-Encoding: gzip, deflate
Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7
Connection: keep-alive
'));

SELECT COALESCE(
	http_transfer_rows_ref(x),
	http_transfer_rows_ref(x, new_http_xfer(
'GET /hello.html?host=wicci.org,user=greg@wicci.org HTTP/1.1
Host: localhost:8080
User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:7.0.1) Gecko/20100101 Firefox/7.0.1
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: en-us,en;q=0.5
Accept-Encoding: gzip, deflate
Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7
Connection: keep-alive
'::text, ''::bytea) ) )
FROM handles('wicci_hello_as_greg') x;

SELECT fresh_http_transfer('wicci_hello_as_greg');
SELECT http_transfer_text(wicci_serve(ref))
FROM http_transfer_rows
WHERE ref = http_transfer_rows_ref('wicci_hello_as_greg');

SELECT COALESCE(
	http_transfer_rows_ref(x),
	http_transfer_rows_ref(x, new_http_xfer(
'GET /Entity-Icon/deadbeef.jpg?user=greg@wicci.org HTTP/1.1
Host: wicci.org:8080
User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:7.0.1) Gecko/20100101 Firefox/7.0.1
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: en-us,en;q=0.5
Accept-Encoding: gzip, deflate
Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7
Connection: keep-alive
'::text, ''::bytea) ) ) FROM handles('wicci_deadbeef_jpg_as_greg') x;

SELECT fresh_http_transfer('wicci_deadbeef_jpg_as_greg');

SELECT http_transfer_text(wicci_serve(ref))
FROM http_transfer_rows
WHERE ref = http_transfer_rows_ref('wicci_deadbeef_jpg_as_greg');

SELECT COALESCE(
	http_transfer_rows_ref(x),
	http_transfer_rows_ref(x, new_http_xfer(
'GET /Theme/wicci-home.svg?user=greg@wicci.org HTTP/1.1
Host: wicci.org:8080
User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:7.0.1) Gecko/20100101 Firefox/7.0.1
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: en-us,en;q=0.5
Accept-Encoding: gzip, deflate
Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7
Connection: keep-alive
'::text, ''::bytea) ) ) FROM handles('wicci_home_svg_as_greg') x;

SELECT fresh_http_transfer('wicci_home_svg_as_greg');
SELECT http_transfer_text(wicci_serve(ref))
FROM http_transfer_rows
WHERE ref = http_transfer_rows_ref('wicci_home_svg_as_greg');

SELECT COALESCE(
	http_transfer_rows_ref(x),
	http_transfer_rows_ref(x, new_http_xfer(
'GET /hello-svg.html?user=greg@wicci.org HTTP/1.1
Host: wicci.org:8080
User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:7.0.1) Gecko/20100101 Firefox/7.0.1
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: en-us,en;q=0.5
Accept-Encoding: gzip, deflate
Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7
Connection: keep-alive
', '') ) ) FROM handles('hello_svg_as_greg') x;

SELECT fresh_http_transfer('hello_svg_as_greg');
SELECT http_transfer_text(wicci_serve(ref))
FROM http_transfer_rows
WHERE ref = http_transfer_rows_ref('hello_svg_as_greg');
