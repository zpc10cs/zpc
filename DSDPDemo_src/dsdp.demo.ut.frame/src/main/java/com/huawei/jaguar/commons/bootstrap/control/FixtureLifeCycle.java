/*
 * 文件名：FixtureLifeCycle.java
 * 版权：Copyright 2006-2007 Huawei Tech. Co. Ltd. All Rights Reserved.
 * 描述： FixtureLifeCycle.java
 * 修改人：m46230
 * 修改时间：2006-11-25
 * 修改内容：新增
 */
package com.huawei.jaguar.commons.bootstrap.control;

/**
 * 装置的生命周期接口
 *
 * @author m46230
 * @since 1.2
 */
public interface FixtureLifeCycle
{
    /**
     * 初始化上下文前的操作方法
     */
    void initBeforeContextLoad();
    
    /**
     * 初始化上下文后的操作方法
     */
    void initAfterContextLoad();
    
    /**
     * 关闭上下文前的操作方法
     */
    void destroyBeforeContextClose();
    
    /**
     * 关闭上下文后的操作方法
     */
    void destroyAfterContextClose();
}
