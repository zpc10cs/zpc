package com.huawei.jaguar.dsdp.demo.service.dfx.status;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.lang3.tuple.ImmutableTriple;
import org.apache.commons.lang3.tuple.Triple;
import org.apache.curator.framework.state.ConnectionState;

import com.huawei.bme.commons.util.debug.DebugLog;
import com.huawei.bme.commons.util.debug.LogFactory;
import com.huawei.jaguar.commons.sdk.configuration.exception.ClusterClientOperationException;
import com.huawei.jaguar.commons.sdk.configuration.factory.ZKClientFactory;
import com.huawei.jaguar.commons.sdk.configuration.listener.ZKClientConnectionListener;
import com.huawei.jaguar.commons.sdk.configuration.zookeeper.ZKClusterClient;
import com.huawei.jaguar.commons.sdk.data.integrate.api.cache.RedisCacheManager;
import com.huawei.jaguar.commons.sdk.data.integrate.vo.ServerInfo;
import com.huawei.jaguar.commons.sdk.log.alarm.Alarm;
import com.huawei.jaguar.commons.sdk.log.alarm.AlarmFactory;
import com.huawei.jaguar.commons.sdk.log.alarm.AlarmKind;
import com.huawei.jaguar.commons.sdk.maintenance.status.CheckAppStatusService;
import com.huawei.jaguar.dsdp.demo.dao.mybatis.health.DBHealthDao;
import com.huawei.jaguar.dsdp.demo.service.dfx.alarm.AlarmID;

import redis.clients.jedis.Jedis;

public class CheckStatusServiceImpl implements CheckAppStatusService, ZKClientConnectionListener
{
    private static final DebugLog DEBUGGER = LogFactory.getDebugLog(CheckStatusServiceImpl.class);
    private static final DebugLog SYSTEM_LOG = LogFactory.getDebugLog("DSDPDEMO_SYSTEM_LOG");
    private static final Alarm ALARM = AlarmFactory.getAlarm("DSDPDEMO");

    private static final String COMP_NAME = "DSDPDEMO";
    private static final String REDIS_KEY = "Redis";
    private static final String MQ_KEY = "MQ";
    private static final String DB_KEY = "Database";
    private static final String ZOOKEEPER_KEY = "Zookeeper";

    private boolean zkStatus = true;
    private boolean dbStatus = true;
    private Map<String, Boolean> redisStatus = new HashMap<String, Boolean>(0);

    private ZKClientFactory zkClientFactory;
    private RedisCacheManager redisCacheManager;
    private DBHealthDao dbHealthDao;
    private String connectionName;
    private ZKClusterClient zkClusterClient;

    public void init()
    {
        // 异步注册监听
        try
        {
            zkClientFactory.fetchZKClusterClientAsyn(connectionName, this);
        }
        catch (ClusterClientOperationException e)
        {
            DEBUGGER.warn("Fetch zookeeper client failed!", e);
        }
    }

