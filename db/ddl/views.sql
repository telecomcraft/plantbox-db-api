CREATE OR REPLACE VIEW plant.service_zone_stats AS
SELECT service_zone_id AS id, count(id) AS parcels
FROM plant.parcels
WHERE service_zone_id IS NOT null
GROUP BY service_zone_id
ORDER BY service_zone_id;
ALTER VIEW IF EXISTS plant.service_zone_stats OWNER TO plantbox_users;
GRANT SELECT on plant.service_zone_stats to anonymous;

CREATE OR REPLACE VIEW plant.facility_stats AS
SELECT service_zone_id AS id, count(id) AS parcels
FROM plant.parcels
WHERE service_zone_id IS NOT null
GROUP BY service_zone_id
ORDER BY service_zone_id;
ALTER VIEW IF EXISTS plant.facility_stats OWNER TO plantbox_users;
--GRANT SELECT on plant.facility_stats to anonymous;

--CREATE OR REPLACE VIEW plant.cable_stats AS
--SELECT t.model_name, count(c.id) AS count,
--       round(sum(st_length(geom))) AS total_length_ft,
       round(avg(st_length(geom))) AS avg_length_ft,
       round(sum(st_length(geom)) / 5280) AS total_length_mi
FROM plant.cables AS c, plant.cable_types AS t
WHERE status_id = 3 AND c.type_id = t.id
GROUP BY t.model_name
ORDER BY t.model_name;
ALTER VIEW IF EXISTS plant.cable_stats OWNER TO plantbox_users;
--GRANT SELECT on plant.cable_stats to anonymous;