from sqlalchemy import Column, String, Integer, ForeignKey, Date, DateTime, func
from plantbox.database import Base

class Project(Base):
    __tablename__ = 'projects'
    project_id = Column(String, primary_key=True)
    name = Column(String, nullable=False)
    status = Column(String, default='PROPOSED')
    start_date = Column(Date)

class Phase(Base):
    __tablename__ = 'phases'
    phase_id = Column(String, primary_key=True)
    project_id = Column(String, ForeignKey('projects.project_id'), nullable=False)
    name = Column(String, nullable=False)
    sequence_order = Column(Integer, nullable=False)
    status = Column(String, default='PENDING') 

class Build(Base):
    __tablename__ = 'builds'
    build_id = Column(String, primary_key=True)
    phase_id = Column(String, ForeignKey('phases.phase_id'), nullable=False)
    name = Column(String, nullable=False)
    work_type = Column(String) 
    status = Column(String, default='ENGINEERING') 

# --- Specific Activity Ledgers ---

class BuildEnclosure(Base):
    __tablename__ = 'build_enclosures'
    build_id = Column(String, ForeignKey('builds.build_id'), primary_key=True)
    enclosure_id = Column(String, ForeignKey('enclosures.asset_id'), primary_key=True)
    action_type = Column(String, nullable=False)
    action_date = Column(DateTime, default=func.now())
    notes = Column(String)

class BuildCable(Base):
    __tablename__ = 'build_cables'
    build_id = Column(String, ForeignKey('builds.build_id'), primary_key=True)
    cable_id = Column(String, ForeignKey('cables.asset_id'), primary_key=True)
    action_type = Column(String, nullable=False)
    action_date = Column(DateTime, default=func.now())
    notes = Column(String)