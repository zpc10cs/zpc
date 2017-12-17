/*
 * 文 件 名:  LogUtil.java
 * 版    权:  Huawei Technologies Co., Ltd. Copyright YYYY-YYYY,  All rights reserved
 * 描    述:  <描述>
 * 修 改 人:  w00255795
 * 修改时间:  2015年2月6日
 * 跟踪单号:  <跟踪单号>
 * 修改单号:  <修改单号>
 * 修改内容:  <修改内容>
 */
package com.huawei.jaguar.commons.bootstrap.util;

/**
 * <一句话功能简述>
 * <功能详细描述>.
 * 
 * @author  w00255795
 * @version  [版本号, 2015年2月6日]
 * @see  [相关类/方法]
 * @since  [产品/模块版本]
 */
public class LogUtil
{
    /** The Constant FROMATLENGTH. */
    public static final int FROMAT_LENGTH = 80;
    
    /** The Constant EQUAL. */
    public static final String EQUAL = "=";
    
    /** The Constant DOT. */
    public static final String DOT = ".";
    
    /** The Constant PERCENT. */
    public static final String PERCENT = "%";
    
    /** The Constant COST_STR. */
    public static final String COST_STR = " [cost % ms]";
    
    /**
     * Padding str.
     * 
     * @param orgStrBegin the org str begin
     * @param orgStrEnd the org str end
     * @param fillStr the fill str
     * @param formatLength the format length
     * @return the string
     */
    public static String paddingStr(String orgStrBegin, String orgStrEnd, String fillStr, int formatLength)
    {
        StringBuffer sb = new StringBuffer();
        sb.append(orgStrBegin);
        
        int length = 0;
        if (null != orgStrBegin)
        {
            length += orgStrBegin.getBytes().length;
        }
        
        if (null != orgStrEnd)
        {
            length += orgStrEnd.getBytes().length;
        }
        
        int pad = formatLength - length;
        for (int i = 0; i < pad; i++)
        {
            sb.append(fillStr);
        }
        
        sb.append(orgStrEnd);
        
        return sb.toString();
    }
}