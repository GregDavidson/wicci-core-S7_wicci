-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('wicci-code.sql', '$Id');

-- Wicci Schema Code
-- Functions to support the Wicci Schema

-- ** Copyright

-- Copyright (c) 2005-2012, J. Greg Davidson.
-- You may use this file under the terms of the
-- GNU AFFERO GENERAL PUBLIC LICENSE 3.0
-- as specified in the file LICENSE.md included with this distribution.
-- All other use requires my permission in writing.

-- * wicci_login_refs

-- ** casts and conversions

CREATE OR REPLACE
FUNCTION wicci_login_to_uri(wicci_login_refs)
RETURNS entity_uri_refs AS $$
	SELECT unchecked_entity_uri_from_id( ref_id($1) )
$$ LANGUAGE SQL IMMUTABLE;

COMMENT ON FUNCTION wicci_login_to_uri(wicci_login_refs)
IS 'Simply retags the id; could instead fetch the uri field
from the row but this should be cheaper.';

DROP CAST IF EXISTS (wicci_login_refs AS entity_uri_refs) CASCADE;
CREATE CAST (wicci_login_refs AS entity_uri_refs)
WITH FUNCTION wicci_login_to_uri(wicci_login_refs);

CREATE OR REPLACE
FUNCTION try_wicci_login(entity_uri_refs)
RETURNS wicci_login_refs AS $$
	SELECT ref FROM wicci_login_rows WHERE uri = $1
$$ LANGUAGE SQL STRICT;

CREATE OR REPLACE
FUNCTION find_wicci_login(entity_uri_refs)
RETURNS wicci_login_refs AS $$
	SELECT non_null(
		try_wicci_login($1), 'find_wicci_login(entity_uri_refs)'
	)
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION try_wicci_login(wicci_user_refs) RETURNS wicci_login_refs AS $$
	SELECT login_ FROM wicci_user_rows WHERE ref = $1
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION wicci_login(wicci_user_refs) RETURNS wicci_login_refs AS $$
	SELECT non_null( try_wicci_login($1), 'wicci_login(wicci_user_refs)' )
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION wicci_login_or_nil(wicci_user_refs) RETURNS wicci_login_refs AS $$
	SELECT COALESCE( try_wicci_login($1), wicci_login_nil() )
$$ LANGUAGE SQL;

-- ** I/O

CREATE OR REPLACE
FUNCTION wicci_login_ref_in(text) RETURNS wicci_login_refs AS $$
	SELECT unchecked_wicci_login_from_id(ref_id(
		find_entity_uri($1, uri_entity_type_name_nil())
	))
$$ LANGUAGE SQL;

COMMENT ON FUNCTION wicci_login_ref_in(text)
IS 'Construct a wicci_login reference which may not yet
be associated with a row. Used when constructing such rows.
Does not check referential integrity!';

CREATE OR REPLACE
FUNCTION try_wicci_login(text) RETURNS wicci_login_refs AS $$
	SELECT ref FROM wicci_login_rows
	WHERE ref = wicci_login_ref_in($1) 
$$ LANGUAGE SQL STRICT;

CREATE OR REPLACE
FUNCTION find_wicci_login(text) RETURNS wicci_login_refs AS $$
	SELECT non_null(try_wicci_login($1), 'find_wicci_login(text)', $1)
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION wicci_login_text(wicci_login_refs) RETURNS text AS $$
	SELECT entity_uri_text(uri) FROM wicci_login_rows WHERE ref = $1
$$ LANGUAGE SQL;

SELECT type_class_in(
	'wicci_login_refs', 'wicci_login_rows', 'try_wicci_login(text)'
);

SELECT type_class_out(
	'wicci_login_refs', 'wicci_login_rows',
	'wicci_login_text(wicci_login_refs)'
);

SELECT type_class_op_method(
	'wicci_login_refs', 'wicci_login_rows',
	'ref_text_op(refs)',
	'wicci_login_text(wicci_login_refs)'
);

-- ** Construction

-- +++ get_wicci_login(login uri, passwd?) -> wicci_login_refs
CREATE OR REPLACE
FUNCTION try_get_wicci_login(entity_uri_refs, text = '')
RETURNS wicci_login_refs AS $$
	DECLARE
		_login RECORD;
		kilroy_was_here boolean := false;
		this regprocedure := 'try_get_wicci_login(entity_uri_refs, text)';
	BEGIN
		LOOP
			SELECT * INTO _login FROM wicci_login_rows WHERE uri = $1;
			IF FOUND THEN
				IF $2 <> '' AND _login.password IS DISTINCT FROM $2
				THEN
					RAISE EXCEPTION '%(%,%!=%)', this, $1, $2, _login.password;
				END IF;
				RETURN _login.ref;
			END IF;
			IF kilroy_was_here THEN
				RAISE EXCEPTION '% looping with %', this, $1;
			END IF;
			kilroy_was_here := true;
			BEGIN
				INSERT INTO wicci_login_rows(ref, uri, password)
				VALUES(
					unchecked_wicci_login_from_id(ref_id($1)), $1, NULLIF($2,'')
				);
			EXCEPTION
				WHEN unique_violation THEN			-- another thread??
					RAISE NOTICE '% % raised %!', this, $1, 'unique_violation';
			END;
		END LOOP;
	END;
$$ LANGUAGE plpgsql STRICT;

CREATE OR REPLACE
FUNCTION get_wicci_login(entity_uri_refs, text = '')
RETURNS wicci_login_refs AS $$
	SELECT non_null(
		try_get_wicci_login($1, $2),
		'get_wicci_login(entity_uri_refs, text)'
	)
$$ LANGUAGE SQL;

COMMENT ON FUNCTION get_wicci_login(entity_uri_refs, text)
IS 'email uri, passwd? -> login; maybe creating new row';

CREATE OR REPLACE
FUNCTION try_get_wicci_login(text, text = '')  
RETURNS wicci_login_refs AS $$
	SELECT get_wicci_login(
		try_get_entity_uri($1, uri_entity_type_name_nil()), $2
	)
$$ LANGUAGE SQL STRICT;

CREATE OR REPLACE
FUNCTION get_wicci_login(text, text = '') 
RETURNS wicci_login_refs AS $$
	SELECT non_null(
		try_get_wicci_login($1, COALESCE($2, '')),
		'get_wicci_login(text,text)', $1
	)
$$ LANGUAGE SQL;

