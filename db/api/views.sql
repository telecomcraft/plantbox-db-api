-- Returns all parcel IDs
CREATE OR REPLACE VIEW api.all_parcel_ids AS
SELECT
    id
FROM plant.parcels;
ALTER VIEW IF EXISTS api.all_parcel_ids OWNER TO plantbox_users;
GRANT SELECT on api.all_parcel_ids to anonymous;

-- Returns all service areas
CREATE OR REPLACE VIEW api.service_areas AS
SELECT *
FROM plant.service_areas;
ALTER VIEW IF EXISTS api.service_areas OWNER TO plantbox_users;
GRANT SELECT on api.service_areas to anonymous;

CREATE OR REPLACE VIEW api.service_zones AS
SELECT *
FROM plant.service_zones;
ALTER VIEW IF EXISTS api.service_zones OWNER TO plantbox_users;
GRANT SELECT on api.service_zones to anonymous;

