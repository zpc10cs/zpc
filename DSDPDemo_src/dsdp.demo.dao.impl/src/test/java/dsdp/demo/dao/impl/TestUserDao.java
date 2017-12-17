package dsdp.demo.dao.impl;

import java.util.Date;
import java.util.logging.SimpleFormatter;

import org.junit.Test;

import com.huawei.ans.uoa.util.Format;
import com.huawei.jaguar.dsdp.demo.dao.mybatis.impl.UserDaoImpl;
import com.huawei.jaguar.dsdp.demo.domain.User;

public class TestUserDao extends InitSpring {

	  private UserDaoImpl UserDaoImpl = (UserDaoImpl) applicationContext.getBean("dsdpdemo.userDao");
	@Test
	public void testcreate(){
		User user=new User();
		user.setName("zpc");
		user.setSex(1);
		Date birth=new Date();
		Format f=new Format("yymm");
		user.setBirth(birth);
		user.setBirthaddr("zzz");
		UserDaoImpl.create(user);
	}
}
