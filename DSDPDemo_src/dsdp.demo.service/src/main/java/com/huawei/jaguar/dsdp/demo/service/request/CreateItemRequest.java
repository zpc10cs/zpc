package com.huawei.jaguar.dsdp.demo.service.request;

import java.io.Serializable;

import com.huawei.jaguar.dsdp.demo.domain.Item;

/**
 * 创建Item请求。
 *
 * <h1>主要功能：</h1>
 * <p>
 * 定义创建Item请求模型。
 * </p>
 *
 * @version DSDP V500R005C00, 2016年4月26日
 * @author z00297102
 * @since DSDP V500R005C00
 */
public class CreateItemRequest implements Serializable
{
    private static final long serialVersionUID = 7069498351174987367L;

    /**
     * Item对象
     */
    private Item item;

    public Item getItem()
    {
        return item;
    }

    public void setItem(Item item)
    {
        this.item = item;
    }

    @Override
    public String toString()
    {
        StringBuilder builder = new StringBuilder();
        builder.append("CreateItemRequest [item=");
        builder.append(item);
        builder.append(']');
        return builder.toString();
    }
}
