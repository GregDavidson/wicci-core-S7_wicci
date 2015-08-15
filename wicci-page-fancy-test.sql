-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('wicci-page-fancy-test.sql', '$Id');

-- *

SELECT COALESCE(
	http_transfer_rows_ref('fancy'),
	http_transfer_rows_ref('fancy',
		new_http_xfer(
			'GET fancy.html HTTP/1.1' || nl
			|| 'User-Agent: Mozilla' || nl,
			hubba_bytes()
) )	) FROM text(E'\r\n') nl;

SELECT fresh_http_transfer('fancy');
SELECT http_transfer_text(wicci_serve(http_transfer_rows_ref('fancy')));

-- SELECT test_func(
-- 	'wicci_serve(http_transfer_refs)',
-- 	http_transfer_responses(http_transfer_rows_ref('fancy'))^'_body';
-- 	' <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">XS'
-- );

SELECT CASE WHEN _env IS NOT NULL THEN drop_env( _env ) END
FROM try_env( 'fancy-nobody' ) _env;

SELECT env_rows_ref('fancy-nobody', make_user_env());

SELECT fresh_http_transfer('fancy');
SELECT http_responses_text(try_wicci_serve_responses(
	env_rows_ref('fancy-nobody'), ref,
	wicci_user_nil(),
 try_get_http_requests_url(request),
 get_http_requests_cookies(request)
)) FROM http_transfer_rows
WHERE ref = http_transfer_rows_ref('fancy');

SELECT wicci_grafts_from_to(
	find_doc_page('fancy.html'),
	find_wicci_user_or_nil('user:greg@wicci.org')
);

SELECT CASE WHEN _env IS NOT NULL THEN drop_env( _env ) END
FROM try_env( 'fancy-greg' ) _env;

SELECT env_rows_ref('fancy-greg', make_user_env());

SELECT fresh_http_transfer('fancy');
SELECT http_responses_text(try_wicci_serve_responses(
	env_rows_ref('fancy-greg'),	ref,
	find_wicci_user_or_nil('user:greg@wicci.org'),
 try_get_http_requests_url(request),
 get_http_requests_cookies(request)
)) FROM http_transfer_rows
WHERE ref = http_transfer_rows_ref('fancy');
