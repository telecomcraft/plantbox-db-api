
-- Reports the current version of the Plantbox geodatabase HTTP API
CREATE OR REPLACE FUNCTION api.api_version() RETURNS INTEGER AS $$
BEGIN
    RETURN 0.1;
END;
$$ language plpgsql;
ALTER FUNCTION api.api_version() OWNER TO authenticator;