    @Override
    public List<Triple<String, Boolean, String>> checkAppConnections()
    {
        List<Triple<String, Boolean, String>> resultList = new ArrayList<Triple<String, Boolean, String>>(5);

        boolean redisStatus = checkRedisStatus();

        String redisNormalMsg = "Status check process, result description{RedisStatus:Connect redis success}";
        String redisErrorMsg = "Status check process, result description{RedisStatus:Connect redis  fail}";
        Triple<String, Boolean, String> redisCheck = new ImmutableTriple<String, Boolean, String>(REDIS_KEY,
                redisStatus, redisStatus ? redisNormalMsg : redisErrorMsg);

        if (redisStatus)
        {
            SYSTEM_LOG.info("Redis is OK now.");
        }

        boolean mqStatus = checkMQStatus();
        String mqNormalMsg = "Status check process, result description{MQStatus:Connect MQ success}.";
        String mqErrorMsg = "Status check process, result description{MQStatus:Connect MQ fail}";
        Triple<String, Boolean, String> mqCheck = new ImmutableTriple<String, Boolean, String>(MQ_KEY, mqStatus,
                mqStatus ? mqNormalMsg : mqErrorMsg);

        if (mqStatus)
        {
            SYSTEM_LOG.info("MQ is OK now.");
        }

        boolean dbStatus = checkDBStatus();
        String dbNormalMsg = "Status check process, result description{DBStatus:Connect DataBase success}";
        String dbErrorMsg = "Status check process, result description{DBStatus:Connect DataBase fail}";
        Triple<String, Boolean, String> dbCheck = new ImmutableTriple<String, Boolean, String>(DB_KEY, dbStatus,
                dbStatus ? dbNormalMsg : dbErrorMsg);

        if (dbStatus)
        {
            SYSTEM_LOG.info("DB is ok now.");
        }

        boolean zookeeperStatus = checkZookeeperStatus();
        String zookeeperNormalMsg = "Status check process, result description{ZookeeperStatus:Connect Zookeeper Server(IP) success}";
        String zookeeperErrorMsg = "Status check process, result description{ZookeeperStatus:Connect Zookeeper Server(IP) fail}";
        Triple<String, Boolean, String> zookeeperCheck = new ImmutableTriple<String, Boolean, String>(ZOOKEEPER_KEY,
                zookeeperStatus, zookeeperStatus ? zookeeperNormalMsg : zookeeperErrorMsg);

        if (zookeeperStatus)
        {
            SYSTEM_LOG.info("Zookeeper is ok now.");
        }

        resultList.add(redisCheck);
        resultList.add(mqCheck);
        resultList.add(dbCheck);
        resultList.add(zookeeperCheck);

        return resultList;
    }

    private boolean checkZookeeperStatus()
    {
        DEBUGGER.debug("Enter checkZKStatus method.");
        boolean zkCurrentStatus = false;
        if (zkClusterClient != null)
        {
            zkCurrentStatus = zkClusterClient.isConnected();
        }
        String locationInfo = "ZookeeperConfigFileName=${HOME}/dsdpdemo_container/modules/dsdpdemo/conf/dsf.properties,"
                + " ZookeeperConfigItem=zk.server.url";
        if (zkCurrentStatus != zkStatus)
        {
            if (zkCurrentStatus)
            {
                ALARM.sendAlarm(AlarmID.ZOOKEEPER_EXCEPTION_ID, AlarmKind.RESUME, locationInfo);
                SYSTEM_LOG.info("Zookeeper connected, " + locationInfo);
            }
            else
            {
                ALARM.sendAlarm(AlarmID.ZOOKEEPER_EXCEPTION_ID, AlarmKind.FAULT, locationInfo);
            }
        }
        if (!zkCurrentStatus)
        {
            SYSTEM_LOG.error("Zookeeper disconnected, " + locationInfo);
        }
        zkStatus = zkCurrentStatus;
        return zkCurrentStatus;
    }

    private boolean checkDBStatus()
    {
        DEBUGGER.debug("Enter checkDBStatus method.");
        boolean dbCurrentStatus = false;
        try
        {
            dbCurrentStatus = dbHealthDao.checkAlive();
        }
        catch (Exception e)
        {
            DEBUGGER.error("Error happened when connecting to database.", e);
        }
        String locationInfo = "DBConfigFile=${HOME}/dsdpdemo_container/modules/dsdpdemo/conf/dsdpdemo.resource.properties,"
                + " DBConfigItem=dsdpdemodb[1].connect";
        if (dbCurrentStatus != dbStatus)
        {
            if (dbCurrentStatus)
            {
                ALARM.sendAlarm(AlarmID.ORACLE_EXCEPTION_ID, AlarmKind.RESUME, locationInfo);
                SYSTEM_LOG.info("DB connected, " + locationInfo);
            }
            else
            {
                ALARM.sendAlarm(AlarmID.ORACLE_EXCEPTION_ID, AlarmKind.FAULT, locationInfo);
            }
            dbStatus = dbCurrentStatus;
        }
        if (!dbCurrentStatus)
        {
            SYSTEM_LOG.error("DB disconnected, " + locationInfo);
        }
        return dbCurrentStatus;

    }

