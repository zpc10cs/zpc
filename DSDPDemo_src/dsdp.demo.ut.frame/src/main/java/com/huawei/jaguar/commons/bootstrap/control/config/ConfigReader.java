/*
 * 文件名：ConfigReader.java
 * 版权：Copyright 2006-2007 Huawei Tech. Co. Ltd. All Rights Reserved.
 * 描述： 读取容器启动配置类的数据
 * 修改人：m46230
 * 修改时间：2006-11-25
 * 修改内容：新增
 */
package com.huawei.jaguar.commons.bootstrap.control.config;

import java.io.IOException;
import java.util.List;

import org.apache.commons.lang.SystemUtils;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

import com.huawei.bme.commons.om.log.DebugLog;
import com.huawei.bme.commons.om.log.LogFactory;
import com.huawei.bme.commons.util.Assert;
import com.huawei.bme.commons.util.XmlUtil;

/**
 * 配置数据读取类
 *
 * @author m46230
 * @since 1.2
 *
 */
public class ConfigReader
{
    private static final DebugLog DEBUGGER = LogFactory.getDebugLog(ConfigReader.class);
    
    /**
     * 配置单例
     */
    private static ConfigData initConfigData = null;
    
    /**
     * 简单的互斥锁
     */
    private static final Object LOCK = new Object();
    
    private static final String INIT_START_FIXTURE_DEFAULT_POLICY = "classpath*:*.fixture.xml";
    
    // private static final String INIT_START_FIXTURE_XSD_FILE = "startUpConfig.xsd";
    
    /**
     * 获取初始配置
     *
     * @return 初始配置
     */
    public static ConfigData getInitConfigData()
    {
        if (initConfigData == null)
        {
            synchronized (LOCK)
            {
                if (initConfigData == null)
                {
                    PathMatchingResourcePatternResolver resolver = new PathMatchingResourcePatternResolver();
                    Resource[] resources = null;
                    try
                    {
                        resources = resolver.getResources(INIT_START_FIXTURE_DEFAULT_POLICY);
                    }
                    catch (IOException e)
                    {
                        DEBUGGER.error("load start policy failed: " + e);
                    }
                    String fileName = "";
                    if (resources != null && resources.length >= 1)
                    {
                        try
                        {
                            fileName = resources[0].getFile().getCanonicalPath();
                        }
                        catch (IOException e)
                        {
                            DEBUGGER.error("load start policy failed: " + e);
                        }
                    }
                    Document doc = XmlUtil.getDocument(fileName);
                    initConfigData = readConfigData(doc);
                }
            }
        }
        return initConfigData;
    }
    
    /**
     * 清空初始配置缓存。
     */
    public static void clearConfigData()
    {
        if (null != initConfigData)
        {
            synchronized (LOCK)
            {
                initConfigData = null;
            }
        }
    }
    
    /**
     *
     * 将文档对象解析为配置数据对象
     *
     * @param doc
     *            文档对象
     * @return 配置数据对象
     */
    public static ConfigData readConfigData(Document doc)
    {
        Assert.notNull(doc);
        
        // 初始化策略集合
        ConfigData configData = new ConfigData();
        try
        {
            // XmlUtil.verifyXsd(doc, initStartXSDIS);
            Element docElement = doc.getDocumentElement();
            Assert.isTrue(XmlUtil.nodeNameEquals(docElement, "fixtures"));
            List<Element> childElementsByTagName = XmlUtil.getChildElementsByTagName(docElement, "fixture");
            for (Element element : childElementsByTagName)
            {
                ConfigItem item = new ConfigItem();
                item.setKey(XmlUtil.getAttrValue(element, "key"));
                item.setIndex(XmlUtil.getAttrValue(element, "index"));
                item.setType(XmlUtil.getAttrValue(element, "type", "instance"));
                item.setBiIndex(XmlUtil.getAttrValue(element, "bi-index"));
                item.setAiIndex(XmlUtil.getAttrValue(element, "ai-index"));
                item.setBdIndex(XmlUtil.getAttrValue(element, "bd-index"));
                item.setAdIndex(XmlUtil.getAttrValue(element, "ad-index"));
                item.setBeforeInitMethod(XmlUtil.getAttrValue(element, "before-init-method"));
                item.setAfterInitMethod(XmlUtil.getAttrValue(element, "after-init-method"));
                item.setBeforeDestroyMethod(XmlUtil.getAttrValue(element, "before-destroy-method"));
                item.setAfterDestroyMethod(XmlUtil.getAttrValue(element, "after-destroy-method"));
                item.setFactoryMethod(XmlUtil.getAttrValue(element, "factory-method"));
                item.setDesc(XmlUtil.getAttrValue(element, "desc"));
                item.setThrowException(Boolean.valueOf(XmlUtil.getAttrValue(element, "throwException", "true")));
                item.setSilent(Boolean.valueOf(XmlUtil.getAttrValue(element, "silent", "false")));
                item.setClassName(XmlUtil.getNodeValue(element));
                
                configData.addConfigItem(item);
            }
        }
        catch (Exception e)
        {
            if (DEBUGGER.isErrorEnable())
            {
                DEBUGGER.error("Fixture file parse error, the merged document is:" + SystemUtils.LINE_SEPARATOR
                    + XmlUtil.DOM2String(doc), e);
            }
        }
        
        return configData;
    }
}
