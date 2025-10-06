CREATE OR REPLACE FUNCTION test.update_table2() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO test.table_2 (id, test_id)
    VALUES (nextval('test.table_2_id_seq'::regclass), NEW.id);

    RETURN NEW;
END;
$$ language plpgsql;