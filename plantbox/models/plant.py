import uuid
from sqlalchemy import Column, String, Integer, Float, ForeignKey, BigInteger, Uuid
from sqlalchemy.orm import relationship
from geoalchemy2 import Geometry
from plantbox.database import Base

# --- Metadata / Lookup Tables ---

class AssetStatus(Base):
    """Lookup table for valid plant statuses (e.g., PLANNED, IN_SERVICE, ABANDONED)"""
    __tablename__ = 'asset_statuses'
    status_code = Column(String, primary_key=True)
    description = Column(String)

# --- Core Plant Assets (Polymorphic Inheritance) ---

class PlantAsset(Base):
    __tablename__ = 'plant_assets'
    
    # Internal DB ID
    asset_id = Column(BigInteger, primary_key=True, autoincrement=True)
    
    # Clean, simple UUID for external API exchange
    uuid = Column(Uuid, default=uuid.uuid4, unique=True, index=True, nullable=False)
    
    asset_type = Column(String, nullable=False)
    
    # Foreign Key linking to our grouped metadata table above
    status_code = Column(String, ForeignKey('asset_statuses.status_code'), default='PLANNED')
    
    # Relationship to the work ledger (Needs to be updated in work.py to point to PlantAsset)
    build_activities = relationship("BuildActivity", back_populates="asset")
    
    __mapper_args__ = {
        'polymorphic_on': asset_type,
        'polymorphic_identity': 'asset'
    }

class Enclosure(PlantAsset):
    __tablename__ = 'enclosures'
    
    asset_id = Column(BigInteger, ForeignKey('plant_assets.asset_id'), primary_key=True)
    category = Column(String) 
    geom = Column(Geometry('POINT', srid=4326))

    __mapper_args__ = {
        'polymorphic_identity': 'enclosure'
    }

class CableType(Base):
    """Lookup table for cable specifications (e.g., Loose Tube, Ribbon, Armored)"""
    __tablename__ = 'cable_types'
    type_code = Column(String, primary_key=True)
    description = Column(String)
    diameter_mm = Column(Float)

class Cable(PlantAsset):
    __tablename__ = 'cables'
    
    asset_id = Column(BigInteger, ForeignKey('plant_assets.asset_id'), primary_key=True)
    fiber_count = Column(Integer)
    
    # Foreign Key linking to our grouped metadata table
    type_code = Column(String, ForeignKey('cable_types.type_code'))
    
    geom = Column(Geometry('LINESTRING', srid=4326))

    __mapper_args__ = {
        'polymorphic_identity': 'cable'
    }

class Splice(Base):
    __tablename__ = 'splices'
    
    splice_id = Column(BigInteger, primary_key=True, autoincrement=True)
    enclosure_id = Column(BigInteger, ForeignKey('enclosures.asset_id'), nullable=False)
    loss_db = Column(Float) 
    
    enclosure = relationship("Enclosure")