package com.huawei.jaguar.dsdp.demo.domain;

public class UserCond {

	private String name;

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}
	@Override
	public String toString(){
		StringBuilder builder=new StringBuilder();
		builder.append(name);
		
		return builder.toString();
	}
}
