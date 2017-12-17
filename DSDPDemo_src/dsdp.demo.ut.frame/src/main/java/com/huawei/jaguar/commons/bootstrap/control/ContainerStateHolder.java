/*
 * 文件名：ContainerStateHolder.java
 * 版权：Copyright 2006-2009 Huawei Tech. Co. Ltd. All Rights Reserved.
 * 描述： ContainerStateHolder.java
 * 修改人：z68187
 * 修改时间：2009-7-3
 * 修改内容：新增
 */
package com.huawei.jaguar.commons.bootstrap.control;

/**
 * 容器启动状态保值器。
 *
 * @author z68187
 * @version BME V100R001 2009-7-3
 * @since BME V100R001C04B105
 */
public class ContainerStateHolder
{
    /**
     * 容器尚未初始化。
     */
    public static final int NOT_INITIALIZED = 0;
    
    /**
     * 正在初始化容器。
     */
    public static final int INITIALIZING = 1;
    
    /**
     * 容器启动成功。
     */
    public static final int STARTUP_SUCCESS = 2;
    
    /**
     * 容器启动失败。
     */
    public static final int STARTUP_FAILED = 3;
    
    private static int containerState = NOT_INITIALIZED;
    
    /**
     * 获取容器启动状态。
     *
     * @return 容器状态
     */
    public static int getContainerState()
    {
        return ContainerStateHolder.containerState;
    }
    
    /**
     * 设置容器启动状态。
     *
     * @param state
     *            容器状态
     */
    public static void setContainerState(int state)
    {
        ContainerStateHolder.containerState = state;
    }
}
