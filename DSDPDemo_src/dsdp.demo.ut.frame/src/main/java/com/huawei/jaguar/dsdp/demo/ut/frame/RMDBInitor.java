package com.huawei.jaguar.dsdp.demo.ut.frame;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;
import java.util.Arrays;
import java.util.Comparator;
import java.util.Properties;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;

public class RMDBInitor
{
    public static void initDB()
    {
        Connection con = null;
        Statement stat = null;
        InputStream inStream = null;
        try
        {
            PathMatchingResourcePatternResolver loader = new PathMatchingResourcePatternResolver(
                    RMDBInitor.class.getClassLoader());
            Resource[] db = loader.getResources("classpath*:db.properties");

            Properties props = new Properties();
            inStream = db[0].getInputStream();
            props.load(inStream);

            String sqlPattern = props.getProperty("sql_file_pattern");

            PathMatchingResourcePatternResolver resolver = new PathMatchingResourcePatternResolver(
                    RMDBInitor.class.getClassLoader());

            Resource[] sqlFiles = resolver.getResources(sqlPattern);
            Arrays.sort(sqlFiles, new ResourceComparator());

            Class.forName("org.h2.Driver");
            con = DriverManager.getConnection("jdbc:h2:~/dsdpdemo", "dsdpdemo", "dsdpdemo");
            stat = con.createStatement();

            for (Resource resource : sqlFiles)
            {
                if (resource.getFilename().startsWith("000_"))
                    continue;
                System.out.println("begin to execute [" + resource.getFile().getAbsolutePath() + "]");
                stat.execute("RUNSCRIPT FROM '" + resource.getFile().getAbsolutePath() + "'");
                System.out.println(resource.getFile().getAbsolutePath() + " execute successfully.");
            }

        }
        catch (Exception e)
        {
            throw new RuntimeException(e);
        }
        finally
        {
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

    static class ResourceComparator implements Comparator<Resource>
    {
        @Override
        public int compare(Resource o1, Resource o2)
        {
            Pattern p = Pattern.compile("[^0-9]");
            String f1 = o1.getFilename();
            String f2 = o2.getFilename();
            Matcher m1 = p.matcher(f1);
            Matcher m2 = p.matcher(f2);
            Integer i1 = Integer.valueOf(m1.replaceAll("").trim());
            Integer i2 = Integer.valueOf(m2.replaceAll("").trim());

            if (i1 == i2)
            {
                return 0;
            }
            else if (i1 < i2)
            {
                return -1;
            }
            else
            {
                return 1;
            }
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
}