COMMENT ON FUNCTION get_wicci_login(text, text)
IS 'name@domain, passwd? -> wicci_login_refs
creating new tuple if necessary,';

-- ** Mutation

CREATE OR REPLACE
FUNCTION try_update_wicci_login_passwd(wicci_login_refs, text) 
RETURNS wicci_login_refs AS $$
	UPDATE wicci_login_rows SET password = $2 WHERE ref = $1
	RETURNING ref
$$ LANGUAGE sql STRICT;

-- +++ update_wicci_login_passwd(name@domain, passwd)
CREATE OR REPLACE
FUNCTION update_wicci_login_passwd(wicci_login_refs, text)
RETURNS wicci_login_refs AS $$
	SELECT non_null(
		try_update_wicci_login_passwd($1,$2),
		'update_wicci_login_passwd(wicci_login_refs,text)'
	)
$$ LANGUAGE sql;

-- * wicci_users

-- ** casts and conversions

CREATE OR REPLACE
FUNCTION wicci_user_to_uri(wicci_user_refs)
RETURNS entity_uri_refs AS $$
	SELECT unchecked_entity_uri_from_id( ref_id($1) )
$$ LANGUAGE SQL IMMUTABLE;

COMMENT ON FUNCTION wicci_user_to_uri(wicci_user_refs)
IS 'Simply retags the id; could instead fetch the uri field
from the row but this should be cheaper.';

DROP CAST IF EXISTS (wicci_user_refs AS entity_uri_refs) CASCADE;
CREATE CAST (wicci_user_refs AS entity_uri_refs)
WITH FUNCTION wicci_user_to_uri(wicci_user_refs);

/*
CREATE OR REPLACE
FUNCTION try_wicci_uri_to_user(entity_uri_refs) 
RETURNS wicci_user_refs AS $$
	SELECT ref FROM wicci_user_rows WHERE uri = $1
$$ LANGUAGE SQL STRICT;

CREATE OR REPLACE
FUNCTION wicci_uri_to_user(entity_uri_refs)
RETURNS wicci_user_refs AS $$
	SELECT non_null(
		try_wicci_uri_to_user($1), 'wicci_uri_to_user(entity_uri_refs)'
	)
$$ LANGUAGE SQL;
*/

CREATE OR REPLACE
FUNCTION try_wicci_user(entity_uri_refs)
RETURNS wicci_user_refs AS $$
--	SELECT ref FROM wicci_user_rows WHERE uri::refs = $1
	SELECT ref FROM wicci_user_rows WHERE uri = $1
$$ LANGUAGE SQL STRICT;

CREATE OR REPLACE
FUNCTION find_wicci_user_or_nil(entity_uri_refs)
RETURNS wicci_user_refs AS $$
	SELECT COALESCE( try_wicci_user($1), wicci_user_nil() )
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION find_wicci_user_or_nil(entity_uri_refs)
RETURNS wicci_user_refs AS $$
	SELECT non_null( try_wicci_user($1), 'find_wicci_user_or_nil(entity_uri_refs)' )
$$ LANGUAGE SQL;

-- ** I/O

CREATE OR REPLACE
FUNCTION wicci_user_ref_in(text) RETURNS wicci_user_refs AS $$
	SELECT unchecked_wicci_user_from_id( ref_id(
		find_entity_uri($1, 'user')
	) )
$$ LANGUAGE SQL;

COMMENT ON FUNCTION wicci_user_ref_in(text)
IS 'Construct a wicci_user reference which may not yet
be associated with a row. Used when constructing such rows.
Does not check referential integrity!';

CREATE OR REPLACE
FUNCTION try_wicci_user(text) RETURNS wicci_user_refs AS $$
	SELECT ref FROM wicci_user_rows
	WHERE ref = wicci_user_ref_in($1) 
$$ LANGUAGE SQL STRICT;

CREATE OR REPLACE
FUNCTION find_wicci_user_or_nil(text) RETURNS wicci_user_refs AS $$
	SELECT COALESCE( try_wicci_user($1), wicci_user_nil() )
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION find_wicci_user(text) RETURNS wicci_user_refs AS $$
	SELECT non_null( try_wicci_user($1), 'find_wicci_user_or_nil(text)' )
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION wicci_user_text(wicci_user_refs) RETURNS text AS $$
	SELECT entity_uri_text(uri) FROM wicci_user_rows WHERE ref = $1
$$ LANGUAGE SQL;

SELECT type_class_in(
	'wicci_user_refs', 'wicci_user_rows', 'try_wicci_user(text)'
);

SELECT type_class_out(
	'wicci_user_refs', 'wicci_user_rows',
	'wicci_user_text(wicci_user_refs)'
);

SELECT type_class_op_method(
	'wicci_user_refs', 'wicci_user_rows',
	'ref_text_op(refs)',
	'wicci_user_text(wicci_user_refs)'
);

-- ** Construction

-- +++ get_wicci_user(user uri, login) -> wicci_user_refs
CREATE OR REPLACE
FUNCTION try_get_wicci_user(entity_uri_refs, wicci_login_refs)
RETURNS wicci_user_refs AS $$
	DECLARE
		_user RECORD;
		kilroy_was_here boolean := false;
		this regprocedure := 'try_get_wicci_user(entity_uri_refs, wicci_login_refs)';
	BEGIN
		LOOP
			SELECT * INTO _user FROM wicci_user_rows WHERE uri = $1;
			IF FOUND THEN
				IF _user.login_ <> $2 THEN
					RAISE EXCEPTION '%: % login %, not %',
					this, $1, _user.login_, $2;
				END IF;
				RETURN _user.ref;
			END IF;
			IF kilroy_was_here THEN
				RAISE EXCEPTION '% looping with % %', this, $1, $2;
			END IF;
			kilroy_was_here := true;
			BEGIN
				INSERT INTO wicci_user_rows(ref, uri, login_)
				VALUES(unchecked_wicci_user_from_id(ref_id($1)), $1, $2);
			EXCEPTION
				WHEN unique_violation THEN			-- another thread??
					RAISE NOTICE '% % % raised %!', this, $1, $2, 'unique_violation';
			END;
		END LOOP;
	END;
$$ LANGUAGE plpgsql STRICT;

CREATE OR REPLACE
FUNCTION get_wicci_user(entity_uri_refs, wicci_login_refs)
RETURNS wicci_user_refs AS $$
	SELECT non_null(
		try_get_wicci_user($1, $2),
		'get_wicci_user(entity_uri_refs, wicci_login_refs)'
	)
