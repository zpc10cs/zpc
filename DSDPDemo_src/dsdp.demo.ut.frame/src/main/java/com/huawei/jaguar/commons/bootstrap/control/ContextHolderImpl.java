/*
 * 文件名：ContextHolderImpl.java
 * 版权：Copyright 2006-2010 Huawei Tech. Co. Ltd. All Rights Reserved.
 * 描述： ContextHolderImpl.java
 * 修改人：h00140663
 * 修改时间：2010-4-21
 * 修改内容：新增
 */
package com.huawei.jaguar.commons.bootstrap.control;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.BeansException;
import org.springframework.context.ApplicationContext;

import com.huawei.bme.commons.exception.ExceptionCode;
import com.huawei.bme.commons.exception.GeneralBMEException;
import com.huawei.bme.commons.util.debug.DebugLog;
import com.huawei.bme.commons.util.debug.LogFactory;

/**
 * TODO 添加类的一句话简单描述。
 * <p>
 * TODO 详细描述
 * <p>
 * TODO 示例代码
 *
 * <pre>
 * </pre>
 *
 * @author h00140663
 * @version BME V100R001 2010-4-21
 * @since BME V100R001C40B104
 */
public class ContextHolderImpl implements IContextHolder
{
    /**
     * 调测日志记录器。
     */
    private static final DebugLog DEBUGGER = LogFactory.getDebugLog(ContextHolderImpl.class);
    
    /**
     * Spring上下文。
     */
    private ApplicationContext context = null;
    
    /**
     * OSGi服务注册表。
     */
    private Map<String, Object> osgiServices = null;
    
    public ContextHolderImpl()
    {
        
    }
    
    public ContextHolderImpl(ApplicationContext context, Map<String, Object> osgiServices)
    {
        this.context = context;
        this.osgiServices = osgiServices;
    }
    
    public void clearCtx()
    {
        context = null;
        if (null != osgiServices)
        {
            osgiServices.clear();
        }
        
    }
    
    /**
     * {@inheritDoc}
     */
    public Object getBean(String beanName)
    {
        if (getContext() != null)
        {
            try
            {
                return getContext().getBean(beanName);
            }
            catch (BeansException e)
            {
                if (DEBUGGER.isDebugEnable())
                {
                    DEBUGGER.debug("Get bean failed,bean=" + beanName);
                }
                throw new GeneralBMEException(ExceptionCode.BME_CONTAINER_GENERAL_GET_BEAN_ERR, beanName, e);
            }
        }
        else
        {
            if (DEBUGGER.isErrorEnable())
            {
                DEBUGGER.error("Application context is null,bean=" + beanName);
            }
            
            throw new GeneralBMEException(ExceptionCode.BME_CONTAINER_GENERAL_APPCONTEXT_ISNULL, beanName);
        }
    }
    
    /**
     * {@inheritDoc}
     */
    @SuppressWarnings("unchecked")
    public String[] getBeanNamesForType(Class clazz)
    {
        if (getContext() != null)
        {
            return getContext().getBeanNamesForType(clazz);
        }
        else
        {
            // 修正FindBugs发现的错误,必须返回一个空数组
            return new String[0];
        }
    }
    
    /**
     * {@inheritDoc}
     */
    public boolean containsBean(String beanName)
    {
        return null != getContext() && getContext().containsBean(beanName);
    }
    
    /**
     * {@inheritDoc}
     */
    public Object getService(String servicename)
    {
        Object object = getBean(servicename);
        if (null == object)
        {
            return getOsgiService(servicename);
        }
        return object;
    }
    
    /**
     * {@inheritDoc}
     */
    public ApplicationContext getContext()
    {
        return context;
    }
    
    /**
     * {@inheritDoc}
     */
    public Object getOsgiService(String servicename)
    {
        if (null == osgiServices)
        {
            return null;
        }
        return osgiServices.get(servicename);
    }
    
    /**
     * {@inheritDoc}
     */
    public void setContext(ApplicationContext context)
    {
        this.context = context;
    }
    
    /**
     * {@inheritDoc}
     */
    public void setOsgiServices(Map<String, Object> osgiServices)
    {
        this.osgiServices = osgiServices;
    }
    
    /**
     * {@inheritDoc}
     */
    public void clearCtx(ApplicationContext context)
    {
        context = null;
    }
    
    /**
     * {@inheritDoc}
     */
    public boolean isSingleton(String beanId)
    {
        return this.getContext().isSingleton(beanId);
    }
    
    /**
     * {@inheritDoc}
     */
    public void putService(String serviceName, Object service)
    {
        if (null != osgiServices)
        {
            osgiServices.put(serviceName, service);
        }
    }
    
    /**
     * {@inheritDoc}
     */
    public void removeService(String serviceName)
    {
        if (null != osgiServices)
        {
            osgiServices.remove(serviceName);
        }
        
    }
    
    @SuppressWarnings("unchecked")
    public <T> Map<String, T> getBeansOfType(Class<T> type)
    {
        Map<String, T> map = new HashMap<String, T>();
        Map<String, T> tMap = context.getBeansOfType(type);
        for (Map.Entry<String, T> entry : tMap.entrySet())
        {
            String key = entry.getKey();
            T value = entry.getValue();
            T service = null;
            try
            {
                // 如果强制转换失败，则不处理。
                service = (T)getOsgiService(key);
            }
            catch (Exception ex)
            {
                if (DEBUGGER.isWarnEnable())
                {
                    DEBUGGER.warn("Got the osgi sergice of bean name [" + key + "],but is not the type of "
                        + value.getClass(),
                        ex);
                }
            }
            map.put(key, service == null ? value : service);
        }
        return map;
    }
}
