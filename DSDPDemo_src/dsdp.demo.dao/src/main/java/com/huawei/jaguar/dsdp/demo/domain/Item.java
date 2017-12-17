package com.huawei.jaguar.dsdp.demo.domain;

import java.io.Serializable;
import java.util.Date;

/**
 * Item对象。
 *
 * <h1>主要功能：</h1>
 * <p>
 * 定义Item对象模型。
 * </p>
 *
 * @version DSDP V500R005C00, 2016年4月26日
 * @author z00297102
 * @since DSDP V500R005C00
 */
public class Item implements Serializable
{
    private static final long serialVersionUID = -385213349175321827L;

    /**
     * 商品ID
     */
    private Long itemId;

    /**
     * 商品名称
     */
    private String itemName;

    /**
     * 商品价格
     */
    private Double itemPrice;

    /**
     * 创建时间
     */
    private Date createTime;

    /**
     * 上次更新时间
     */
    private Date lastUpdateTime;

    public Item()
    {
    }

    public Item(Long itemId, String itemName, Double itemPrice)
    {
        this.itemId = itemId;
        this.itemName = itemName;
        this.itemPrice = itemPrice;
    }

    public Long getItemId()
    {
        return itemId;
    }

    public void setItemId(Long itemId)
    {
        this.itemId = itemId;
    }

    public String getItemName()
    {
        return itemName;
    }

    public void setItemName(String itemName)
    {
        this.itemName = itemName;
    }

    public Double getItemPrice()
    {
        return itemPrice;
    }

    public void setItemPrice(Double itemPrice)
    {
        this.itemPrice = itemPrice;
    }

    public Date getCreateTime()
    {
        return createTime;
    }

    public void setCreateTime(Date createTime)
    {
        this.createTime = createTime;
    }

    public Date getLastUpdateTime()
    {
        return lastUpdateTime;
    }

    public void setLastUpdateTime(Date lastUpdateTime)
    {
        this.lastUpdateTime = lastUpdateTime;
    }

    @Override
    public String toString()
    {
        StringBuilder builder = new StringBuilder();
        builder.append("Item [itemId=");
        builder.append(itemId);
        builder.append(", itemName=");
        builder.append(itemName);
        builder.append(", itemPrice=");
        builder.append(itemPrice);
        builder.append(", createTime=");
        builder.append(createTime);
        builder.append(", lastUpdateTime=");
        builder.append(lastUpdateTime);
        builder.append(']');
        return builder.toString();
    }
}