$$ LANGUAGE SQL;

COMMENT ON
FUNCTION get_wicci_user(entity_uri_refs, wicci_login_refs)
IS 'user uri, login --> login; maybe creating new row';

-- +++ get_wicci_user(user:name@..., login) -> wicci_user_refs
CREATE OR REPLACE
FUNCTION try_get_wicci_user(text, wicci_login_refs)  
RETURNS wicci_user_refs AS $$
	SELECT try_get_wicci_user(
		try_get_entity_uri($1, 'user'), $2
	)
$$ LANGUAGE SQL STRICT;

CREATE OR REPLACE
FUNCTION get_wicci_user(text, wicci_login_refs) 
RETURNS wicci_user_refs AS $$
	SELECT non_null(
		try_get_wicci_user($1,$2), 'get_wicci_user(text,wicci_login_refs)', $1
	)
$$ LANGUAGE SQL;

-- *  wicci_groups

-- ** casts and conversions

CREATE OR REPLACE
FUNCTION wicci_group_to_uri(wicci_group_refs)
RETURNS entity_uri_refs AS $$
	SELECT unchecked_entity_uri_from_id( ref_id( $1) )
$$ LANGUAGE SQL IMMUTABLE;

COMMENT ON FUNCTION wicci_group_to_uri(wicci_group_refs)
IS 'Simply retags the id; could instead fetch the uri field
from the row but this should be cheaper.';

DROP CAST IF EXISTS (wicci_group_refs AS entity_uri_refs) CASCADE;
CREATE CAST (wicci_group_refs AS entity_uri_refs)
WITH FUNCTION wicci_group_to_uri(wicci_group_refs);

CREATE OR REPLACE
FUNCTION try_wicci_group(entity_uri_refs) 
RETURNS wicci_group_refs AS $$
	SELECT ref FROM wicci_group_rows WHERE uri = $1
$$ LANGUAGE SQL STRICT;

CREATE OR REPLACE
FUNCTION find_wicci_group(entity_uri_refs)
RETURNS wicci_group_refs AS $$
	SELECT non_null(
		try_wicci_group($1), 'find_wicci_group(entity_uri_refs)'
	)
$$ LANGUAGE SQL;

-- ** I/O

CREATE OR REPLACE
FUNCTION wicci_group_ref_in(text) RETURNS wicci_group_refs AS $$
	SELECT unchecked_wicci_group_from_id(
		ref_id(find_entity_uri($1, 'group'))
	)
$$ LANGUAGE SQL;

COMMENT ON FUNCTION wicci_group_ref_in(text)
IS 'Construct a wicci_group reference which may not yet
be associated with a row. Used when constructing such rows.
Does not check referential integrity!';

CREATE OR REPLACE
FUNCTION try_wicci_group(text) RETURNS wicci_group_refs AS $$
	SELECT ref FROM wicci_group_rows
	WHERE ref = wicci_group_ref_in($1) 
$$ LANGUAGE SQL STRICT;

CREATE OR REPLACE
FUNCTION find_wicci_group(text) RETURNS wicci_group_refs AS $$
	SELECT non_null(try_wicci_group($1), 'find_wicci_group(text)', $1)
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION wicci_group_text(wicci_group_refs) RETURNS text AS $$
	SELECT entity_uri_text(uri) FROM wicci_group_rows WHERE ref = $1
$$ LANGUAGE SQL;

SELECT type_class_in(
	'wicci_group_refs', 'wicci_group_rows', 'try_wicci_group(text)'
);

SELECT type_class_out(
	'wicci_group_refs', 'wicci_group_rows',
	'wicci_group_text(wicci_group_refs)'
);

SELECT type_class_op_method(
	'wicci_group_refs', 'wicci_group_rows',
	'ref_text_op(refs)',
	'wicci_group_text(wicci_group_refs)'
);

-- ** Construction

-- +++ get_wicci_group(group:name@..., owner_) -> wicci_group_refs
CREATE OR REPLACE
FUNCTION try_get_wicci_group(entity_uri_refs, wicci_user_refs)
RETURNS wicci_group_refs AS $$
	DECLARE
		_group RECORD;
		kilroy_was_here boolean := false;
		this regprocedure :=
			'try_get_wicci_group(entity_uri_refs, wicci_user_refs)';
	BEGIN
		LOOP
			SELECT * INTO _group FROM wicci_group_rows WHERE uri = $1;
			IF FOUND THEN
				IF _group.owner_ <> $2 THEN
					RAISE EXCEPTION '%: % owner % <> %',
						this, $1, _group.owner_, $2;
				END IF;
				RETURN _group.ref;
			END IF;
			IF kilroy_was_here THEN
				RAISE EXCEPTION '% looping with % %', this, $1, $2;
			END IF;
			kilroy_was_here := true;
			BEGIN
				INSERT INTO wicci_group_rows(ref, uri, owner_)
				VALUES( unchecked_wicci_group_from_id(ref_id($1)), $1, $2 );
			EXCEPTION
				WHEN unique_violation THEN			-- another thread??
					RAISE NOTICE '% % % raised %!', this, $1, $2, 'unique_violation';
			END;
		END LOOP;
	END;
$$ LANGUAGE plpgsql STRICT;

CREATE OR REPLACE
FUNCTION get_wicci_group(entity_uri_refs, wicci_user_refs)
RETURNS wicci_group_refs AS $$
	SELECT non_null(
		try_get_wicci_group($1, $2),
		'get_wicci_group(entity_uri_refs, wicci_user_refs)'
	)
$$ LANGUAGE SQL;

COMMENT ON
FUNCTION get_wicci_group(entity_uri_refs, wicci_user_refs)
IS 'group uri, user --> group; maybe creating new row';

-- +++ get_wicci_group(group:name@..., user) -> wicci_group_refs
CREATE OR REPLACE
FUNCTION try_get_wicci_group(text, wicci_user_refs) 
RETURNS wicci_group_refs AS $$
	SELECT try_get_wicci_group(
		try_get_entity_uri($1, 'group'), $2
	)
$$ LANGUAGE SQL STRICT;

CREATE OR REPLACE
FUNCTION get_wicci_group(text, wicci_user_refs)
RETURNS wicci_group_refs AS $$
	SELECT non_null(
		try_get_wicci_group(
			get_entity_uri($1, 'group'), $2
		),
		'get_wicci_group(text,wicci_user_refs)', $1
	)
