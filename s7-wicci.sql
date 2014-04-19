-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('s7-wicci.sql', '$Id');

-- * without abbreviations:

CREATE OR REPLACE
FUNCTION public.wicci_ready(text = '') RETURNS void AS $$
BEGIN
	PERFORM refs_ready();
  -- PERFORM require_module(''s7_wicci.wicci-page-code'');
	RAISE NOTICE 'wicci_ready(%)', $1;
END
$$ LANGUAGE plpgsql SET search_path FROM CURRENT;

-- * with some abbreviations from my .psqlrc file:

:function public.wicci_ready(text = ''):void $$
BEGIN
	PERFORM refs_ready();
  -- PERFORM require_module(''s7_wicci.wicci-page-code'');
	RAISE NOTICE 'wicci_ready(%)', $1;
--	:notice 'wicci_ready(%)', $1;
END
$$ :plpgsql

:Function wicci_ready(text) IS '
	Ensure that all modules of the wicci schema
	are present and initialized.
  Check sufficient elements of the Wicci
  dependency tree that we can be assured that
  all of its modules have been loaded.
';
