package com.huawei.jaguar.dsdp.demo.dao.mybatis.health;

/**
 * 数据库健康检查的DAO层接口。
 *
 * <h1>主要功能：</h1>
 * <p>
 * 定义检查数据库连接的接口。
 * </p>
 *
 * <h1>BeanID：</h1>
 * <p>
 * dsdpdemo.dbHealthDao
 * </p>
 * 
 * @version DSDP V500R005C00, 2016年4月26日
 * @author z00297102
 * @since DSDP V500R005C00
 */
public interface DBHealthDao
{
    /**
     * 检查连接是否正常。
     *
     * <h1>主要功能：</h1>
     * <p>
     * 该函数用于检查数据库连接是否正常。
     * </p>
     * 
     * @return 数据库连接状态，true代表连接正常，反之返回false
     * @since V500R005C00B040
     * @author z00297102
     */
    boolean checkAlive();
}
