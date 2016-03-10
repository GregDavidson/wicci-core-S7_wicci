-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('tag-schema.sql', '$Id');

-- Tag Schema
-- An architecture for Semantic Tagging

-- ** Copyright

-- Copyright (c) 2012-2014, J. Greg Davidson.
-- You may use this file under the terms of the
-- GNU AFFERO GENERAL PUBLIC LICENSE 3.0
-- as specified in the file LICENSE.md included with this distribution.
-- All other use requires my permission in writing.

-- Tags tell us something about an entity.
-- The meaning of tags is conveyed by
-- + their name
-- + explanatory text
-- + relationships with other tags (see below)

-- Question: How are tags different from environments?
-- Tentative answer: Environments are system-level, tags are user-level.
-- Question:  Should the two systems be unified?
-- Tentative answer: Let's keep these things related but distinct.

-- We should be able to represent tags with a URI
-- Canonical: wicci.org/<doc-node-id>
-- Symbolic: wicci.org/group/tag/path
-- tags are always owned by some group
-- it's up to that group to hierarchically
-- categorize their tags in namespaces.

-- Tag namespaces are independent of tag semantic
-- categories.  Tags in a namespace can be associated with
-- other tags as aliases (including translations),
-- specializations (subsets), similies, contexts,
-- exclusions, and perhaps more!

-- A tag's symbolic URI should also take us to an editable,
-- structured document where the tag is "defined" (actually,
-- distinguished).

SELECT create_ref_type('tag_refs');

CREATE TABLE tag_keys (
	key tag_refs primary key
);

SELECT create_key_trigger_functions_for('tag_keys');

CREATE TABLE tags_envs_values (
	tag_ tag_refs NOT NULL REFERENCES tag_keys,
	env_ env_refs NOT NULL REFERENCES env_rows,
	value_ refs NOT NULL			-- needs to be renderable
	PRIMARY KEY(tag_, env_, value_)
);

COMMENT ON TABLE tags_values IS '
	Associates (any kind of) tag with a environment
	context and a presentation value.  This table
	might be redundant!!
';

COMMENT ON COLUMN tags_values.env_ IS '
	A system context environment for this (tag, value) pair,
	e.g. a specific human language.  We could alternatively
	use a meta-tag; so is this redundant??
';

COMMENT ON COLUMN tags_values.value_ IS '
	A renderable value for presenting this
	tag to a user, e.g. text, svg, etc.
	This could instead be provided through
	the information at the tag''s associated
	doc_node_ref, if we can police its structure.
	Or, we could update this from that.
';

CREATE TABLE abstract_tag_rows (
	ref tag_refs NOT NULL, -- PRIMARY KEY
	def doc_node_refs NOT NULL -- REFERENCES doc_node_keys
);

COMMENT ON COLUMN abstract_tag_rows.def IS '
	The section of the document defining this tag.
	There will be views in multiple languages.
';

SELECT declare_abstract('abstract_tag_rows');

-- We should be able to do something like:
-- SELECT create_entity_tag('owner_tag_rows', 'wicci_group_rows');
-- maybe variadic to allow additional field references

CREATE TABLE owner_tag_rows (
	group_ wicci_group_refs NOT NULL REFERENCES wicci_group_rows,
	context_ env_refs NOT NULL REFERENCES env_rows
) INHERITS(abstract_tag_rows) ;

COMMENT ON TABLE tag_cloud_rows IS '
	Represents a collection (cloud) of tags
	associated with the same "owning" group
	and with a default language and semantic
	context.  Associates tags with the groups which
	"own" them.  Groups here work much like
	Postgres "roles".
';

SELECT create_key_triggers_for('owner_tag_rows', '');

CREATE TABLE tags_contexts (
	tag_ tag_refs NOT NULL REFERENCES tag_keys,
	context_ tag_refs NOT NULL REFERENCES tag_keys,
	PRIMARY KEY(tag_, context_)
);

COMMENT ON TABLE tags_contexts IS '
	Associates tags with semantic contexts,
	e.g. apple (fruit), apple (computers),
	apple (record label), etc.
';

-- * URLs as concepts vs. as targets

CREATE TABLE uri_tag_rows (
	uri uri_refs
) INHERITS(abstract_tag_rows);

COMMENT ON TABLE uri_tag_rows IS '
	Somehow represents a tag as a uri
';

CREATE TABLE url_tag_rows (
) INHERITS(uri_refs);

-- cool weird shit below:

CREATE TABLE named_tag_rows (
    profile human_language_rows NOT NULL
        REFERENCES human_language_rows,
    name text NOT NULL,
        PRIMARY KEY(ns, name, profile),
        FOREIGN KEY(ref, ns) REFERENCES tag_keys
) INHERITS (abstract_tag_rows);
SELECT create_key_triggers_for('named_tag_rows', 'tag_keys');

CREATE TABLE functor_tag_rows (
        PRINARY KEY(ref),
        FOREIGN KEY(ref, ns) REFERENCES tag_keys,
        arity int1 CHECK(arity > 1) -- arity=0 is named_tag
) INHERITS (named_tag_rows);
SELECT create_key_triggers_for('functor_tag_rows', 'tag_keys');

-- How can we get rid of the storage
    -- redundancy of namespace_refs
-- and retain the integrity?
    -- Ah - use triggers!

CREATE TABLE tags_targets (
        tag tag_refs NOT NULL,
        target target_refs NOT NULL,
        UNIQUE(tag, target)
    );
    COMMENT ON CREATE TABLE tags_targets IS
'Associates tags with targets';

CREATE TABLE tags_slots (
        FOREIGN KEY(target) REFERENCES functor_tag_rows,
    slot int1 NOT NULL -- check in arity range of target            
    ) INHERITS tags_targets;
    COMMENT ON CREATE TABLE tags_slots IS
'Associates tags with functor slots';
