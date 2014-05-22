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
				SELECT debug_on( 'wicci_serve(text,http_response_name_refs)', true);
				SELECT debug_on( 'wicci_serve(http_transfer_refs,uri_refs,uri_query_refs,http_response_name_refs)', true);
				-- SELECT debug_on( 'wicci_serve(env_refs, http_transfer_refs)', true);
				SELECT debug_on( 'try_wicci_serve_responses(
					env_refs, http_transfer_refs, wicci_user_refs,
					uri_refs, uri_query_refs, http_response_name_refs
				)', true );
				SELECT debug_on( 'wicci_serve_responses(text,http_response_name_refs)', true );
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
				SELECT debug_on( 'try_parse_http_requests(text)', true );
				SELECT debug_on( 'new_http_transfer(text)', true );
				SELECT debug_on( 'try_new_http_transfer(text)', true );
				SELECT debug_on( 'try_parse_http_requests(text)', true );
				SELECT debug_on( 'try_new_http_transfer(text)', true );
$$ LANGUAGE sql SET search_path FROM CURRENT;

SELECT wicci_debug_on();

-- SELECT test_func(
-- 	'find_wicci_user(http_transfer_refs)',
-- 	find_wicci_user( http_transfer_rows_ref('host-simple') ),
-- 	wicci_user_nil()
-- );

-- SELECT test_func(
-- 	'find_doc_page(http_transfer_refs)',
-- 	find_doc_page( http_transfer_rows_ref('host-simple') ),
-- 	find_doc_page('simple.html')
-- );

-- SELECT wicci_serve( http_transfer_rows_ref('host-simple') );

SELECT doc_page_doc( find_doc_page('simple.html') );

SELECT tree_doc_text(simple)
FROM find_page_doc('simple.html') simple;

SELECT http_requests_text(http_transfer_requests(http_transfer_rows_ref('host-simple-greg')));

SELECT http_transfer_rows_ref('host-simple-greg')^'_url';

SELECT * FROM uri_rows
WHERE ref = try_get_uri(http_transfer_rows_ref('host-simple-greg')
^'_url');

SELECT try_get_uri( http_transfer_rows_ref('host-simple-greg')
^'_url')^'user';

SELECT try_get_uri(
	http_transfer_rows_ref('host-simple-greg')^'_url'
)^'user';

-- returns NULL!!!
SELECT try_entity_uri( try_get_uri(
	http_transfer_rows_ref('host-simple-greg')^'_url'
)^'user', 'user');

SELECT try_wicci_user( try_entity_uri(try_get_uri(
	http_transfer_rows_ref('host-simple-greg')^'_url'
)^'user', 'user') );

-- SELECT wicci_serve( http_transfer_rows_ref('host-simple-greg') );

CREATE OR REPLACE
FUNCTION real_transfer(text, text, text = NULL, text = 'wicci.org')
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
	COALESCE('Cookie: user=user:' || $3 || '@' || $4 || E'\n', '') ||
	E'\n'													-- empty body
$$ LANGUAGE sql;

SELECT real_transfer('wicci.org', '/simple', 'greg');

SELECT COALESCE(
	http_transfer_rows_ref('real-simple'),
	http_transfer_rows_ref('real-simple',
		new_http_xfer( real_transfer(
		'wicci.org', '/simple', 'greg'
		) )
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

-- returns NULL!!!
SELECT find_wicci_user( http_transfer_rows_ref('real-simple') );

SELECT fresh_http_transfer('real-simple');

SELECT try_get_http_requests_url(request)
FROM http_transfer_rows WHERE ref=http_transfer_rows_ref('real-simple');

SELECT get_http_requests_cookies(request)
FROM http_transfer_rows WHERE ref=http_transfer_rows_ref('real-simple');

SELECT array( select http_request_text(r) from unnest(request) r )
FROM http_transfer_rows WHERE ref=http_transfer_rows_ref('real-simple');

SELECT http_transfer_text(ref)
FROM http_transfer_rows WHERE ref=http_transfer_rows_ref('real-simple');

SELECT http_transfer_text(wicci_serve(ref))
FROM http_transfer_rows WHERE ref=http_transfer_rows_ref('real-simple');

SELECT wicci_serve( real_transfer('wicci.org', '/simple', 'greg') );

SELECT COALESCE(
	http_transfer_rows_ref('real-fancy-greg'),
	http_transfer_rows_ref('real-fancy-greg', new_http_xfer( real_transfer(
	'wicci.org', '/fancy', 'greg'
) ) ) );

SELECT fresh_http_transfer('real-fancy-greg');
SELECT http_transfer_text(wicci_serve(ref))
FROM http_transfer_rows
WHERE ref = http_transfer_rows_ref('real-fancy-greg');

SELECT COALESCE(
	http_transfer_rows_ref('real-fancy-sher'),
	http_transfer_rows_ref('real-fancy-sher', new_http_xfer( real_transfer(
	'wicci.org', '/fancy', 'sher'
) ) ) );

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

') ) ) FROM handles('wicci_hello_as_greg') x;

SELECT fresh_http_transfer('wicci_hello_as_greg');
SELECT http_transfer_text(wicci_serve(ref))
FROM http_transfer_rows
WHERE ref = http_transfer_rows_ref('wicci_hello_as_greg');

SELECT COALESCE(
	http_transfer_rows_ref(x),
	http_transfer_rows_ref(x, new_http_xfer(
'GET /Entity-Icon/group-bm.jpg?user=greg@wicci.org HTTP/1.1
Host: wicci.org:8080
User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:7.0.1) Gecko/20100101 Firefox/7.0.1
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: en-us,en;q=0.5
Accept-Encoding: gzip, deflate
Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7
Connection: keep-alive

') ) ) FROM handles('wicci_group_jpg_as_greg') x;

SELECT fresh_http_transfer('wicci_group_jpg_as_greg');
SELECT http_transfer_text(wicci_serve(ref))
FROM http_transfer_rows
WHERE ref = http_transfer_rows_ref('wicci_group_jpg_as_greg');

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

') ) ) FROM handles('wicci_home_svg_as_greg') x;

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

') ) ) FROM handles('hello_svg_as_greg') x;

SELECT fresh_http_transfer('hello_svg_as_greg');
SELECT http_transfer_text(wicci_serve(ref))
FROM http_transfer_rows
WHERE ref = http_transfer_rows_ref('hello_svg_as_greg');
