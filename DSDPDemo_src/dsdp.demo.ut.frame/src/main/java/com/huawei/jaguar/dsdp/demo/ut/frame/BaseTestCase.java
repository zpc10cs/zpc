package com.huawei.jaguar.dsdp.demo.ut.frame;

import org.junit.Before;
import org.springframework.context.ApplicationContext;

public class BaseTestCase
{
    protected ApplicationContext ctx = SpringInitor.getCtx();

    @Before
    public void clearDB()
    {
        DBCleaner.cleanDB();
        RMDBInitor.initDB();
    }
}
