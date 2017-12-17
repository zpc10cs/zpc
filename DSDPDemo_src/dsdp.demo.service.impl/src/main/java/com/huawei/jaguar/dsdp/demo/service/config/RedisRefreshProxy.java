package com.huawei.jaguar.dsdp.demo.service.config;

import java.io.UnsupportedEncodingException;

import org.apache.commons.lang3.StringUtils;
import org.apache.curator.framework.state.ConnectionState;

import com.huawei.bme.commons.om.log.DebugLog;
import com.huawei.jaguar.commons.sdk.configuration.event.ZKNodeEvent;
import com.huawei.jaguar.commons.sdk.configuration.event.ZKNodeEventSource;
import com.huawei.jaguar.commons.sdk.configuration.event.ZKNodeEventType;
import com.huawei.jaguar.commons.sdk.configuration.factory.ZKClientFactory;
import com.huawei.jaguar.commons.sdk.configuration.listener.ZKClientConnectionListener;
import com.huawei.jaguar.commons.sdk.configuration.listener.ZKNodeListener;
import com.huawei.jaguar.commons.sdk.configuration.utils.JSONUtils;
import com.huawei.jaguar.commons.sdk.configuration.zookeeper.NodeInfo;
import com.huawei.jaguar.commons.sdk.configuration.zookeeper.ZKClusterClient;
import com.huawei.jaguar.commons.sdk.data.integrate.api.cache.RedisCacheManager;
import com.huawei.jaguar.commons.sdk.log.etrace.LoggerFactory;

public class RedisRefreshProxy implements ZKNodeListener, ZKClientConnectionListener
{
    private static final DebugLog LOGGER = LoggerFactory.getDebugLog(RedisRefreshProxy.class);

    private String acceptPath;
    private String connectionName;
    private RedisCacheManager redisCacheManager;
    private ZKClientFactory zkClientFactory;

    public void setAcceptPath(String acceptPath)
    {
        this.acceptPath = acceptPath;
    }

    public void setConnectionName(String connectionName)
    {
        this.connectionName = connectionName;
    }

    public void setRedisCacheManager(RedisCacheManager redisCacheManager)
    {
        this.redisCacheManager = redisCacheManager;
    }

    public void setZkClientFactory(ZKClientFactory zkClientFactory)
    {
        this.zkClientFactory = zkClientFactory;
    }

    public void initConnectionListener()
    {
        // 异步注册监听
        zkClientFactory.fetchZKClusterClientAsyn(connectionName, this);
    }

    @Override
    public void stateChanged(ZKClusterClient client, ConnectionState newState)
    {
        synchronized (this)
        {
            if ((ConnectionState.RECONNECTED == newState) || (ConnectionState.CONNECTED == newState))
            {
                client.registerListener(acceptPath, this, new ZKNodeEventType[] { ZKNodeEventType.ALL });
            }
        }
    }

    @Override
    public boolean accept(ZKNodeEvent event)
    {
        ZKNodeEventSource eventSource = (ZKNodeEventSource) event.getSource();
        if (eventSource.getData().getPath().equals(acceptPath))
        {
            return true;
        }
        return false;
    }

    @Override
    public void onEvent(ZKNodeEvent event)
    {
        LOGGER.debug("Begin reload redis");
        synchronized (this)
        {
            ZKNodeEventSource eventSource = (ZKNodeEventSource) event.getSource();
            String value = null;
            try
            {
                value = new String(eventSource.getData().getData(), "UTF-8");
            }
            catch (UnsupportedEncodingException e)
            {
                LOGGER.error("Unsupported this charset", e);
                throw new RuntimeException(e);
            }
            if (StringUtils.isEmpty(value))
            {
                throw new RuntimeException("Illegal connection URL.");
            }

            // json反序列化操作
            NodeInfo nodeInfo = JSONUtils.parseObject(value, NodeInfo.class);
            if (nodeInfo == null)
            {
                throw new RuntimeException("Illegal connection URL.");
            }

            redisCacheManager.reload(nodeInfo.getValue());
        }
        LOGGER.debug("End reload redis!!");
    }
}
