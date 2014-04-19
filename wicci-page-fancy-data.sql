-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('wicci-page-fancy-data.sql', '$Id');

-- SELECT debug_on('xml_user_status_kind_text(env_refs, crefs, refs[])'::regprocedure, true);
-- SELECT debug_on('wicci_doc_serve_page(xml_doc_refs, env_refs, crefs)'::regprocedure, true);
-- SELECT debug_on('serve_page(wicci_user_ids, wicci_group_ids, text, url_refs, xml_attr_array_refs, xml_attr_array_refs, xml_attr_array_refs)'::regprocedure, true);
-- SELECT debug_on('serve_page(text, text, text, text, text, text, text, text, text, text)'::regprocedure, true);

-- ** TABLE wicci_groups_pages_contents

SELECT COALESCE(
	wicci_transaction_rows_ref('greg@wicci.org/fancy'),
	wicci_transaction_rows_ref('greg@wicci.org/fancy',
		new_wicci_trans(find_wicci_user('user:greg@wicci.org'))
	)
);

SELECT set_wicci_page_transaction_grafts(
	doc_page,
	wicci_transaction_rows_ref('greg@wicci.org/fancy'),
	xml_graft(
		doc_id_node(doc, 'header.1'),
		get_xml_text_kind( get_xml_text('We Send Our Love To You!') )
	),
	xml_graft(
		doc_id_node(doc, 'list.1.1'),
		get_xml_text_kind( get_xml_text('I need lots of love!') )
	),
	xml_graft(
		doc_id_node(doc, 'list.2.1'),
		get_xml_text_kind( get_xml_text('I have lots of love to give!') )
	),
	xml_graft(
		doc_id_node(doc, 'list.3.1'),
		get_xml_text_kind( get_xml_text('Let''s love each other!') )
	)
) FROM
	find_page_doc('fancy.html') doc,
	find_doc_page('fancy.html') doc_page;

SELECT wicci_group_add_trans(
	find_wicci_group('group:greg@wicci.org'),
	wicci_transaction_rows_ref('greg@wicci.org/fancy')
);

SELECT test_func(
	'wicci_grafts(doc_page_refs, wicci_user_refs)',
	array_length( ARRAY( SELECT wicci_grafts(
		find_doc_page('fancy.html'),
		find_wicci_user('user:greg@wicci.org')
	) ) ),
	4
);
