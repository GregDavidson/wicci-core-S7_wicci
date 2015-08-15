-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('wicci-test-index-data.sql', '$Id');

-- doc-to-sql index.html

SELECT COALESCE(
	wicci_transaction_rows_ref('greg@wicci.org/index'),
	wicci_transaction_rows_ref('greg@wicci.org/index',
		new_wicci_trans(find_wicci_user_or_nil('user:greg@wicci.org'))
	)
);

SELECT set_wicci_page_transaction_grafts(
	find_doc_page('index.html'),
	wicci_transaction_rows_ref('greg@wicci.org/index'),
	xml_graft(
		doc_id_node(doc, 'welcome'),
		html_kind('h1', xml_attr('', 'id', 'index-h1-graft1'), xml_attr('', 'class', 'red')),
		new_xml_tree_node(
			get_xml_text_kind( get_xml_text('Wicci System Features') )
		)
	),
	xml_graft(
		doc_id_node(doc, 'features'),
		html_kind('ol'),
		doc_id_node(doc, 'features.1'),
		doc_id_node(doc, 'features.2'),
		doc_id_node(doc, 'features.3'),
		doc_id_node(doc, 'features.4'),
		doc_node_keys_key( 'index:features.5',
			new_xml_tree_node(  html_kind('li', xml_attr('', 'class', 'red')),
			 doc_node_keys_key( 'index:features.5.1',
				new_xml_tree_node(  get_xml_text_kind( get_xml_text(
					'New views do not overwrite other views - no view can be lost!'
		) ) ) ) ) )
	)
) FROM find_page_doc('index.html') doc;

SELECT wicci_group_add_trans(
	find_wicci_group('group:greg@wicci.org'),
	wicci_transaction_rows_ref('greg@wicci.org/index')
);

-- oftd !!!
SELECT (
	SELECT (
		SELECT oftd_ref_env_crefs_text_op(
			'ref_env_crefs_text_op(refs, env_refs, crefs)',
			_from, _to, doc, doc, env_nil(), crefs_nil()
		) FROM
			wicci_grafts_from_to( doc_page, wicci_user_nil() )
			AS foo(_from, _to)
	) FROM doc_page_doc(doc_page) doc
) FROM find_doc_page('index.html') doc_page;

SELECT wicci_grafts_from_to( try_doc_page('index.html'),
wicci_user_nil() );

SELECT wicci_grafts_from_to( try_doc_page('index.html'), find_wicci_user_or_nil('user:greg@wicci.org') );

-- oftd !!!
SELECT (
	SELECT (
		SELECT oftd_ref_env_crefs_text_op(
			'ref_env_crefs_text_op(refs, env_refs, crefs)',
			_from, _to, doc, doc, env_nil(), crefs_nil()
		) FROM wicci_grafts_from_to(
			doc_page, find_wicci_user_or_nil('user:greg@wicci.org')
		) AS foo(_from, _to)
	) FROM doc_page_doc(doc_page) doc
) FROM find_doc_page('index.html') doc_page;
