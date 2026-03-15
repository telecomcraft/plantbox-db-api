from sqlalchemy import create_engine
from sqlalchemy.schema import CreateTable
from plantbox.database import Base

# This single import loads everything in the correct order
import plantbox.models 

def export_ddl():
    output_file = "osp_1_0_gpkg_schema.sql"
    
    # We use a standard SQLite engine just to provide the dialect rules.
    # We won't actually connect to it or create a file.
    engine = create_engine('gpkg:///')
    
    print(f"Generating SpatiaLite DDL into {output_file}...")
    
    with open(output_file, "w") as file:
        # sorted_tables guarantees parent tables are created before child tables
        for table in Base.metadata.sorted_tables:
            # Compile the specific CREATE TABLE statement for this dialect
            statement = CreateTable(table).compile(engine)
            file.write(str(statement).strip() + ";\n\n")
            
    print("Export complete! Open the SQL file to inspect your SpatiaLite schema.")

if __name__ == "__main__":
    export_ddl()