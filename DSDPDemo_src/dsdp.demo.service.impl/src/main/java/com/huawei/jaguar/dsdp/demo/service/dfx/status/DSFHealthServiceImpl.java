package com.huawei.jaguar.dsdp.demo.service.dfx.status;

import java.util.HashMap;

import org.apache.commons.lang3.tuple.ImmutablePair;
import org.apache.commons.lang3.tuple.Pair;

import com.huawei.bme.commons.om.log.DebugLog;
import com.huawei.jaguar.commons.sdk.log.etrace.LoggerFactory;
import com.huawei.jaguar.commons.sdk.maintenance.monitor.client.dsf.DSFHealthService;
import com.huawei.jaguar.dsdp.demo.dao.mybatis.health.DBHealthDao;

public class DSFHealthServiceImpl implements DSFHealthService
{
    private static final DebugLog LOGGER = LoggerFactory.getDebugLog(DSFHealthServiceImpl.class);

    private DBHealthDao dbHealthDao;

    public void setDbHealthDao(DBHealthDao dbHealthDao)
    {
        this.dbHealthDao = dbHealthDao;
    }

    @Override
    public Pair<Boolean, HashMap<String, String>> checkStatus()
    {
        Pair<Boolean, HashMap<String, String>> ret;
        HashMap<String, String> compMap = new HashMap<String, String>(1);

        try
        {
            if (dbHealthDao.checkAlive())
            {
                compMap.put("DataBaseStatus", "DB is alive.");
                ret = new ImmutablePair<Boolean, HashMap<String, String>>(true, compMap);
            }
            else
            {
                compMap.put("DataBaseStatus", "DB is not alive.");
                ret = new ImmutablePair<Boolean, HashMap<String, String>>(false, compMap);
            }
        }
        catch (Throwable e)
        {
            compMap.put("DataBaseStatus", e.getMessage().substring(0, 100));
            ret = new ImmutablePair<Boolean, HashMap<String, String>>(false, compMap);
            LOGGER.error("Error happened when monitoring DB status", e);
        }

        return ret;
    }
}
