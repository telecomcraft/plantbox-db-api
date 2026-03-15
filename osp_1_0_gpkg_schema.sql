CREATE TABLE asset_statuses (
	status_code VARCHAR NOT NULL, 
	description VARCHAR, 
	PRIMARY KEY (status_code)
);

CREATE TABLE cable_types (
	type_code VARCHAR NOT NULL, 
	description VARCHAR, 
	diameter_mm FLOAT, 
	PRIMARY KEY (type_code)
);

CREATE TABLE plant_assets (
	asset_id BIGINT NOT NULL, 
	uuid CHAR(32) NOT NULL, 
	asset_type VARCHAR NOT NULL, 
	status_code VARCHAR, 
	PRIMARY KEY (asset_id), 
	FOREIGN KEY(status_code) REFERENCES asset_statuses (status_code)
);

CREATE TABLE cables (
	asset_id BIGINT NOT NULL, 
	fiber_count INTEGER, 
	type_code VARCHAR, 
	geom geometry(LINESTRING,4326), 
	PRIMARY KEY (asset_id), 
	FOREIGN KEY(asset_id) REFERENCES plant_assets (asset_id), 
	FOREIGN KEY(type_code) REFERENCES cable_types (type_code)
);

CREATE TABLE enclosures (
	asset_id BIGINT NOT NULL, 
	category VARCHAR, 
	geom geometry(POINT,4326), 
	PRIMARY KEY (asset_id), 
	FOREIGN KEY(asset_id) REFERENCES plant_assets (asset_id)
);

CREATE TABLE splices (
	splice_id BIGINT NOT NULL, 
	enclosure_id BIGINT NOT NULL, 
	loss_db FLOAT, 
	PRIMARY KEY (splice_id), 
	FOREIGN KEY(enclosure_id) REFERENCES enclosures (asset_id)
);

