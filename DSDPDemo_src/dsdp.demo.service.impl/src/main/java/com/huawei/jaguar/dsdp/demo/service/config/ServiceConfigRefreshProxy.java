package com.huawei.jaguar.dsdp.demo.service.config;

import java.io.UnsupportedEncodingException;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.List;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.lang.StringUtils;
import org.apache.curator.framework.state.ConnectionState;
import org.springframework.util.ReflectionUtils;

import com.huawei.bme.commons.om.log.DebugLog;
import com.huawei.bme.commons.om.log.LogFactory;
import com.huawei.jaguar.commons.sdk.configuration.event.ZKNodeEvent;
import com.huawei.jaguar.commons.sdk.configuration.event.ZKNodeEventSource;
import com.huawei.jaguar.commons.sdk.configuration.event.ZKNodeEventType;
import com.huawei.jaguar.commons.sdk.configuration.factory.ZKClientFactory;
import com.huawei.jaguar.commons.sdk.configuration.listener.ZKClientConnectionListener;
import com.huawei.jaguar.commons.sdk.configuration.listener.ZKNodeListener;
import com.huawei.jaguar.commons.sdk.configuration.spring.SpringContext;
import com.huawei.jaguar.commons.sdk.configuration.utils.JSONUtils;
import com.huawei.jaguar.commons.sdk.configuration.zookeeper.NodeInfo;
import com.huawei.jaguar.commons.sdk.configuration.zookeeper.ZKClusterClient;

/**
 * 刷新业务配置项。
 * 
 * <h1>主要功能：</h1>
 * <p>
 * 当zookeeper上的配置更改时，同步刷新该配置到bean对应属性中。目前支持刷新的属性类型为String、
 * Integer/Long/Short/Double/Float/Boolean以及它们对应的基本类型。
 * </p>
 * 
 * @version DEP V300R003C20, 2014-10-24
 * @author z00297102
 * @since DEP V300R003C20
 */
public class ServiceConfigRefreshProxy implements ZKNodeListener, ZKClientConnectionListener
{
    /**
     * 日志打印器
     */
    private static final DebugLog LOGGER = LogFactory.getDebugLog(ServiceConfigRefreshProxy.class);

    private SpringContext springContext;
    private String connectionName;
    private List<ServiceConfig> serviceConfigs;
    private ZKClientFactory zkClientFactory;

    public void setSpringContext(SpringContext springContext)
    {
        this.springContext = springContext;
    }

    public void setConnectionName(String connectionName)
    {
        this.connectionName = connectionName;
    }

    public void setServiceConfigs(List<ServiceConfig> serviceConfigs)
    {
        this.serviceConfigs = serviceConfigs;
    }

    public void setZkClientFactory(ZKClientFactory zkClientFactory)
    {
        this.zkClientFactory = zkClientFactory;
    }

    public void init()
    {
        // 异步注册监听
        zkClientFactory.fetchZKClusterClientAsyn(connectionName, this);
    }

    @Override
    public void stateChanged(ZKClusterClient client, ConnectionState newState)
    {
        synchronized (this)
        {
            if (CollectionUtils.isNotEmpty(serviceConfigs)
                    && ((ConnectionState.RECONNECTED == newState) || (ConnectionState.CONNECTED == newState)))
            {
                for (ServiceConfig serviceConfig : serviceConfigs)
                {
                    client.registerListener(serviceConfig.getPath(), this, ZKNodeEventType.ALL);
                }
            }
        }
    }

    @Override
    public boolean accept(ZKNodeEvent event)
    {
        boolean accept = false;
        ZKNodeEventSource eventSource = (ZKNodeEventSource) event.getSource();
        String path = eventSource.getData().getPath();
        if (CollectionUtils.isNotEmpty(serviceConfigs))
        {
            for (ServiceConfig serviceConfig : serviceConfigs)
            {
                if (path.equals(serviceConfig.getPath()))
                {
                    accept = true;
                    break;
                }
            }
        }
        return accept;
    }

