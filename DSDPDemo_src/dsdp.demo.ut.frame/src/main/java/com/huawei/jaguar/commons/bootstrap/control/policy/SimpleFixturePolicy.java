/*
 * 文件名：SimpleFixturePolicy.java
 * 版权：Copyright 2006-2007 Huawei Tech. Co. Ltd. All Rights Reserved.
 * 描述： 简单的装置策略，所有的装置按照给定的次序处理。
 * 修改人：m46230
 * 修改时间：2006-11-25
 * 修改内容：新增
 */
package com.huawei.jaguar.commons.bootstrap.control.policy;

import org.apache.commons.lang.StringUtils;

import com.huawei.bme.commons.util.ClassUtils;
import com.huawei.bme.commons.util.ReflectionUtils;
import com.huawei.bme.commons.util.debug.DebugLog;
import com.huawei.bme.commons.util.debug.LogFactory;
import com.huawei.jaguar.commons.bootstrap.control.FixtureLifeCycle;
import com.huawei.jaguar.commons.bootstrap.control.config.ConfigItem;
import com.huawei.jaguar.commons.bootstrap.util.LogUtil;

/**
 * 简单的装置策略，所有的装置按照给定的次序处理。.
 * 
 * @author m46230
 * @since 1.2
 */
public class SimpleFixturePolicy extends AbstractFixturePolicy
{
    /** The Constant DEBUGGER. */
    private static final DebugLog DEBUGGER = LogFactory.getDebugLog(SimpleFixturePolicy.class);
    
    /**
     * Do process after close.
     * 
     * @param item the item
     * {@inheritDoc}
     */
    protected void doProcessAfterClose(ConfigItem item)
    {
        String outPut = "";
        if (!StringUtils.isEmpty(item.getAfterDestroyMethod()))
        {
            long begin = System.currentTimeMillis();
            outPut = generateOutput(item, ConfigItem.SHUTDOWN_TAG);
            doProcess(item, item.getAfterDestroyMethod(), outPut);
            long end = System.currentTimeMillis();
            
            System.out.println(LogUtil.paddingStr(outPut + " successful.",
                LogUtil.COST_STR.replaceAll(LogUtil.PERCENT, String.valueOf(end - begin)),
                LogUtil.DOT,
                LogUtil.FROMAT_LENGTH));
        }
        else
        {
            doProcess(item, ConfigItem.DEFAULT_AFTER_DESTROY_METHOD, outPut);
        }
    }
    
    /**
     * Do process after load.
     * 
     * @param item the item
     * {@inheritDoc}
     */
    protected void doProcessAfterLoad(ConfigItem item)
    {
        String outPut = "";
        if (!StringUtils.isEmpty(item.getAfterInitMethod()))
        {
            long begin = System.currentTimeMillis();
            outPut = generateOutput(item, ConfigItem.START_UP_TAG);
            doProcess(item, item.getAfterInitMethod(), outPut);
            long end = System.currentTimeMillis();
            
            System.out.println(LogUtil.paddingStr(outPut + " successful.",
                LogUtil.COST_STR.replaceAll(LogUtil.PERCENT, String.valueOf(end - begin)),
                LogUtil.DOT,
                LogUtil.FROMAT_LENGTH));
        }
        else
        {
            doProcess(item, ConfigItem.DEFAULT_AFTER_INIT_METHOD, outPut);
        }
    }
    
    /**
     * Do process before load.
     * 
     * @param item the item
     * {@inheritDoc}
     */
    protected void doProcessBeforeLoad(ConfigItem item)
    {
        String outPut = "";
        if (!StringUtils.isEmpty(item.getBeforeInitMethod()))
        {
            long begin = System.currentTimeMillis();
            outPut = generateOutput(item, ConfigItem.START_UP_TAG);
            doProcess(item, item.getBeforeInitMethod(), outPut);
            long end = System.currentTimeMillis();
            
            System.out.println(LogUtil.paddingStr(outPut + " successful.",
                LogUtil.COST_STR.replaceAll(LogUtil.PERCENT, String.valueOf(end - begin)),
                LogUtil.DOT,
                LogUtil.FROMAT_LENGTH));
        }
        else
        {
            doProcess(item, ConfigItem.DEFAULT_BEFORE_INIT_METHOD, outPut);
        }
    }
    
