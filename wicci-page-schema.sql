-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('wicci-page-schema.sql', '$Id');

-- Wicci Page Schema
-- Structure for generating Wicci Pages to browsers

-- ** Copyright

-- Copyright (c) 2005-2012, J. Greg Davidson.
-- You may use this file under the terms of the
-- GNU AFFERO GENERAL PUBLIC LICENSE 3.0
-- as specified in the file LICENSE.md included with this distribution.
-- All other use requires my permission in writing.

CREATE OR REPLACE
VIEW wicci_response_names(name_) AS
VALUES
	( http_response_name_refs '_status'),
	( 'Date'), ( 'Server'), ( 'Set-Cookie'),
	( 'Content-Length'), ( 'Content-Type'), ( '_body');

DROP TABLE IF EXISTS wicci_responses CASCADE;

CREATE TABLE wicci_responses (
	name_ http_response_name_refs PRIMARY KEY
		REFERENCES http_response_name_rows,
	default_ http_response_refs NOT NULL
		REFERENCES http_response_keys
);

COMMENT ON TABLE wicci_responses IS
'potential http response headers independent of content type';

COMMENT ON COLUMN wicci_responses.default_ IS
'overridden by any language-specific value';

INSERT INTO wicci_responses(name_, default_) VALUES
	( '_status', get_http_text_response('_status', 'HTTP/1.1 200 OK') ),
	( 'Server', get_http_text_response('Server', 'Wicci/0.2') ),
	( 'Content-Type', get_http_text_response('Content-Type', 'text') );

SELECT http_small_text_response_rows_ref('404',
	get_http_text_response('_status', 'HTTP/1.1 404 Not Found')
);

CREATE OR REPLACE FUNCTION wicci_response_default_(
	http_response_name_refs
) RETURNS http_response_refs AS $$
		SELECT default_ FROM wicci_responses WHERE name_ = $1
$$ LANGUAGE sql;


CREATE TABLE IF NOT EXISTS wicci_lang_responses (
	lang doc_lang_name_refs
		REFERENCES doc_lang_name_rows,
	name_ http_response_name_refs
		REFERENCES http_response_name_rows,
	PRIMARY KEY(lang, name_),
	default_ http_response_refs NOT NULL
		REFERENCES http_response_keys
);

COMMENT ON COLUMN wicci_lang_responses.default_ IS
'overridden by any dynamic value';

CREATE OR REPLACE FUNCTION wicci_response_default_(
	doc_lang_name_refs, http_response_name_refs
) RETURNS http_response_refs AS $$
	SELECT default_ FROM wicci_lang_responses
	WHERE lang = $1 AND name_ = $2
$$ LANGUAGE sql;

COMMENT ON FUNCTION wicci_response_default_(
	doc_lang_name_refs, http_response_name_refs
) IS 'Only looks at the specific language; does not try
to find the language family.';

CREATE OR REPLACE FUNCTION wicci_response_default(
	doc_lang_name_refs, http_response_name_refs
) RETURNS http_response_refs AS $$
	SELECT _response FROM COALESCE(
		wicci_response_default_($1, $2),
		wicci_response_default_($2)
	) _response WHERE NOT is_nil(_response)
$$ LANGUAGE sql;

COMMENT ON FUNCTION wicci_response_default(
	doc_lang_name_refs, http_response_name_refs
) IS '';

DELETE FROM wicci_lang_responses;
INSERT INTO wicci_lang_responses(lang, name_, default_)
VALUES
	( 'html', '_doctype', get_http_text_response( '_doctype',	'<!DOCTYPE HTML">') ),
	( 'xhtml', '_doctype', get_http_text_response( '_doctype',
		'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">'
	) ),
	( 'svg', '_doctype', get_http_text_response( '_doctype',
		E'<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN" "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">'
	) ),
	( 'html', 'Content-Type', get_http_text_response('Content-Type', 'text/html; charset=UTF-8') ),
	( 'css', 'Content-Type', get_http_text_response('Content-Type', 'text/css') ),
	( 'svg','Content-Type',get_http_text_response('Content-Type','image/svg+xml') ),
	( 'jpeg','Content-Type',get_http_text_response('Content-Type','image/jpeg') ),
	( 'javascript','Content-Type',get_http_text_response('Content-Type', 'text/x-js') ),
	( 'ajax', 'Content-Type', get_http_text_response('Content-Type', 'application/json') ),
-- ( 'ajax', 'Content-Type', http_response_nil() ),
	( 'ajax',  '_status', get_http_text_response('_status', 'HTTP/1.1 200 OK') );
-- ( 'ajax','Content-Length', get_http_text_response('Content-Length', '0') ),
-- ( 'ajax','_body', get_http_text_response('_body', '') );

CREATE OR REPLACE FUNCTION wicci_env_add_association(
	env_refs, http_transfer_refs, http_response_name_refs, http_response_refs
) RETURNS env_refs AS $$
	SELECT ( env_add_association($1, $2, $3, $4) ).env
$$ LANGUAGE sql;

CREATE TABLE IF NOT EXISTS supported_binary_doc_formats (
	storage_policy regclass NOT NULL,
	request_format http_response_name_refs NOT NULL,
	PRIMARY KEY(storage_policy, request_format)
);

INSERT INTO supported_binary_doc_formats VALUES
('file_doc_rows', '_body_bin'),
('file_doc_rows', '_body_hex'),
('blob_doc_rows', '_body_bin'),
('blob_doc_rows', '_body_hex'),
('large_object_doc_rows', '_body_lo');
