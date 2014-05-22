\i settings.sql
\set doc_uri '''404.html'''
\set doc_type '''html'''
-- SELECT set_file(:doc_uri, '$Id');

-- This file was generated automatically by
-- /home/greg/.Wicci/Tools/Bin/doc-to-sql
-- Any changes you make to it will likely be lost!

-- Any Copyrights which apply to the source file
-- very likely apply to this derived file as well!

SELECT COALESCE(
 doc_page_from_uri_lang(u, t),
 doc_page_from_uri_lang_root(u, t,
  xml_tree( '',
   xml_root_kind(t, '', 'html' ),
   xml_tree( '',
    xml_kind(t, '', 'head' ),
    xml_tree( 'title',
     xml_kind(t, '', 'title',
      xml_attr( '', 'id', 'title' ) ),
     xml_leaf( 'title-text', 'CODE 404: Wicci Page Not Found!' ) ) ),
   xml_tree( '',
    xml_kind(t, '', 'body' ),
    xml_tree( '',
     xml_kind(t, '', 'h1',
      xml_attr( '', 'handle', 'h1' ) ),
     xml_leaf( 'h1-text', 'CODE 404: Wicci Page Not Found!' ) ),
    xml_tree( '',
     xml_kind(t, '', 'p' ),
     xml_leaf( 'sorry', 'We''re awfully sorry,' ),
     xml_meta( 'wicci_user_name' ),
     xml_tree( '',
      xml_kind(t, '', 'span' ),
      xml_leaf( 'user-to-path', ':' ) ),
     xml_meta( 'wicci_this_path' ),
     xml_tree( '',
      xml_kind(t, '', 'span' ),
      xml_leaf( 'not-found', 'does not exist on site' ) ),
     xml_meta( 'wicci_this_domain' ),
     xml_tree( 'full-stop',
      xml_kind(t, '', 'span' ),
      xml_leaf( '', '.' ) ) ) ) ) )
) FROM get_page_uri(:doc_uri) u, xml_doctype(:doc_type, 'html') t;
