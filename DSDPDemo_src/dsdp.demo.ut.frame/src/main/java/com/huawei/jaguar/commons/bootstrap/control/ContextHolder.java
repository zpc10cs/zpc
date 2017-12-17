/*
 * 文件名：ContextHolder.java
 * 版权：Copyright 2006-2007 Huawei Tech. Co. Ltd. All Rights Reserved.
 * 描述： 上下文的保持类
 * 修改人：m46230
 * 修改时间：Nov 10, 2006
 * 修改内容：新增
 */
package com.huawei.jaguar.commons.bootstrap.control;

import org.springframework.context.ApplicationContext;

/**
 * 上下文的保持类
 *
 * @author m46230
 * @since 1.2
 * @deprecated by h00140663
 *             在OSGi环境下容器需要管理多个Spring上下文，传统的Holder模式已经不能满足，对此已做重构，采用注册机制
 *             。
 * @see ContextRegistry
 * @see DefaultContextHolder
 */

public class ContextHolder
{
    /**
     * 获取容器的应用上下文
     *
     * @return 容器的应用上下文
     */
    public static ApplicationContext getCtx()
    {
        return ContextRegistry.getContextHolder().getContext();
    }
    
    /**
     * 根据bean名称获取bean对象
     *
     * @param beanName
     *            bean的名称
     * @return bean对象
     */
    public static Object getBean(String beanName)
    {
        return ContextRegistry.getContextHolder().getBean(beanName);
    }
    
    /**
     * 指定的bean是否存在
     *
     * @param beanName
     *            bean的名称
     * @return 是否存在
     */
    public static boolean containsBean(String beanName)
    {
        ApplicationContext ctx = ContextRegistry.getContextHolder().getContext();
        return null != ctx && ctx.containsBean(beanName);
    }
    
    /**
     * 根据service名称获取服务对象
     *
     * @param servicename
     *            服务名称
     * @return service对象
     */
    public static Object getService(String servicename)
    {
        return ContextRegistry.getContextHolder().getService(servicename);
    }
    
    /**
     * 设置应用上下文对象
     *
     * @param ctx
     *            应用上下文对象
     */
    public static void setCtx(ApplicationContext ctx)
    {
        ContextRegistry.getContextHolder().setContext(ctx);
    }
    
    /**
     * 根据类型获取Bean的名称
     *
     * @param clazz
     *            类
     * @return 指定类型的Bean的名称
     */
    @SuppressWarnings("unchecked")
    public static String[] getBeanNamesForType(Class clazz)
    {
        return ContextRegistry.getContextHolder().getBeanNamesForType(clazz);
    }
    
    /**
     * 清空应用上下文对象
     */
    public static void clearCtx()
    {
        ContextRegistry.getContextHolder().clearCtx();
    }
    
}
