/*
 * 文件名：DefaultContextHolder.java
 * 版权：Copyright 2006-2010 Huawei Tech. Co. Ltd. All Rights Reserved.
 * 描述： DefaultContextHolder.java
 * 修改人：h00140663
 * 修改时间：2010-4-23
 * 修改内容：新增
 */
package com.huawei.jaguar.commons.bootstrap.control;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;

import org.springframework.beans.BeansException;
import org.springframework.beans.factory.NoSuchBeanDefinitionException;
import org.springframework.context.ApplicationContext;

import com.huawei.bme.commons.exception.ExceptionCode;
import com.huawei.bme.commons.exception.GeneralBMEException;
import com.huawei.bme.commons.util.debug.DebugLog;
import com.huawei.bme.commons.util.debug.LogFactory;

/**
 * 默认上下文保持实现，为了保证OSGi和非OSGi环境下的代码的兼容，在OSGi环境下，将所有Bundle的应用上下文统一进行缓存，在获取对应bean的时候
 * ，在每个上下文中进行查找，查到了返回。
 * <p>
 * 这种方式在特定的场景下会存在一定的问题，在OSGi环境下，Spring上下文各Bundle之间是相互隔离的，
 * 也就是说可以在不同的Bundle之间以相同的beanID定义不同的实例，但在这种实现中，如果不同的Bundle之间定义了相同的Bean
 * id有可能会获得非期望的实例。在使用该类时候，要将不同的Bundle之间不能定义相同的Bean
 * ID作为使用的一个约束。这种实现的主要目的是保证非OSGi和OSGi环境的代码统一。
 * <p>
 *
 * @author h00140663
 * @version BME V100R001 2010-4-23
 * @since BME V100R001C40B104
 */
public class DefaultContextHolder implements IContextHolder
{
    /**
     * 调测日志记录器。
     */
    private static final DebugLog DEBUGGER = LogFactory.getDebugLog(DefaultContextHolder.class);
    
    /**
     * 兼容OSGi环境下Spring上下文。将不同Bundle的Spring上下文放到列表中，当获得Bean的时候，遍历所有上下文查找指定的bean。
     * 在写少读取多的场景下，使用CopyOnWriteArrayList来提供性能。
     */
    private List<ApplicationContext> list = new CopyOnWriteArrayList<ApplicationContext>();
    
    /**
     * bean与对应的ApplicationContext实例之间的映射，避免每次get bean的时候进行循环，以提高性能。
     */
    private Map<String, ApplicationContext> beanMap = new ConcurrentHashMap<String, ApplicationContext>();
    
    /**
     * OSGi服务注册表。
     */
    private Map<String, Object> osgiServices = new ConcurrentHashMap<String, Object>();
    
    /**
     * {@inheritDoc}
     */
    public void clearCtx()
    {
        list.clear();
        beanMap.clear();
        
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
        // 优先取OSGi服务。
        Object object = this.getOsgiService(beanName);
        if (null != object)
        {
            return object;
        }
        
        return getBeanInner(beanName);
    }
    
    /**
     * {@inheritDoc}
     */
    
    public boolean containsBean(String beanName)
    {
        for (ApplicationContext context : list)
        {
            if (context.containsBean(beanName))
            {
                return true;
            }
        }
        
        return false;
    }
    
    private Object getBeanInner(String beanName)
        throws GeneralBMEException
    {
        Object bean = null;
        
        bean = getBeanApplyCache(beanName);
        if (null != bean)
        {
            return bean;
        }
        
        BeansException otherBeanException = null;
        BeansException noSuchBeanDefException = null;
        // Bean无法找到的异常。
        GeneralBMEException gex = null;
        List<ApplicationContext> illegalStateContextList = new ArrayList<ApplicationContext>();
        for (ApplicationContext context : list)
        {
            try
            {
                bean = context.getBean(beanName);
                
                if (null != bean)
                {
                    // 缓存bean id与上下文实例的映射。
                    beanMap.put(beanName, context);
                    return bean;
                }
            }
            // 如果Spring上下文已经关闭会抛该异常，以解决在OSGi环境下事件触发无序的问题。
            catch (IllegalStateException ex)
            {
                illegalStateContextList.add(context);
                continue;
            }
            catch (BeansException e)
            {
                if (!(e instanceof NoSuchBeanDefinitionException))
                {
                    otherBeanException = e;
                }
                else
                {
                    // 缓存住除bean没有定义外的其他异常。
                    noSuchBeanDefException = e;
                }
            }
        }
        
        cleanIllegalStateContext(illegalStateContextList);
        if (null != noSuchBeanDefException)
        {
            // 将bean无法找到的异常栈设置到异常实例中，方便定位Bean无法找的原因。
            gex =
                new GeneralBMEException(ExceptionCode.BME_CONTAINER_GENERAL_GET_BEAN_ERR, beanName,
                    noSuchBeanDefException);
        }
        
        if (null != otherBeanException)
        {
            // 在OSGi环境下采用轮询的方式查找Bean在大多数情况下，找不到对应的bean，
            // 所以会抛出没有bean定义的错误，但对于类似懒加载的bean，调用时候会抛出其他异常，
            // 这里应该优先抛出除bean没有定义以外的其他异常。
            gex =
                new GeneralBMEException(ExceptionCode.BME_CONTAINER_GENERAL_GET_BEAN_ERR, beanName, otherBeanException);
        }
        
        if (null == gex)
        {
            // 构造出Bean无法找到的异常实例。
            gex = new GeneralBMEException(ExceptionCode.BME_CONTAINER_GENERAL_GET_BEAN_ERR, beanName);
        }
        
        if (DEBUGGER.isDebugEnable())
        {
            DEBUGGER.debug("Get bean failed,bean=" + beanName);
        }
        throw gex;
    }
    
