package com.huawei.jaguar.dsdp.demo.service.dsf.impl;

import com.huawei.jaguar.dsdp.demo.dao.mybatis.ItemDao;
import com.huawei.jaguar.dsdp.demo.domain.Item;
import com.huawei.jaguar.dsdp.demo.service.dsf.ItemService;
import com.huawei.jaguar.dsdp.demo.service.request.CreateItemRequest;
import com.huawei.jaguar.dsdp.demo.service.request.DeleteItemRequest;
import com.huawei.jaguar.dsdp.demo.service.request.RetrieveItemRequest;
import com.huawei.jaguar.dsdp.demo.service.request.UpdateItemRequest;
import com.huawei.jaguar.dsdp.demo.service.response.CreateItemResponse;
import com.huawei.jaguar.dsdp.demo.service.response.DeleteItemResponse;
import com.huawei.jaguar.dsdp.demo.service.response.RetrieveItemResponse;
import com.huawei.jaguar.dsdp.demo.service.response.UpdateItemResponse;

public class ItemServiceImpl implements ItemService
{
    private ItemDao itemDao;

    public void setItemDao(ItemDao itemDao)
    {
        this.itemDao = itemDao;
    }

    @Override
    public CreateItemResponse create(CreateItemRequest createItemRequest)
    {
        itemDao.create(createItemRequest.getItem());
        CreateItemResponse createItemResponse = new CreateItemResponse();
        createItemResponse.setResult(true);
        return createItemResponse;
    }

    @Override
    public UpdateItemResponse update(UpdateItemRequest updateItemRequest)
    {
        itemDao.update(updateItemRequest.getItem());
        UpdateItemResponse updateItemResponse = new UpdateItemResponse();
        updateItemResponse.setResult(true);
        return updateItemResponse;
    }

    @Override
    public DeleteItemResponse delete(DeleteItemRequest deleteItemRequest)
    {
        itemDao.delete(deleteItemRequest.getItemId());
        DeleteItemResponse deleteItemResponse = new DeleteItemResponse();
        deleteItemResponse.setResult(true);
        return deleteItemResponse;
    }

    @Override
    public RetrieveItemResponse retrieve(RetrieveItemRequest retrieveItemRequest)
    {
        Item item = itemDao.retrieve(retrieveItemRequest.getItemId());
        RetrieveItemResponse retrieveItemResponse = new RetrieveItemResponse();
        retrieveItemResponse.setItem(item);
        return retrieveItemResponse;
    }
}