    @Override
    public void onEvent(ZKNodeEvent event)
    {
        synchronized (this)
        {
            if (CollectionUtils.isNotEmpty(serviceConfigs))
            {
                ZKNodeEventSource eventSource = (ZKNodeEventSource) event.getSource();
                String path = eventSource.getData().getPath();
                String value = null;
                try
                {
                    value = new String(eventSource.getData().getData(), "UTF-8");
                }
                catch (UnsupportedEncodingException e)
                {
                    LOGGER.error("Charset must be \"UTF-8\"", e);
                    return;
                }
                // json反序列化操作
                NodeInfo nodeInfo = JSONUtils.parseObject(value, NodeInfo.class);
                value = nodeInfo == null ? null : nodeInfo.getValue();
                for (ServiceConfig serviceConfig : serviceConfigs)
                {
                    // 不跳出循环，以支持多个bean的property映射到同一个path
                    if (path.equals(serviceConfig.getPath()))
                    {
                        updatePropertyOfBean(serviceConfig, value);
                    }
                }
            }
        }
    }

    private void updatePropertyOfBean(ServiceConfig serviceConfig, String value)
    {
        Object bean = springContext.getBeanQuietly(serviceConfig.getBeanId());
        if (bean == null)
        {
            LOGGER.error("Bean " + serviceConfig.getBeanId() + " was not found.");
        }
        else
        {
            try
            {
                Method method = ReflectionUtils.findMethod(bean.getClass(),
                        "set" + StringUtils.capitalize(serviceConfig.getPropertyName()), null);
                if (method == null)
                {
                    throw new RuntimeException("Property " + serviceConfig.getPropertyName()
                            + " has no setter method in bean " + serviceConfig.getBeanId() + '.');
                }
                else if (method.getParameterTypes() == null || method.getParameterTypes().length != 1)
                {
                    throw new RuntimeException("Setter method of property " + serviceConfig.getPropertyName()
                            + " in bean " + serviceConfig.getBeanId() + " should only has one parameter.");
                }
                ReflectionUtils.makeAccessible(method);
                invokeMethod(bean, method, value);
                if (LOGGER.isDebugEnable())
                {
                    LOGGER.debug("Property " + serviceConfig.getPropertyName() + " of bean " + serviceConfig.getBeanId()
                            + " was updated to " + value + '.');
                }
            }
            catch (Throwable t)
            {
                LOGGER.error("Error happened when updating property " + serviceConfig.getPropertyName() + " of bean "
                        + serviceConfig.getBeanId() + '.', t);
            }
        }
    }

    private void invokeMethod(Object target, Method method, String value)
            throws IllegalArgumentException, IllegalAccessException, InvocationTargetException
    {
        Class<?> clazz = method.getParameterTypes()[0];
        Object newValue = null;

        if (String.class == clazz)
        {
            newValue = value;
        }
        else if (Integer.class == clazz || Integer.TYPE == clazz)
        {
            newValue = Integer.valueOf(value);
        }
        else if (Long.class == clazz || Long.TYPE == clazz)
        {
            newValue = Long.valueOf(value);
        }
        else if (Short.class == clazz || Short.TYPE == clazz)
        {
            newValue = Short.valueOf(value);
        }
        else if (Double.class == clazz || Double.TYPE == clazz)
        {
            newValue = Double.valueOf(value);
        }
        else if (Float.class == clazz || Float.TYPE == clazz)
        {
            newValue = Float.valueOf(value);
        }
        else if (Boolean.class == clazz || Boolean.TYPE == clazz)
        {
            newValue = "true".equalsIgnoreCase(value) ? Boolean.TRUE : Boolean.FALSE;
        }
        else
        {
            throw new RuntimeException("Type " + clazz + " is currently not supported.");
        }
        method.invoke(target, newValue);
    }
}
