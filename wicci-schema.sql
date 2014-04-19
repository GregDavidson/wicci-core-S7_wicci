-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('wicci-schema.sql', '$Id');

-- Wicci Schema
-- Realizes the Wicci Use Cases, other than content management

-- ** Copyright

-- Copyright (c) 2005-2012, J. Greg Davidson.
-- You may use this file under the terms of the
-- GNU AFFERO GENERAL PUBLIC LICENSE 3.0
-- as specified in the file LICENSE.md included with this distribution.
-- All other use requires my permission in writing.

-- SET ROLE TO WICCI1;

-- ** Background

-- wicci_logins aka accounts
--	are expressed as one or more wicci_users
--	are not visible to other users
--	are used for authentication

--  wicci_users aka personae
--	own ordered list of wicci_groups - some may be private
--	may own wicci_sites
--	may participate as friends, group_leaders, etc.

-- xml_entiity_uris provide secondary keys for
--	wicci_logins
--	wicci_users - which can own things
--	wicci_groups
--	wicci_sites
--	wicci_pages

--	wicci_transaction_refs
--	organize wicci edits to one or more pages
--	by one user in one session

-- * the types

SELECT create_ref_type('wicci_login_refs');
SELECT create_ref_type('wicci_user_refs');
SELECT create_ref_type('wicci_group_refs');

-- * wicci_login_rows

CREATE TABLE IF NOT EXISTS wicci_login_rows (
	ref wicci_login_refs PRIMARY KEY,
	uri entity_uri_refs UNIQUE NOT NULL REFERENCES entity_uri_rows
		CHECK(
			( is_nil(uri) OR uri_entity_type_name(uri)
				IS NOT DISTINCT FROM uri_entity_type_name_nil()
			) AND ref_id(ref) = ref_id(uri)
		),
	password TEXT
);
COMMENT ON TABLE wicci_login_rows
IS 'account with login information';
COMMENT ON COLUMN wicci_login_rows.uri
IS 'A uri for authenticating a responsible person, typically
an EMail address.  Could be derived from ref - but how to do
so portably and retain the reference?';

SELECT create_notes_for('wicci_login_rows');

SELECT declare_ref_class_with_funcs(
	'wicci_login_rows', _updateable_ := true
);

-- create a row referenced by the nil value
INSERT INTO wicci_login_rows(ref, uri, password)
VALUES (wicci_login_nil(), entity_uri_nil(), 'x');

-- * wicci_user_rows

CREATE TABLE IF NOT EXISTS wicci_user_rows (
	ref wicci_user_refs PRIMARY KEY,
	uri entity_uri_refs UNIQUE NOT NULL REFERENCES entity_uri_rows,
	CHECK(
		( is_nil(uri) OR is_entity_uri_type(uri, 'user')
		) AND ref_id(ref) = ref_id(uri)
	),
	login_ wicci_login_refs UNIQUE NOT NULL
		REFERENCES wicci_login_rows,
	groups wicci_group_refs[] DEFAULT '{}'::wicci_group_refs[] NOT NULL
);
COMMENT ON TABLE wicci_user_rows IS
'a user name/alias/handle/persona, as well as an ordered list of
groups; a given user login may have several of these';
COMMENT ON COLUMN wicci_user_rows.uri
IS 'A unique and human-friendly URI for a user within the
system.  Should bring up the user''s home page.
Could be derived from ref  - but how to do so portably
and retain the reference?';
COMMENT ON COLUMN wicci_user_rows.groups IS
 'groups in decreasing view priority';

SELECT create_notes_for('wicci_user_rows');
SELECT declare_ref_class_with_funcs(
	'wicci_user_rows', _updateable_ := true
);

INSERT INTO wicci_user_rows(ref, uri, login_)
VALUES (wicci_user_nil(), entity_uri_nil(), wicci_login_nil());

-- * wicci_group_rows

-- Every user starts out  with an initial (default) group.
-- A user may create additional groups as desired.
-- Changes are associated with groups.
-- When a user admits a friend it requires mutual consent.
-- A user may, however, determine which of the user's group(s)
-- each friend belongs to.
-- group names must be unique within a wicci domain

