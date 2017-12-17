/*
 * 文件名：ContainerStartUp.java
 * 版权：Copyright 2006-2007 Huawei Tech. Co. Ltd. All Rights Reserved.
 * 描述： 容器独立启动和关闭的入口类,实现容器的启动和关闭功能
 * 修改人：x60014113
 * 修改时间：Nov 10, 2006
 * 修改内容：新增
 */
package com.huawei.jaguar.commons.bootstrap.control;

import com.huawei.jaguar.commons.bootstrap.control.policy.FixturePolicy;
import com.huawei.jaguar.commons.bootstrap.control.policy.SimpleFixturePolicy;

/**
 * 容器独立启动和关闭的入口类
 *
 * @author x60014113
 * @since 1.2
 */
public class ContainerControl implements FixturePolicy
{
    /**
     * 装置策略
     */
    private FixturePolicy fixturePolicy;
    
    /**
     * 构造函数
     *
     * @param fixturePolicy
     *            装置策略
     */
    public ContainerControl(FixturePolicy fixturePolicy)
    {
        this.fixturePolicy = fixturePolicy == null ? new SimpleFixturePolicy() : fixturePolicy;
    }
    
    /**
     * {@inheritDoc}
     */
    public void doAfterContextClose()
    {
        this.fixturePolicy.doAfterContextClose();
    }
    
    /**
     * {@inheritDoc}
     */
    public void doAfterContextLoad()
    {
        this.fixturePolicy.doAfterContextLoad();
    }
    
    /**
     * {@inheritDoc}
     */
    public void doBeforeContextClose()
    {
        this.fixturePolicy.doBeforeContextClose();
    }
    
    /**
     * {@inheritDoc}
     */
    public void doBeforeContextLoad()
    {
        this.fixturePolicy.doBeforeContextLoad();
    }
    
    /**
     * 主动调用静默状态的装置器。
     *
     */
    public void startSilentFixture()
    {
        ((SimpleFixturePolicy)this.fixturePolicy).startSilentFixture();
    }
}
