-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('wicci-page-simple-data.sql', '$Id');

-- Wicci Schema Test Data
-- Data to support testing the Wicci Schema

-- properly, the name of this module_file should be
--	wicci-schema-test-data
-- but until dependencies work better for test modules
-- we will elide the morpheme "test"

-- ** Copyright

-- Copyright (c) 2005-2012, J. Greg Davidson.
-- You may use this file under the terms of the
-- GNU AFFERO GENERAL PUBLIC LICENSE 3.0
-- as specified in the file LICENSE.md included with this distribution.
-- All other use requires my permission in writing.

-- * CONCEPT wicci_contents

-- ** TABLE wicci_groups_pages_contents

SELECT COALESCE(
	wicci_transaction_rows_ref('greg@wicci.org/simple'),
	wicci_transaction_rows_ref('greg@wicci.org/simple',
		new_wicci_trans(find_wicci_user('user:greg@wicci.org'))
	)
);

SELECT set_wicci_page_transaction_grafts(
	doc,
	wicci_transaction_rows_ref('greg@wicci.org/simple'),
	doc_node_keys_key('simple-graft')
) FROM find_doc_page('simple.html') doc;

SELECT wicci_group_add_trans(
	find_wicci_group('group:greg@wicci.org'),
	wicci_transaction_rows_ref('greg@wicci.org/simple')
);

SELECT test_func(
	'wicci_grafts(doc_page_refs, wicci_user_refs)',
	ARRAY( SELECT wicci_grafts(
		find_doc_page('simple.html'),
		find_wicci_user('user:greg@wicci.org')
	) ),
	ARRAY[ doc_node_keys_key('simple-graft') ]::doc_node_refs[]
);

-- Need more test data and HERE!!

-- missing test cases:
--	derived transactions
--	multi-level changesets
--	transaction and changeset compatibility tests
--	and more!
