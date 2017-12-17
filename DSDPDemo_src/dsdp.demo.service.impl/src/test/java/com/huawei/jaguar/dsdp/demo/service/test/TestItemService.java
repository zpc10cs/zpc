package com.huawei.jaguar.dsdp.demo.service.test;

import java.util.Date;

import org.junit.Assert;
import org.junit.Test;

import com.huawei.jaguar.dsdp.demo.domain.Item;
import com.huawei.jaguar.dsdp.demo.service.dsf.ItemService;
import com.huawei.jaguar.dsdp.demo.service.request.CreateItemRequest;
import com.huawei.jaguar.dsdp.demo.service.request.DeleteItemRequest;
import com.huawei.jaguar.dsdp.demo.service.request.RetrieveItemRequest;
import com.huawei.jaguar.dsdp.demo.service.request.UpdateItemRequest;
import com.huawei.jaguar.dsdp.demo.ut.frame.BaseTestCase;

public class TestItemService extends BaseTestCase
{
    private ItemService itemService = (ItemService) ctx.getBean("dsdpdemo.itemService");

    @Test
    public void testCRUD()
    {
        long itemId = new Date().getTime();
        String itemName = "Item one";
        double itemPrice = 2.01;
        Item item = new Item(itemId, itemName, itemPrice);
        CreateItemRequest createItemRequest = new CreateItemRequest();
        createItemRequest.setItem(item);
        itemService.create(createItemRequest);

        RetrieveItemRequest retrieveItemRequest = new RetrieveItemRequest();
        retrieveItemRequest.setItemId(itemId);
        item = itemService.retrieve(retrieveItemRequest).getItem();
        Assert.assertEquals(itemId, item.getItemId().longValue());
        Assert.assertEquals(itemName, item.getItemName());
        Assert.assertEquals(itemPrice, item.getItemPrice().doubleValue(), 0);
        Assert.assertNotNull(item.getCreateTime());
        Assert.assertNull(item.getLastUpdateTime());

        String itemNameUpdate = "item one updated";
        double itemPriceUpdate = 3.02;
        item.setItemName(itemNameUpdate);
        item.setItemPrice(itemPriceUpdate);
        UpdateItemRequest updateItemRequest = new UpdateItemRequest();
        updateItemRequest.setItem(item);
        itemService.update(updateItemRequest);

        item = itemService.retrieve(retrieveItemRequest).getItem();
        Assert.assertEquals(itemId, item.getItemId().longValue());
        Assert.assertEquals(itemNameUpdate, item.getItemName());
        Assert.assertEquals(itemPriceUpdate, item.getItemPrice().doubleValue(), 0);
        Assert.assertNotNull(item.getCreateTime());
        Assert.assertNotNull(item.getLastUpdateTime());

        DeleteItemRequest deleteItemRequest = new DeleteItemRequest();
        deleteItemRequest.setItemId(itemId);
        itemService.delete(deleteItemRequest);
        item = itemService.retrieve(retrieveItemRequest).getItem();
        Assert.assertNull(item);
    }
}
