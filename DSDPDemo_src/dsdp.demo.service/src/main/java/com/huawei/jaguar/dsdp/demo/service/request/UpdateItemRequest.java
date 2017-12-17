package com.huawei.jaguar.dsdp.demo.service.request;

import java.io.Serializable;

import com.huawei.jaguar.dsdp.demo.domain.Item;

/**
 * 更新Item请求。
 *
 * <h1>主要功能：</h1>
 * <p>
 * 定义更新Item请求。
 * </p>
 *
 * @version DSDP V500R005C00, 2016年4月26日
 * @author z00297102
 * @since DSDP V500R005C00
 */
public class UpdateItemRequest implements Serializable
{
    private static final long serialVersionUID = -8743741470689114905L;

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
        builder.append("UpdateItemRequest [item=");
        builder.append(item);
        builder.append(']');
        return builder.toString();
    }
}
