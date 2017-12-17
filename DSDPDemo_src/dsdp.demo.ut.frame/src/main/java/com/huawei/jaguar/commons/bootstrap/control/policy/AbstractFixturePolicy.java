/*
 * 文件名：AbstractFixturePolicy.java
 * 版权：Copyright 2006-2007 Huawei Tech. Co. Ltd. All Rights Reserved.
 * 描述： 抽象的装置策略类
 * 修改人：m46230
 * 修改时间：2006-11-25
 * 修改内容：新增
 */
package com.huawei.jaguar.commons.bootstrap.control.policy;

import java.util.Collections;
import java.util.Comparator;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;

import com.huawei.bme.commons.util.debug.DebugLog;
import com.huawei.bme.commons.util.debug.LogFactory;
import com.huawei.bme.container.silent.SilentStatusControl;
import com.huawei.jaguar.commons.bootstrap.control.config.ConfigData;
import com.huawei.jaguar.commons.bootstrap.control.config.ConfigItem;
import com.huawei.jaguar.commons.bootstrap.control.config.ConfigItemComparator;
import com.huawei.jaguar.commons.bootstrap.control.config.ConfigReader;

/**
 * 抽象的装置策略.
 * 
 * @author m46230
 * @since 1.2
 */
public abstract class AbstractFixturePolicy implements FixturePolicy
{
    
    /** 配置数据. */
    protected ConfigData configData;
    
    /** 载入前列表. */
    protected List<ConfigItem> beforeLoadList;
    
    /** 载入后列表. */
    protected List<ConfigItem> afterLoadList;
    
    /** 关闭前列表. */
    protected List<ConfigItem> beforeCloseList;
    
    /** 关闭后列表. */
    protected List<ConfigItem> afterCloseList;
    
    /** 日志对象. */
    private static final DebugLog DEBUGGER = LogFactory.getDebugLog(AbstractFixturePolicy.class);
    
    /**
     * 构造函数.
     */
    public AbstractFixturePolicy()
    {
        this.configData = ConfigReader.getInitConfigData();
        initLists();
    }
    
    /**
     * 构造函数.
     * 
     * @param config 配置数据
     */
    public AbstractFixturePolicy(ConfigData config)
    {
        this.configData = config;
        initLists();
    }
    
    /**
     * 按照比较器排序.
     * 
     * @param comparator 比较器
     * @param checker 检查器
     * @return 排完序的列表
     */
    @SuppressWarnings("unchecked")
    private List<ConfigItem> sortList(Comparator comparator, ItemChecker checker)
    {
        List<ConfigItem> resultList = new LinkedList<ConfigItem>();
        ConfigItem item = null;
        for (Iterator<ConfigItem> iter = this.configData.getConfigItems().iterator(); iter.hasNext();)
        {
            item = iter.next();
            if (checker.canAdd2List(item))
            {
                resultList.add(item);
            }
        }
        Collections.sort(resultList, comparator);
        return resultList;
    }
    
    /**
     * 初始化各个处理列表.
     */
    private void initLists()
    {
        beforeLoadList = sortList(new ConfigItemComparator("getBiIndex"), new CommonItemChecker("getBeforeInitMethod"));
        afterLoadList = sortList(new ConfigItemComparator("getAiIndex"), new CommonItemChecker("getAfterInitMethod"));
        beforeCloseList =
            sortList(new ConfigItemComparator("getBdIndex"), new CommonItemChecker("getBeforeDestroyMethod"));
        afterCloseList =
            sortList(new ConfigItemComparator("getAdIndex"), new CommonItemChecker("getAfterDestroyMethod"));
    }
    
    /**
     * Do after context close.
     * 
     * {@inheritDoc}
     */
    public void doAfterContextClose()
    {
        for (ConfigItem configItem : afterCloseList)
        {
            // 静默状态且装置有静默状态配置时
            if (configItem.isSilent())
            {
                System.out.println("Since the vlaue of 'silentStatus' is true and the fixture[" + configItem.getKey()
                    + "]'s silent vlaue is true, the fixture[" + configItem.getKey()
                    + "] didn't start.So the fixture doesn't need to be closed.");
                continue;
            }
            
            try
            {
                doProcessAfterClose(configItem);
            }
            catch (Exception e)
            {
                if (DEBUGGER.isErrorEnable())
                {
                    DEBUGGER.error("There are some problems after closing fixture.", e);
                }
            }
        }
    }
    
