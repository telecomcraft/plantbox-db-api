-- SCHEMAS AND EXTENSIONS
-----------------------------------------------------------------------------------------------------------------------

-- WARNING: This overwrites EVERYTHING in the PlantBox database!
DROP SCHEMA IF EXISTS plant CASCADE;
CREATE SCHEMA plant;
COMMENT ON SCHEMA plant IS 'Stores all plant facility and operation records.';

--CREATE EXTENSION postgis SCHEMA plant;
--CREATE EXTENSION postgis_raster SCHEMA plant;
--CREATE EXTENSION postgis_topology SCHEMA plant;

-- TYPES
-----------------------------------------------------------------------------------------------------------------------

CREATE TYPE plant.vehicle_type AS ENUM (
    'Car',
    'Trailer',
    'Truck',
    'Van'
);
COMMENT ON TYPE plant.vehicle_type IS 'Types for plant.vehicles';

CREATE TYPE plant.inventory_model_type AS ENUM (
    'Device',
    'Hardware',
    'Maintenance Supplies',
    'Materials',
    'Tools/Equipment'
);
COMMENT ON TYPE plant.inventory_model_type IS 'Types for plant.models';

CREATE TYPE plant.hardware_assembly_type AS ENUM (
    'Aerial Attachment',
    'Bonding/Grounding',
    'Submarine Attachment',
    'Underground Attachment'
);
COMMENT ON TYPE plant.hardware_assembly_type IS 'Types for plant.hardware_assemblies';

-- TODO: Do we want this? Might make sense to make it available.
CREATE TYPE plant.region_type AS ENUM ('Geographic Area', 'Service Area', 'Service Zone');
COMMENT ON TYPE plant.region_type IS 'Types for plant.regions';

CREATE TYPE plant.site_type AS ENUM ('Network', 'Storage', 'Premises');
COMMENT ON TYPE plant.site_type IS 'Types for plant.sites';

CREATE TYPE plant.task_status AS ENUM ('Not Started', 'Incomplete', 'Blocked', 'Complete');
COMMENT ON TYPE plant.task_status IS 'Statuses for plant.tasks';

CREATE TYPE plant.unit_type AS ENUM ('Each', 'Foot', 'Inch');
COMMENT ON TYPE plant.unit_type IS 'Types of units for quantities, measurements, etc.';

CREATE TYPE plant.termination_type AS ENUM ('Fusion Splice', 'Mechanical Splice');
COMMENT ON TYPE plant.termination_type IS 'Types of cable terminations';

-- STORED PROCEDURES
-----------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION plant.update_date_modified_column() RETURNS TRIGGER AS $$
BEGIN
    NEW.date_updated := current_timestamp;
    RETURN NEW;
END;
$$ language plpgsql;
COMMENT ON FUNCTION plant.update_date_modified_column() IS 'Updates the date_modified field of a record.';
--ALTER FUNCTION plant.update_date_modified_column() OWNER TO plantbox_users;


CREATE OR REPLACE FUNCTION plant.update_user_modified_column() RETURNS TRIGGER AS $$
BEGIN
    NEW.user_updated := current_user;
    RETURN NEW;
END;
$$ language plpgsql;
COMMENT ON FUNCTION plant.update_user_modified_column() IS 'Updates the user_modified field of a record.';
--ALTER FUNCTION plant.update_user_modified_column() OWNER TO plantbox_users;


-- TODO: Should we use defaults for these if they're going to be overwritten anyway?
CREATE OR REPLACE FUNCTION plant.update_row_modifications() RETURNS TRIGGER AS $$
BEGIN
    NEW.date_updated := current_timestamp;
    NEW.user_updated := current_user;
    RETURN NEW;
END;
$$ language plpgsql;
COMMENT ON FUNCTION plant.update_row_modifications() IS 'Updates the modification fields of a row.';
--ALTER FUNCTION plant.update_date_modified_column() OWNER TO plantbox_users;


-- TODO: Implement this once the rest of the initial design is done
/*
CREATE OR REPLACE FUNCTION plant.copy_revision() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO plant.entities_revisions (id, uuid, notes, date_created, date_updated, user_created, user_updated)
    VALUES (OLD.id, OLD.uuid, OLD.notes, OLD.date_created, OLD.date_updated, OLD.user_created, OLD.user_updated);
    RETURN NEW;
END;
$$ language plpgsql;
*/

-- TODO: Finish
-- CREATE OR REPLACE FUNCTION plant.name_inventory_item()
-- RETURNS TEXT AS 'text_concat_ws' LANGUAGE internal immutable;

-- TABLES
-----------------------------------------------------------------------------------------------------------------------

/*
It appears we can now use arrays in QGIS to reference relations in other tables, even adding multiple keys to a feature
and having QGIS manage the association behind the scenes. The main problem at this point is the lack of referential
integrity, so tags must remain a more casual, "use at your own risk" functionality until PostgreSQL addresses this. I've
noticed that some forms (in 3.22) still reference a deleted tag, so I don't think this is ready for use in production.
 */
CREATE TABLE plant.tags (
    id bigint GENERATED ALWAYS AS IDENTITY,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    name varchar NOT NULL,
    description text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    PRIMARY KEY (id)
);

-- Entities and Contacts
-----------------------------------------------------------

