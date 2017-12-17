package com.huawei.jaguar.dsdp.demo.dao.mybatis;

/**
 * 通用DAO层接口。
 *
 * <h1>主要功能：</h1>
 * <p>
 * 提供基本的增删改查功能。
 * </p>
 *
 * @version DSDP V500R005C00, 2016年4月26日
 * @author z00297102
 * @since DSDP V500R005C00
 * @param <T> 对象类型
 * @param <K> 主键类型
 */
public interface GenericDao<T, K>
{
    /**
     * 新增对象接口。
     *
     * <h1>主要功能：</h1>
     * <p>
     * 该函数用于新增对象。
     * </p>
     * 
     * @param t 要新增的对象
     * @since V500R005C00B040
     * @author z00297102
     */
    void create(T t);

    /**
     * 修改对象接口。
     *
     * <h1>主要功能：</h1>
     * <p>
     * 该函数用于修改对象。
     * </p>
     * 
     * @param t 要修改的对象
     * @since V500R005C00B040
     * @author z00297102
     */
    void update(T t);

    /**
     * 删除对象接口。
     *
     * <h1>主要功能：</h1>
     * <p>
     * 该函数用于删除对象。
     * </p>
     * 
     * @param k 要删除的对象的主键
     * @since V500R005C00B040
     * @author z00297102
     */
    void delete(K k);

    /**
     * 查询对象接口。
     *
     * <h1>主要功能：</h1>
     * <p>
     * 该函数用于查询对象。
     * </p>
     * 
     * @param k 要查询的对象的主键
     * @return 查询到的对象
     * @since V500R005C00B040
     * @author z00297102
     */
    T retrieve(K k);
}
