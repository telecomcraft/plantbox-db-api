DROP TRIGGER IF EXISTS table1_to_table2_test
    ON test.table_1;
CREATE TRIGGER table1_to_table2_test
    AFTER INSERT OR UPDATE ON test.table_1
    FOR EACH ROW EXECUTE PROCEDURE test.update_table2();