CREATE TABLE IF NOT EXISTS wicci_group_rows (
	ref wicci_group_refs PRIMARY KEY,
	uri entity_uri_refs UNIQUE NOT NULL REFERENCES entity_uri_rows
		CHECK(
			( is_nil(uri) OR is_entity_uri_type(uri, 'group')
			) AND ref_id(ref) = ref_id(uri)
		),
	owner_ wicci_user_refs NOT NULL REFERENCES wicci_user_rows,
	is_default boolean NOT NULL default true
);
COMMENT ON TABLE wicci_group_rows IS
'represents a group of 1 or more users
maybe use a trigger to correlate with wicci_user_rows.groups???';
COMMENT ON COLUMN wicci_group_rows.uri
IS 'Could be derived from ref  - but how to do so portably
and retain the reference?';
COMMENT ON COLUMN wicci_group_rows.is_default
IS 'The initial group for a user represents them to their
friends.  You become someone''s friend by joining their
default group.  A default group will show up in others''
friends/groups list as that friend.';

SELECT declare_ref_class_with_funcs('wicci_group_rows');
SELECT create_notes_for('wicci_group_rows');

INSERT INTO wicci_group_rows(ref, uri, owner_)
VALUES (wicci_group_nil(), entity_uri_nil(), wicci_user_nil());

UPDATE wicci_user_rows SET groups = ARRAY[wicci_group_nil()]
WHERE ref = wicci_user_nil();

-- ** TABLE wicci_groups_members

CREATE TABLE IF NOT EXISTS wicci_groups_members (
	group_ wicci_group_refs NOT NULL REFERENCES wicci_group_rows,
	member_ wicci_user_refs NOT NULL REFERENCES wicci_user_rows,
	UNIQUE (group_, member_),
	private BOOLEAN DEFAULT false
);
COMMENT ON TABLE wicci_groups_members IS
'associates users as members of groups';
COMMENT ON COLUMN wicci_groups_members.private IS
'a placeholder for multiple group privacy controls:
(1) hiding from others what groups I belong to,
(2) hiding from others which of my groups they are
		actually in as a result of my friending them;
complete the schema, implement the functionality!!';

-- add triggers to correlate wicci_user_rows.groups
-- and wicci_groups_members!!!

INSERT INTO wicci_groups_members(group_,member_, private)
VALUES (wicci_group_nil(), wicci_user_nil(), true);

-- ** TABLE wicci_groups_leaders

CREATE TABLE IF NOT EXISTS wicci_groups_leaders (
	group_ wicci_group_refs NOT NULL REFERENCES wicci_group_rows,
	leader_ wicci_user_refs NOT NULL REFERENCES wicci_user_rows
);
COMMENT ON TABLE wicci_groups_leaders IS
'associates group leaders aka moderators with groups';

-- * wicci_site_rows

CREATE TABLE IF NOT EXISTS wicci_site_rows (
	ref doc_page_refs PRIMARY KEY REFERENCES doc_page_rows,
	owner_ wicci_user_refs NOT NULL REFERENCES wicci_user_rows
);
COMMENT ON TABLE wicci_site_rows IS
'represents a wicci site; is very much like a group';
COMMENT ON COLUMN wicci_site_rows.ref IS
'ref of a page which is also a site, typically a domain';
COMMENT ON COLUMN wicci_site_rows.owner_ IS
'ref of website owner';

SELECT create_notes_for('wicci_site_rows');

-- ** wicci_pages_delegates

CREATE TABLE IF NOT EXISTS wicci_pages_delegates (
	page_ doc_page_refs NOT NULL REFERENCES doc_page_rows,
	delegate_ wicci_user_refs NOT NULL REFERENCES wicci_user_rows,
	levels INTEGER NOT NULL CHECK(levels >= 0)
);

COMMENT ON TABLE wicci_pages_delegates IS
'associates users as delegates with websites or portions thereof';

COMMENT ON COLUMN wicci_pages_delegates.levels IS
'depth of directory levels covered by the authority of this delegate,
0 means unlimited';

-- * wicci_transaction_refs

SELECT create_ref_type('wicci_transaction_refs');