    private boolean checkMQStatus()
    {
        DEBUGGER.debug("Enter checkMQStatus method.");
        return true;
    }

    private boolean checkRedisStatus()
    {
        DEBUGGER.debug("Enter checkRedisStatus method.");
        boolean redisStatus = false;

        List<ServerInfo> serverInfos = null;
        try
        {
            serverInfos = redisCacheManager.getServerInfo();
            if (CollectionUtils.isNotEmpty(serverInfos))
            {
                for (ServerInfo serverInfo : serverInfos)
                {
                    boolean singleRedisStatus = checkSingleRedisStatus(serverInfo);
                    redisStatus = redisStatus || singleRedisStatus;
                }
            }
        }
        catch (Throwable t)
        {
            DEBUGGER.error("Error happened when connecting to redis.", t);
        }
        if (!redisStatus)
        {
            SYSTEM_LOG.error("Redis disconnected,"
                    + " RedisConfigFile=${HOME}/dsdpdemo_container/modules/dsdpdemo/conf/dsdpdemo.resource.properties,"
                    + " RedisConfigItem=redis.connect");
        }

        return redisStatus;
    }

    private boolean checkSingleRedisStatus(ServerInfo serverInfo)
    {
        Jedis jedis = new Jedis(serverInfo.getHost(), serverInfo.getPort());
        String url = serverInfo.getHost() + ":" + serverInfo.getPort();
        boolean originalMasterStatus = redisStatus.containsKey(url) ? redisStatus.get(url) : false;
        boolean currentMasterStatus = getJedisStatus(jedis);
        String errorMsg = "Redis[" + url + "] disconnected.";
        if (currentMasterStatus != originalMasterStatus)
        {
            if (currentMasterStatus)
            {
                String infoMsg = "Redis[" + url + "] connected.";
                ALARM.sendAlarm(AlarmID.REDIS_EXCEPTION_ID, AlarmKind.RESUME, infoMsg);
                SYSTEM_LOG.info(infoMsg);
            }
            else
            {
                ALARM.sendAlarm(AlarmID.REDIS_EXCEPTION_ID, AlarmKind.FAULT, errorMsg);
            }
        }
        if (!currentMasterStatus)
        {
            SYSTEM_LOG.error(errorMsg);
        }
        redisStatus.put(url, currentMasterStatus);
        return currentMasterStatus;
    }

    private boolean getJedisStatus(Jedis jedis)
    {
        boolean jedisStatus = false;
        try
        {
            String status = jedis.set("testkey", "testValue");
            if ("OK".equalsIgnoreCase(status))
            {
                jedisStatus = true;
            }
        }
        catch (Exception e)
        {
            DEBUGGER.error("Error happened when setting value to redis.", e);
        }
        finally
        {
            jedis.close();
        }
        return jedisStatus;
    }

    @Override
    public String getCheckedComp()
    {
        return COMP_NAME;
    }

    @Override
    public void stateChanged(ZKClusterClient client, ConnectionState state)
    {
        if (DEBUGGER.isDebugEnable())
        {
            DEBUGGER.debug("The current state of zookeeper client is " + state);
        }
        this.zkClusterClient = client;
    }

    public void setZkClientFactory(ZKClientFactory zkClientFactory)
    {
        this.zkClientFactory = zkClientFactory;
    }

    public void setRedisCacheManager(RedisCacheManager redisCacheManager)
    {
        this.redisCacheManager = redisCacheManager;
    }

    public void setConnectionName(String connectionName)
    {
        this.connectionName = connectionName;
    }

    public void setDbHealthDao(DBHealthDao dbHealthDao)
    {
        this.dbHealthDao = dbHealthDao;
    }
}
