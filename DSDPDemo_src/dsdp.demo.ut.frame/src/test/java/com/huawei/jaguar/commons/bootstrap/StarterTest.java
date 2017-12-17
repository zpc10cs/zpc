package com.huawei.jaguar.commons.bootstrap;

import static org.junit.Assert.fail;

import org.junit.Before;
import org.junit.Test;
import org.springframework.beans.BeansException;

public class StarterTest
{
    
    @Before
    public void setUp()
        throws Exception
    {
    }
    
    @Test
    public void test()
    {
        try
        {
            String startupPath = "classpath*:*.startup.xml";
            //            System.setProperty("protostuff.runtime.collection_schema_on_repeated_fields", "true");
            //            System.setProperty("protostuff.runtime.morph_non_final_pojos", "true");
            
            final Starter starter = new Starter();
            
            starter.startup(new String[] {startupPath});
            
        }
        catch (BeansException e)
        {
            fail("Not yet implemented");
        }
    }
    
}