$$ LANGUAGE SQL;

-- * wicci_sites

-- ** casts and conversions

CREATE OR REPLACE
FUNCTION try_wicci_uri_to_site(page_uri_refs) 
RETURNS doc_page_refs AS $$
	SELECT s.ref FROM wicci_site_rows s, doc_page_rows p
	WHERE p.uri = $1 AND s.ref = p.ref
$$ LANGUAGE SQL STRICT;

CREATE OR REPLACE
FUNCTION wicci_uri_to_site(page_uri_refs)
RETURNS doc_page_refs AS $$
	SELECT non_null(
		try_wicci_uri_to_site($1), 'wicci_uri_to_site(page_uri_refs)'
	)
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION try_wicci_site(refs) RETURNS doc_page_refs AS $$
	SELECT ref FROM wicci_site_rows WHERE ref = try_doc_page($1)
$$ LANGUAGE SQL STRICT;

-- ** I/O

CREATE OR REPLACE
FUNCTION try_wicci_site(text)  RETURNS doc_page_refs AS $$
	SELECT ref FROM wicci_site_rows WHERE ref = try_doc_page($1)
$$ LANGUAGE SQL STRICT;

-- -- +++ wicci_site(site_uri text) -> doc_page_refs
CREATE OR REPLACE
FUNCTION find_wicci_site(text) RETURNS doc_page_refs AS $$
	SELECT non_null( try_wicci_site($1), 'find_wicci_site(text)', $1 )
$$ LANGUAGE SQL;

-- +++ get_wicci_site(site_uri, owner) -> doc_page_refs
CREATE OR REPLACE
FUNCTION try_get_wicci_site(doc_page_refs, wicci_user_refs)
RETURNS doc_page_refs AS $$
	DECLARE
		_site RECORD;
		kilroy_was_here boolean := false;
		this regprocedure :=
			'try_get_wicci_site(doc_page_refs, wicci_user_refs)';
	BEGIN
		LOOP
			SELECT * INTO _site FROM wicci_site_rows WHERE ref = $1;
			IF FOUND THEN
				IF _site.owner_ <> $2 THEN
					RAISE EXCEPTION '% %, owner % <> %',
					this, $1, $2, _site.owner_;
				END IF;
				RETURN _site.ref;
			END IF;
			IF kilroy_was_here THEN
				RAISE EXCEPTION '% looping with % %', this, $1, $2;
			END IF;
			kilroy_was_here := true;
			BEGIN
				INSERT INTO wicci_site_rows(ref, owner_) VALUES($1, $2);
			EXCEPTION
				WHEN unique_violation THEN			-- another thread??
					RAISE NOTICE '% % % raised %!', this, $1, $2, 'unique_violation';
			END;
		END LOOP;
	END;
$$ LANGUAGE plpgsql STRICT;

CREATE OR REPLACE
FUNCTION get_wicci_site(doc_page_refs, wicci_user_refs)
RETURNS doc_page_refs AS $$
	SELECT non_null(
		try_get_wicci_site($1, $2),
		'get_wicci_site(doc_page_refs, wicci_user_refs)'
	)
$$ LANGUAGE SQL;

COMMENT ON
FUNCTION get_wicci_site(doc_page_refs, wicci_user_refs)
IS 'return ref described, creating new tuple if necessary';

-- * Some nice views

CREATE OR REPLACE
VIEW view_sites AS
	SELECT
		ref AS "site",
		owner_ AS "owner",
		attributed_notes_text(ARRAY(
			SELECT note_id::integer
			FROM wicci_site_rows_row_notes n WHERE n.ref = s.ref
		)::attributed_note_id_arrays ) AS "notes"
	FROM wicci_site_rows s;

-- ** ok, now make entities look pretty:

CREATE OR REPLACE
VIEW view_logins AS
	SELECT
		l.ref AS login,
		password,
		ARRAY(
			SELECT u.uri FROM wicci_user_rows u WHERE u.login_ = l.ref
		) AS "user identities"
	FROM wicci_login_rows l;

CREATE OR REPLACE
VIEW view_users AS
	SELECT
		u.ref AS "user",
		ARRAY(
			SELECT g.uri FROM wicci_group_rows g WHERE g.owner_ = u.ref
		) AS "groups",
		groups AS "view_groups",
		attributed_notes_text(ARRAY(
			SELECT note_id::integer
			FROM wicci_user_rows_row_notes n WHERE n.ref = u.ref
		)::attributed_note_id_arrays ) AS "notes"
	FROM wicci_user_rows u;

-- * TABLE wicci_group_rows

CREATE OR REPLACE
VIEW view_groups AS
	SELECT
		g.ref AS "group",
		owner_ AS "owner",
		ARRAY(
			SELECT leader_::entity_uri_refs FROM wicci_groups_leaders WHERE group_ = g.ref
		) AS "leaders",
		attributed_notes_text(ARRAY(
			SELECT note_id::integer
			FROM wicci_group_rows_row_notes n WHERE n.ref = g.ref
		)::attributed_note_id_arrays ) AS "notes"
	FROM wicci_group_rows g;

CREATE OR REPLACE
VIEW view_group_members AS
	SELECT
		g.ref AS "group",
		ARRAY(
			SELECT member_::entity_uri_refs FROM wicci_groups_members WHERE group_ = g.ref
		) AS "members"
	FROM wicci_group_rows g;

CREATE OR REPLACE
VIEW view_user_memberships AS
	SELECT
		u.ref AS "user",
		ARRAY(
			SELECT group_::entity_uri_refs FROM wicci_groups_members WHERE member_ = u.ref
		) AS "memberships"
	FROM wicci_user_rows u;

-- * TABLE wicci_groups_members

CREATE OR REPLACE FUNCTION try_wicci_user_add_group(
	wicci_user_refs, wicci_group_refs
) RETURNS boolean AS $$
	DECLARE
		inserted boolean := false;
		kilroy_was_here boolean := false;
		this regprocedure :=
			'try_wicci_user_add_group(wicci_user_refs, wicci_group_refs)';
	BEGIN
		LOOP
			PERFORM 0 FROM wicci_groups_members
			WHERE member_ = $1 AND group_ = $2;
			IF FOUND THEN RETURN inserted; END IF;
			IF kilroy_was_here THEN
				RAISE EXCEPTION '% looping with % %', this, $1, $2;
			END IF;
			kilroy_was_here := true;
			BEGIN
				INSERT INTO wicci_groups_members(member_, group_)
				VALUES($1, $2);
				inserted := true;
				UPDATE wicci_user_rows
					SET groups = groups || $2
				WHERE ref = $1;
			EXCEPTION
				WHEN unique_violation THEN			-- another thread??
					RAISE NOTICE '% % % raised %!', this, $1, $2, 'unique_violation';
			END;
		END LOOP;
	END;
