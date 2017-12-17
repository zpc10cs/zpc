package com.huawei.jaguar.dsdp.demo.service.request;

import java.io.Serializable;

/**
 * 删除Item请求。
 *
 * <h1>主要功能：</h1>
 * <p>
 * 定义删除Item请求。
 * </p>
 *
 * @version DSDP V500R005C00, 2016年4月26日
 * @author z00297102
 * @since DSDP V500R005C00
 */
public class DeleteItemRequest implements Serializable
{
    private static final long serialVersionUID = -95877063697475684L;

    /**
     * Item ID
     */
    private Long itemId;

    public Long getItemId()
    {
        return itemId;
    }

    public void setItemId(Long itemId)
    {
        this.itemId = itemId;
    }

    @Override
    public String toString()
    {
        StringBuilder builder = new StringBuilder();
        builder.append("DeleteItemRequest [itemId=");
        builder.append(itemId);
        builder.append(']');
        return builder.toString();
    }
}
