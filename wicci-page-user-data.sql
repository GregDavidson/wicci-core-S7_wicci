-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('wicci-page-user-data.sql', '$Id');

-- Wicci User Page Data

-- ** Copyright

-- Copyright (c) 2005-2012, J. Greg Davidson.
-- You may use this file under the terms of the
-- GNU AFFERO GENERAL PUBLIC LICENSE 3.0
-- as specified in the file LICENSE.md included with this distribution.
-- All other use requires my permission in writing.

-- *

SELECT get_doc_page(
	get_page_uri('wicci.org/user'), find_page_doc('user.html')
);

