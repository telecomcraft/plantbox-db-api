from sqlalchemy import create_mock_engine
# Ensure all your models are imported so they register with Base.metadata
from plantbox.database import Base
# from plantbox.models.work import Project, Phase, Build, BuildActivity
from plantbox.models.plant import PlantAsset, Enclosure, Cable # Splice

def export_ddl():
    output_file = "osp_1_0_schema.sql"
    
    with open(output_file, "w") as file:
        def dump_to_file(sql, *multiparams, **params):
            # Compile the SQL for the PostgreSQL dialect
            statement = str(sql.compile(dialect=engine.dialect)).strip()
            if statement:
                # Add a semicolon and newlines for readability
                file.write(statement + ";\n\n")

        # We use a mock postgresql engine to see the PostGIS specific types
        engine = create_mock_engine('postgresql+psycopg2://', dump_to_file)
        
        print(f"Generating DDL into {output_file}...")
        
        # This tells SQLAlchemy to generate the CREATE TABLE statements
        # checkfirst=False removes the "IF NOT EXISTS" clutter from the output
        Base.metadata.create_all(engine, checkfirst=False)
        
    print("Export complete! Open the SQL file to inspect your schema.")

if __name__ == "__main__":
    export_ddl()