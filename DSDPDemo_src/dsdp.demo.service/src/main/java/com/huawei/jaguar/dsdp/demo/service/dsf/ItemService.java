package com.huawei.jaguar.dsdp.demo.service.dsf;

import com.huawei.jaguar.dsdp.demo.service.request.CreateItemRequest;
import com.huawei.jaguar.dsdp.demo.service.request.DeleteItemRequest;
import com.huawei.jaguar.dsdp.demo.service.request.RetrieveItemRequest;
import com.huawei.jaguar.dsdp.demo.service.request.UpdateItemRequest;
import com.huawei.jaguar.dsdp.demo.service.response.CreateItemResponse;
import com.huawei.jaguar.dsdp.demo.service.response.DeleteItemResponse;
import com.huawei.jaguar.dsdp.demo.service.response.RetrieveItemResponse;
import com.huawei.jaguar.dsdp.demo.service.response.UpdateItemResponse;

/**
 * Item服务接口。
 *
 * <h1>主要功能：</h1>
 * <p>
 * 定义Item的增删改查等方法。
 * </p>
 *
 * <h1>BeanID：</h1>
 * <p>
 * dsdp.itemService
 * </p>
 * 
 * @version DSDP V500R005C00, 2016年4月26日
 * @author z00297102
 * @since DSDP V500R005C00
 */
public interface ItemService
{
    /**
     * 创建Item。
     *
     * <h1>主要功能：</h1>
     * <p>
     * 该函数用于创建Item。
     * </p>
     * 
     * @param createItemRequest 创建Item请求
     * @return 创建Item响应
     * @since V500R005C00B040
     * @author z00297102
     */
    CreateItemResponse create(CreateItemRequest createItemRequest);

    /**
     * 更新Item。
     *
     * <h1>主要功能：</h1>
     * <p>
     * 该函数用于更新Item。
     * </p>
     * 
     * @param updateItemRequest 更新Item请求
     * @return 更新Item响应
     * @since V500R005C00B040
     * @author z00297102
     */
    UpdateItemResponse update(UpdateItemRequest updateItemRequest);

    /**
     * 删除Item。
     *
     * <h1>主要功能：</h1>
     * <p>
     * 该函数用于删除Item。
     * </p>
     * 
     * @param deleteItemRequest 删除Item请求
     * @return 删除Item响应
     * @since V500R005C00B040
     * @author z00297102
     */
    DeleteItemResponse delete(DeleteItemRequest deleteItemRequest);

    /**
     * 查询Item。
     *
     * <h1>主要功能：</h1>
     * <p>
     * 该函数用于查询Item。
     * </p>
     * 
     * @param retrieveItemRequest 查询Item请求
     * @return 查询Item响应
     * @since V500R005C00B040
     * @author z00297102
     */
    RetrieveItemResponse retrieve(RetrieveItemRequest retrieveItemRequest);
}