$$ LANGUAGE plpgsql STRICT;

CREATE OR REPLACE
FUNCTION wicci_user_add_group(wicci_user_refs, wicci_group_refs)
RETURNS boolean AS $$
	SELECT non_null(
		try_wicci_user_add_group($1,$2),
		'wicci_user_add_group(wicci_user_refs,wicci_group_refs)'
	)
$$ LANGUAGE sql;

COMMENT ON
FUNCTION wicci_user_add_group(wicci_user_refs, wicci_group_refs)
IS 'add group to array and associated table;
perhaps using a trigger would be better??
how about allowing more control over order??';

CREATE OR REPLACE
FUNCTION new_wicci_user_group(wicci_user_refs, wicci_group_refs)
RETURNS wicci_user_refs AS $$
	SELECT $1 WHERE wicci_user_add_group($1, $2)
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION new_wicci_user_group(wicci_user_refs, text)
RETURNS wicci_user_refs AS $$
	SELECT new_wicci_user_group($1, find_wicci_group($2))
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION new_wicci_user_group(text, wicci_group_refs)
RETURNS wicci_user_refs AS $$
	SELECT new_wicci_user_group(find_wicci_user_or_nil($1), $2)
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION new_wicci_user_group(text, text)
RETURNS wicci_user_refs AS $$
	SELECT new_wicci_user_group(find_wicci_user_or_nil($1), $2)
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION try_wicci_user_drop_group(
	wicci_user_refs, wicci_group_refs
) RETURNS boolean AS $$
	BEGIN
		DELETE FROM wicci_groups_members
		WHERE member_ = $1 AND group_ = $2;
		IF NOT FOUND THEN RETURN false; END IF;
		UPDATE wicci_user_rows SET groups = array_remove(groups, group_)
		FROM wicci_login_rows wul, wicci_user_rows wu
		WHERE wu.ref = $1 AND wul.ref = wu.login_
		AND wicci_user_rows.login_ = wu.ref;
		RETURN true;
	END;
$$ LANGUAGE plpgsql STRICT;

CREATE OR REPLACE
FUNCTION wicci_user_drop_group(wicci_user_refs, wicci_group_refs)
RETURNS boolean AS $$
	SELECT non_null(
		try_wicci_user_drop_group($1,$2),
		'wicci_user_drop_group(wicci_user_refs,wicci_group_refs)'
	)
$$ LANGUAGE sql;

-- * TABLE wicci_groups_leaders

-- +++ wicci_group_add_leader(wicci_group_refs, wicci_user_refs) -> INTEGER
CREATE OR REPLACE FUNCTION try_wicci_group_add_leader(
	wicci_group_refs, wicci_user_refs
) RETURNS boolean AS $$
	DECLARE
		maybe RECORD;
		inserted boolean := false;
		kilroy_was_here boolean := false;
		this regprocedure :=
			'try_wicci_group_add_leader(wicci_group_refs, wicci_user_refs)';
	BEGIN
		LOOP
			SELECT * INTO maybe FROM wicci_groups_leaders
			WHERE group_ = $1 AND leader_ = $2;
			IF FOUND THEN RETURN inserted; END IF;
			IF kilroy_was_here THEN
				RAISE EXCEPTION '% looping with % %', this, $1, $2;
			END IF;
			kilroy_was_here := true;
			BEGIN
				INSERT INTO wicci_groups_leaders(group_, leader_)
				VALUES($1, $2);
				inserted := true;
			EXCEPTION
				WHEN unique_violation THEN			-- another thread??
					RAISE NOTICE '% % % raised %!', this, $1, $2, 'unique_violation';
			END;
		END LOOP;
	END;
$$ LANGUAGE plpgsql STRICT;

CREATE OR REPLACE
FUNCTION wicci_group_add_leader(wicci_group_refs, wicci_user_refs)
RETURNS boolean AS $$
	SELECT non_null(
		try_wicci_group_add_leader($1,$2),
		'wicci_group_add_leader(wicci_group_refs,wicci_user_refs)'
	)
$$ LANGUAGE sql;

COMMENT ON
FUNCTION wicci_group_add_leader(wicci_group_refs, wicci_user_refs)
IS 'set group leader;
return true if inserted newly, false if already present';

CREATE OR REPLACE
FUNCTION wicci_group_add_leader(wicci_group_refs, text)
RETURNS wicci_group_refs AS $$
	SELECT $1
	WHERE wicci_group_add_leader( $1, find_wicci_user_or_nil($2) );
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION wicci_group_add_leader(text, text)
RETURNS wicci_group_refs AS $$
	SELECT wicci_group_add_leader(find_wicci_group($1), $2)
$$ LANGUAGE sql;

-- * TABLE wicci_pages_delegates

-- +++ wicci_page_add_delegate(doc_page_refs, wicci_user_refs, levels integer) -> stati

CREATE OR REPLACE FUNCTION try_wicci_page_add_delegate(
	doc_page_refs, wicci_user_refs, integer = 0
)  RETURNS stati AS $$
DECLARE
	old_levels integer;
	status stati := 'failed status'::stati;
	kilroy_was_here boolean := false;
	this regprocedure :=
'try_wicci_page_add_delegate(doc_page_refs,wicci_user_refs,integer)';
BEGIN
	LOOP
		SELECT levels INTO old_levels FROM wicci_pages_delegates
			WHERE page_ = $1 AND delegate_ = $2;
		IF FOUND THEN
			IF old_levels = $3 THEN
				IF status = 'failed status'::stati THEN
					RETURN 'found status'::stati;
				END IF;
				RETURN status;
			END IF;
			UPDATE wicci_pages_delegates SET levels = $3
				WHERE page_ = $1 AND delegate_ = $2;
			RETURN 'updated status'::stati;
		END IF;
		IF kilroy_was_here THEN
			RAISE EXCEPTION '% looping with % % %', this, $1, $2, $3;
		END IF;
		kilroy_was_here := true;
		BEGIN
			INSERT INTO wicci_pages_delegates(page_, delegate_, levels)
				VALUES($1, $2, $3);
			status := 'inserted status'::stati;
		EXCEPTION
			WHEN unique_violation THEN			-- another thread??
