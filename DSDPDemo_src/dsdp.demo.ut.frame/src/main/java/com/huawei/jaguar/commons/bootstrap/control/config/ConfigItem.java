/*
 * 文件名：ConfigItem.java
 * 版权：Copyright 2006-2007 Huawei Tech. Co. Ltd. All Rights Reserved.
 * 描述： ConfigItem.java
 * 修改人：m46230
 * 修改时间：2006-11-25
 * 修改内容：新增
 */
package com.huawei.jaguar.commons.bootstrap.control.config;

import org.apache.commons.lang.StringUtils;

import com.huawei.bme.commons.util.Assert;

/**
 * 对应每个配置项的数据结构
 *
 * @author m46230
 * @since 1.2
 */
public class ConfigItem
{
    /**
     *
     * 配置项的类型枚举
     */
    public enum ItemType
    {
        /**
         * 实例方式
         */
        instance,
        
        /**
         * 工厂方式
         */
        factory,
        
        /**
         * 工厂实例方式
         */
        factoryInstance,
    };
    
    /**
     * 缺省的初始化上下文前的操作方法
     */
    public static final String DEFAULT_BEFORE_INIT_METHOD = "initBeforeContextLoad";
    
    /**
     * 缺省的初始化上下文后的操作方法
     */
    public static final String DEFAULT_AFTER_INIT_METHOD = "initAfterContextLoad";
    
    /**
     * 缺省的关闭上下文前的操作方法
     */
    public static final String DEFAULT_BEFORE_DESTROY_METHOD = "destroyBeforeContextClose";
    
    /**
     * 缺省的关闭上下文后的操作方法
     */
    public static final String DEFAULT_AFTER_DESTROY_METHOD = "destroyAfterContextClose";
    
    /**
     * 缺省的配置项类型
     */
    public static final String DEFAULT_ITEM_TYPE = ItemType.instance.toString();
    
    /**
     * 缺省的索引值
     */
    public static final String DEFAULT_INDEX = String.valueOf(Integer.MAX_VALUE);
    
    /**
     * 关掉标签
     */
    public static final String SHUTDOWN_TAG = "Stopping ";
    
    /**
     * 停止标签
     */
    public static final String STOPPED_TAG = " stopped ";
    
    /**
     * 开始标签
     */
    public static final String START_UP_TAG = "Starting ";
    
    /**
     * 已开始标签
     */
    public static final String STARTED_TAG = " started ";
    
    /**
     * 初时化上下文之前
     */
    public static final String BEFORE_CONTEXT_INIT = " before context start.";
    
    /**
     * 初时化上下文之后
     */
    public static final String AFTER_CONTEXT_INIT = " after context started.";
    
    /**
     * 上下文毁掉前
     */
    public static final String BEFORE_CONTEXT_DESTROY = " before context close.";
    
    /**
     * 上下文毁掉后
     */
    public static final String AFTER_CONTEXT_DESTROY = " after context closed.";
    
    /**
     * 头
     */
    public static final String HEADER = "[Fixture]";
    
    /**
     * 分割符
     */
    public static final char PAD_CHAR = '.';
    
    /**
     * cost
     */
    public static final String COST = "[cost ";
    
    /**
     * cost结束
     */
    public static final String COST_SUFIX = "ms]";
    
    /**
     * 初始化上下文前的操作方法
     */
    private String beforeInitMethod;
    
    /**
     * 初始化上下文后的操作方法
     */
    private String afterInitMethod;
    
    /**
     * 关闭上下文前的操作方法
     */
    private String beforeDestroyMethod;
    
    /**
     * 关闭上下文后的操作方法
     */
    private String afterDestroyMethod;
    
    /**
     * 工厂方法名称
     */
    private String factoryMethod;
    
    /**
     * 配置项的统一索引
     */
    private String index;
    
    /**
     * 配置项的键值
     */
    private String key;
    
    /**
     * 初始前索引
     */
    private String biIndex;
    
