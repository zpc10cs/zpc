package com.huawei.jaguar.dsdp.demo.dao.mybatis.impl;

import org.springframework.orm.ibatis.support.SqlMapClientDaoSupport;

import com.huawei.jaguar.dsdp.demo.dao.mybatis.GenericDao;

public abstract class GenericDaoImpl<T, K> extends SqlMapClientDaoSupport implements GenericDao<T, K>
{
    protected abstract String getCreateSQLId();

    protected abstract String getUpdateSQLId();

    protected abstract String getDeleteSQLId();

    protected abstract String getRetrieveSQLId();

    @Override
    public void create(T t)
    {
        getSqlMapClientTemplate().insert(getCreateSQLId(), t);
    }

    @Override
    public void update(T t)
    {
        getSqlMapClientTemplate().update(getUpdateSQLId(), t);
    }

    @Override
    public void delete(K k)
    {
        getSqlMapClientTemplate().delete(getDeleteSQLId(), k);
    }

    @SuppressWarnings("unchecked")
    @Override
    public T retrieve(K k)
    {
        return (T) getSqlMapClientTemplate().queryForObject(getRetrieveSQLId(), k);
    }
}