RAISE NOTICE '% % % % raised %!',this,$1,$2, $3,'unique_violation';
		END;
	END LOOP;
END;
$$ LANGUAGE plpgsql STRICT;

CREATE OR REPLACE FUNCTION wicci_page_add_delegate(
	doc_page_refs, wicci_user_refs, integer = 0
) RETURNS stati AS $$
	SELECT non_null(
		try_wicci_page_add_delegate($1,$2,$3),
'wicci_page_add_delegate(doc_page_refs,wicci_user_refs,integer)'
	)
$$ LANGUAGE sql;

COMMENT ON FUNCTION
wicci_page_add_delegate(doc_page_refs, wicci_user_refs, integer)
IS 'set page delegate, return 0 if found, 1 if inserted, 2 if updated';

-- * TABLE wicci_transaction_rows

-- +++ new_wicci_trans(wicci_user_refs) -> wicci_transaction_refs
CREATE OR REPLACE
FUNCTION try_new_wicci_trans(wicci_user_refs) 
RETURNS wicci_transaction_refs AS $$
	INSERT INTO wicci_transaction_rows(user_)
	VALUES($1) RETURNING ref
$$ LANGUAGE sql STRICT;

CREATE OR REPLACE
FUNCTION new_wicci_trans(wicci_user_refs)
RETURNS wicci_transaction_refs AS $$
	SELECT non_null(
		try_new_wicci_trans($1), 'new_wicci_trans(wicci_user_refs)'
	)
$$ LANGUAGE sql;

COMMENT ON FUNCTION new_wicci_trans(wicci_user_refs) IS
'create a new wicci trans and return its ref';

CREATE OR REPLACE
FUNCTION wicci_trans_text(wicci_transaction_refs)
RETURNS TEXT AS $$
	SELECT '<wicci_trans id=' || ref_id($1)
		|| ' time=' || time || ' user=' || user_ || ' />'
	FROM wicci_transaction_rows WHERE ref = $1
$$ LANGUAGE sql;

SELECT type_class_op_method(
	'wicci_transaction_refs', 'wicci_transaction_rows',
	'ref_text_op(refs)',
	'wicci_trans_text(wicci_transaction_refs)'
);

-- * TABLE wicci_page_transaction_grafts

-- make unique/idempotent???
-- make accumulative???
-- make into an insert or update???
-- split into multiple functions???

CREATE OR REPLACE FUNCTION try_set_wicci_page_transaction_grafts(
	doc_page_refs, wicci_transaction_refs, VARIADIC doc_node_refs[]
)  RETURNS TABLE(
	_page doc_page_refs, _trans wicci_transaction_refs
) AS $$
	DELETE FROM wicci_page_transaction_grafts
	WHERE page_ = $1 AND trans_ = $2;
	INSERT INTO wicci_page_transaction_grafts(page_, trans_, grafts)
	VALUES($1, $2, $3) RETURNING page_, trans_
$$ LANGUAGE sql STRICT;

/*
-- Bogus error!!!
-- psql:wicci-page-simple-data.sql:36: ERROR:  0A000: set-valued function called in context that cannot accept a set
-- CONTEXT:  SQL function "set_wicci_page_transaction_grafts" statement 1
-- LOCATION:  ExecMakeTableFunctionResult, execQual.c:2001

CREATE OR REPLACE FUNCTION set_wicci_page_transaction_grafts(
	doc_page_refs, wicci_transaction_refs, VARIADIC doc_node_refs[]
) RETURNS TABLE(
	_page doc_page_refs, _trans wicci_transaction_refs
) AS $$
	SELECT _page_, _trans_ FROM non_null(
		try_set_wicci_page_transaction_grafts($1, $2, VARIADIC $3),
'set_wicci_page_transaction_grafts(doc_page_refs,wicci_transaction_refs,doc_node_refs[])'
	) AS foo(_page_ doc_page_refs, _trans_ wicci_transaction_refs)
$$ LANGUAGE sql;
*/

CREATE OR REPLACE FUNCTION set_wicci_page_transaction_grafts(
	doc_page_refs, wicci_transaction_refs, VARIADIC doc_node_refs[]
) RETURNS TABLE(
	_page doc_page_refs, _trans wicci_transaction_refs
) AS $$
	SELECT non_null(_page_, this), non_null(_trans_, this)
	FROM
		try_set_wicci_page_transaction_grafts($1, $2, VARIADIC $3)
		foo(_page_, _trans_),
--			foo(_page_ doc_page_refs, _trans_ wicci_transaction_refs),
		COALESCE(
'set_wicci_page_transaction_grafts(doc_page_refs,wicci_transaction_refs,doc_node_refs[]
		)'::regprocedure) this
	WHERE non_null(foo, this) IS NOT NULL
$$ LANGUAGE sql;

-- * TABLE wicci_groups_transactions

-- make unique/idempotent???
-- make accumulative???
-- make into an insert or update???
-- split into multiple functions???

CREATE OR REPLACE FUNCTION try_wicci_group_add_trans(
	wicci_group_refs, wicci_transaction_refs
) RETURNS wicci_transaction_refs AS $$
	DELETE FROM wicci_groups_transactions
	WHERE group_ = $1 AND trans_ = $2;
	INSERT INTO wicci_groups_transactions(group_, trans_)
	VALUES($1, $2) RETURNING trans_
$$ LANGUAGE sql STRICT;

CREATE OR REPLACE FUNCTION wicci_group_add_trans(
	wicci_group_refs, wicci_transaction_refs
) RETURNS wicci_transaction_refs AS $$
	SELECT non_null(
		try_wicci_group_add_trans($1,$2),
		'wicci_group_add_trans(wicci_group_refs,wicci_transaction_refs)'
	)
$$ LANGUAGE sql;

-- * TABLE wicci_derived_transactions

CREATE OR REPLACE FUNCTION try_new_wicci_trans_base(
	derived wicci_transaction_refs, base wicci_transaction_refs
) RETURNS wicci_transaction_refs AS $$
	INSERT INTO wicci_derived_transactions(derived_, base_)
	VALUES($1, $2) RETURNING derived_
$$ LANGUAGE sql STRICT;