    /**
     * 初始后索引
     */
    private String aiIndex;
    
    /**
     * 关闭前索引
     */
    private String bdIndex;
    
    /**
     * 关闭后索引
     */
    private String adIndex;
    
    /**
     * 启动类名称
     */
    private String className;
    
    /**
     * 配置类型
     *
     * @see ConfigItem.ItemType
     *
     */
    private String type;
    
    /**
     * 启动描述信息
     */
    private String desc;
    
    /**
     * 该启动项是否允许抛出异常。
     */
    private boolean throwException = true;
    
    /**
     * 静默启动配置项
     */
    private boolean silent = false;
    
    public String getDesc()
    {
        return desc;
    }
    
    public void setDesc(String desc)
    {
        this.desc = desc;
    }
    
    /**
     * 取得afterDestroyMethod *
     *
     * @return 返回 afterDestroyMethod。
     *
     */
    public String getAfterDestroyMethod()
    {
        return afterDestroyMethod;
    }
    
    /**
     * 设置afterDestroyMethod
     *
     * @param afterDestroyMethod
     *            要设置的 afterDestroyMethod。
     *
     */
    public void setAfterDestroyMethod(String afterDestroyMethod)
    {
        this.afterDestroyMethod = afterDestroyMethod;
    }
    
    /**
     * 取得afterInitMethod *
     *
     * @return 返回 afterInitMethod。
     *
     */
    public String getAfterInitMethod()
    {
        return afterInitMethod;
    }
    
    /**
     * 设置afterInitMethod
     *
     * @param afterInitMethod
     *            要设置的 afterInitMethod。
     *
     */
    public void setAfterInitMethod(String afterInitMethod)
    {
        this.afterInitMethod = afterInitMethod;
    }
    
    /**
     * 取得beforeDestroyMethod *
     *
     * @return 返回 beforeDestroyMethod。
     *
     */
    public String getBeforeDestroyMethod()
    {
        return beforeDestroyMethod;
    }
    
    /**
     * 设置beforeDestroyMethod
     *
     * @param beforeDestroyMethod
     *            要设置的 beforeDestroyMethod。
     *
     */
    public void setBeforeDestroyMethod(String beforeDestroyMethod)
    {
        this.beforeDestroyMethod = beforeDestroyMethod;
    }
    
    /**
     * 取得beforeInitMethod *
     *
     * @return 返回 beforeInitMethod。
     *
     */
    public String getBeforeInitMethod()
    {
        return beforeInitMethod;
    }
    
    /**
     * 设置beforeInitMethod
     *
     * @param beforeInitMethod
     *            要设置的 beforeInitMethod。
     *
     */
    public void setBeforeInitMethod(String beforeInitMethod)
    {
        this.beforeInitMethod = beforeInitMethod;
    }
    
    /**
     * 取得adIndex *
     *
     * @return 返回 adIndex。
     *
     */
    public String getAdIndex()
    {
        return StringUtils.isEmpty(adIndex) ? ((StringUtils.isEmpty(getIndex()) ? DEFAULT_INDEX : getIndex()))
            : adIndex;
    }
    
    /**
     * 设置adIndex
     *
     * @param adIndex
     *            要设置的 adIndex。
     *
     */
    public void setAdIndex(String adIndex)
    {
        this.adIndex = adIndex;
    }
    
    /**
     * 取得aiIndex *
     *
     * @return 返回 aiIndex。
     *
     */
    public String getAiIndex()
    {
        return StringUtils.isEmpty(aiIndex) ? ((StringUtils.isEmpty(getIndex()) ? DEFAULT_INDEX : getIndex()))
            : aiIndex;
    }
    
    /**
     * 设置aiIndex
     *
     * @param aiIndex
     *            要设置的 aiIndex。
     *
     */
    public void setAiIndex(String aiIndex)
    {
        this.aiIndex = aiIndex;
    }
    
