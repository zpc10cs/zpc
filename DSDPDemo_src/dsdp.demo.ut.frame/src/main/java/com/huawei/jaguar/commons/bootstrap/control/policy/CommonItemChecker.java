/*
 * 文件名：CommonItemChecker.java
 * 版权：Copyright 2006-2007 Huawei Tech. Co. Ltd. All Rights Reserved.
 * 描述： 公共的检查启动或关闭项的类
 * 修改人：x60014113
 * 修改时间：Dec 12, 2006
 * 修改内容：新增
 */
package com.huawei.jaguar.commons.bootstrap.control.policy;

import org.apache.commons.lang.StringUtils;

import com.huawei.bme.commons.util.ReflectionUtils;
import com.huawei.bme.commons.util.debug.DebugLog;
import com.huawei.bme.commons.util.debug.LogFactory;
import com.huawei.jaguar.commons.bootstrap.control.FixtureLifeCycle;
import com.huawei.jaguar.commons.bootstrap.control.config.ConfigItem;

/**
 *
 * 公共的检查启动或关闭项的类，主要判断启动或关闭项是否满足条件。
 *
 * <p>
 * 检测条件如下：
 * <li>如果项为空则不能通过检测；</li>
 * <li>如果项为instance类型且实现了{@link com.huawei.soa.foundation.container.control.FixtureLifeCycle}接口，检测通过；
 * <li>不属于第二项且对应的方法不存在则不能通过检测。</li>
 *
 *
 *
 * @author x60014113
 * @author m46230
 *
 * @since 1.2
 *
 */
public class CommonItemChecker implements ItemChecker
{
    /**
     * 获取方法名称
     */
    private String checkMethod;
    
    /** 日志记录 */
    private final DebugLog logger = LogFactory.getDebugLog(CommonItemChecker.class);
    
    /**
     *
     * 构造函数
     *
     * @param checkMethod
     *            被检查的方法名称
     */
    public CommonItemChecker(String checkMethod)
    {
        this.checkMethod = checkMethod;
    }
    
    /**
     * {@inheritDoc}
     */
    public boolean canAdd2List(ConfigItem item)
    {
        if (item == null)
        {
            return false;
        }
        
        // 对于实现装置接口的类，直接加入到可执行列表中
        try
        {
            if (ConfigItem.DEFAULT_ITEM_TYPE.equals(item.getType()))
            {
                if (Class.forName(item.getClassName()).newInstance() instanceof FixtureLifeCycle)
                {
                    return true;
                }
            }
        }
        catch (Exception e)
        {
            if (logger.isErrorEnable())
            {
                logger.error("Can't get class for " + item.getClassName(), e);
            }
            return false;
        }
        
        // 用反射的方法获取对象
        Object obj = ReflectionUtils.invokeMethod(checkMethod, item, null, null);
        if ((obj != null) && (obj instanceof String) && (StringUtils.isNotEmpty((String)obj)))
        {
            return true;
        }
        
        return false;
    }
}
