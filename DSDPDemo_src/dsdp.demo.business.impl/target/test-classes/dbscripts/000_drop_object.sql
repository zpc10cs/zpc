DECLARE
    --删除表
    PROCEDURE drop_table(tablename VARCHAR2) AS
        i_l_number INTEGER;
    BEGIN
        SELECT COUNT(*)
          INTO i_l_number
          FROM user_tables
         WHERE table_name = UPPER(tablename);
    
        IF i_l_number > 0 THEN
            EXECUTE IMMEDIATE 'DROP TABLE ' || tablename || ' PURGE';
        END IF;
    END drop_table;

    --删除序列
    PROCEDURE drop_sequence(sequencename VARCHAR2) AS
        i_l_number INTEGER;
    BEGIN
        SELECT COUNT(*)
          INTO i_l_number
          FROM user_sequences
         WHERE sequence_name = UPPER(sequencename);
    
        IF i_l_number > 0 THEN
            EXECUTE IMMEDIATE 'DROP SEQUENCE ' || sequencename;
        END IF;
    END drop_sequence;

--删除表、序列等
BEGIN
    drop_table('DSDPDEMO_T_ITEM');
END;
/
