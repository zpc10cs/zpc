/*
 * 文件名：IContextHolder.java
 * 版权：Copyright 2006-2010 Huawei Tech. Co. Ltd. All Rights Reserved.
 * 描述： IContextHolder.java
 * 修改人：h00140663
 * 修改时间：2010-4-20
 * 修改内容：新增
 */
package com.huawei.jaguar.commons.bootstrap.control;

import java.util.Map;

import org.springframework.context.ApplicationContext;

/**
 * 上下文接口
 *
 * <pre>
 * </pre>
 *
 * @author h00140663
 * @version BME V100R001 2010-4-20
 * @since BME V100R001C40B104
 */
public interface IContextHolder
{
    /**
     * 获得对应的bean对象。
     *
     * @param beanName
     *            bean名称。
     * @return bean实例对象。
     */
    Object getBean(String beanName);
    
    /**
     * 指定的bean是否存在
     *
     * @param beanName
     *            bean的名称
     * @return 是否存在
     */
    public boolean containsBean(String beanName);
    
    /**
     * 获得对应的服务。
     *
     * @param servicename
     *            服务名称。
     * @return 服务对象。
     */
    Object getService(String servicename);
    
    /**
     * 获得OSGi服务。
     *
     * @param servicename
     *            服务名称。
     * @return 服务对象。
     */
    Object getOsgiService(String servicename);
    
    /**
     * 根据类获得对应的bean名称列表。
     *
     * @param clazz
     *            类对象。
     * @return 对应的bean名称列表。
     */
    @SuppressWarnings("unchecked")
    String[] getBeanNamesForType(Class clazz);
    
    /**
     * 清除上下文对象。
     *
     */
    void clearCtx();
    
    /**
     * 清除指定的上下文对象。
     *
     * @param context
     *            Spring上下文对象。
     */
    void clearCtx(ApplicationContext context);
    
    /**
     * 设置Spring应用上下文。
     *
     * @param context
     *            Spring应用上下文。
     */
    public void setContext(ApplicationContext context);
    
    /**
     * 加入OSGi服务。
     *
     * @param serviceName
     *            服务名称。
     * @param service
     *            服务实例。
     */
    public void putService(String serviceName, Object service);
    
    /**
     * 设置OSGi服务注册表。
     *
     * @param osgiServices
     *            OSGi服务注册表。
     */
    public void setOsgiServices(Map<String, Object> osgiServices);
    
    /**
     * 删除OSGi服务。
     *
     * @param serviceName
     *            服务名称。
     */
    public void removeService(String serviceName);
    
    /**
     * 获得上下文对象。
     *
     */
    public ApplicationContext getContext();
    
    /**
     * 根据BeanID判断是否是单例bean。
     *
     * @param beanId
     *            beanID。
     * @return 是否是单例bean。
     */
    boolean isSingleton(String beanId);
    
    /**
     * 获得Class对应的bean实例，支持OSGi运行环境，优先获取OSGi服务，当OSGi服务不存在的时候获取bean实例。
     *
     * @see ApplicationContext#getBeansOfType(Class)
     * @param <T>
     *            class泛型。
     * @param type
     *            class类型。
     * @return beanID与bean实例的映射，如果没有找对对应的映射，返回空Map。
     */
    <T> Map<String, T> getBeansOfType(Class<T> type);
}
