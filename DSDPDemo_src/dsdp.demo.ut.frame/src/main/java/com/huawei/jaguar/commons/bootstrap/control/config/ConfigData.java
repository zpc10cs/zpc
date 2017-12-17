/*
 * 文件名：ConfigData.java
 * 版权：Copyright 2006-2007 Huawei Tech. Co. Ltd. All Rights Reserved.
 * 描述： ConfigData.java
 * 修改人：m46230
 * 修改时间：2006-11-25
 * 修改内容：新增
 */
package com.huawei.jaguar.commons.bootstrap.control.config;

import java.util.Arrays;
import java.util.LinkedList;
import java.util.List;

import org.apache.commons.lang.ArrayUtils;

/**
 * 容器装置的配置数据
 *
 * @author m46230
 * @since 1.2
 *
 */
public class ConfigData
{
    
    /**
     * 所有的配置项
     */
    private List<ConfigItem> configItems;
    
    /**
     *
     * 构造函数
     */
    public ConfigData()
    {
        configItems = new LinkedList<ConfigItem>();
        
    }
    
    /**
     *
     * 构造函数
     *
     * @param items
     *            配置项
     */
    public ConfigData(final List<ConfigItem> items)
    {
        configItems = Arrays.asList((ConfigItem[])ArrayUtils.clone(items.toArray(new ConfigItem[items.size()])));
        
    }
    
    /**
     * 取得configItems *
     *
     * @return 返回 configItems。
     *
     */
    public List<ConfigItem> getConfigItems()
    {
        return configItems;
    }
    
    /**
     *
     * 增加配置项
     *
     * @param item
     *            配置项
     */
    public void addConfigItem(ConfigItem item)
    {
        this.configItems.add(item);
        
    }
    
}