CREATE OR REPLACE FUNCTION new_wicci_trans_base(
	derived wicci_transaction_refs, base wicci_transaction_refs
) RETURNS wicci_transaction_refs AS $$
	SELECT non_null(
		try_new_wicci_trans_base($1,$2),
'new_wicci_trans_base(wicci_transaction_refs,wicci_transaction_refs)'
	)
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION new_wicci_trans_bases(
	derived wicci_transaction_refs, bases wicci_transaction_refs[]
) RETURNS wicci_transaction_refs AS $$
	SELECT $1 WHERE array_length( ARRAY(
		SELECT new_wicci_trans_base($1, base)
		FROM unnest($2) base
	) ) > 0
$$ LANGUAGE sql;
COMMENT ON
FUNCTION new_wicci_trans_bases(
	wicci_transaction_refs, wicci_transaction_refs[]
) IS 'add bases to a new wicci trans and return its ref';

-- * more views

-- not a good view as page is not constrained???
CREATE OR REPLACE
VIEW view_transactions AS
	SELECT
		ref, time, user_ as owner,
		ARRAY(
			SELECT group_::entity_uri_refs FROM wicci_groups_transactions
			WHERE trans_ = ref
		) AS "groups",
		ARRAY(
			SELECT base_ FROM wicci_derived_transactions
			WHERE derived_ = ref
		) AS "based on",
		( SELECT grafts FROM wicci_page_transaction_grafts
			WHERE trans_ = ref
		) AS "grafts"
	FROM wicci_transaction_rows;

-- ** TABLE wicci_groups_pages_contents

/*
-- +++ wicci_group_page_content(group, page, doc) ->  (0, 1, 2)
CREATE OR REPLACE FUNCTION wicci_group_page_content(
	wicci_group_refs, doc_page_refs, doc_refs
) RETURNS integer AS $$
	DECLARE
		this regprocedure
		:= 'wicci_group_page_content(wicci_group_refs, doc_page_refs, doc_refs)';
		some_content doc_refs := unchecked_ref_null();
	BEGIN
		LOOP
			BEGIN
				SELECT doc INTO some_content
				FROM wicci_groups_pages_contents
				WHERE group_ = $1 AND page_ = $2;
				IF FOUND THEN
					IF some_content = $3 THEN
						RETURN 0;
					ELSE
						UPDATE wicci_groups_pages_contents
							SET doc = $3
						WHERE group_ = $1 AND page_ = $2;
						IF FOUND THEN
							RETURN 2;
						END IF;
					END IF;
				ELSE
					INSERT INTO
						wicci_groups_pages_contents(group_, page_, doc)
					VALUES($1, $2, $3);
					IF FOUND THEN
						RETURN 2;
					END IF;
				END IF;
			EXCEPTION
				WHEN unique_violation THEN
					RAISE NOTICE '% unique_violation on %, %, %', this, $1, $2, $3;
					-- evidence of another thread
			END;
		END LOOP;
	END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION
wicci_group_page_content(wicci_group_refs, doc_page_refs, doc_refs) IS
'let the group_page content of the given group and page be the given
content; return whether we found(0)/inserted(1)/updated(2) the row';
*/

/*
CREATE OR REPLACE
FUNCTION group_page_grafts(wicci_group_refs,doc_page_refs)
RETURNS xml_node_refs[] AS $$
	SELECT doc FROM wicci_groups_pages_contents
	WHERE group_ = $1 AND page_ = $2
$$ LANGUAGE sql;
*/

/*
CREATE OR REPLACE
VIEW view_groups_pages_contents AS
	SELECT
		group_ AS "group",
		page_ AS "page",
		type_, class_, doc
	FROM wicci_groups_pages_contents, typed_object_classes
	WHERE tag_ = ref_tag(doc);
*/

-- ** Creating a new account

CREATE OR REPLACE FUNCTION get_wicci_user_login(
	_user text, _login text, _passwd TEXT=''
) RETURNS wicci_user_refs AS $$
DECLARE
	_login wicci_login_refs := get_wicci_login( $2, $3 );
	_user wicci_user_refs := get_wicci_user(
		CASE WHEN $1 = '' THEN '' ELSE 'user:' END || $1, _login
	);
	_group wicci_group_refs := get_wicci_group(
		CASE WHEN $1 = '' THEN '' ELSE 'group:' END || $1, _user
	);
BEGIN
	RETURN new_wicci_user_group(_user, _group);
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION get_wicci_user_login(text, text, text) IS '
	Create or find given user, login and default user-associated
	group and return the user.
';

-- * wicci_grafts

CREATE OR REPLACE
FUNCTION wicci_grafts(doc_page_refs, wicci_user_refs)
RETURNS SETOF doc_node_refs AS $$
	SELECT
		unnest(wptg.grafts)
	FROM
		wicci_groups_members wgu,
		wicci_groups_transactions wgt,
		wicci_page_transaction_grafts wptg
	WHERE
		wgu.member_ = $2 AND
		wgu.group_ = wgt.group_ AND
		wgt.trans_ = wptg.trans_ AND
		wptg.page_ = $1
$$ LANGUAGE sql;
COMMENT ON
FUNCTION wicci_grafts(doc_page_refs, wicci_user_refs) IS
'This needs to be adjusted so that it eliminates
unwanted duplicates according to group order';

CREATE OR REPLACE FUNCTION wicci_grafts_from_to(
	doc_page_refs, wicci_user_refs,
	OUT _from refs[], OUT _to refs[] -- really doc_node_refs[]
) AS $$
	SELECT
		graft_node_old_array(grafts), -- really doc_node_refs[]
		graft_node_new_array(grafts)
	FROM (SELECT ARRAY( SELECT wicci_grafts($1, $2) ) ) foo(grafts)
$$ LANGUAGE sql;

--  * Wicci XML Widgets

--- ** names used as keys

-- SELECT declare_name(
--  	'user', 'group', 'page', 'url'
-- );

--  ** helper functions to generate group lists

CREATE OR REPLACE
FUNCTION wicci_all_groups(wicci_user_refs)
RETURNS wicci_group_refs[] AS $$
	SELECT u.groups || wicci_group_nil()
	FROM wicci_user_rows u WHERE u.ref = $1
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION wicci_grouplist_text(wicci_user_refs, env_refs, crefs)
RETURNS text AS $$
	SELECT xml_tag_body( 'ol', array_to_string( ARRAY(
		SELECT xml_tag_body('li', wicci_group_text(g), nl)
		FROM unnest(groups) g
	),  '' ), nl ) 
	FROM xml_nl($2, $3) nl, wicci_user_rows WHERE ref=$1
