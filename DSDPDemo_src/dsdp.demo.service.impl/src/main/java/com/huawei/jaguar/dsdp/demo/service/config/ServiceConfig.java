package com.huawei.jaguar.dsdp.demo.service.config;

/**
 * 统一配置对应的配置属性。
 * 
 * <h1>主要功能：</h1>
 * <p>
 * 配置的主要属性，包括zookeeper上的路径，使用该配置的bean，以及配置对应的property。
 * </p>
 * 
 * @version DEP V300R003C20, 2014-10-24
 * @author z00297102
 * @since DEP V300R003C20
 */
public class ServiceConfig
{
    /**
     * 配置在zookeeper上的路径。
     */
    private String path;
    /**
     * 使用该配置的bean ID。
     */
    private String beanId;
    /**
     * 该配置在bean中对应的属性名。
     */
    private String propertyName;

    public String getPath()
    {
        return path;
    }

    public void setPath(String path)
    {
        this.path = path;
    }

    public String getBeanId()
    {
        return beanId;
    }

    public void setBeanId(String beanId)
    {
        this.beanId = beanId;
    }

    public String getPropertyName()
    {
        return propertyName;
    }

    public void setPropertyName(String propertyName)
    {
        this.propertyName = propertyName;
    }

    @Override
    public String toString()
    {
        StringBuilder builder = new StringBuilder();
        builder.append("ServiceConfig [beanId=");
        builder.append(beanId);
        builder.append(", path=");
        builder.append(path);
        builder.append(", propertyName=");
        builder.append(propertyName);
        builder.append(", hashCode()=");
        builder.append(hashCode());
        builder.append(", toString()=");
        builder.append(super.toString());
        builder.append("] ");
        return builder.toString();
    }
}
