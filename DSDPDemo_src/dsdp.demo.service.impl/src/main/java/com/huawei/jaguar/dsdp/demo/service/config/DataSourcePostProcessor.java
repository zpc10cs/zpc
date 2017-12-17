package com.huawei.jaguar.dsdp.demo.service.config;

import javax.sql.DataSource;

import org.apache.commons.lang.StringUtils;
import org.springframework.beans.BeansException;
import org.springframework.beans.MutablePropertyValues;
import org.springframework.beans.PropertyValue;
import org.springframework.beans.factory.BeanInitializationException;
import org.springframework.beans.factory.config.BeanDefinition;
import org.springframework.beans.factory.config.BeanFactoryPostProcessor;
import org.springframework.beans.factory.config.ConfigurableListableBeanFactory;
import org.springframework.beans.factory.config.TypedStringValue;
import org.springframework.core.Ordered;

import com.huawei.bme.commons.encryption.EncryptionFactory;
import com.huawei.bme.commons.util.ClassUtils;

public class DataSourcePostProcessor implements BeanFactoryPostProcessor, Ordered
{
    private int order = 2147483647;

    public void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory) throws BeansException
    {
        String[] beanNames = beanFactory.getBeanDefinitionNames();
        beanFactory.getBeanDefinitionNames();

        try
        {
            for (String beanName : beanNames)
            {
                BeanDefinition bd = beanFactory.getBeanDefinition(beanName);

                if (!isImplementDataSource(bd.getBeanClassName()))
                {
                    continue;
                }

                MutablePropertyValues pvs = bd.getPropertyValues();
                PropertyValue propertyValue = pvs.getPropertyValue("password");

                if (null == propertyValue)
                {
                    continue;
                }

                Object oldValue = propertyValue.getValue();
                Object source = propertyValue.getSource();
                String oldPassword = null;
                if (oldValue != null)
                {
                    TypedStringValue typedStringValue = (TypedStringValue) oldValue;
                    oldPassword = typedStringValue.getValue();
                }

                String newPassword = null;
                newPassword = EncryptionFactory.getEncyption().decode(oldPassword);

                pvs.removePropertyValue("password");

                PropertyValue newpv = new PropertyValue("password", newPassword);
                newpv.setSource(source);

                pvs.addPropertyValue(newpv);
            }
        }
        catch (Exception e)
        {
            throw new BeanInitializationException("Decrypt data source faild.", e);
        }
    }

    @SuppressWarnings("rawtypes")
    private boolean isImplementDataSource(String className)
    {
        if (StringUtils.isBlank(className))
        {
            return false;
        }

        Class clazz = null;
        try
        {
            clazz = ClassUtils.getClass(className);
        }
        catch (Exception e)
        {
            return false;
        }
        if (null == clazz)
        {
            return false;
        }

        return isImplementDataSource(clazz);
    }

    @SuppressWarnings("rawtypes")
    private boolean isImplementDataSource(Class<?> clazz)
    {
        if ((null == clazz) || (null == clazz.getInterfaces()))
        {
            return false;
        }

        while ((null != clazz) && (clazz != Object.class))
        {
            for (Class interfaces : clazz.getInterfaces())
            {
                if ((interfaces == DataSource.class) || (isImplementDataSource(interfaces)))
                {
                    return true;
                }

            }

            clazz = clazz.getSuperclass();
        }

        return false;
    }

    public void setOrder(int order)
    {
        this.order = order;
    }

    public int getOrder()
    {
        return this.order;
    }
}