    /**
     * 取得bdIndex *
     *
     * @return 返回 bdIndex。
     *
     */
    public String getBdIndex()
    {
        return StringUtils.isEmpty(bdIndex) ? ((StringUtils.isEmpty(getIndex()) ? DEFAULT_INDEX : getIndex()))
            : bdIndex;
    }
    
    /**
     * 设置bdIndex
     *
     * @param bdIndex
     *            要设置的 bdIndex。
     *
     */
    public void setBdIndex(String bdIndex)
    {
        this.bdIndex = bdIndex;
    }
    
    /**
     * 取得biIndex *
     *
     * @return 返回 biIndex。
     *
     */
    public String getBiIndex()
    {
        return StringUtils.isEmpty(biIndex) ? ((StringUtils.isEmpty(getIndex()) ? DEFAULT_INDEX : getIndex()))
            : biIndex;
    }
    
    /**
     * 设置biIndex
     *
     * @param biIndex
     *            要设置的 biIndex。
     *
     */
    public void setBiIndex(String biIndex)
    {
        this.biIndex = biIndex;
    }
    
    /**
     * 取得index *
     *
     * @return 返回 index。
     *
     */
    public String getIndex()
    {
        return StringUtils.isEmpty(index) ? DEFAULT_INDEX : index;
    }
    
    /**
     * 设置index
     *
     * @param index
     *            要设置的 index。
     *
     */
    public void setIndex(String index)
    {
        this.index = index;
    }
    
    /**
     * 取得key *
     *
     * @return 返回 key。
     *
     */
    public String getKey()
    {
        return key;
    }
    
    /**
     * 设置key
     *
     * @param key
     *            要设置的 key。
     *
     */
    public void setKey(String key)
    {
        this.key = key;
    }
    
    /**
     * 取得className *
     *
     * @return 返回 className。
     *
     */
    public String getClassName()
    {
        return className;
    }
    
    /**
     * 设置className
     *
     * @param className
     *            要设置的 className。
     *
     */
    public void setClassName(String className)
    {
        this.className = className;
        if (this.className != null)
            this.className = this.className.trim();
    }
    
    /**
     * 取得type *
     *
     * @return 返回 type。
     *
     */
    public String getType()
    {
        return StringUtils.isEmpty(type) ? DEFAULT_ITEM_TYPE : type;
    }
    
    /**
     * 设置type
     *
     * @param type
     *            要设置的 type。
     *
     */
    public void setType(String type)
    {
        Assert.notNull(type);
        Assert.isTrue(ItemType.instance.toString().equalsIgnoreCase(type)
            || ItemType.factoryInstance.toString().equalsIgnoreCase(type)
            || ItemType.factory.toString().equalsIgnoreCase(type),
            "[Assertion failed] - type should be " + ItemType.instance.toString() + ","
                + ItemType.factoryInstance.toString() + " or " + ItemType.factory.toString());
        this.type = type;
    }
    
    /**
     * 取得factoryMethod *
     *
     * @return 返回 factoryMethod。
     *
     */
    public String getFactoryMethod()
    {
        return factoryMethod;
    }
    
    /**
     * 设置factoryMethod
     *
     * @param factoryMethod
     *            要设置的 factoryMethod。
     *
     */
    public void setFactoryMethod(String factoryMethod)
    {
        this.factoryMethod = factoryMethod;
    }
    
    /**
     * 设置throwException
     *
     * @return 返回throwException
     */
    public boolean isThrowException()
    {
        return throwException;
    }
    
    /**
     * 获取throwException
     *
     * @param throwException
     *            要设置的throwException
     */
    public void setThrowException(boolean throwException)
    {
        this.throwException = throwException;
    }
    
    /**
     * 获取silent
     *
     * @return 返回silent
     */
    public boolean isSilent()
    {
        return silent;
    }
    
    /**
     * 设置silent
     *
     * @param silent
     */
    public void setSilent(boolean silent)
    {
        this.silent = silent;
    }
}
