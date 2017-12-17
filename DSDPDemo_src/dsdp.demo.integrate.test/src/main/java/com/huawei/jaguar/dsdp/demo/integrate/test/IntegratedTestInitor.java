package com.huawei.jaguar.dsdp.demo.integrate.test;

import org.springframework.context.ApplicationContext;
import org.springframework.context.support.ClassPathXmlApplicationContext;

import com.huawei.bme.container.control.ContextRegistry;
import com.huawei.openas.dsf.DSFStartup;

public class IntegratedTestInitor
{
    private static ApplicationContext applicationContext = new ClassPathXmlApplicationContext(
            "dsdp/demo/spring/application-context.xml");

    private static boolean dsfInit = false;

    public static ApplicationContext getApplicationContext()
    {
        if (!dsfInit)
        {
            dsfInit = true;
            ContextRegistry.getContextHolder().setContext(applicationContext);
            DSFStartup.init();
            try
            {
                Thread.sleep(10000);
            }
            catch (InterruptedException e)
            {
                e.printStackTrace();
            }
        }

        return applicationContext;
    }
}
