package com.huawei.jaguar.dsdp.demo.service.dfx.status;

import java.util.List;

import com.huawei.jaguar.commons.sdk.data.integrate.api.cache.RedisCacheManager;
import com.huawei.jaguar.commons.sdk.maintenance.monitor.connectionpool.ConnectionPoolMonitorResponse;
import com.huawei.jaguar.commons.sdk.maintenance.monitor.connectionpool.IRedisConnectionPoolMonitorService;

public class RedisConnectionPoolMonitorServiceImpl implements IRedisConnectionPoolMonitorService
{
    private RedisCacheManager redisCacheManager;
    private String redisConnPoolName;

    public void setRedisCacheManager(RedisCacheManager redisCacheManager)
    {
        this.redisCacheManager = redisCacheManager;
    }

    public void setRedisConnPoolName(String redisConnPoolName)
    {
        this.redisConnPoolName = redisConnPoolName;
    }

    @Override
    public List<ConnectionPoolMonitorResponse> getConnPoolMonitorResponse()
    {
        /*if (null != redisCacheManager.getJedisPoolConfig())
        {
            List<ConnectionPoolMonitorResponse> list = new ArrayList<ConnectionPoolMonitorResponse>(10);
            ConnectionPoolMonitorResponse rsp = new ConnectionPoolMonitorResponse();
            rsp.setConnectionPoolName(redisConnPoolName);
            rsp.setMaxIdle(jedisCluster.getJedisPoolConfig().getMaxIdle());
            rsp.setMaxTotal(jedisCluster.getJedisPoolConfig().getMaxTotal());
            rsp.setMinIdle(jedisCluster.getJedisPoolConfig().getMinIdle());
            if (null != jedisCluster.getJedisPool())
            {
                rsp.setCurrentIdle(jedisCluster.getJedisPool().getNumIdle());
                rsp.setCurrentActive(jedisCluster.getJedisPool().getNumActive());
                rsp.setCurrentWait(jedisCluster.getJedisPool().getNumWaiters());
            }
            list.add(rsp);
            return list;
        }*/
        return null;
    }

}
