package com.huawei.jaguar.dsdp.demo.dao.mybatis;

import com.huawei.jaguar.dsdp.demo.domain.User;
import com.huawei.jaguar.dsdp.demo.domain.UserCond;

public interface UserDao {

    /**
     * 新增用户信息接口。
     *
     * <h1>主要功能：</h1>
     * <p>
     * 该函数用于新增一个用户信息。
     * </p>
     * 
     * @param t 要新增的对象
     * @since V500R005C20B010
     * @author zpc
     */
	void create(User user);
    /**
     * 删除用户信息接口。
     *
     * <h1>主要功能：</h1>
     * <p>
     * 该函数用于删除一个用户信息。
     * </p>
     * 
     * @param t 要删除的对象
     * @since V500R005C20B010
     * @author zpc
     */
	void delete(UserCond userCond);
    /**
     * 更新用户信息接口。
     *
     * <h1>主要功能：</h1>
     * <p>更新新增一个用户信息。
     * </p>
     * 
     * @param t 要更新的对象
     * @since V500R005C20B010
     * @author zpc
     */
	void update(User user);
    /**
     * 查询用户信息接口。
     *
     * <h1>主要功能：</h1>
     * <p>
     * 该函数用于查询一个用户信息。
     * </p>
     * 
     * @param t 要查询的对象
     * @since V500R005C20B010
     * @author zpc
     */
	String  query(UserCond userCond);

}
