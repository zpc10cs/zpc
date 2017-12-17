package dsdp.demo.dao.impl;

import org.springframework.context.ApplicationContext;
import org.springframework.context.support.ClassPathXmlApplicationContext;

public class InitSpring {
	 public   ApplicationContext applicationContext = new ClassPathXmlApplicationContext(
	            "dsdp/demo/spring/dsdp.demo.dao.service.xml");
}
