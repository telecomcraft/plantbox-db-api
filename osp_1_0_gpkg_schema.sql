CREATE TABLE cables (
	asset_id VARCHAR NOT NULL, 
	status VARCHAR, 
	cable_type VARCHAR, 
	fiber_count INTEGER, 
	geom geometry(LINESTRING,4326), 
	PRIMARY KEY (asset_id)
);

CREATE TABLE enclosures (
	asset_id VARCHAR NOT NULL, 
	status VARCHAR, 
	category VARCHAR, 
	geom geometry(POINT,4326), 
	PRIMARY KEY (asset_id)
);

CREATE TABLE projects (
	project_id VARCHAR NOT NULL, 
	name VARCHAR NOT NULL, 
	status VARCHAR, 
	start_date DATE, 
	PRIMARY KEY (project_id)
);

CREATE TABLE phases (
	phase_id VARCHAR NOT NULL, 
	project_id VARCHAR NOT NULL, 
	name VARCHAR NOT NULL, 
	sequence_order INTEGER NOT NULL, 
	status VARCHAR, 
	PRIMARY KEY (phase_id), 
	FOREIGN KEY(project_id) REFERENCES projects (project_id)
);

CREATE TABLE splices (
	splice_id VARCHAR NOT NULL, 
	enclosure_id VARCHAR NOT NULL, 
	status VARCHAR, 
	loss_db FLOAT, 
	PRIMARY KEY (splice_id), 
	FOREIGN KEY(enclosure_id) REFERENCES enclosures (asset_id)
);

CREATE TABLE builds (
	build_id VARCHAR NOT NULL, 
	phase_id VARCHAR NOT NULL, 
	name VARCHAR NOT NULL, 
	work_type VARCHAR, 
	status VARCHAR, 
	PRIMARY KEY (build_id), 
	FOREIGN KEY(phase_id) REFERENCES phases (phase_id)
);

CREATE TABLE build_cables (
	build_id VARCHAR NOT NULL, 
	cable_id VARCHAR NOT NULL, 
	action_type VARCHAR NOT NULL, 
	action_date DATETIME, 
	notes VARCHAR, 
	PRIMARY KEY (build_id, cable_id), 
	FOREIGN KEY(build_id) REFERENCES builds (build_id), 
	FOREIGN KEY(cable_id) REFERENCES cables (asset_id)
);

CREATE TABLE build_enclosures (
	build_id VARCHAR NOT NULL, 
	enclosure_id VARCHAR NOT NULL, 
	action_type VARCHAR NOT NULL, 
	action_date DATETIME, 
	notes VARCHAR, 
	PRIMARY KEY (build_id, enclosure_id), 
	FOREIGN KEY(build_id) REFERENCES builds (build_id), 
	FOREIGN KEY(enclosure_id) REFERENCES enclosures (asset_id)
);

