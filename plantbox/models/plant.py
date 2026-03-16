from sqlalchemy import Column, String, Integer, Float, ForeignKey
from geoalchemy2 import Geometry
from plantbox.database import Base

class Enclosure(Base):
    __tablename__ = 'enclosures'
    asset_id = Column(String, primary_key=True)
    status = Column(String, default='PLANNED')
    category = Column(String) 
    geom = Column(Geometry('POINT', srid=4326))

class Cable(Base):
    __tablename__ = 'cables'
    asset_id = Column(String, primary_key=True)
    status = Column(String, default='PLANNED')
    cable_type = Column(String)
    fiber_count = Column(Integer)
    geom = Column(Geometry('LINESTRING', srid=4326))

class Splice(Base):
    __tablename__ = 'splices'
    splice_id = Column(String, primary_key=True)
    enclosure_id = Column(String, ForeignKey('enclosures.asset_id'), nullable=False)
    status = Column(String, default='PLANNED')
    loss_db = Column(Float)