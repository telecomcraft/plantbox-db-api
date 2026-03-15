import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.event import listen
from geoalchemy2 import load_spatialite_gpkg

Base = declarative_base()

def get_engine(database_url: str):
    """
    Creates an engine. If connecting to a GeoPackage, attaches the 
    required SpatiaLite event listener for OGC compliance.
    """
    engine = create_engine(database_url, echo=False)
    
    if database_url.startswith("gpkg:///"):
        # This allows SQLite to load the mod_spatialite C-extension you installed
        listen(engine, "connect", load_spatialite_gpkg)
        
    return engine

def get_session_factory(engine):
    return sessionmaker(autocommit=False, autoflush=False, bind=engine)