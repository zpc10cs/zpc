package com.huawei.jaguar.dsdp.demo.service.response;

import java.io.Serializable;

/**
 * 创建Item响应。
 *
 * <h1>主要功能：</h1>
 * <p>
 * 定义创建Item响应。
 * </p>
 *
 * @version DSDP V500R005C00, 2016年4月26日
 * @author z00297102
 * @since DSDP V500R005C00
 */
public class CreateItemResponse implements Serializable
{
    private static final long serialVersionUID = -2281187488704790529L;

    /**
     * 结果
     */
    private Boolean result;

    public Boolean getResult()
    {
        return result;
    }

    public void setResult(Boolean result)
    {
        this.result = result;
    }

    @Override
    public String toString()
    {
        StringBuilder builder = new StringBuilder();
        builder.append("CreateItemResponse [result=");
        builder.append(result);
        builder.append("]");
        return builder.toString();
    }
}