    /**
     * 容器关闭后的操作。.
     * 
     * @param item 配置项
     */
    protected abstract void doProcessAfterClose(ConfigItem item);
    
    /**
     * 容器关闭前的操作。.
     * 
     * @param item 配置项
     */
    protected abstract void doProcessBeforeClose(ConfigItem item);
    
    /**
     * Do after context load.
     * 
     * {@inheritDoc}
     */
    public void doAfterContextLoad()
    {
        for (ConfigItem configItem : afterLoadList)
        {
            // 静默状态且装置有静默状态配置时
            if (configItem.isSilent())
            {
                System.out.println("[Fixture]" + configItem.getKey()
                    + " doesn't start because both the system and the fixture is in the silent status.");
                continue;
            }
            
            try
            {
                doProcessAfterLoad(configItem);
            }
            catch (Exception e)
            {
                if (DEBUGGER.isErrorEnable())
                {
                    DEBUGGER.error("There are some problems after load fixture.", e);
                }
                
                throw new RuntimeException(e);
            }
        }
    }
    
    /**
     * 容器加载后的操作。.
     * 
     * @param item 配置项
     */
    protected abstract void doProcessAfterLoad(ConfigItem item);
    
    /**
     * Do before context close.
     * 
     * {@inheritDoc}
     */
    public void doBeforeContextClose()
    {
        for (ConfigItem configItem : beforeCloseList)
        {
            // 静默状态且装置有静默状态配置时
            //if (SilentStatusControl.getInstance().isSilentStatus() && configItem.isSilent())
            if (configItem.isSilent())
            {
                System.out.println("[Fixture]" + configItem.getKey() + " needn't to be closed because it didn't start.");
                continue;
            }
            
            try
            {
                doProcessBeforeClose(configItem);
            }
            catch (Exception e)
            {
                if (DEBUGGER.isErrorEnable())
                {
                    DEBUGGER.error("There are some problems before closing fixture.", e);
                }
            }
        }
    }
    
    /**
     * Do before context load.
     * 
     * {@inheritDoc}
     */
    public void doBeforeContextLoad()
    {
        for (ConfigItem configItem : beforeLoadList)
        {
            // 静默状态且装置有静默状态配置时
            if (configItem.isSilent())
            {
                System.out.println("[Fixture]" + configItem.getKey()
                    + " doesn't start because both the system and the fixture is in the silent status.");
                continue;
            }
            
            try
            {
                doProcessBeforeLoad(configItem);
            }
            catch (Exception e)
            {
                if (DEBUGGER.isErrorEnable())
                {
                    DEBUGGER.error("There are some problems before load fixture.", e);
                }
                
                throw new RuntimeException(e);
            }
        }
    }
    
    /**
     * 主动调用静默状态的装置器。.
     */
    public void startSilentFixture()
    {
        if (SilentStatusControl.getInstance().isSilentStatus())
        {
            System.out.println("The system is in silent status.");
            return;
        }
        
        System.out.println("Since the system has been changed to normal status, the silent fixture will be started.");
        
        for (Iterator<ConfigItem> iter = beforeLoadList.iterator(); iter.hasNext();)
        {
            ConfigItem configItem = iter.next();
            
            // 非静默状态且装置的配置为静默状态配置时,主动拉起装置
            if (configItem.isSilent())
            {
                doProcessBeforeLoad(configItem);
            }
        }
        for (Iterator<ConfigItem> iter = afterLoadList.iterator(); iter.hasNext();)
        {
            ConfigItem configItem = iter.next();
            
            // 非静默状态且装置的配置为静默状态配置时,主动拉起装置
            if (configItem.isSilent())
            {
                doProcessAfterLoad(configItem);
            }
        }
    }
    
    /**
     * 容器加载前的操作。.
     * 
     * @param item 配置项
     */
    protected abstract void doProcessBeforeLoad(ConfigItem item);
}
