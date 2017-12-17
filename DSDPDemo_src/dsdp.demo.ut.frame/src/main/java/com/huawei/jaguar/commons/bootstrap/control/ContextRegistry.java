/*
 * 文件名：ContextRegister.java
 * 版权：Copyright 2006-2010 Huawei Tech. Co. Ltd. All Rights Reserved.
 * 描述： ContextRegister.java
 * 修改人：h00140663
 * 修改时间：2010-4-21
 * 修改内容：新增
 */
package com.huawei.jaguar.commons.bootstrap.control;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 上下文的注册表
 *
 * @author h00140663
 * @version BME V100R001 2010-4-21
 * @since BME V100R001C40B104
 */
public class ContextRegistry
{
    /**
     * 为了兼容非OSGi环境。
     */
    public static final String MAIN_CONTEXT = "main_context";
    
    /**
     * 上下文保持注册表初始化大小。
     */
    private static final int INIT_SIZE = 10;
    
    /**
     * 上下文保持注册表。
     */
    private static final Map<String, IContextHolder> REGISTERMAP = new ConcurrentHashMap<String, IContextHolder>(
        INIT_SIZE);
    
    private static IContextHolder contextHolder = new DefaultContextHolder();
    
    /**
     * 获得上下文保持注册表对象。
     *
     * @return 注册表对象。
     */
    public static void setContextHolder(String bundleSymbolicName, IContextHolder contextHolder)
    {
        if (null == bundleSymbolicName)
        {
            REGISTERMAP.put(MAIN_CONTEXT, contextHolder);
            return;
        }
        REGISTERMAP.put(bundleSymbolicName, contextHolder);
    }
    
    public static void setContextHolder(IContextHolder contextHolder)
    {
        ContextRegistry.contextHolder = contextHolder;
    }
    
    public static void removeContextHolder(String bundleSymbolicName)
    {
        if (null == bundleSymbolicName)
        {
            REGISTERMAP.remove(MAIN_CONTEXT);
            return;
        }
        REGISTERMAP.remove(bundleSymbolicName);
    }
    
    public static void clear()
    {
        REGISTERMAP.clear();
        ContextRegistry.contextHolder.clearCtx();
    }
    
    /**
     * 根据指定Bundle名称，获得指定的上下文保持实例。
     *
     * @param bundleSymbolicName
     *            Bundle名称，可以为null，为null时兼容非OSGi运行环境。
     * @return 上下文保持对象。
     */
    public static IContextHolder getContextHolder(String bundleSymbolicName)
    {
        if (null == bundleSymbolicName)
        {
            return REGISTERMAP.get(MAIN_CONTEXT);
        }
        return REGISTERMAP.get(bundleSymbolicName);
    }
    
    /**
     * 返回默认的上下文保持对象。
     *
     * @return 上下文保持对象。
     */
    public static IContextHolder getContextHolder()
    {
        return ContextRegistry.contextHolder;
    }
}