    /**
     * 基于cache获取bean。
     *
     * @param beanName
     *            bean名称。
     * @return bean对应的实例。
     */
    private Object getBeanApplyCache(String beanName)
    {
        ApplicationContext context = beanMap.get(beanName);
        if (null != context)
        {
            try
            {
                return context.getBean(beanName);
            }
            // 如果Spring上下文已经关闭会抛该异常，以解决在OSGi环境下事件触发无序的问题。
            catch (IllegalStateException ex)
            {
                beanMap.remove(beanName);
                if (list.contains(context))
                {
                    list.remove(context);
                }
            }
        }
        
        return null;
    }
    
    /**
     * {@inheritDoc}
     */
    @SuppressWarnings("unchecked")
    public String[] getBeanNamesForType(Class clazz)
    {
        List<String> beanNames = new ArrayList<String>();
        for (ApplicationContext context : list)
        {
            String[] args = context.getBeanNamesForType(clazz);
            if (null != args)
            {
                beanNames.addAll(Arrays.asList(args));
            }
        }
        String[] args = new String[beanNames.size()];
        return beanNames.toArray(args);
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
    public Object getService(String servicename)
    {
        return getBean(servicename);
    }
    
    public void setOsgiServices(Map<String, Object> osgiServices)
    {
        this.osgiServices = osgiServices;
    }
    
    /**
     * {@inheritDoc}
     */
    public void setContext(ApplicationContext context)
    {
        if (!list.contains(context))
        {
            list.add(context);
        }
        
        if (DEBUGGER.isDebugEnable())
        {
            DEBUGGER.debug("Add context to unite context registry successful, size :" + list.size() + ", context is :["
                + context + "]");
        }
    }
    
    /**
     * {@inheritDoc}
     */
    public void clearCtx(ApplicationContext context)
    {
        if (!list.contains(context))
        {
            return;
        }
        
        list.remove(context);
        if (DEBUGGER.isDebugEnable())
        {
            DEBUGGER.debug("Remove context from unite context registry successful, context is :[" + context
                + "], size :" + list.size());
        }
        
        Iterator<Map.Entry<String, ApplicationContext>> it = beanMap.entrySet().iterator();
        while (it.hasNext())
        {
            Map.Entry<String, ApplicationContext> entry = it.next();
            if (entry.getValue().equals(context))
            {
                it.remove();
                if (DEBUGGER.isDebugEnable())
                {
                    DEBUGGER.debug("Removed bean[" + entry.getKey() + "] from bean map.");
                }
            }
        }
    }
    
    public ApplicationContext getContext()
    {
        if (list.isEmpty())
        {
            return null;
        }
        
        if (list.size() > 1)
        {
            if (DEBUGGER.isErrorEnable())
            {
                DEBUGGER.error("Current holder has more then one context, context list size is :" + list.size());
            }
        }
        return list.get(0);
    }
    
    /**
     * {@inheritDoc}
     */
    public boolean isSingleton(String beanId)
    {
        for (ApplicationContext context : list)
        {
            try
            {
                if (null != context.getBean(beanId))
                {
                    return context.isSingleton(beanId);
                }
            }
            catch (Exception e)
            {
                // 忽略该异常。
            }
        }
        return false;
    }
    
    /**
     * {@inheritDoc}
     */
    public void putService(String serviceName, Object service)
    {
        if (null == osgiServices)
        {
            DEBUGGER.error("OSGi services map is null.");
            return;
        }
        osgiServices.put(serviceName, service);
    }
    
    /**
     * {@inheritDoc}
     */
    public void removeService(String serviceName)
    {
        if (null == osgiServices)
        {
            DEBUGGER.error("OSGi services map is null.");
            return;
        }
        osgiServices.remove(serviceName);
    }
    
    /**
     * {@inheritDoc}
     */
    @SuppressWarnings("unchecked")
    public <T> Map<String, T> getBeansOfType(Class<T> type)
    {
        Map<String, T> map = new HashMap<String, T>();
        List<ApplicationContext> illegalStateContextList = new ArrayList<ApplicationContext>();
        for (ApplicationContext context : list)
        {
            try
            {
                Map<String, T> tmap = null;
                try
                {
                    tmap = context.getBeansOfType(type);
                }
                catch (IllegalStateException ex)
                {
                    illegalStateContextList.add(context);
                    continue;
                }
                if (null != tmap && !tmap.isEmpty())
                {
                    for (Map.Entry<String, T> entry : tmap.entrySet())
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
                                DEBUGGER.warn("Gain the osgi sergice of bean name [" + key
                                    + "],but is not the type of " + value.getClass(), ex);
                            }
                        }
                        map.put(key, service == null ? value : service);
                    }
                }
            }
            catch (Exception ex)
            {
                if (DEBUGGER.isErrorEnable())
                {
                    DEBUGGER.error("Get beans of type error.", ex);
                }
            }
        }
        
        cleanIllegalStateContext(illegalStateContextList);
        
        return map;
    }
    
    /**
     * 清除已经关闭的上下文实例。
     *
     * @param illegalStateContextList
     *            待清除的上下文实例列表。
     */
    private void cleanIllegalStateContext(List<ApplicationContext> illegalStateContextList)
    {
        // 去除已经关闭的Spring上下文。
        if (!illegalStateContextList.isEmpty())
        {
            list.removeAll(illegalStateContextList);
        }
    }
}
