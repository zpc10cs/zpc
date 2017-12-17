/*
 * 文件名：ConfigItemComparator.java
 * 版权：Copyright 2006-2007 Huawei Tech. Co. Ltd. All Rights Reserved.
 * 描述： ConfigItemComparator.java
 * 修改人：m46230
 * 修改时间：2006-11-25
 * 修改内容：新增
 */
package com.huawei.jaguar.commons.bootstrap.control.config;

import java.util.Comparator;

import org.apache.commons.lang.StringUtils;

import com.huawei.bme.commons.util.ReflectionUtils;

/**
 * 配置项的比较器
 *
 */
public class ConfigItemComparator implements Comparator<ConfigItem>
{
    /**
     * 缺省索引值
     */
    private static final int DEFAULT_VALUE = -1;
    
    /**
     * 获取索引的方法名称
     */
    private String indexMethod;
    
    /**
     *
     * 构造函数
     *
     *
     * @param indexMethod
     *            索引方法，该方法必须返回一个整数值
     */
    public ConfigItemComparator(String indexMethod)
    {
        this.indexMethod = indexMethod;
        
    }
    
    /**
     * {@inheritDoc}
     */
    public int compare(ConfigItem o1, ConfigItem o2)
    {
        float i1 = getIndex(o1);
        float i2 = getIndex(o2);
        
        return (i1 < i2) ? -1 : (i1 > i2) ? 1 : 0;
    }
    
    /**
     * 返回索引
     *
     * @param item
     *            配置项
     * @return 返回索引
     */
    protected float getIndex(ConfigItem item)
    {
        Object obj = ReflectionUtils.invokeMethod(indexMethod, item, null, null);
        if ((obj != null) && (obj instanceof String))
        {
            String s = (String)obj;
            if (StringUtils.isNotEmpty(s))
            {
                return Float.valueOf((String)obj);
            }
        }
        
        return DEFAULT_VALUE;
    }
}
