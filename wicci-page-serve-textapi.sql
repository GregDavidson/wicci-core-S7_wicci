-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('wicci-page-serve-textapi.sql', '$Id');

-- Code to Serve a Wicci Page
-- Functions to support serving Wicci pages

-- Deprecated Old Text API
-- Request is passed as an unparsed text object

-- Also includes some Testing Funcitons

-- ** Copyright

-- Copyright (c) 2005-2015, J. Greg Davidson.
-- You may use this file under the terms of the
-- GNU AFFERO GENERAL PUBLIC LICENSE 3.0
-- as specified in the file LICENSE.md included with this distribution.
-- All other use requires my permission in writing.

-- Building up to wicci_serve

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
Original obsolete code for converting an http request
encoded as text into a new_http_transfer object and
wicci_serve it to create response headers.	See instead
wicci_serve_responses(bytea, bytea, http_response_name_refs)';

CREATE OR REPLACE
FUNCTION public.wicci_serve(text, _bin_ text = '_body_bin')
RETURNS TABLE("name" text, text_value text, binary_value bytea)  AS $$
	SELECT http_response_name_text(name_), text_value, binary_value FROM
  	http_response_rows _row,
		wicci_serve_responses($1) response,
		debug_enter('wicci_serve(text,text)', $1),
		non_null(try_http_response_name(_bin_), 'wicci_serve(text, text)') _bin,
		supported_binary_doc_formats
	WHERE ref = response
	AND storage_policy = static_doc_storage_policy()
	AND request_format = _bin
$$ LANGUAGE sql SET search_path FROM CURRENT;

COMMENT ON
FUNCTION public.wicci_s(erve(text, text) IS  '
Original obsolete method for serving a webpage.
Everything is passed as text, including the body,
which doesn''t work so well anymore!
See instead wicci_serve(bytea,bytea,text)';

-- * for testing convenience:

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

-- * Round-Trip Testing

CREATE OR REPLACE
FUNCTION wicci_echo_headers(bytea)
RETURNS TABLE("name" text, text_value text, binary_value bytea)  AS $$
	SELECT http_request_name_text(name_), text_value, binary_value FROM
		debug_enter('wicci_echo_headers(bytea)', $1) _this,
		http_request_rows rows,
		parse_http_requests($1) refs
	WHERE refs = rows.ref
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION wicci_echo_body(bytea, _bin_ text)
RETURNS TABLE("name" text, text_value text, binary_value bytea)  AS $$
	SELECT $2, ''::text, $1
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION public.wicci_echo_request(bytea, bytea, _bin_ text = '_body_bin')
RETURNS TABLE("name" text, text_value text, binary_value bytea)  AS $$
	SELECT wicci_echo_headers($1)
	UNION
	SELECT wicci_echo_body($2, $3)
$$ LANGUAGE sql SET search_path FROM CURRENT;
