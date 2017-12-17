#用户和组件的MAP,用于页面展示
#格式：用户名:'组件1,组件2:用户密码:用户家目录'
default_user_config_dic = {
    "dsdp":'TAG,UPM,SNS,MQ,CGW,PAYMENT,CHARGING,ORDER,SUBSCRIPTION,PRODUCT,CONTENT,PLMF,publicinfo,CHANNELMGMT,CAMPAIGN,MARKETINGMGMT:sRom6FFR2fNYUFjM/a34qg==:/home/dsdp',
	"lca":'LOGAgent:Kgv1kw5K7z9sqEcdwJ5Dzg==:/home/lca'
    }

#数据库用户和组件的MAP，用于页面展示
#格式：数据库用户:'组件1,组件2:密码'    
default_db_user_config_dic = {
    "sysdb":'PAYMENT,CGW:sys_Db123',
    "pmtdb":'PAYMENT: pmt_Db123',
    "chgdb":'CAMPAIGN,CHARGING:chg_Db123',
    "cntdb":'CONTENT:cnt_Db123',
    "subdb":'SUBSCRIPTION:sub_Db123',
    "orddb":'ORDER:ord_Db123',
    "prodb":'PRODUCT:pro_Db123',
    "pubdb":'publicinfo:pub_Db123', 
	"upmdb":'UPM:upm_123',	
	"tagdb":'TAG:tag_Db123',
	"mgmtdb":'MARKETINGMGMT:mgmt_Db123',
	"channeldbdb":'CHANNELMGMT:channel_Db123',
	"dsdpdemodb":'DSDPDEMO:sub_Db123'
    }    