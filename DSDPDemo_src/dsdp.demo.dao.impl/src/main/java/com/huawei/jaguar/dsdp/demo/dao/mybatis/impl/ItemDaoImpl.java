package com.huawei.jaguar.dsdp.demo.dao.mybatis.impl;

import com.huawei.jaguar.dsdp.demo.dao.mybatis.ItemDao;
import com.huawei.jaguar.dsdp.demo.domain.Item;

public class ItemDaoImpl extends GenericDaoImpl<Item, Long> implements ItemDao
{
    private static final String CREATE_SQL_ID = "dsdpdemo.item.create";
    private static final String UPDATE_SQL_ID = "dsdpdemo.item.update";
    private static final String DELETE_SQL_ID = "dsdpdemo.item.delete";
    private static final String RETRIEVE_SQL_ID = "dsdpdemo.item.retrieve";

    @Override
    protected String getCreateSQLId()
    {
        return CREATE_SQL_ID;
    }

    @Override
    protected String getUpdateSQLId()
    {
        return UPDATE_SQL_ID;
    }

    @Override
    protected String getDeleteSQLId()
    {
        return DELETE_SQL_ID;
    }

    @Override
    protected String getRetrieveSQLId()
    {
        return RETRIEVE_SQL_ID;
    }
}