    /**
     * Do process before close.
     * 
     * @param item the item
     * {@inheritDoc}
     */
    protected void doProcessBeforeClose(ConfigItem item)
    {
        String outPut = "";
        if (!StringUtils.isEmpty(item.getBeforeDestroyMethod()))
        {
            long begin = System.currentTimeMillis();
            outPut = generateOutput(item, ConfigItem.SHUTDOWN_TAG);
            doProcess(item, item.getBeforeDestroyMethod(), outPut);
            long end = System.currentTimeMillis();
            
            System.out.println(LogUtil.paddingStr(outPut + " successful.",
                LogUtil.COST_STR.replaceAll(LogUtil.PERCENT, String.valueOf(end - begin)),
                LogUtil.DOT,
                LogUtil.FROMAT_LENGTH));
        }
        else
        {
            doProcess(item, ConfigItem.DEFAULT_BEFORE_DESTROY_METHOD, outPut);
        }
    }
    
    /**
     * 通用的处理流程.
     * 
     * @param item 配置项目
     * @param methodName 配置项需调用的方法
     * @param outPut the out put
     */
    private void doProcess(ConfigItem item, String methodName, String outPut)
    {
        long beginTime = System.currentTimeMillis();
        try
        {
            switch (ConfigItem.ItemType.valueOf(item.getType()))
            {
                case instance:
                {
                    Object obj = ClassUtils.createClass(item.getClassName());
                    internalProcess(methodName, obj);
                    break;
                }
                case factory:
                {
                    process(methodName, ClassUtils.getClass(item.getClassName()), null);
                    break;
                }
                case factoryInstance:
                {
                    Object obj = process(item.getFactoryMethod(), ClassUtils.getClass(item.getClassName()), null);
                    internalProcess(methodName, obj);
                    break;
                }
                default:
                {
                    break;
                }
            }
        }
        catch (Exception e)
        {
            System.out.println(LogUtil.paddingStr(outPut + " fail.", "", LogUtil.DOT, LogUtil.FROMAT_LENGTH));
            
            if (item.isThrowException())
            {
                throw new RuntimeException(e);
            }
            else
            {
                if (DEBUGGER.isErrorEnable())
                {
                    DEBUGGER.error("Failed to process fixture[" + item.getClassName() + "], throwException is "
                        + item.isThrowException(),
                        e);
                }
            }
        }
        
        long endTime = System.currentTimeMillis();
        long costTime = endTime - beginTime;
        
        if (DEBUGGER.isInfoEnable())
        {
            DEBUGGER.info("[Process] " + item.getClassName() + " cost " + costTime + " ms");
        }
    }
    
    /**
     * 调用给定的方法.
     * 
     * @param methodName 方法名称
     * @param obj 调用对象
     */
    private void internalProcess(String methodName, Object obj)
    {
        if (obj != null)
        {
            
            // 实现了生命周期接口优先调用
            if (obj instanceof FixtureLifeCycle)
            {
                FixtureLifeCycle lifeCycle = (FixtureLifeCycle)obj;
                if (ConfigItem.DEFAULT_BEFORE_INIT_METHOD.equals(methodName))
                {
                    lifeCycle.initBeforeContextLoad();
                }
                else if (ConfigItem.DEFAULT_AFTER_INIT_METHOD.equals(methodName))
                {
                    lifeCycle.initAfterContextLoad();
                }
                else if (ConfigItem.DEFAULT_BEFORE_DESTROY_METHOD.equals(methodName))
                {
                    lifeCycle.destroyBeforeContextClose();
                }
                else if (ConfigItem.DEFAULT_AFTER_DESTROY_METHOD.equals(methodName))
                {
                    lifeCycle.destroyAfterContextClose();
                }
            }
            else
            {
                process(methodName, obj.getClass(), obj);
            }
        }
    }
    
    /**
     * 简单处理.
     * 
     * @param methodName 方法名称
     * @param clazz 类
     * @param obj 目标对象
     * @return 方法结果
     */
    @SuppressWarnings("unchecked")
    private Object process(String methodName, Class clazz, Object obj)
    {
        Object result = null;
        if (clazz != null)
        {
            result = ReflectionUtils.invokeMethod(methodName, clazz, obj, null, null);
        }
        return result;
    }
    
    /**
     * Generate output.
     * 
     * @param item the item
     * @param tag the tag
     * @return the string
     */
    private String generateOutput(ConfigItem item, String tag)
    {
        String desc = getDesc(item.getDesc());
        
        String output = ConfigItem.HEADER + ' ' + tag + item.getKey() + desc;
        
        return output;
    }
    
    /**
     * Gets the desc.
     * 
     * @param desc the desc
     * @return the desc
     */
    private String getDesc(String desc)
    {
        if (desc == null)
        {
            return "";
        }
        
        desc = desc.trim();
        
        if (desc.length() > 0)
        {
            desc = "[" + desc + "]";
        }
        return desc;
    }
}
