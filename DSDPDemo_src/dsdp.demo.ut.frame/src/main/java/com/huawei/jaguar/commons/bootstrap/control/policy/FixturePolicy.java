/*
 * 文件名：FixturePolicy.java
 * 版权：Copyright 2006-2007 Huawei Tech. Co. Ltd. All Rights Reserved.
 * 描述： FixturePolicy.java
 * 修改人：m46230
 * 修改时间：2006-11-25
 * 修改内容：新增
 */
package com.huawei.jaguar.commons.bootstrap.control.policy;

/**
 * 装置策略接口
 *
 * @author m46230
 * @since 1.2
 *
 */
public interface FixturePolicy
{
    
    /**
     *
     * 应用上下文启动前的操作
     */
    void doBeforeContextLoad();
    
    /**
     *
     * 应用上下文启动后的操作
     */
    void doAfterContextLoad();
    
    /**
     * 应用上下文关闭前的操作
     *
     */
    void doBeforeContextClose();
    
    /**
     *
     * 应用上下文关闭后的操作
     */
    void doAfterContextClose();
}