CREATE TABLE IF NOT EXISTS wicci_transaction_rows (
	ref wicci_transaction_refs PRIMARY KEY,
	time TIMESTAMP NOT NULL DEFAULT (CURRENT_TIMESTAMP),
	user_ wicci_user_refs NOT NULL REFERENCES wicci_user_rows
);

COMMENT ON TABLE wicci_transaction_rows IS
'represents >=1 changes on >=1 pages contributed together';

SELECT create_handles_for('wicci_transaction_rows');
SELECT declare_ref_class_with_funcs('wicci_transaction_rows');
SELECT create_simple_serial('wicci_transaction_rows');

-- ** TABLE wicci_derived_transactions

CREATE TABLE IF NOT EXISTS wicci_derived_transactions (
	base_ wicci_transaction_refs NOT NULL
		REFERENCES wicci_transaction_rows,
	derived_  wicci_transaction_refs NOT NULL
		REFERENCES wicci_transaction_rows
);
COMMENT ON TABLE wicci_derived_transactions IS
'represents relationship of a transaction derived from
one or more contributed base transactions';

-- ** TABLE wicci_subset_transactions

CREATE TABLE IF NOT EXISTS wicci_subset_transactions (
	base_ wicci_transaction_refs NOT NULL
		REFERENCES wicci_transaction_rows,
	subset_  wicci_transaction_refs NOT NULL
		REFERENCES wicci_transaction_rows
);
COMMENT ON TABLE wicci_subset_transactions IS
'represents relationship of an original transaction which
was not accepted and a subset of it which was, i.e.
the original transaction was cherry-picked';

-- * TABLE wicci_transactions_grafts
CREATE TABLE IF NOT EXISTS wicci_page_transaction_grafts (
	page_ doc_page_refs REFERENCES doc_page_rows,
	trans_ wicci_transaction_refs REFERENCES wicci_transaction_rows,
	PRIMARY KEY(page_, trans_),
	grafts doc_node_refs[] NOT NULL -- ELEMENTS_REF doc_node_keys
);
COMMENT ON TABLE wicci_page_transaction_grafts IS
'stores grafts belonging to a specific transaction and page;
make unique???';

CREATE TYPE wicci_contribution_stati AS ENUM (
    'pending',									-- waiting for approval
    'accepted',									-- approved
    'rejected',
    'cherry_picked'
);

-- * TABLE wicci_groups_transactions
CREATE TABLE IF NOT EXISTS wicci_groups_transactions (
	group_ wicci_group_refs REFERENCES wicci_group_rows,
	trans_ wicci_transaction_refs REFERENCES wicci_transaction_rows,
	PRIMARY KEY(group_, trans_),
	status wicci_contribution_stati NOT NULL default 'pending'
);
COMMENT ON TABLE wicci_groups_transactions IS
'associates groups with wicci transactions which have been
accepted for that group';
COMMENT ON COLUMN wicci_groups_transactions.status IS
'Contributed transactions begin in state "pending", waiting
for review (which may be automatic and immediate).  After
review the status will change to "accepted" or "rejected" or
if only part of the transaction is accepted then the original
transaction will be marked "cherry_picked" and a new
subset transaction will be created which will be marked
as "accepted"';

-- * BACK REFS: TABLE wicci_group_rows, TABLE uri_rows

-- * TABLE wicci_transfers_users

CREATE TABLE IF NOT EXISTS wicci_transfers_users (
	xfer_ http_transfer_refs NOT NULL REFERENCES http_transfer_rows,
	user_ wicci_user_refs NOT NULL REFERENCES wicci_user_rows
);
COMMENT ON TABLE wicci_transfers_users IS
'http_transfers associated with wicci_user_rows';

-- * environment access

SELECT create_env_name_type_func(
	'env_wicci_login', 'wicci_login_refs'
);
SELECT create_env_name_type_func(
	'env_wicci_user', 'wicci_user_refs'
);
SELECT create_env_name_type_func(
	'env_http_transfer', 'http_transfer_refs'
);
SELECT create_env_name_type_func(
	'env_http_url', 'uri_refs'
);
SELECT create_env_name_type_func(
	'env_page_url', 'page_uri_refs'
);
SELECT create_env_name_type_func(
	'env_doc_page', 'doc_page_refs'
);
SELECT create_env_name_type_func(
	'env_cookies', 'uri_query_refs'
);

