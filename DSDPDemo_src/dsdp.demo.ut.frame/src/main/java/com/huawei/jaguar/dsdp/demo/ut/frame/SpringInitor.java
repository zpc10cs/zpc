package com.huawei.jaguar.dsdp.demo.ut.frame;

import java.sql.SQLException;

import org.h2.tools.Server;
import org.springframework.context.ApplicationContext;
import org.springframework.context.support.ClassPathXmlApplicationContext;

public class SpringInitor
{
    private static ApplicationContext ctx = null;
    private static Server server = null;

    public static ApplicationContext getCtx()
    {
        System.setProperty("isZKenv", "0");
        initH2();
        if (ctx == null)
        {

            ctx = new ClassPathXmlApplicationContext("dsdp/demo/spring/application-context.xml");
            ((ClassPathXmlApplicationContext) ctx).registerShutdownHook();
        }
        return ctx;
    }

    public static void initH2()
    {
        if (null == server)
        {
            try
            {
                server = Server.createTcpServer().start();
                System.out.println("H2 database started successfully.");
                Runtime.getRuntime().addShutdownHook(new Thread()
                {
                    @Override
                    public void run()
                    {
                        System.out.println("Begin to stop H2.");
                        server.stop();
                    }
                });
            }
            catch (SQLException e)
            {
                throw new RuntimeException(e);
            }
        }
    }
}
