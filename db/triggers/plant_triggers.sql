-- plant.connections

DROP TRIGGER IF EXISTS update_splice_geometry
    ON plant.connections;
CREATE TRIGGER update_connections_geometry
    BEFORE INSERT OR UPDATE ON plant.connections
    FOR EACH ROW EXECUTE PROCEDURE plant.update_splice_geometry();

-- plant.circuits
-------------------------------------------------------------------------------
DROP TRIGGER IF EXISTS update_circuit_geometry
    ON plant.circuits;
CREATE TRIGGER update_circuit_geometry
    AFTER INSERT OR UPDATE ON plant.circuits
    FOR EACH ROW EXECUTE PROCEDURE plant.update_circuit_geometry();

-- plant.closures
-------------------------------------------------------------------------------
-- TODO: Update related splice geometries on closure moves


-- plant.parcels
-------------------------------------------------------------------------------

DROP TRIGGER IF EXISTS update_service_area_geometry
    ON plant.parcels;
CREATE TRIGGER update_service_area_geometry
    AFTER INSERT OR UPDATE ON plant.parcels
    FOR EACH ROW EXECUTE PROCEDURE plant.update_service_zone_geometry();

-- DROP TRIGGER IF EXISTS update_cables_length
--     ON maw.cables;
-- CREATE TRIGGER update_cables_length
--     BEFORE INSERT OR UPDATE ON maw.cables
--     FOR EACH ROW EXECUTE PROCEDURE update_cables_length();