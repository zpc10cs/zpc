package com.huawei.jaguar.dsdp.demo.dao.mybatis.impl;

import org.springframework.orm.ibatis.support.SqlMapClientDaoSupport;

import com.huawei.jaguar.dsdp.demo.dao.mybatis.UserDao;
import com.huawei.jaguar.dsdp.demo.domain.User;
import com.huawei.jaguar.dsdp.demo.domain.UserCond;

public class UserDaoImpl extends SqlMapClientDaoSupport implements UserDao {

	private static final String CREATE_USER = "user.create";
	private static final String DELETE_USER = "user.delete";
	private static final String UPDATE_USER = "user.update";
	private static final String QUERY_USER = "user.query";

	@Override
	public void create(User user) {

		getSqlMapClientTemplate().insert(CREATE_USER, user);
	}

	@Override
	public void delete(UserCond userCond) {
		getSqlMapClientTemplate().delete(DELETE_USER, userCond);
	}

	@Override
	public void update(User user) {
		getSqlMapClientTemplate().update(UPDATE_USER, user);
	}

	@Override
	public String query(UserCond userCond) {
		getSqlMapClientTemplate().queryForObject(QUERY_USER, userCond);
		return null;
	}

}
