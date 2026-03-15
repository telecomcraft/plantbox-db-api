CREATE TABLE plant_assets (
	asset_id VARCHAR NOT NULL, 
	asset_type VARCHAR NOT NULL, 
	status VARCHAR, 
	PRIMARY KEY (asset_id)
);

CREATE TABLE cables (
	asset_id VARCHAR NOT NULL, 
	fiber_count INTEGER, 
	geom geometry(LINESTRING,4326), 
	PRIMARY KEY (asset_id), 
	FOREIGN KEY(asset_id) REFERENCES plant_assets (asset_id)
);

CREATE TABLE enclosures (
	asset_id VARCHAR NOT NULL, 
	category VARCHAR, 
	geom geometry(POINT,4326), 
	PRIMARY KEY (asset_id), 
	FOREIGN KEY(asset_id) REFERENCES plant_assets (asset_id)
);