$$ LANGUAGE sql IMMUTABLE;

COMMENT ON FUNCTION 
wicci_grouplist_text(wicci_user_refs, env_refs, crefs)
IS 'Separate out friends (user groups) from non-user groups???';

CREATE OR REPLACE
FUNCTION wicci_changelist_text(wicci_user_refs, env_refs, crefs)
RETURNS text AS $$
	SELECT 'Not Done!!!'::text
$$ LANGUAGE sql IMMUTABLE;

COMMENT ON FUNCTION 
wicci_changelist_text(wicci_user_refs, env_refs, crefs)
IS 'List of websites which the user has changed,
organized reverse chronologically - NOT IMPLEMENTED!!!';

-- ** special kinds: abstract tables that are hooks for procedures

-- the first four arguments of any methods associated with
-- these tables should be:
-- (<ref-type>, env_refs, crefs, _chiln doc_node_refs[])

-- * dynamic kinds for adding code to html elements

-- See xml-html-data.sql

-- * wicci model dynamic kinds

SELECT create_dynamic_kind('wicci_user_status');

SELECT create_dynamic_kind_text_method(
	'wicci_user_status', $$
	SELECT xml_tag_attrs_body(
		'em', ARRAY['style', 'color:red'], 'user status', xml_nl($2, $3)
	)
$$);

/*
SELECT create_dynamic_kind_text_method('wicci_user_status', $$
	SELECT xml_tag_attrs_body(
		'em', ARRAY['style', 'color:red'], 'user status', xml_nl($2, $3)
	)
$$);
*/

SELECT create_dynamic_kind('wicci_user_name');

SELECT create_dynamic_kind_text_method('wicci_user_name', $$
	SELECT wicci_user_text(try_env_wicci_user($2))
$$);

SELECT create_dynamic_kind('wicci_login_name');

SELECT create_dynamic_kind_text_method('wicci_login_name', $$
	SELECT wicci_login_text(try_env_wicci_login($2))
$$);

SELECT create_dynamic_kind('wicci_group_list');

SELECT create_dynamic_kind_text_method('wicci_group_list', $$
	SELECT wicci_grouplist_text(
		try_env_wicci_user($2), $2, $3
	)
$$);

SELECT create_dynamic_kind('wicci_changes_list');

SELECT create_dynamic_kind_text_method('wicci_changes_list', $$
	SELECT wicci_changelist_text(
		try_env_wicci_user($2), $2, $3
	)
$$);

SELECT create_dynamic_kind('wicci_this_domain');

SELECT create_dynamic_kind_text_method('wicci_this_domain', $$
	SELECT uri_domain_name_text(domain_) FROM page_uri_rows
	WHERE ref IS NOT DISTINCT FROM
  try_page_uri(try_env_http_url($2))
$$);

SELECT create_dynamic_kind('wicci_this_path');

SELECT create_dynamic_kind_text_method('wicci_this_path', $$
	SELECT uri_path_name_text(path_) FROM page_uri_rows
	WHERE ref IS NOT DISTINCT FROM
  try_page_uri(try_env_http_url($2))
$$);

SELECT create_dynamic_kind('wicci_js_library');

-- this needs to vary depending on whether we're
-- operating on-line or offline!
SELECT create_dynamic_kind_text_method('wicci_js_library', $$
	SELECT E'<script type="text/javascript"
 src="//ajax.googleapis.com/ajax/libs/jquery/1.5.1/jquery.min.js"></script>
<script type="text/javascript">
  $(document).ready(function() {
    // This is more like it!
  });
</script>
'::text
$$);

-- ++ wicci_user_status_kind

-- !!! should these be special kinds ???

CREATE OR REPLACE
FUNCTION wicci_backside_button(TEXT) RETURNS text AS $$
	SELECT html_img_button(
		$1, NULL, NULL, xml_query_text('goto', 'back_page'),
		'404'::text, 'Images/blacktriangle.png', '<'::text
	)
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION wicci_userpage_button(TEXT) RETURNS text AS $$
	SELECT html_img_button(
		$1, NULL, NULL, xml_query_text('goto', 'user_page'),
		'user'::text, 'Images/bigstar.png', '*'::text
	)
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION wicci_othergroup_button(TEXT, wicci_group_refs)
RETURNS text AS $$
	SELECT html_button(
		$1, NULL, NULL, xml_query_text('group', group_text), group_text,
		'[' || $2::text || ']'
	) FROM wicci_group_text($2) group_text
$$ LANGUAGE sql;

-- * TABLE wicci_transfers_users

-- only used in following function - candidate for upgrading!!
CREATE OR REPLACE FUNCTION get_wicci_transfers_users(
	http_transfer_refs, wicci_user_refs
) RETURNS wicci_transfers_users AS $$
DECLARE
	maybe RECORD;
	kilroy_was_here boolean := false;
	_this regprocedure :=
	'get_wicci_transfers_users(http_transfer_refs, wicci_user_refs)';
BEGIN
	LOOP
		SELECT * INTO maybe FROM wicci_transfers_users
		WHERE xfer_ = $1 AND user_ = $2;
		IF FOUND THEN RETURN maybe; END IF;
		IF kilroy_was_here THEN
			RAISE EXCEPTION '% looping with % %', this, $1, $2;
		END IF;
		kilroy_was_here := true;
		BEGIN
			INSERT INTO wicci_transfers_users(xfer_, user_)
			VALUES($1, $2);
		EXCEPTION
			WHEN unique_violation THEN			-- another thread??
				RAISE NOTICE '% % % raised %!', this, $1, $2, 'unique_violation';
		END;
	END LOOP;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION get_wicci_transfers_users(
	http_transfer_refs, wicci_user_refs
) IS 'associates given http_transfer with given wicci_user_refs,
creating new tuple if necessary';

CREATE OR REPLACE FUNCTION set_wicci_transfer_user(
	http_transfer_refs, wicci_user_refs,
	 OUT http_transfer_refs, OUT wicci_user_refs
)  AS $$
	SELECT CASE
		WHEN is_nil($2) THEN $1
		ELSE ( get_wicci_transfers_users($1, $2) ).xfer_
	END, $2
$$ LANGUAGE sql;

COMMENT ON FUNCTION 
set_wicci_transfer_user(http_transfer_refs, wicci_user_refs)
IS 'associates user, when non-nil, with transfer, returning both for threading';
