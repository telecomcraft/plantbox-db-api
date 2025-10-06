CREATE OR REPLACE FUNCTION plant.update_circuit_geometry() RETURNS TRIGGER AS $$
DECLARE
    splice_points geometry[];
    a_point geometry;
    z_point geometry;
    circuit_geom geometry;
BEGIN
    a_point = (SELECT geom FROM plant.closures WHERE id = NEW.closure_a_id);
    z_point = (SELECT geom FROM plant.closures WHERE id = NEW.closure_z_id);
    --splice_points := (SELECT array_agg(geom) FROM plant.splices WHERE circuit_id = NEW.id);
    --splice_points := array_prepend(splice_points, a_point);
    --splice_points := array_append(splice_points, z_point);
    circuit_geom = st_makeline(a_point, z_point);

    NEW.geom = circuit_geom;

    RETURN NEW;
END;
$$ language plpgsql;
ALTER FUNCTION plant.update_circuit_geometry() OWNER TO plantbox_users;

CREATE OR REPLACE FUNCTION plant.update_connection_geometry() RETURNS TRIGGER AS $$
DECLARE
    closure_geom geometry;
BEGIN
    closure_geom = (SELECT geom FROM plant.closures WHERE id = NEW.closure_id);

    NEW.geom = closure_geom;

    RETURN NEW;
END;
$$ language plpgsql;
ALTER FUNCTION plant.update_connection_geometry() OWNER TO plantbox_users;

-- Updates service zone geometry any time a parcel's service_zone_id field is updated
CREATE OR REPLACE FUNCTION plant.update_service_zone_geometry() RETURNS TRIGGER AS $$
DECLARE
    new_geom geometry;
    new_residential_count bigint;
    new_commercial_count bigint;
    old_geom geometry;
    old_residential_count bigint;
    old_commercial_count bigint;
BEGIN
    new_geom = (SELECT ST_ConcaveHull(ST_Union(geom), 0.9, FALSE) FROM plant.parcels WHERE
                                                                                                        service_zone_id =
                                                                                                  NEW.service_zone_id);
    old_geom = (SELECT ST_ConcaveHull(ST_Union(geom), 0.9, FALSE) FROM plant.parcels WHERE
                                                                                                        service_zone_id =
                                                                                                  OLD.service_zone_id);
    new_residential_count = (SELECT sum(residential_units) FROM plant.parcels WHERE service_zone_id = NEW
        .service_zone_id);
    new_commercial_count = (SELECT sum(commercial_units) FROM plant.parcels WHERE service_zone_id = NEW
        .service_zone_id);
    old_residential_count = (SELECT sum(residential_units) FROM plant.parcels WHERE service_zone_id = OLD
        .service_zone_id);
    old_commercial_count = (SELECT sum(commercial_units) FROM plant.parcels WHERE service_zone_id = OLD
        .service_zone_id);

    UPDATE plant.service_zones
        SET geom = new_geom,
            residential_units = new_residential_count,
            commercial_units = new_commercial_count
    WHERE id = NEW.service_zone_id;

    UPDATE plant.service_zones
        SET geom = old_geom,
            residential_units = old_residential_count,
            commercial_units = old_commercial_count
    WHERE id = OLD.service_zone_id;

    RETURN NEW;
END;
$$ language plpgsql;
ALTER FUNCTION plant.update_service_zone_geometry() OWNER TO plantbox_users;
