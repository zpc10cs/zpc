/*
 * 文件名：ItemChecker.java
 * 版权：Copyright 2006-2007 Huawei Tech. Co. Ltd. All Rights Reserved.
 * 描述：提供判断启动项是否可以增加到启动或关闭列表中的方法
 * 修改人：x60014113
 * 修改时间：Dec 12, 2006
 * 修改内容：新增
 */
package com.huawei.jaguar.commons.bootstrap.control.policy;

import com.huawei.jaguar.commons.bootstrap.control.config.ConfigItem;

/**
 * 判断启动项是否可以增加到启动或关闭列表中
 * @author x60014113
 * @since 1.2
 */
public interface ItemChecker
{
    /**
     *
     * 判断配置项是否可以增加到启动或关闭列表中
     * @param item 启动或关闭项
     * @return True or False
     */
    boolean canAdd2List(ConfigItem item);
    
}
