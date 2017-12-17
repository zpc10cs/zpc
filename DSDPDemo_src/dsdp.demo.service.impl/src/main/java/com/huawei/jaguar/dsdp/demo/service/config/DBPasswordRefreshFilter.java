package com.huawei.jaguar.dsdp.demo.service.config;

import com.huawei.bme.commons.encryption.EncryptionFactory;
import com.huawei.jaguar.commons.sdk.configuration.proxy.ZKRefreshFilter;

public class DBPasswordRefreshFilter implements ZKRefreshFilter
{
    @SuppressWarnings("unchecked")
    @Override
    public <T> T onRefresh(String zkPath, String propertyName, T value)
    {
        if ("password".equals(propertyName))
        {
            return (T) EncryptionFactory.getEncyption().decode((String) value);
        }
        return value;
    }

    @Override
    public boolean accept(String arg0, String arg1)
    {
        return true;
    }
}