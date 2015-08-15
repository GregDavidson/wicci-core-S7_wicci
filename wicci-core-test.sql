-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('wicci-core-test.sql', '$Id');

-- Wicci Core Test

-- ** Copyright

-- Copyright (c) 2005-2012, J. Greg Davidson.
-- You may use this file under the terms of the
-- GNU AFFERO GENERAL PUBLIC LICENSE 3.0
-- as specified in the file LICENSE.md included with this distribution.
-- All other use requires my permission in writing.

-- * page_uris, doc_pages, page_docs

SELECT test_func(
	'find_page_uri(text)',
	NOT is_nil( find_page_uri( 'simple.html'::text ) )
);

SELECT test_func(
	'find_doc_page(text)',
	NOT is_nil( find_doc_page( 'simple.html'::text ) )
);

SELECT test_func(
	'find_doc_page(page_uri_refs)',
	NOT is_nil( find_doc_page( 'simple.html'::page_uri_refs ) )
);

SELECT test_func(
	'find_page_doc(page_uri_refs)',
	NOT is_nil( find_page_doc( 'simple.html' ) )
);

TABLE view_logins;

SELECT test_func(
	'find_wicci_login(text)',
	NOT is_nil( find_wicci_login( 'greg@ngender.net'::text ) )
);

SELECT test_func(
	'find_wicci_login(entity_uri_refs)',
	NOT is_nil( find_wicci_login( 'greg@ngender.net'::entity_uri_refs ) )
);

TABLE view_users;

SELECT test_func(
	'find_wicci_user_or_nil(text)',
	NOT is_nil(find_wicci_user_or_nil( 'user:greg@wicci.org'::text ))
);

SELECT test_func(
	'find_wicci_user_or_nil(entity_uri_refs)',
	NOT is_nil( find_wicci_user_or_nil( 'user:greg@wicci.org'::entity_uri_refs ) )
);

TABLE view_groups;

SELECT test_func(
	'find_wicci_group(text)',
	NOT is_nil( find_wicci_group( 'group:puuhonua@wicci.org'::text ) )
);

SELECT test_func(
	'find_wicci_group(entity_uri_refs)',
	NOT is_nil( find_wicci_group( 'group:puuhonua@wicci.org'::entity_uri_refs ) )
);

-- * special kinds

SELECT find_xml_tag('meta');

SELECT
	get_xml_element_kind(
		find_xml_tag('meta'),
		ARRAY[ get_xml_attr( ns, 'kind', get_text('wicci_user_name') ) ]
	)
FROM
	page_uri_nil() ns,
	find_doc_lang_name('html') lang
;

SELECT COALESCE(
	env_rows_row( 'user:greg' ),
	env_rows_row( 'user:greg', make_user_env(user_base_env()) )
);

SELECT env_wicci_user(_env, _user) FROM
	env_rows_ref('user:greg') _env,
	find_wicci_user_or_nil('user:greg@wicci.org'::text) _user;

SELECT test_func(
	'try_env_wicci_user(env_refs)',
	try_env_wicci_user( 'user:greg' ),
	find_wicci_user_or_nil('user:greg@wicci.org'::text)
);

/* WTF ???
SELECT tag
	get_xml_element_kind(
		find_xml_tag('meta'::xml_tag_name_refs, lang),
		ARRAY[ get_xml_attr( ns, 'kind', get_text('wicci_user_name') ) ]
	), _env, crefs_nil(), '{}'::doc_node_refs[]
) FROM
	env_rows_ref('user:greg') _env,
	page_uri_nil() ns,
	find_doc_lang_name('html') lang;
*/

SELECT wicci_user_name_text(
	get_xml_element_kind(
		find_xml_tag('meta'),
		ARRAY[ get_xml_attr( ns, 'kind', get_text('wicci_user_name') ) ]
	), _env, crefs_nil(), '{}'::doc_node_refs[]
) FROM
	env_rows_ref('user:greg') _env,
	page_uri_nil() ns,
	find_doc_lang_name('html') lang;

SELECT ref_env_text_op(
	get_xml_element_kind(
		find_xml_tag('meta'),
		ARRAY[ get_xml_attr( ns, 'kind', get_text('wicci_user_name') ) ]
	), _env
) FROM
	env_rows_ref('user:greg') _env,
	page_uri_nil() ns,
	find_doc_lang_name('html') lang;
