/*
 * 文件名：ContainerInfo.java
 * 版权：Copyright 2006-2007 Huawei Tech. Co. Ltd. All Rights Reserved.
 * 描述：  容器的启动和关闭的相关信息
 * 修改人：x60014113
 * 修改时间：Nov 28, 2006
 * 修改内容：新增
 */
package com.huawei.jaguar.commons.bootstrap.control;

import java.util.Date;

/**
 *
 * 容器的启动和关闭的相关信息,所有信息都在控制台输出
 *
 * @author x60014113
 * @since 1.2
 */
public class ContainerInfo
{
    /**
     * 容器上下文启动成功
     */
    public static final String CONTEXT_STARTSUCCESS_INFO = "[Context] Container context is initialized successful.";
    
    /**
     * 容器上下文启动失败
     */
    public static final String CONTEXT_STARTFAIL_INFO = "[Context] Container context is initialized fail.";
    
    /**
     * 开始启动容器
     */
    public static final String CONTAINER_STARTUP_INFO = "Starting business container..." + "\n";
    
    /**
     * 容器上下文关闭成功
     */
    public static final String CONTEXT_CLOSESUCCESS_INFO = "[Context] Container context is closed successful.";
    
    /**
     * 容器正在关闭
     */
    public static final String CONTAINER_SHUTDOWN_INFO = "Closing business container..." + "\n";
    
    /**
     * 启动时刻
     */
    private static Date startTime;
    
    /**
     * 容器启动成功
     *
     * @return 容器启动成功信息
     */
    public static String containerStartSuccess()
    {
        StringBuffer bf = new StringBuffer();
        bf.append("*******************************************************" + "\n");
        bf.append("*                                                     *" + "\n");
        bf.append("*     Business container is started successfully!     *" + "\n");
        bf.append("*                                                     *" + "\n");
        bf.append("*******************************************************" + "\n");
        return bf.toString();
    }
    
    /**
     * 容器关闭成功
     *
     * @return 容器关闭成功信息
     */
    public static String containerShutDownSuccess()
    {
        StringBuffer bf = new StringBuffer();
        bf.append("*******************************************************" + "\n");
        bf.append("*                                                     *" + "\n");
        bf.append("*    Business container is closed successfully!       *" + "\n");
        bf.append("*                                                     *" + "\n");
        bf.append("*******************************************************" + "\n");
        return bf.toString();
    }
    
    /**
     * 获得开始时间
     *
     * @return 开始时间
     */
    public static Date getStartTime()
    {
        Date tempDate = startTime;
        
        return tempDate;
    }
    
    /**
     * 设置开始时间
     *
     * @param startTime 开始时间
     */
    public static void setStartTime(Date startTime)
    {
        Date tempDate = startTime;
        ContainerInfo.startTime = tempDate;
    }
}
