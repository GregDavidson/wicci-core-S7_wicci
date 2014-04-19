-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('wicci-schema.sql', '$Id');

-- Wicci Schema Shape Classes
-- Support for Geometric Shapes in the Wicci System

-- This file is NOT YET part of the Wicci System!

-- ** Copyright

-- Copyright (c) 2005-2012, J. Greg Davidson.
-- You may use this file under the terms of the
-- GNU AFFERO GENERAL PUBLIC LICENSE 3.0
-- as specified in the file LICENSE.md included with this distribution.
-- All other use requires my permission in writing.

-- * Shape classes

-- These classes are supposed to be useful, but also
-- they are supposed to illustrate the features and
-- advantages of the Wicci SQL Extensions

-- * Some Shape Schema

SELECT create_ref_type('shape_refs');

CREATE TABLE shape_keys (
	key shape_refs PRIMARY KEY
);

COMMENT ON TABLE shape_keys IS
'Provides referential integrity for geometric shapes';

CREATE TABLE shape_rows (
	ref shape_refs PRIMARY KEY,
	origin points
);

COMMENT ON TABLE shape_rows IS
'Base class for arbitrary geometric shapes';

CREATE TABLE bitmap_shape_rows (
	PRIMARY KEY(ref),
	shape bytea	
) INHERITS(shape_rows);

CREATE TABLE svg_shape_rows (
	PRIMARY KEY(ref),
	shape xml
) INHERITS(shape_rows);

-- * Let's add some integrity

-- prohibit inserts, updates, deletes on abstract base class
SELECT declare_abstract('shape_rows');

-- ensure referential integrity of shape references:
SELECT create_key_trigger_functions_for('shape_keys');
SELECT create_key_triggers_for('bitmap_shape_rows', 'shape_keys');
SELECT create_key_triggers_for('svg_shape_rows', 'shape_keys');

-- prohibits delete, updates of non-NULL fields
SELECT declare_monotonic('bitmap_shape_rows');
-- just as an example, silly for this table!

-- * Add some associated tables

SELECT declare_handles_for('shape_keys');
-- allows weak named-references for specific shapes

SELECT declare_notes_for('shape_keys');
-- allows multiple time and author stamped notes
-- to be associated with specific shapes

-- * Add object-oriented message dispatching

-- Set up reference classes with fundamenntal functions
SELECT declare_ref_class_with_funcs('bitmap_shape_rows');
SELECT declare_ref_class_with_funcs('svg_shape_rows');

CREATE OR REPLACE FUNCTION bitmap_shape_text(shape_refs)
RETURNS text AS $$
	SELECT 'html code to display given bitmap'
$$ LANGUAGE sql;

SELECT type_class_op_method(
	'shape_refs', 'bitmap_shape_rows',
	'ref_text_op(refs)', 'bitmap_shape_text(shape_refs)'
);

CREATE OR REPLACE FUNCTION svg_shape_text(shape_refs)
RETURNS text AS $$
	SELECT 'html code to display given svg'
$$ LANGUAGE sql;

SELECT type_class_op_method(
	'shape_refs', 'svg_shape_rows',
	'ref_text_op(refs)', 'svg_shape_text(shape_refs)'
);
