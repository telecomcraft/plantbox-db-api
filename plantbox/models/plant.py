from sqlalchemy import Column, String, Integer, Float, ForeignKey, DateTime, func
from sqlalchemy.orm import relationship
from geoalchemy2 import Geometry
from plantbox.database import Base

# 1. The Generic Ledger (Only one needed now!)
# class BuildActivity(Base):
#     __tablename__ = 'build_activities'
    
#     build_id = Column(String, ForeignKey('builds.build_id'), primary_key=True)
#     asset_id = Column(String, ForeignKey('plant_assets.asset_id'), primary_key=True)
    
#     action_type = Column(String, nullable=False) # INSTALL, SPLICING
#     action_date = Column(DateTime, default=func.now())
    
#     build = relationship("Build", back_populates="activities")
#     asset = relationship("PlantAsset", back_populates="build_activities")

# 2. The Base Asset Table
class PlantAsset(Base):
    __tablename__ = 'plant_assets'
    asset_id = Column(String, primary_key=True)
    asset_type = Column(String, nullable=False) # 'cable', 'enclosure', etc.
    status = Column(String, default='PLANNED')
    
    # The Ledger Relationship lives here, available to all children
    build_activities = relationship("BuildActivity", back_populates="asset")
    
    # SQLAlchemy configuration for inheritance
    __mapper_args__ = {
        'polymorphic_on': asset_type,
        'polymorphic_identity': 'asset'
    }

# 3. The Specific Child Tables
class Enclosure(PlantAsset):
    __tablename__ = 'enclosures'
    # The PK is also a FK to the parent table
    asset_id = Column(String, ForeignKey('plant_assets.asset_id'), primary_key=True)
    category = Column(String) 
    geom = Column(Geometry('POINT', srid=4326))

    __mapper_args__ = {
        'polymorphic_identity': 'enclosure'
    }

class Cable(PlantAsset):
    __tablename__ = 'cables'
    asset_id = Column(String, ForeignKey('plant_assets.asset_id'), primary_key=True)
    fiber_count = Column(Integer)
    geom = Column(Geometry('LINESTRING', srid=4326))

    __mapper_args__ = {
        'polymorphic_identity': 'cable'
    }

# class Splice(PlantAsset):
#     __tablename__ = 'splices'
#     splice_id = Column(String, primary_key=True)
#     enclosure_id = Column(String, ForeignKey('enclosures.asset_id'), nullable=False)
#     loss_db = Column(Float) 
    
#     enclosure = relationship("Enclosure", back_populates="splices")