/*

*/
-- STATUS: In development; Needs documentation
CREATE TABLE plant.entity_groups (
    id bigint GENERATED ALWAYS AS IDENTITY,
    parent_id bigint NULL REFERENCES plant.entity_groups(id) ON DELETE RESTRICT,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    name varchar NOT NULL,
    description text NULL,
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE plant.entity_groups IS 'Entity groups are used to organize entities together, such as customers and vendors.';
COMMENT ON COLUMN plant.entity_groups.id IS 'Primary key of the plant.entity_groups record.';
COMMENT ON COLUMN plant.entity_groups.parent_id IS 'Key of the the parent plant.entity_groups record.';
COMMENT ON COLUMN plant.entity_groups.uuid IS 'UUID key of the plant.entity_groups record.';
COMMENT ON COLUMN plant.entity_groups.name IS 'Name of the plant.entity_groups record.';
COMMENT ON COLUMN plant.entity_groups.description IS 'Description of the plant.entity_groups record.';
COMMENT ON COLUMN plant.entity_groups.notes IS 'Notes of the plant.entity_groups record.';
COMMENT ON COLUMN plant.entity_groups.date_created IS 'Creation date of the plant.entity_groups record.';
COMMENT ON COLUMN plant.entity_groups.date_updated IS 'Update date of the plant.entity_groups record.';
COMMENT ON COLUMN plant.entity_groups.user_created IS 'Creator of the plant.entity_groups record.';
COMMENT ON COLUMN plant.entity_groups.user_updated IS 'Modifier of the plant.entity_groups record.';

CREATE TRIGGER update_modified_fields
    -- TODO: Can we handle the INSERT defaults here too?
    BEFORE UPDATE ON plant.entity_groups
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.entity_groups IS 'Updates modification fields of each edited plant.entity_groups row.';

CREATE TABLE plant.entity_groups_revisions (LIKE plant.entity_groups INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.entity_groups_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.entity_groups_revisions IS 'Stores all revisions of records in the plant.entity_groups table.';


/*

*/
CREATE TABLE plant.entities (
    id bigint GENERATED ALWAYS AS IDENTITY,
    parent_id bigint NULL REFERENCES plant.entities(id) ON DELETE RESTRICT,
    group_id bigint NULL REFERENCES plant.entity_groups(id) ON DELETE RESTRICT,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    name varchar NOT NULL,
    description text NULL,
    -- The following booleans are for specific system "roles" entities can have
    is_ahj bool NULL,
    is_contractor bool NULL,
    is_customer bool NULL,
    is_manufacturer bool NULL,
    is_partner bool NULL,
    is_vendor bool NULL,
    -- TODO: finish fleshing this out and then document!
    physical_address_street_number varchar NULL,
    physical_address_street_name varchar NULL,
    physical_address_street_unit varchar NULL,
    physical_address_street_city varchar NULL,
    physical_address_street_state varchar NULL,
    physical_address_street_zipcode char NULL,
    mailing_address_street_number varchar NULL,
    mailing_address_street_name varchar NULL,
    mailing_address_street_unit varchar NULL,
    mailing_address_street_city varchar NULL,
    mailing_address_street_state varchar NULL,
    mailing_address_street_zipcode char NULL,
    notes text NULL,
    tags bigint[] NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE plant.entities IS 'Entities are organizations involved in the plant, starting with the plant owner, as well as customers, vendors, and other facility owners that the plant relies on. Entities can be nested for hierarchical organization and subaccounts.';
COMMENT ON COLUMN plant.entities.id IS 'Primary key of the plant.entities record.';
COMMENT ON COLUMN plant.entities.parent_id IS 'Key of the the parent plant.entities record.';
COMMENT ON COLUMN plant.entities.group_id IS 'Key of the entity group of the plant.entities record.';
COMMENT ON COLUMN plant.entities.uuid IS 'UUID key of the plant.entities record.';
COMMENT ON COLUMN plant.entities.name IS 'Name of the plant.entities record.';
COMMENT ON COLUMN plant.entities.description IS 'Description of the plant.entities record.';
COMMENT ON COLUMN plant.entities.is_customer IS 'Indicates if the entity is a customer paying for services.';
COMMENT ON COLUMN plant.entities.is_vendor IS 'Indicates if the entity is a vendor providing services.';
COMMENT ON COLUMN plant.entities.is_partner IS 'Indicates if the entity is a partner involved in the business.';
COMMENT ON COLUMN plant.entities.notes IS 'Notes of the plant.entities record.';
COMMENT ON COLUMN plant.entities.date_created IS 'Creation date of the plant.entities record.';
COMMENT ON COLUMN plant.entities.date_updated IS 'Update date of the plant.entities record.';
COMMENT ON COLUMN plant.entities.user_created IS 'Creator of the plant.entities record.';
COMMENT ON COLUMN plant.entities.user_updated IS 'Modifier of the plant.entities record.';

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.entities
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.entities IS 'Updates modification fields of each edited plant.entities row.';

CREATE TABLE plant.entities_revisions (LIKE plant.entities INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.entities_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.entities_revisions IS 'Stores all revisions of records in the plant.entities table.';


/*

*/
CREATE TABLE plant.contact_groups (
    id bigint GENERATED ALWAYS AS IDENTITY,
    parent_id bigint NULL REFERENCES plant.contact_groups(id),
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    name varchar NOT NULL,
    description text NULL,
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE plant.contact_groups IS 'Contact groups are used to organize contacts within an entity. Contact groups can be nested for hierarchical organization.';
COMMENT ON COLUMN plant.contact_groups.id IS 'Primary key of the plant.contact_groups record.';
COMMENT ON COLUMN plant.contact_groups.parent_id IS 'Key of the parent group of the plant.contact_groups record.';
COMMENT ON COLUMN plant.contact_groups.uuid IS 'UUID key of the plant.contact_groups record.';
COMMENT ON COLUMN plant.contact_groups.name IS 'Name of the plant.contact_groups record.';
COMMENT ON COLUMN plant.contact_groups.description IS 'Description of the plant.contact_groups record.';
COMMENT ON COLUMN plant.contact_groups.notes IS 'Notes of the plant.contact_groups record.';
COMMENT ON COLUMN plant.contact_groups.date_created IS 'Creation date of the plant.contact_groups record.';
COMMENT ON COLUMN plant.contact_groups.date_updated IS 'Update date of the plant.contact_groups record.';
COMMENT ON COLUMN plant.contact_groups.user_created IS 'Creator of the plant.contact_groups record.';
COMMENT ON COLUMN plant.contact_groups.user_updated IS 'Modifier of the plant.contact_groups record.';

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.contact_groups
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.contact_groups IS 'Updates modification fields of each edited plant.contact_groups row.';

CREATE TABLE plant.contact_groups_revisions (LIKE plant.contact_groups INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.contact_groups_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.contact_groups_revisions IS 'Stores all revisions of records in the plant.contact_groups table.';


/*
Contact roles define the responsibilities a contact has within an entity, such as the billing or technical contact.
Currently it's just an administrative record, but could be used for more purposes in the future.
*/
CREATE TABLE plant.contact_roles (
    id bigint GENERATED ALWAYS AS IDENTITY,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    name varchar NOT NULL,
    description text NULL,
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE plant.contact_roles IS 'Contact roles define the specific role a contact can serve in for an entity.';
COMMENT ON COLUMN plant.contact_roles.id IS 'Primary key of the plant.contact_roles record.';
COMMENT ON COLUMN plant.contact_roles.uuid IS 'UUID key of the plant.contact_roles record.';
COMMENT ON COLUMN plant.contact_roles.name IS 'Name of the plant.contact_roles record.';
COMMENT ON COLUMN plant.contact_roles.description IS 'Description of the plant.contact_roles record.';
COMMENT ON COLUMN plant.contact_roles.notes IS 'Notes of the plant.contact_roles record.';
COMMENT ON COLUMN plant.contact_roles.date_created IS 'Creation date of the plant.contact_roles record.';
COMMENT ON COLUMN plant.contact_roles.date_updated IS 'Update date of the plant.contact_roles record.';
COMMENT ON COLUMN plant.contact_roles.user_created IS 'Creator of the plant.contact_roles record.';
COMMENT ON COLUMN plant.contact_roles.user_updated IS 'Modifier of the plant.contact_roles record.';

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.contact_roles
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.contact_roles IS 'Updates modification fields of each edited plant.contact_roles row.';

CREATE TABLE plant.contact_roles_revisions (LIKE plant.contact_roles INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.contact_roles_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.contact_roles_revisions IS 'Stores all revisions of records in the plant.contact_roles table.';


/*
Contacts define individuals involved in entities, sites, and other places in the network. Initially they are mainly
used to track contact information and roles, but can also be used for project management purposes and assigning
inventory items to, as well. They can be further organized into contact groups.
*/
CREATE TABLE plant.contacts (
    id bigint GENERATED ALWAYS AS IDENTITY,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    contact_role_id bigint NULL REFERENCES plant.contact_roles(id) ON DELETE RESTRICT,
    is_task_assignee bool NULL DEFAULT false,
    entity_id bigint NULL REFERENCES plant.entities(id) ON DELETE RESTRICT,
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE plant.contacts IS 'Contacts are individuals or groups related to entities that serve as points of contact in some capacity. Contacts can be further organized into groups.';
COMMENT ON COLUMN plant.contacts.id IS 'Primary key of the plant.contacts record.';
COMMENT ON COLUMN plant.contacts.uuid IS 'UUID key of the plant.contacts record.';
COMMENT ON COLUMN plant.contacts.contact_role_id IS 'Role the contact serves as for the entity.';
COMMENT ON COLUMN plant.contacts.is_task_assignee IS 'Contact can be assigned tasks.';
COMMENT ON COLUMN plant.contacts.entity_id IS 'Entity key that the contact serves a role in.';
COMMENT ON COLUMN plant.contacts.notes IS 'Notes of the plant.contacts record.';
COMMENT ON COLUMN plant.contacts.date_created IS 'Creation date of the plant.contacts record.';
COMMENT ON COLUMN plant.contacts.date_updated IS 'Update date of the plant.contacts record.';
COMMENT ON COLUMN plant.contacts.user_created IS 'Creator of the plant.contacts record.';
COMMENT ON COLUMN plant.contacts.user_updated IS 'Modifier of the plant.contacts record.';

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.contacts
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.contacts IS 'Updates modification fields of each edited plant.contacts row.';

CREATE TABLE plant.contacts_revisions (LIKE plant.contacts INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.contacts_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.contacts_revisions IS 'Stores all revisions of records in the plant.contacts table.';


-- Projects, Project Templates, Plans, Plan Templates, Tasks, Task Lists, Task Templates,
-- Agreements, Agreement Templates, Jobs, Job Templates, Tickets, Ticket Templates
-- TODO: Workflows
-----------------------------------------------------------

/*

*/
CREATE TABLE plant.projects (
    id bigint GENERATED ALWAYS AS IDENTITY,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE plant.projects IS 'Projects are a collection of planned work on the plant, organized into plan records.';
COMMENT ON COLUMN plant.projects.id IS 'Primary key of the plant.projects record.';
COMMENT ON COLUMN plant.projects.uuid IS 'UUID key of the plant.projects record.';
COMMENT ON COLUMN plant.projects.notes IS 'Notes of the plant.projects record.';
COMMENT ON COLUMN plant.projects.date_created IS 'Creation date of the plant.projects record.';
COMMENT ON COLUMN plant.projects.date_updated IS 'Update date of the plant.projects record.';
COMMENT ON COLUMN plant.projects.user_created IS 'Creator of the plant.projects record.';
COMMENT ON COLUMN plant.projects.user_updated IS 'Modifier of the plant.projects record.';

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.projects
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.projects IS 'Updates modification fields of each edited plant.projects row.';

CREATE TABLE plant.projects_revisions (LIKE plant.projects INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.projects_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.projects_revisions IS 'Stores all revisions of records in the plant.projects table.';


/*

*/
CREATE TABLE plant.plans (
    id bigint GENERATED ALWAYS AS IDENTITY,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE plant.plans IS 'Plans are a defined unit of work on the plant, organized into projects.';
COMMENT ON COLUMN plant.plans.id IS 'Primary key of the plant.plans record.';
COMMENT ON COLUMN plant.plans.uuid IS 'UUID key of the plant.plans record.';
COMMENT ON COLUMN plant.plans.notes IS 'Notes of the plant.plans record.';
COMMENT ON COLUMN plant.plans.date_created IS 'Creation date of the plant.plans record.';
COMMENT ON COLUMN plant.plans.date_updated IS 'Update date of the plant.plans record.';
COMMENT ON COLUMN plant.plans.user_created IS 'Creator of the plant.plans record.';
COMMENT ON COLUMN plant.plans.user_updated IS 'Modifier of the plant.plans record.';

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.plans
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.plans IS 'Updates modification fields of each edited plant.plans row.';

CREATE TABLE plant.plans_revisions (LIKE plant.plans INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.plans_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.plans_revisions IS 'Stores all revisions of records in the plant.plans table.';


/*

*/
CREATE TABLE plant.tickets (
    id bigint GENERATED ALWAYS AS IDENTITY,
    -- TODO: parent ticket?
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE plant.tickets IS 'Tickets are specific issues that must be addressed.';
COMMENT ON COLUMN plant.tickets.id IS 'Primary key of the plant.tickets record.';
COMMENT ON COLUMN plant.tickets.uuid IS 'UUID key of the plant.tickets record.';
COMMENT ON COLUMN plant.tickets.notes IS 'Notes of the plant.tickets record.';
COMMENT ON COLUMN plant.tickets.date_created IS 'Creation date of the plant.tickets record.';
COMMENT ON COLUMN plant.tickets.date_updated IS 'Update date of the plant.tickets record.';
COMMENT ON COLUMN plant.tickets.user_created IS 'Creator of the plant.tickets record.';
COMMENT ON COLUMN plant.tickets.user_updated IS 'Modifier of the plant.tickets record.';

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.tickets
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.tickets IS 'Updates modification fields of each edited plant.tickets row.';

CREATE TABLE plant.tickets_revisions (LIKE plant.tickets INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.tickets_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.tickets_revisions IS 'Stores all revisions of records in the plant.tickets table.';


/*

*/
CREATE TABLE plant.jobs (
    id bigint GENERATED ALWAYS AS IDENTITY,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE plant.jobs IS 'Jobs are specific issues that must be addressed.';
COMMENT ON COLUMN plant.jobs.id IS 'Primary key of the plant.jobs record.';
COMMENT ON COLUMN plant.jobs.uuid IS 'UUID key of the plant.jobs record.';
COMMENT ON COLUMN plant.jobs.notes IS 'Notes of the plant.jobs record.';
COMMENT ON COLUMN plant.jobs.date_created IS 'Creation date of the plant.jobs record.';
COMMENT ON COLUMN plant.jobs.date_updated IS 'Update date of the plant.jobs record.';
COMMENT ON COLUMN plant.jobs.user_created IS 'Creator of the plant.jobs record.';
COMMENT ON COLUMN plant.jobs.user_updated IS 'Modifier of the plant.jobs record.';

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.jobs
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.jobs IS 'Updates modification fields of each edited plant.jobs row.';

CREATE TABLE plant.jobs_revisions (LIKE plant.jobs INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.jobs_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.jobs_revisions IS 'Stores all revisions of records in the plant.jobs table.';


/*
Tasks can be associated with many other records in a one-to-many relationship. I'm thinking it should be nearly
any of the management modules here (projects, plans, tickets, jobs, agreements), but each task is constrained to
only one of those items.
*/
CREATE TABLE plant.tasks (
    id bigint GENERATED ALWAYS AS IDENTITY,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    status plant.task_status NOT NULL DEFAULT 'Not Started',
    contact_id bigint NULL REFERENCES plant.contacts(id),
    name varchar NOT NULL,
    description text NULL,
    project_id bigint NULL REFERENCES plant.projects(id) ON DELETE RESTRICT,
    plan_id bigint NULL REFERENCES plant.plans(id) ON DELETE RESTRICT,
    ticket_id bigint NULL REFERENCES plant.tickets(id) ON DELETE RESTRICT,
    job_id bigint NULL REFERENCES plant.jobs(id) ON DELETE RESTRICT,
    date_due timestamp NULL,
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    PRIMARY KEY (id)
    --TODO: How to restrict only one of multiple fields being true without a large set of permutation logic?
);
COMMENT ON TABLE plant.tasks IS 'Tasks are a specific action to be performed as part of another management object.';
COMMENT ON COLUMN plant.tasks.id IS 'Primary key of the plant.tasks record.';
COMMENT ON COLUMN plant.tasks.uuid IS 'UUID key of the plant.tasks record.';
COMMENT ON COLUMN plant.tasks.status IS 'Current status of the task.';
COMMENT ON COLUMN plant.tasks.contact_id IS 'Contact assigned to the task.';
COMMENT ON COLUMN plant.tasks.name IS 'Name of the task.';
COMMENT ON COLUMN plant.tasks.description IS 'Description of the task.';
COMMENT ON COLUMN plant.tasks.project_id IS 'Project ID of the task.';
COMMENT ON COLUMN plant.tasks.plan_id IS 'Plan ID of the task.';
COMMENT ON COLUMN plant.tasks.ticket_id IS 'Ticket ID of the task.';
COMMENT ON COLUMN plant.tasks.job_id IS 'Job ID of the task.';
COMMENT ON COLUMN plant.tasks.date_due IS 'Due date of the task.';
COMMENT ON COLUMN plant.tasks.notes IS 'Notes of the task.';
COMMENT ON COLUMN plant.tasks.date_created IS 'Creation date of the task.';
COMMENT ON COLUMN plant.tasks.date_updated IS 'Last update date of the task.';
COMMENT ON COLUMN plant.tasks.user_created IS 'Initial user that created the task.';
COMMENT ON COLUMN plant.tasks.user_updated IS 'Last user that updated the task.';

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.tasks
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.tasks IS 'Updates modification fields of each edited plant.tasks row.';

CREATE TABLE plant.tasks_revisions (LIKE plant.tasks INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.tasks_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.tasks_revisions IS 'Stores all revisions of records in the plant.plans table.';


/*

*/
CREATE TABLE plant.agreements (
    id bigint GENERATED ALWAYS AS IDENTITY,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    --TODO: agreement type
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE plant.agreements IS '';
COMMENT ON COLUMN plant.agreements.id IS 'Primary key of the plant.agreements record.';
COMMENT ON COLUMN plant.agreements.uuid IS 'UUID key of the plant.agreements record.';
COMMENT ON COLUMN plant.agreements.notes IS 'Notes of the plant.agreements record.';
COMMENT ON COLUMN plant.agreements.date_created IS 'Creation date of the plant.agreements record.';
COMMENT ON COLUMN plant.agreements.date_updated IS 'Update date of the plant.agreements record.';
COMMENT ON COLUMN plant.agreements.user_created IS 'Creator of the plant.agreements record.';
COMMENT ON COLUMN plant.agreements.user_updated IS 'Modifier of the plant.agreements record.';

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.agreements
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.agreements IS 'Updates modification fields of each edited plant.agreements row.';

CREATE TABLE plant.agreements_revisions (LIKE plant.agreements INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.agreements_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.agreements_revisions IS 'Stores all revisions of records in the plant.agreements table.';

-- Scheduling Management
-----------------------------------------------------------

-- TODO: plant.geofences
/*

*/

-- TODO: plant.scheduling_availability
/*

*/

-- TODO: plant.scheduling
/*
The schedule tracks any jobs
*/

-- Fleet Management
-----------------------------------------------------------

/*

*/
CREATE TABLE plant.vehicle_manufacturers (
    id bigint GENERATED ALWAYS AS IDENTITY,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    name varchar NOT NULL,
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE plant.vehicle_manufacturers IS 'Regions are geographic areas the network operates within.';
COMMENT ON COLUMN plant.vehicle_manufacturers.id IS 'Primary key of the plant.regions record.';
COMMENT ON COLUMN plant.vehicle_manufacturers.uuid IS 'UUID key of the plant.regions record.';
COMMENT ON COLUMN plant.vehicle_manufacturers.name IS '';
COMMENT ON COLUMN plant.vehicle_manufacturers.notes IS 'Notes of the plant.regions record.';
COMMENT ON COLUMN plant.vehicle_manufacturers.date_created IS 'Creation date of the plant.regions record.';
COMMENT ON COLUMN plant.vehicle_manufacturers.date_updated IS 'Update date of the plant.regions record.';
COMMENT ON COLUMN plant.vehicle_manufacturers.user_created IS 'Creator of the plant.regions record.';
COMMENT ON COLUMN plant.vehicle_manufacturers.user_updated IS 'Modifier of the plant.regions record.';

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.vehicle_manufacturers
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.vehicle_manufacturers IS 'Updates modification fields of each edited plant.vehicle_manufacturers row.';

CREATE TABLE plant.vehicle_manufacturers_revisions (LIKE plant.vehicle_manufacturers INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.vehicle_manufacturers_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.vehicle_manufacturers_revisions IS 'Stores all revisions of records in the plant.vehicle_manufacturers table.';


/*

*/
CREATE TABLE plant.vehicle_models (
    id bigint GENERATED ALWAYS AS IDENTITY,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    type plant.vehicle_type NOT NULL,
    name varchar NOT NULL,
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE plant.vehicle_models IS 'Regions are geographic areas the network operates within.';
COMMENT ON COLUMN plant.vehicle_models.id IS 'Primary key of the plant.regions record.';
COMMENT ON COLUMN plant.vehicle_models.uuid IS 'UUID key of the plant.regions record.';
COMMENT ON COLUMN plant.vehicle_models.type IS '';
COMMENT ON COLUMN plant.vehicle_models.name IS '';
COMMENT ON COLUMN plant.vehicle_models.notes IS 'Notes of the plant.regions record.';
COMMENT ON COLUMN plant.vehicle_models.date_created IS 'Creation date of the plant.regions record.';
COMMENT ON COLUMN plant.vehicle_models.date_updated IS 'Update date of the plant.regions record.';
COMMENT ON COLUMN plant.vehicle_models.user_created IS 'Creator of the plant.regions record.';
COMMENT ON COLUMN plant.vehicle_models.user_updated IS 'Modifier of the plant.regions record.';

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.vehicle_models
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.vehicle_models IS 'Updates modification fields of each edited plant.vehicle_models row.';

CREATE TABLE plant.vehicle_models_revisions (LIKE plant.vehicle_models INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.vehicle_models_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.vehicle_models_revisions IS 'Stores all revisions of records in the plant.vehicle_models table.';


/*

*/
CREATE TABLE plant.vehicles (
    id bigint GENERATED ALWAYS AS IDENTITY,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    name varchar NOT NULL,
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    geom geometry(Point) NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE plant.vehicles IS 'Regions are geographic areas the network operates within.';
COMMENT ON COLUMN plant.vehicles.id IS 'Primary key of the plant.regions record.';
COMMENT ON COLUMN plant.vehicles.uuid IS 'UUID key of the plant.regions record.';
COMMENT ON COLUMN plant.vehicles.name IS '';
COMMENT ON COLUMN plant.vehicles.notes IS 'Notes of the plant.regions record.';
COMMENT ON COLUMN plant.vehicles.date_created IS 'Creation date of the plant.regions record.';
COMMENT ON COLUMN plant.vehicles.date_updated IS 'Update date of the plant.regions record.';
COMMENT ON COLUMN plant.vehicles.user_created IS 'Creator of the plant.regions record.';
COMMENT ON COLUMN plant.vehicles.user_updated IS 'Modifier of the plant.regions record.';
COMMENT ON COLUMN plant.vehicles.geom IS '';

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.vehicles
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.vehicles IS 'Updates modification fields of each edited plant.vehicles row.';

CREATE TABLE plant.vehicles_revisions (LIKE plant.vehicles INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.vehicles_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.vehicles_revisions IS 'Stores all revisions of records in the plant.vehicles table.';

-- Regions, Serice Areas/Zones, Sites, and Locations
-----------------------------------------------------------

/*
These tables organize where the plant literally is, from the global scale down to specific sites and even locations
within them. In addition, we want to provide ways to define not only where the plant is, but exactly where people can
get service from the plant.
*/

-- TODO: Define the overall topology constraints for all places. These should all just be using PostGIS topology.


/*
The entire plant should exist within a defined region. Regions can be as large as needed, and don't hold a rigid
classification.
*/
CREATE TABLE plant.regions (
    -- TODO: Should regions have geometries? Are they different enough from service areas/zones?
    -- TODO: Should regions have any uniqueness constraints?
    id bigint GENERATED ALWAYS AS IDENTITY,
    parent_id bigint NULL REFERENCES plant.regions(id) ON DELETE RESTRICT,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    type plant.region_type,
    name varchar NOT NULL,
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    geom geometry(MultiPolygon) NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE plant.regions IS 'Regions are geographic areas the network operates within.';
COMMENT ON COLUMN plant.regions.id IS 'Primary key of the plant.regions record.';
COMMENT ON COLUMN plant.regions.parent_id IS 'Key of the parent region of the plant.regions record.';
COMMENT ON COLUMN plant.regions.uuid IS 'UUID key of the plant.regions record.';
COMMENT ON COLUMN plant.regions.type IS '';
COMMENT ON COLUMN plant.regions.name IS '';
COMMENT ON COLUMN plant.regions.notes IS 'Notes of the plant.regions record.';
COMMENT ON COLUMN plant.regions.date_created IS 'Creation date of the plant.regions record.';
COMMENT ON COLUMN plant.regions.date_updated IS 'Update date of the plant.regions record.';
COMMENT ON COLUMN plant.regions.user_created IS 'Creator of the plant.regions record.';
COMMENT ON COLUMN plant.regions.user_updated IS 'Modifier of the plant.regions record.';
COMMENT ON COLUMN plant.regions.geom IS '';

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.regions
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.regions IS 'Updates modification fields of each edited plant.regions row.';

CREATE TABLE plant.regions_revisions (LIKE plant.regions INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.regions_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.regions_revisions IS 'Stores all revisions of records in the plant.regions table.';


/*

*/
CREATE TABLE plant.service_areas (
    id bigint GENERATED ALWAYS AS IDENTITY,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    region_id bigint NULL REFERENCES plant.regions ON DELETE RESTRICT,
    name varchar NOT NULL,
    description varchar NULL,
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    geom geometry(MultiPolygon) NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE plant.service_areas IS 'service_areas are used to logically organize multiple sites.';
COMMENT ON COLUMN plant.service_areas.id IS 'Primary key of the plant.service_areas record.';
COMMENT ON COLUMN plant.service_areas.uuid IS 'UUID key of the plant.service_areas record.';
COMMENT ON COLUMN plant.service_areas.name IS 'Name of the service_areas.';
COMMENT ON COLUMN plant.service_areas.description IS 'Description of the service_areas.';
COMMENT ON COLUMN plant.service_areas.notes IS 'Notes of the plant.service_areas record.';
COMMENT ON COLUMN plant.service_areas.date_created IS 'Creation date of the plant.service_areas record.';
COMMENT ON COLUMN plant.service_areas.date_updated IS 'Update date of the plant.service_areas record.';
COMMENT ON COLUMN plant.service_areas.user_created IS 'Creator of the plant.service_areas record.';
COMMENT ON COLUMN plant.service_areas.user_updated IS 'Modifier of the plant.service_areas record.';

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.service_areas
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.service_areas IS 'Updates modification fields of each edited plant.service_areas row.';

CREATE TABLE plant.service_areas_revisions (LIKE plant.service_areas INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.service_areas_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.service_areas_revisions IS 'Stores all revisions of records in the plant.service_areas table.';


/*

*/
CREATE TABLE plant.service_zones (
    id bigint GENERATED ALWAYS AS IDENTITY,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    name varchar NOT NULL,
    description varchar NULL,
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    geom geometry(MultiPolygon) NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE plant.service_zones IS 'service_zones are used to logically organize multiple sites.';
COMMENT ON COLUMN plant.service_zones.id IS 'Primary key of the plant.service_zones record.';
COMMENT ON COLUMN plant.service_zones.uuid IS 'UUID key of the plant.service_zones record.';
COMMENT ON COLUMN plant.service_zones.name IS 'Name of the service_zones.';
COMMENT ON COLUMN plant.service_zones.description IS 'Description of the service_zones.';
COMMENT ON COLUMN plant.service_zones.notes IS 'Notes of the plant.service_zones record.';
COMMENT ON COLUMN plant.service_zones.date_created IS 'Creation date of the plant.service_zones record.';
COMMENT ON COLUMN plant.service_zones.date_updated IS 'Update date of the plant.service_zones record.';
COMMENT ON COLUMN plant.service_zones.user_created IS 'Creator of the plant.service_zones record.';
COMMENT ON COLUMN plant.service_zones.user_updated IS 'Modifier of the plant.service_zones record.';

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.service_zones
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.service_zones IS 'Updates modification fields of each edited plant.service_zones row.';

CREATE TABLE plant.service_zones_revisions (LIKE plant.service_zones INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.service_zones_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.service_zones_revisions IS 'Stores all revisions of records in the plant.service_zones table.';


/*

*/
CREATE TABLE plant.site_groups (
    id bigint GENERATED ALWAYS AS IDENTITY,
    -- Sites must not have parent sites; they must remain as unique as possible. Logical organization can be done
    -- via plant.site_groups
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    name varchar NOT NULL,
    description varchar NULL,
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE plant.site_groups IS 'Site groups are used to logically organize multiple sites.';
COMMENT ON COLUMN plant.site_groups.id IS 'Primary key of the plant.site_groups record.';
COMMENT ON COLUMN plant.site_groups.uuid IS 'UUID key of the plant.site_groups record.';
COMMENT ON COLUMN plant.site_groups.name IS 'Name of the site group.';
COMMENT ON COLUMN plant.site_groups.description IS 'Description of the site group.';
COMMENT ON COLUMN plant.site_groups.notes IS 'Notes of the plant.site_groups record.';
COMMENT ON COLUMN plant.site_groups.date_created IS 'Creation date of the plant.site_groups record.';
COMMENT ON COLUMN plant.site_groups.date_updated IS 'Update date of the plant.site_groups record.';
COMMENT ON COLUMN plant.site_groups.user_created IS 'Creator of the plant.site_groups record.';
COMMENT ON COLUMN plant.site_groups.user_updated IS 'Modifier of the plant.site_groups record.';

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.site_groups
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.site_groups IS 'Updates modification fields of each edited plant.site_groups row.';

CREATE TABLE plant.site_groups_revisions (LIKE plant.site_groups INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.site_groups_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.site_groups_revisions IS 'Stores all revisions of records in the plant.site_groups table.';


/*
Sites must not have parent sites; they must remain as unique as possible. Logical organization can be done via
plant.site_groups
*/
CREATE TABLE plant.sites (
    id bigint GENERATED ALWAYS AS IDENTITY,
    group_id bigint NULL REFERENCES plant.site_groups(id) ON DELETE RESTRICT,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    region_id bigint NOT NULL REFERENCES plant.regions(id) ON DELETE RESTRICT,
    owner_id bigint REFERENCES plant.entities(id) ON DELETE RESTRICT,
    tenant_id bigint REFERENCES plant.entities(id) ON DELETE RESTRICT,
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    geom geometry(Point),  -- TODO: Test point
    PRIMARY KEY (id)
);
COMMENT ON TABLE plant.sites IS 'Sites are key points related to the network operations and service delivery. They are defined inside of regions and unique down to the unit of a physical address.';
COMMENT ON COLUMN plant.sites.id IS 'Primary key of the plant.sites record.';
COMMENT ON COLUMN plant.sites.group_id IS 'Key of the group the site belongs to.';
COMMENT ON COLUMN plant.sites.uuid IS 'UUID key of the plant.sites record.';
COMMENT ON COLUMN plant.sites.region_id IS 'The region record that the plant.sites record exists within.';
COMMENT ON COLUMN plant.sites.owner_id IS 'The entity that owns the site.';
COMMENT ON COLUMN plant.sites.tenant_id IS 'The entity that occupies the site.';
COMMENT ON COLUMN plant.sites.notes IS 'Notes of the plant.sites record.';
COMMENT ON COLUMN plant.sites.date_created IS 'Creation date of the plant.sites record.';
COMMENT ON COLUMN plant.sites.date_updated IS 'Update date of the plant.sites record.';
COMMENT ON COLUMN plant.sites.user_created IS 'Creator of the plant.sites record.';
COMMENT ON COLUMN plant.sites.user_updated IS 'Modifier of the plant.sites record.';

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.sites
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.sites IS 'Updates modification fields of each edited plant.sites row.';

CREATE TABLE plant.sites_revisions (LIKE plant.sites INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.sites_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.sites_revisions IS 'Stores all revisions of records in the plant.sites table.';


-- TODO: location_types
/*

*/
CREATE TABLE plant.locations (
    id bigint GENERATED ALWAYS AS IDENTITY,
    parent_id bigint NULL REFERENCES plant.locations(id) ON DELETE RESTRICT,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id bigint NOT NULL REFERENCES plant.sites(id) ON DELETE RESTRICT,
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE plant.locations IS 'Locations are specific points within sites that records are associated with.';
COMMENT ON COLUMN plant.locations.id IS 'Primary key of the plant.locations record.';
COMMENT ON COLUMN plant.locations.parent_id IS 'Parent key of the location.';
COMMENT ON COLUMN plant.locations.uuid IS 'UUID key of the plant.locations record.';
COMMENT ON COLUMN plant.locations.notes IS 'Notes of the plant.locations record.';
COMMENT ON COLUMN plant.locations.date_created IS 'Creation date of the plant.locations record.';
COMMENT ON COLUMN plant.locations.date_updated IS 'Update date of the plant.locations record.';
COMMENT ON COLUMN plant.locations.user_created IS 'Creator of the plant.locations record.';
COMMENT ON COLUMN plant.locations.user_updated IS 'Modifier of the plant.locations record.';

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.locations
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.locations IS 'Updates modification fields of each edited plant.locations row.';

CREATE TABLE plant.locations_revisions (LIKE plant.locations INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.locations_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.locations_revisions IS 'Stores all revisions of records in the plant.locations table.';


-- Inventory Management
-----------------------------------------------------------

/*

*/
CREATE TABLE plant.manufacturers (
    id bigint GENERATED ALWAYS AS IDENTITY,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id bigint NOT NULL REFERENCES plant.entities(id) ON DELETE RESTRICT,
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    PRIMARY KEY (id)
);
-- TODO: Table comments

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.manufacturers
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.manufacturers IS 'Updates modification fields of each edited plant.manufacturers row.';

CREATE TABLE plant.manufacturers_revisions (LIKE plant.manufacturers INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.manufacturers_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.manufacturers_revisions IS 'Stores all revisions of records in the plant.manufacturers table.';


/*

*/
CREATE TABLE plant.vendors (
    id bigint GENERATED ALWAYS AS IDENTITY,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id bigint NOT NULL REFERENCES plant.entities(id) ON DELETE RESTRICT,
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    PRIMARY KEY (id)
);
-- TODO: Table comments

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.vendors
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.vendors IS 'Updates modification fields of each edited plant.vendors row.';

CREATE TABLE plant.vendors_revisions (LIKE plant.vendors INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.vendors_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.vendors_revisions IS 'Stores all revisions of records in the plant.vendors table.';


/*

*/
CREATE TABLE plant.inventory_categories (
    id bigint GENERATED ALWAYS AS IDENTITY,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    name varchar NOT NULL,
    description text NULL,
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    PRIMARY KEY (id)
);
-- TODO: Table comments

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.inventory_categories
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.inventory_categories IS 'Updates modification fields of each edited plant.inventory_categories row.';

CREATE TABLE plant.inventory_categories_revisions (LIKE plant.inventory_categories INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.inventory_categories_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.inventory_categories_revisions IS 'Stores all revisions of records in the plant.inventory_categories table.';


/*

*/
CREATE TABLE plant.models (
    id bigint GENERATED ALWAYS AS IDENTITY,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    -- TODO: type
    manufacturer_id bigint REFERENCES plant.manufacturers(id) ON DELETE RESTRICT NOT NULL,
    inventory_categories_id bigint NULL REFERENCES plant.inventory_categories(id) ON DELETE SET NULL,
    is_inventoried bool DEFAULT true NOT NULL,
    name varchar NOT NULL,
    listing_name varchar, -- TODO: Make this a generated column from name, quantity_per_unit, quantity_unit
    model_number varchar NULL, -- model number
    part_number varchar NULL,
    sku_code varchar NULL,
    description text NULL,
    preferred_vendor_id bigint NULL REFERENCES plant.vendors(id) ON DELETE RESTRICT,
    quantity_per_unit int DEFAULT 1 NOT NULL,
    quantity_unit plant.unit_type NOT NULL,
    maximum_level int NULL,
    reorder_level int DEFAULT 0 NULL,
    minimum_level int DEFAULT 0 NULL,
    is_generic bool DEFAULT true NULL,  -- TODO: consumable?
    purchase_price numeric DEFAULT 0 NULL,
    purchase_account int NULL,
    is_billable bool DEFAULT true NULL,
    sale_price numeric DEFAULT 0 NULL,
    sale_account int NULL,
    is_taxable bool DEFAULT false NULL,
    -- TODO picture
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    PRIMARY KEY (id)
);
-- TODO: Table comments

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.models
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.models IS 'Updates modification fields of each edited plant.models row.';

CREATE TABLE plant.models_revisions (LIKE plant.models INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.models_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.models_revisions IS 'Stores all revisions of records in the plant.models table.';


/*

*/
CREATE TABLE plant.inventory_items (
    id bigint GENERATED ALWAYS AS IDENTITY,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    model_id bigint REFERENCES plant.models(id) ON DELETE RESTRICT NULL,
    serial_number varchar NULL,
    mac_address macaddr NULL,
    location_id bigint REFERENCES plant.locations(id) NULL,
    contact_id bigint REFERENCES plant.contacts(id) NULL,
    is_reserved bool NULL,
    project_id bigint REFERENCES plant.projects(id) NULL,
    is_consumed bool NULL,
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    PRIMARY KEY (id)
);
-- TODO: Table comments

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.inventory_items
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.inventory_items IS 'Updates modification fields of each edited plant.inventory_items row.';

CREATE TABLE plant.inventory_items_revisions (LIKE plant.inventory_items INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.inventory_items_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.inventory_items_revisions IS 'Stores all revisions of records in the plant.inventory_items table.';

-- Pathways and Spaces
-----------------------------------------------------------

-- TODO: support_structure_types
/*

*/
CREATE TABLE plant.support_structures (
    id bigint GENERATED ALWAYS AS IDENTITY,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE plant.support_structures IS 'Support structures are part of aerial pathways.';
COMMENT ON COLUMN plant.support_structures.id IS 'Primary key of the plant.support_structures record.';
COMMENT ON COLUMN plant.support_structures.uuid IS 'UUID key of the plant.support_structures record.';
COMMENT ON COLUMN plant.support_structures.notes IS 'Notes of the plant.support_structures record.';
COMMENT ON COLUMN plant.support_structures.date_created IS 'Creation date of the plant.support_structures record.';
COMMENT ON COLUMN plant.support_structures.date_updated IS 'Update date of the plant.support_structures record.';
COMMENT ON COLUMN plant.support_structures.user_created IS 'Creator of the plant.support_structures record.';
COMMENT ON COLUMN plant.support_structures.user_updated IS 'Modifier of the plant.support_structures record.';

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.support_structures
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.support_structures IS 'Updates modification fields of each edited plant.support_structures row.';

CREATE TABLE plant.support_structures_revisions (LIKE plant.support_structures INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.support_structures_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.support_structures_revisions IS 'Stores all revisions of records in the plant.support_structures table.';


/*

*/
CREATE TABLE plant.hardware_assemblies (
    /*
    This table represent the hardware used to attach facilities, such as devices, cables, and closures, to
    pathways and spaces. The issue here is how granular to get with the breakdown of the hardware.
    There are multiple ways to install a through bolt, for example, depending on it's length, thickness, washers, nuts,
    etc. My original idea was to produce part assembly records to fully describe attachments for analysis, BOM, etc.,
    but nothing else is currently that granular and it may get complicated to integrate with the frontends for now.

    Another important implementation note is that attachments should be presented with at least three dimensions to
    prepare them for 3D visualization and analysis.
    */
    id bigint GENERATED ALWAYS AS IDENTITY,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    -- TODO: attachment_types
    -- TODO: assembly_id?
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    -- TODO: geometry
    PRIMARY KEY (id)
);
COMMENT ON TABLE plant.hardware_assemblies IS 'Hardware are used on pathways to install and secure facilities.';
COMMENT ON COLUMN plant.hardware_assemblies.id IS 'Primary key of the plant.hardware record.';
COMMENT ON COLUMN plant.hardware_assemblies.uuid IS 'UUID key of the plant.hardware record.';
COMMENT ON COLUMN plant.hardware_assemblies.notes IS 'Notes of the plant.hardware record.';
COMMENT ON COLUMN plant.hardware_assemblies.date_created IS 'Creation date of the plant.hardware record.';
COMMENT ON COLUMN plant.hardware_assemblies.date_updated IS 'Update date of the plant.hardware record.';
COMMENT ON COLUMN plant.hardware_assemblies.user_created IS 'Creator of the plant.hardware record.';
COMMENT ON COLUMN plant.hardware_assemblies.user_updated IS 'Modifier of the plant.hardware record.';

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.hardware_assemblies
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.hardware_assemblies IS 'Updates modification fields of each edited plant.hardware_assemblies row.';

CREATE TABLE plant.hardware_assemblies_revisions (LIKE plant.hardware_assemblies INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.hardware_assemblies_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.hardware_assemblies_revisions IS 'Stores all revisions of records in the plant.hardware_assemblies table.';


/*

*/
CREATE TABLE plant.hardware (
    /*
    This table represent the hardware used to attach facilities, such as devices, cables, and closures, to
    pathways and spaces. The issue here is how granular to get with the breakdown of the hardware.
    There are multiple ways to install a through bolt, for example, depending on it's length, thickness, washers, nuts,
    etc. My original idea was to produce part assembly records to fully describe attachments for analysis, BOM, etc.,
    but nothing else is currently that granular and it may get complicated to integrate with the frontends for now.

    Another important implementation note is that attachments should be presented with at least three dimensions to
    prepare them for 3D visualization and analysis.
    */
    id bigint GENERATED ALWAYS AS IDENTITY,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    assembly_id bigint NOT NULL REFERENCES plant.hardware_assemblies(id) ON DELETE RESTRICT,
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    -- TODO: geometry
    PRIMARY KEY (id)
);
COMMENT ON TABLE plant.hardware IS 'Hardware are used on pathways to install and secure facilities.';
COMMENT ON COLUMN plant.hardware.id IS 'Primary key of the plant.hardware record.';
COMMENT ON COLUMN plant.hardware.uuid IS 'UUID key of the plant.hardware record.';
COMMENT ON COLUMN plant.hardware.notes IS 'Notes of the plant.hardware record.';
COMMENT ON COLUMN plant.hardware.date_created IS 'Creation date of the plant.hardware record.';
COMMENT ON COLUMN plant.hardware.date_updated IS 'Update date of the plant.hardware record.';
COMMENT ON COLUMN plant.hardware.user_created IS 'Creator of the plant.hardware record.';
COMMENT ON COLUMN plant.hardware.user_updated IS 'Modifier of the plant.hardware record.';

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.hardware
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.hardware IS 'Updates modification fields of each edited plant.hardware row.';

CREATE TABLE plant.hardware_revisions (LIKE plant.hardware INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.hardware_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.hardware_revisions IS 'Stores all revisions of records in the plant.hardware table.';


-- TODO: support_strand_types
/*

*/
CREATE TABLE plant.support_strands (
    id bigint GENERATED ALWAYS AS IDENTITY,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE plant.support_strands IS 'Support strands are used for aerial spans and anchor guys.';
COMMENT ON COLUMN plant.support_strands.id IS 'Primary key of the plant.support_strands record.';
COMMENT ON COLUMN plant.support_strands.uuid IS 'UUID key of the plant.support_strands record.';
COMMENT ON COLUMN plant.support_strands.notes IS 'Notes of the plant.support_strands record.';
COMMENT ON COLUMN plant.support_strands.date_created IS 'Creation date of the plant.support_strands record.';
COMMENT ON COLUMN plant.support_strands.date_updated IS 'Update date of the plant.support_strands record.';
COMMENT ON COLUMN plant.support_strands.user_created IS 'Creator of the plant.support_strands record.';
COMMENT ON COLUMN plant.support_strands.user_updated IS 'Modifier of the plant.support_strands record.';

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.support_strands
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.support_strands IS 'Updates modification fields of each edited plant.support_strands row.';

CREATE TABLE plant.support_strands_revisions (LIKE plant.support_strands INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.support_strands_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.support_strands_revisions IS 'Stores all revisions of records in the plant.support_strands table.';


-- TODO: space_types
/*

*/
CREATE TABLE plant.spaces (
    id bigint GENERATED ALWAYS AS IDENTITY,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    --TODO: space type
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE plant.spaces IS 'Spaces are ground or underground based places that contain various facilities.';
COMMENT ON COLUMN plant.spaces.id IS 'Primary key of the plant.spaces record.';
COMMENT ON COLUMN plant.spaces.uuid IS 'UUID key of the plant.spaces record.';
COMMENT ON COLUMN plant.spaces.notes IS 'Notes of the plant.spaces record.';
COMMENT ON COLUMN plant.spaces.date_created IS 'Creation date of the plant.spaces record.';
COMMENT ON COLUMN plant.spaces.date_updated IS 'Update date of the plant.spaces record.';
COMMENT ON COLUMN plant.spaces.user_created IS 'Creator of the plant.spaces record.';
COMMENT ON COLUMN plant.spaces.user_updated IS 'Modifier of the plant.spaces record.';

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.spaces
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.spaces IS 'Updates modification fields of each edited plant.spaces row.';

CREATE TABLE plant.spaces_revisions (LIKE plant.spaces INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.spaces_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.spaces_revisions IS 'Stores all revisions of records in the plant.spaces table.';


-- TODO: conduit_types
/*

*/
CREATE TABLE plant.conduits (
    id bigint GENERATED ALWAYS AS IDENTITY,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    --TODO: type
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE plant.conduits IS 'Conduits are underground pathways that connect sites or spaces.';
COMMENT ON COLUMN plant.conduits.id IS 'Primary key of the plant.conduits record.';
COMMENT ON COLUMN plant.conduits.uuid IS 'UUID key of the plant.conduits record.';
COMMENT ON COLUMN plant.conduits.notes IS 'Notes of the plant.conduits record.';
COMMENT ON COLUMN plant.conduits.date_created IS 'Creation date of the plant.conduits record.';
COMMENT ON COLUMN plant.conduits.date_updated IS 'Update date of the plant.conduits record.';
COMMENT ON COLUMN plant.conduits.user_created IS 'Creator of the plant.conduits record.';
COMMENT ON COLUMN plant.conduits.user_updated IS 'Modifier of the plant.conduits record.';

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.conduits
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.conduits IS 'Updates modification fields of each edited plant.conduits row.';

CREATE TABLE plant.conduits_revisions (LIKE plant.conduits INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.conduits_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.conduits_revisions IS 'Stores all revisions of records in the plant.conduits table.';


-- Devices, Cables, Terminations, and Links
-----------------------------------------------------------

/*

*/
CREATE TABLE plant.devices (
    id bigint GENERATED ALWAYS AS IDENTITY,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    --TODO: type_id
    --TODO: model_id?
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE plant.devices IS 'Devices are passive and active pieces of equipment installed as facilities in the plant.';
COMMENT ON COLUMN plant.devices.id IS 'Primary key of the plant.devices record.';
COMMENT ON COLUMN plant.devices.uuid IS 'UUID key of the plant.devices record.';
COMMENT ON COLUMN plant.devices.notes IS 'Notes of the plant.devices record.';
COMMENT ON COLUMN plant.devices.date_created IS 'Creation date of the plant.devices record.';
COMMENT ON COLUMN plant.devices.date_updated IS 'Update date of the plant.devices record.';
COMMENT ON COLUMN plant.devices.user_created IS 'Creator of the plant.devices record.';
COMMENT ON COLUMN plant.devices.user_updated IS 'Modifier of the plant.devices record.';

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.devices
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.devices IS 'Updates modification fields of each edited plant.devices row.';

CREATE TABLE plant.devices_revisions (LIKE plant.devices INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.devices_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.devices_revisions IS 'Stores all revisions of records in the plant.devices table.';


/*

*/
CREATE TABLE plant.device_components (
    id bigint GENERATED ALWAYS AS IDENTITY,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE plant.device_components IS 'Device components are generic parts of devices that can be optional or customizable.';
COMMENT ON COLUMN plant.device_components.id IS 'Primary key of the plant.device_components record.';
COMMENT ON COLUMN plant.device_components.uuid IS 'UUID key of the plant.device_components record.';
COMMENT ON COLUMN plant.device_components.notes IS 'Notes of the plant.device_components record.';
COMMENT ON COLUMN plant.device_components.date_created IS 'Creation date of the plant.device_components record.';
COMMENT ON COLUMN plant.device_components.date_updated IS 'Update date of the plant.device_components record.';
COMMENT ON COLUMN plant.device_components.user_created IS 'Creator of the plant.device_components record.';
COMMENT ON COLUMN plant.device_components.user_updated IS 'Modifier of the plant.device_components record.';

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.device_components
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.device_components IS 'Updates modification fields of each edited plant.device_components row.';

CREATE TABLE plant.device_components_revisions (LIKE plant.device_components INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.device_components_revisions ADD PRIMARY KEY (id, date_updated);
COMMENT ON TABLE plant.device_components_revisions IS 'Stores all revisions of records in the plant.device_components table.';


/*

*/
CREATE TABLE plant.closures (
    id bigint GENERATED ALWAYS AS IDENTITY,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    geom geometry(Point) NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE plant.closures IS 'Closures are the storage points for all terminations of communication cables.';
COMMENT ON COLUMN plant.closures.id IS 'Primary key of the plant.closures record.';
COMMENT ON COLUMN plant.closures.uuid IS 'UUID key of the plant.closures record.';
COMMENT ON COLUMN plant.closures.notes IS 'Notes of the plant.closures record.';
COMMENT ON COLUMN plant.closures.date_created IS 'Creation date of the plant.closures record.';
COMMENT ON COLUMN plant.closures.date_updated IS 'Update date of the plant.closures record.';
COMMENT ON COLUMN plant.closures.user_created IS 'Creator of the plant.closures record.';
COMMENT ON COLUMN plant.closures.user_updated IS 'Modifier of the plant.closures record.';

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.closures
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.closures IS 'Updates modification fields of each edited plant.closures row.';

CREATE TABLE plant.closures_revisions (LIKE plant.closures INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.closures_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.closures_revisions IS 'Stores all revisions of records in the plant.closures table.';


/*

*/
CREATE TABLE plant.cables (
    id bigint GENERATED ALWAYS AS IDENTITY,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    geom geometry(LineString) NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE plant.cables IS 'Cables are communication cables that transmit data and optionally power.';
COMMENT ON COLUMN plant.cables.id IS 'Primary key of the plant.cables record.';
COMMENT ON COLUMN plant.cables.uuid IS 'UUID key of the plant.cables record.';
COMMENT ON COLUMN plant.cables.notes IS 'Notes of the plant.cables record.';
COMMENT ON COLUMN plant.cables.date_created IS 'Creation date of the plant.cables record.';
COMMENT ON COLUMN plant.cables.date_updated IS 'Update date of the plant.cables record.';
COMMENT ON COLUMN plant.cables.user_created IS 'Creator of the plant.cables record.';
COMMENT ON COLUMN plant.cables.user_updated IS 'Modifier of the plant.cables record.';

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.cables
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.cables IS 'Updates modification fields of each edited plant.cables row.';

CREATE TABLE plant.cables_revisions (LIKE plant.cables INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.cables_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.cables_revisions IS 'Stores all revisions of records in the plant.cables table.';


/*
Data on all fiber, twisted pair, or coaxial cable terminations within closures that, when combined, represent links.
*/
CREATE TABLE plant.terminations (
    id bigint GENERATED ALWAYS AS IDENTITY,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    closure_id bigint NOT NULL REFERENCES plant.closures ON DELETE RESTRICT,
    -- Required for all cable types:
    incoming_cable_id bigint NOT NULL REFERENCES plant.cables ON DELETE RESTRICT,
    -- Incoming fiber fields
    incoming_fiber_tube_number int NULL,
    incoming_fiber_strand_number int NULL,
    incoming_fiber_tray_number int NULL,
    -- Common termination fields
    type termination_type NOT NULL,
    -- Outgoing fiber fields
    outgoing_fiber_tray_number int NULL,
    outgoing_jumper_number int NULL,
    outgoing_pigtail_number int NULL,
    outgoing_fiber_strand_number int NULL,
    outgoing_fiber_tube_number int NULL,
    -- Incoming twisted pair fields
    -- Outgoing twisted pair fields
    -- Incoming coaxial fields
    -- Outgoing coaxial fields
    -- Outgoing port fields
    outgoing_port_number int NULL,
    outgoing_port_type port_type NULL,

    outgoing_cable_id bigint NULL, -- This can't be required as it's not always true
    notes text NULL,
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    geom geometry(Point) NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE plant.terminations IS 'Terminations are spliced or connected cabling points between wireline devices.';
COMMENT ON COLUMN plant.terminations.id IS 'Primary key of the plant.terminations record.';
COMMENT ON COLUMN plant.terminations.uuid IS 'UUID key of the plant.terminations record.';
COMMENT ON COLUMN plant.terminations.notes IS 'Notes of the plant.terminations record.';
COMMENT ON COLUMN plant.terminations.date_created IS 'Creation date of the plant.terminations record.';
COMMENT ON COLUMN plant.terminations.date_updated IS 'Update date of the plant.terminations record.';
COMMENT ON COLUMN plant.terminations.user_created IS 'Creator of the plant.terminations record.';
COMMENT ON COLUMN plant.terminations.user_updated IS 'Modifier of the plant.terminations record.';

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.terminations
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.terminations IS 'Updates modification fields of each edited plant.terminations row.';

CREATE TABLE plant.terminations_revisions (LIKE plant.terminations INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.terminations_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.terminations_revisions IS 'Stores all revisions of records in the plant.terminations table.';


/*

*/
CREATE TABLE plant.links (
    id bigint GENERATED ALWAYS AS IDENTITY,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    notes text NULL,
    -- Radio link fields
    date_created timestamp DEFAULT current_timestamp NOT NULL,
    date_updated timestamp DEFAULT current_timestamp NOT NULL,
    user_created varchar DEFAULT current_user NOT NULL,
    user_updated varchar DEFAULT current_user NOT NULL,
    PRIMARY KEY (id)
);
COMMENT ON TABLE plant.links IS 'Links are unique sequences of terminations that deliver specific connectivity across the network.';
COMMENT ON COLUMN plant.links.id IS 'Primary key of the plant.links record.';
COMMENT ON COLUMN plant.links.uuid IS 'UUID key of the plant.links record.';
COMMENT ON COLUMN plant.links.notes IS 'Notes of the plant.links record.';
COMMENT ON COLUMN plant.links.date_created IS 'Creation date of the plant.links record.';
COMMENT ON COLUMN plant.links.date_updated IS 'Update date of the plant.links record.';
COMMENT ON COLUMN plant.links.user_created IS 'Creator of the plant.links record.';
COMMENT ON COLUMN plant.links.user_updated IS 'Modifier of the plant.links record.';

CREATE TRIGGER update_modified_fields
    BEFORE UPDATE ON plant.links
    FOR EACH ROW EXECUTE PROCEDURE plant.update_row_modifications();
COMMENT ON TRIGGER update_modified_fields ON plant.links IS 'Updates modification fields of each edited plant.links row.';

CREATE TABLE plant.links_revisions (LIKE plant.links INCLUDING ALL EXCLUDING INDEXES);
ALTER TABLE plant.links_revisions
    ADD PRIMARY KEY (id, date_updated),
    ALTER COLUMN id DROP IDENTITY,
    ALTER COLUMN uuid DROP DEFAULT,
    ALTER COLUMN date_created DROP DEFAULT,
    ALTER COLUMN date_updated DROP DEFAULT,
    ALTER COLUMN user_created DROP DEFAULT,
    ALTER COLUMN user_updated DROP DEFAULT;
COMMENT ON TABLE plant.links_revisions IS 'Stores all revisions of records in the plant.links table.';


-- VIEWS
-----------------------------------------------------------------------------------------------------------------------

