-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('wicci-css-data.sql', '$Id');

SELECT COALESCE(
	text_tree_formats_row('css-line'),
	text_tree_formats_row('css-line', get_text_format( E'\t', ': ', ';\n') )
);

SELECT COALESCE(
	text_tree_formats_row('css-block'),
	text_tree_formats_row('css-block', get_text_format(	'', E' {\n', E'}\n' ) )
);

SELECT COALESCE(
	text_keys_key('css-color-red'),
	text_keys_key('css-color-red', get_text_format_tree(
		text_tree_formats_id('css-line'),
		get_text('color'), get_text('red')
) ) );

SELECT ref_text_op(	text_keys_key('css-color-red') );

SELECT COALESCE(
	text_keys_key('css-color-blue'),
	text_keys_key('css-color-blue', get_text_format_tree(
		text_tree_formats_id('css-line'),
		get_text('color'), get_text('blue')
) ) );

SELECT ref_text_op(	text_keys_key('css-color-blue') );

SELECT COALESCE(
	text_keys_key('css-class-red'),
	text_keys_key('css-class-red', get_text_format_tree(
		text_tree_formats_id('css-block'),
		get_text('.red'),  text_keys_key('css-color-red')
) ) );

SELECT ref_text_op(	text_keys_key('css-class-red') );

SELECT COALESCE(
	text_keys_key('css-class-blue'),
	text_keys_key('css-class-blue', get_text_format_tree(
		text_tree_formats_id('css-block'),
		get_text('.blue'),  text_keys_key('css-color-blue')
) ) );

SELECT ref_text_op(	text_keys_key('css-class-blue') );

SELECT COALESCE(
	text_keys_key('wicci.css'),
	text_keys_key('wicci.css', try_get_text_join_tree(
		E'\n', ARRAY[
		text_keys_key('css-class-red'),
		text_keys_key('css-class-blue')
] ) ) );

SELECT ref_text_op(	text_keys_key('wicci.css') );

SELECT COALESCE(
	doc_keys_key( 'wicci.css'),
	doc_keys_key( 'wicci.css', new_tree_doc( COALESCE(
		doc_node_keys_key('wicci.css'),
		doc_node_keys_key( 'wicci.css', new_tree_node(
			show1_kind( text_keys_key('wicci.css') )
		) )
	) ) )
);

SELECT tree_doc_text(	find_page_doc('wicci-css.sql') );

SELECT get_doc_page(
	get_page_uri('wicci.org/wicci.css'),
	find_page_doc('wicci.css')
);

SELECT tree_doc_text( find_page_doc('wicci.org/wicci.css') );

SELECT ref_env_crefs_text_op(
	doc_page_doc( find_page_doc('wicci.org/wicci.css') ),
	env_nil(), crefs_nil()
);
