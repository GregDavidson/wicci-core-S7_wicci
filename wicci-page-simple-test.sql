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

SELECT http_requests_text(
	http_transfer_requests(http_transfer_rows_ref('simple'))
);

SELECT debug_on(
	'wicci_serve(http_transfer_refs,uri_refs,uri_query_refs)',
	true
);

SELECT debug_on(
	'try_wicci_serve_responses(
		env_refs, http_transfer_refs,
		wicci_user_refs, uri_refs, uri_query_refs
	)',
	true
);

SELECT fresh_http_transfer('simple');
SELECT http_transfer_text(wicci_serve(http_transfer_rows_ref('simple')));

SELECT http_transfer_responses(
	http_transfer_rows_ref('simple')
)^'_body';

-- SELECT test_func(
-- 	'wicci_serve(http_transfer_refs)',
-- 	http_transfer_responses(http_transfer_rows_ref('simple'))^'_body';
-- 	' <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">XS'
-- );

SELECT http_responses_text( http_transfer_responses(
	http_transfer_rows_ref('simple')
) );

SELECT CASE WHEN _env IS NOT NULL THEN drop_env( _env ) END
FROM try_env('simple-nobody') _env;

SELECT env_rows_ref('simple-nobody', make_user_env());

SELECT fresh_http_transfer('simple');
SELECT http_responses_text(try_wicci_serve_responses(
	env_rows_ref('simple-nobody'),
	ref,
	wicci_user_nil(),
	 try_get_http_requests_url(request),
	 get_http_requests_cookies(request)
)) FROM http_transfer_rows
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
	 try_get_http_requests_url(request),
	 get_http_requests_cookies(request)
)) FROM http_transfer_rows
WHERE ref = http_transfer_rows_ref('simple');
