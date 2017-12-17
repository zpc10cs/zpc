package com.huawei.jaguar.dsdp.demo.service.dfx.alarm;

/**
 * 告警ID。
 *
 * <h1>主要功能：</h1>
 * <p>
 * 定义告警ID枚举值
 * </p>
 *
 * @version DSDP V500R005C00, 2016年3月22日
 * @author z00297102
 * @since DSDP V500R005C00
 */
public interface AlarmID
{
    /**
     * 数据库连接异常ID
     */
    long ORACLE_EXCEPTION_ID = 208141001L;

    /**
     * CPU告警ID
     */
    long CPU_EXCEPTION_ID = 208141002L;
    /**
     * Mem告警ID
     */
    long MEM_EXCEPTION_ID = 208141003L;
    /**
     * Redis连接异常ID
     */
    long REDIS_EXCEPTION_ID = 208141005L;

    /**
     * Zookeeper连接异常ID
     */
    long ZOOKEEPER_EXCEPTION_ID = 208141006L;

}
