package com.huawei.jaguar.dsdp.demo.domain;

import java.io.Serializable;
import java.util.Date;

public class User implements Serializable {

	/**
	 * User对象。
	 *
	 * <h1>主要功能：</h1>
	 * <p>
	 * 定义User对象模型。
	 * </p>
	 *
	 * @version DSDP V500R005C20, 2017年8月31日 
	 * @author zpc
	 * @since DSDP V500R005C20
	 */
	private static final long serialVersionUID = 7184228912736130304L;

	private String name;
	private Integer sex;
	private Date birth ;
	private String birthaddr;
	
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	public Integer getSex() {
		return sex;
	}
	public void setSex(Integer sex) {
		this.sex = sex;
	}
	public Date getBirth() {
		return birth;
	}
	public void setBirth(Date birth) {
		this.birth = birth;
	}
	public String getBirthaddr() {
		return birthaddr;
	}
	public void setBirthaddr(String birthaddr) {
		this.birthaddr = birthaddr;
	}
	public static long getSerialversionuid() {
		return serialVersionUID;
	}
	public String toString(){
		StringBuilder buider=new StringBuilder();
		buider.append(name);
		buider.append(sex);
		buider.append(birthaddr);
		buider.append(birth);
		return buider.toString();
		
	}
}
