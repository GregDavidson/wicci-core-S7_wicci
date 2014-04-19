-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('wicci-account-data.sql', '$Id');

-- Wicci Schema Test Data
-- Account Data to support Wicci Demos

-- ** Copyright

-- Copyright (c) 2005-2012, J. Greg Davidson.
-- You may use this file under the terms of the
-- GNU AFFERO GENERAL PUBLIC LICENSE 3.0
-- as specified in the file LICENSE.md included with this distribution.
-- All other use requires my permission in writing.

-- * TABLE wicci_entities

-- ** TABLE wicci_login_rows
-- ** TABLE wicci_user_rows
-- ** TABLE wicci_group_rows

-- SELECT get_wicci_login(
-- 	'foo@nobody.org', 'x'
-- );

SELECT get_wicci_user_login(
	'greg@wicci.org', 'greg@ngender.net', 'sheveky'
);

SELECT get_wicci_user_login(
	'sher@wicci.org', 'sher@well.com', 'sherluvy'
);

SELECT get_wicci_user_login(
	'bill@wicci.org', 'bilpal@gmail.com', 'thingy13'
);

SELECT get_wicci_user_login(
	'lynn@wicci.org', 'lynn@bethechange.net', 'stay-c'
);

SELECT get_wicci_user_login(
	'stacey@wicci.org', 'stacey@creditlink.com', '4thekids'
);

SELECT get_wicci_user_login(
	'batman@wicci.org', 'jsa169@gmail.com', 'letmein'
);

SELECT get_wicci_user_login(
	'priused@wicci.org', 'priuscd@yahoo.com', 'letmein'
);

TABLE view_logins;
TABLE view_users;
TABLE view_groups;

SELECT new_wicci_user_group(
	'user:greg@wicci.org', 'group:sher@wicci.org'
);

SELECT
	new_wicci_user_group('user:greg@wicci.org', b),
	new_wicci_user_group('user:sher@wicci.org', b),
	new_wicci_user_group('user:bill@wicci.org', b)
FROM get_wicci_group(
	'group:puuhonua@wicci.org', 'user:greg@wicci.org'
) b;

SELECT
	new_wicci_user_group('user:lynn@wicci.org', b),
	new_wicci_user_group('user:stacey@wicci.org', b)
FROM get_wicci_group(
	'group:home@blackacre.org', 'user:stacey@wicci.org'
) b;

TABLE view_groups;

SELECT wicci_group_add_leader(
	'group:puuhonua@wicci.org', 'user:sher@wicci.org'
);

SELECT wicci_group_add_leader(
	'group:home@blackacre.org', 'user:lynn@wicci.org'
);

-- * TABLE wicci_site_rows

CREATE OR REPLACE
FUNCTION get_site_( text, text, doc_refs = doc_nil() )
RETURNS doc_page_refs AS $$
	SELECT get_wicci_site(
		get_doc_page( get_page_uri($1), $3 ),
		find_wicci_user( find_entity_uri($2) )
	)
$$ LANGUAGE SQL;

-- SELECT find_wicci_user(try_entity_uri(''));

-- SELECT page_uri_text(get_page_uri('wicci.net/error'));

-- SELECT xml_doc_keys_key( '404');

-- SELECT get_doc_page(
-- 	get_page_uri('wicci.net/error'),xml_doc_keys_key( '404')
-- );

SELECT get_wicci_site( get_doc_page(
	try_get_page_uri('wicci.net/error'::text),doc_page_doc('404.html')
), wicci_user_nil() );

SELECT get_site_('wicci.net/error'::text, ''::text);

SELECT get_site_('wicci.com', 'user:greg@wicci.org');

SELECT get_site_('wicci.org', 'user:greg@wicci.org');
SELECT get_site_('wicci.net', 'user:greg@wicci.org');

SELECT get_site_('ifsrad.org', 'user:greg@wicci.org');

SELECT get_site_('blackacre.org', 'user:stacey@wicci.org');

SELECT get_site_('moffit.com', 'user:stacey@wicci.org');

TABLE view_sites;

-- * wicci_pages

SELECT get_page_uri('wicci.com');
SELECT get_page_uri('wicci.org/love');
SELECT get_page_uri('wicci.net');

SELECT get_page_uri('ifsrad.org');

SELECT get_page_uri('blackacre.org');

SELECT get_page_uri('moffit.com');

-- * TABLE wicci_pages_delegates

SELECT wicci_page_add_delegate(
		'simple.html', 'user:bill@wicci.org'
);
