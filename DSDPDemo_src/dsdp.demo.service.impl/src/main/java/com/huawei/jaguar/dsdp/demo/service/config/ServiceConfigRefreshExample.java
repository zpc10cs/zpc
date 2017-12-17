package com.huawei.jaguar.dsdp.demo.service.config;

import com.huawei.bme.commons.util.debug.DebugLog;
import com.huawei.bme.commons.util.debug.LogFactory;

public class ServiceConfigRefreshExample
{
    private static final DebugLog SYSTEM_LOG = LogFactory.getDebugLog("DSDPDEMO_SYSTEM_LOG");

    private String value;

    public void setValue(String value)
    {
        SYSTEM_LOG.info("Before setValue called, value: " + this.value);
        this.value = value;
        SYSTEM_LOG.info("After setValue called, value: " + this.value);
    }
}
