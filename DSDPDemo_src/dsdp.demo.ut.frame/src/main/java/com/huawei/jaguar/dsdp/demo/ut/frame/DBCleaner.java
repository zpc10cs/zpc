package com.huawei.jaguar.dsdp.demo.ut.frame;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.Properties;

import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;

public class DBCleaner
{
    public static void delAllData()
    {
        Connection con = null;
        Statement stat = null;
        ResultSet rs = null;
        ResultSet rsOther = null;
        InputStream inStream = null;
        try
        {
            PathMatchingResourcePatternResolver loader = new PathMatchingResourcePatternResolver(
                    DBCleaner.class.getClassLoader());
            Resource[] db = loader.getResources("classpath*:db.properties");

            Properties props = new Properties();
            inStream = db[0].getInputStream();
            props.load(inStream);

            String tblPattern = props.getProperty("tbl_pattern");
            String tblPatternOther = props.getProperty("tbl_pattern_other");

            Class.forName("org.h2.Driver");
            con = DriverManager.getConnection("jdbc:h2:~/dsdpdemo", "dsdpdemo", "dsdpdemo");
            stat = con.createStatement();
            rs = con.getMetaData().getTables(null, null, tblPattern, null);
            while (rs.next())
            {
                String tblName = rs.getString("TABLE_NAME");
                System.out.println("delete all data of table [" + tblName + "].");
                stat.execute("delete from " + tblName);
            }

            rsOther = con.getMetaData().getTables(null, null, tblPatternOther, null);
            while (rsOther.next())
            {
                String tblName = rsOther.getString("TABLE_NAME");
                System.out.println("delete all data of table [" + tblName + "].");
                stat.execute("delete from " + tblName);
            }
        }
        catch (Exception e)
        {
            throw new RuntimeException(e);
        }
        finally
        {
            closeQuietly(rs);
            closeQuietly(stat);
            closeQuietly(con);
            closeQuietly(inStream);
        }
    }

    private static void closeQuietly(InputStream inStream)
    {
        if (null != inStream)
        {
            try
            {
                inStream.close();
            }
            catch (Exception ignore)
            {

            }
        }
    }

    public static void cleanDB()
    {
        Connection con = null;
        Statement stat = null;
        ResultSet rs = null;
        ResultSet rsOther = null;
        ResultSet rsSeq = null;
        InputStream inStream = null;
        try
        {
            PathMatchingResourcePatternResolver loader = new PathMatchingResourcePatternResolver(
                    DBCleaner.class.getClassLoader());
            Resource[] db = loader.getResources("classpath*:db.properties");

            Properties props = new Properties();
            inStream = db[0].getInputStream();
            props.load(inStream);

            String tblPattern = props.getProperty("tbl_pattern");
            String seqPattern = props.getProperty("seq_pattern");
            String tblPatternOther = props.getProperty("tbl_pattern_other");

            Class.forName("org.h2.Driver");
            con = DriverManager.getConnection("jdbc:h2:~/dsdpdemo", "dsdpdemo", "dsdpdemo");
            stat = con.createStatement();
            rs = con.getMetaData().getTables(null, null, tblPattern, null);
            while (rs.next())
            {
                String tblName = rs.getString("TABLE_NAME");
                System.out.println("drop table [" + tblName + "].");
                stat.execute("drop table " + tblName);
            }

            rsOther = con.getMetaData().getTables(null, null, tblPatternOther, null);
            while (rsOther.next())
            {
                String tblName = rsOther.getString("TABLE_NAME");
                System.out.println("drop table [" + tblName + "].");
                stat.execute("drop table " + tblName);
            }

            rsSeq = stat
                    .executeQuery("select SEQUENCE_NAME from INFORMATION_SCHEMA.SEQUENCES where sequence_name like '"
                            + seqPattern + "'");
            while (rsSeq.next())
            {
                String tblName = rsSeq.getString("SEQUENCE_NAME");
                System.out.println("drop sequence [" + tblName + "].");
                stat.execute("drop sequence " + tblName);
            }
        }
        catch (Exception e)
        {
            throw new RuntimeException(e);
        }
        finally
        {
            closeQuietly(rs);
            closeQuietly(rsOther);
            closeQuietly(rsSeq);
            closeQuietly(stat);
            closeQuietly(con);
            closeQuietly(inStream);
        }
    }

    private static void closeQuietly(Connection con)
    {
        if (null != con)
        {
            try
            {
                con.close();
            }
            catch (Exception ignore)
            {
                throw new RuntimeException(ignore);
            }
        }
    }

    private static void closeQuietly(Statement stat)
    {
        if (null != stat)
        {
            try
            {
                stat.close();
            }
            catch (Exception ignore)
            {
                throw new RuntimeException(ignore);
            }
        }
    }

    private static void closeQuietly(ResultSet rs)
    {
        if (null != rs)
        {
            try
            {
                rs.close();
            }
            catch (Exception ignore)
            {
                throw new RuntimeException(ignore);
            }
        }
    }
}
