package com.huawei.jaguar.dsdp.demo.service.dfx.status;

import java.util.ArrayList;
import java.util.List;

import org.apache.commons.dbcp.BasicDataSource;

import com.huawei.jaguar.commons.sdk.maintenance.monitor.connectionpool.IOracleConnectionPoolMonitorService;
import com.huawei.jaguar.commons.sdk.maintenance.monitor.connectionpool.OracleConnPoolMonitorResponse;

public class OracleConnectionPoolMonitorServiceImpl implements IOracleConnectionPoolMonitorService
{
    private BasicDataSource oracleDataSource;
    private String oracleConnPoolName;

    public void setOracleDataSource(BasicDataSource oracleDataSource)
    {
        this.oracleDataSource = oracleDataSource;
    }

    public void setOracleConnPoolName(String oracleConnPoolName)
    {
        this.oracleConnPoolName = oracleConnPoolName;
    }

    @Override
    public List<OracleConnPoolMonitorResponse> getOracleConnPoolMonitorResponse()
    {
        if (null == oracleDataSource)
        {
            return null;
        }
        List<OracleConnPoolMonitorResponse> list = new ArrayList<OracleConnPoolMonitorResponse>(10);
        OracleConnPoolMonitorResponse rsp = new OracleConnPoolMonitorResponse();
        rsp.setConnectionPoolName(oracleConnPoolName);
        rsp.setMaxActive(oracleDataSource.getMaxActive());
        rsp.setMaxIdle(oracleDataSource.getMaxIdle());
        rsp.setMaxWait(oracleDataSource.getMaxWait());
        rsp.setMinIdle(oracleDataSource.getMinIdle());
        rsp.setCurrentActive(oracleDataSource.getNumActive());
        rsp.setCurrentIdle(oracleDataSource.getNumIdle());
        list.add(rsp);
        return list;
    }
}
