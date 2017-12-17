/*
 * 文件名：ContextStateHolder.java
 * 版权：Copyright 2006-2013 Huawei Tech. Co. Ltd. All Rights Reserved.
 * 描述： ContextStateHolder.java
 * 修改人：z00219429
 * 修改时间：2013-10-12
 * 修改内容：新增
 */
package com.huawei.jaguar.commons.bootstrap.control;

import org.springframework.jmx.export.annotation.ManagedOperation;
import org.springframework.jmx.export.annotation.ManagedResource;

/**
 * Spring Context启动状态保值器。
 *
 * @author     z00219429
 * @version    ONIP BME V300R001 2013-10-12
 * @since      ONIP BME V300R001C00
 */
@ManagedResource(objectName = "bme3:type=container,management=ContextStateHolder", description = "Spring Context State (0: no initialization, 1: initializing, 2: initialized success, 3:initialized failed).")
public class ContextStateHolder
{
    /**
     * Spring Context尚未初始化。
     */
    public static final int NOT_INITIALIZED = 0;
    
    /**
     * Spring Context正在初始化。
     */
    public static final int INITIALIZING = 1;
    
    /**
     * Spring Context初始化成功。
     */
    public static final int STARTUP_SUCCESS = 2;
    
    /**
     * Spring Context初始化失败。
     */
    public static final int STARTUP_FAILED = 3;
    
    /**
     * Spring Context正在关闭。
     */
    public static final int STARTUP_STOPING = 4;
    
    /**
     * Spring Context状态。
     */
    private static int contextState = NOT_INITIALIZED;
    
    /**
     * 获取Spring Context初始化状态。
     *
     * @return Spring Context状态
     */
    @ManagedOperation(description = "Get spring context state, return value 0: no initialization, 1: initializing, 2: initialized success, 3:initialized failed.")
    public static int getContextState()
    {
        return ContextStateHolder.contextState;
    }
    
    /**
     * 设置Spring Context初始化状态。
     *
     * @param state
     *            Spring Context状态
     */
    public static void setContextState(int state)
    {
        ContextStateHolder.contextState = state;
    }
}
