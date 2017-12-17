package com.huawei.jaguar.dsdp.demo.dao.mybatis.health.impl;

import org.springframework.orm.ibatis.support.SqlMapClientDaoSupport;

import com.huawei.jaguar.dsdp.demo.dao.mybatis.health.DBHealthDao;

public class DBHealthDaoImpl extends SqlMapClientDaoSupport implements DBHealthDao
{
    private static final String CHECK_ALIVE = "dsdpdemo.dbhealth.checkAlive";

    @Override
    public boolean checkAlive()
    {
        return getSqlMapClientTemplate().queryForList(CHECK_ALIVE).size() != 0;
    }
}
