package com.huawei.jaguar.dsdp.demo.integrate.test;

import org.springframework.context.ApplicationContext;

public abstract class BaseIntegrateTestCase
{
    protected ApplicationContext applicationContext = IntegratedTestInitor.getApplicationContext();
}
