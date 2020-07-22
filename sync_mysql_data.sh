#!/bin/bash 
################################################
#   Todo:自动部署项目代码。
################################################

################################################
# 已经存在的项目名称
project_list='权限管理(rbac) keymap管理(keymap) 厂商管理(manufacture) 资源文件管理(resoure) 版本升级管理(ota)
 售后服务(service) anti_fake 小车参数管理(car_param) club 数据采集(post)'
################################################

################################################
# 当前存在的环境地质
env_list='++++ test(QA测试环境) | staging(在线冒烟) | production(生产环境) +++'
################################################

################################################
#数据库列表 详情
##db list
db_list_str="car_param club dacq dev event hardware rbac senseplay service senseplay sp_pst ota"
db_list=(car_param club dacq dev event hardware rbac senseplay service senseplay sp_pst ota)
################################################

#######
#oldtime 保留几天以内的数据库备份文件
oldtime=`date -d -7day +'%Y%m%d'` ## 默认为七天
#######

env_name='' ##环境名称
##s输出前缀
prefix="============";
aftfix="============>>>";

#Todo:  打印日志
#Param: logInfo(日志信息)

#目标服务器参数
REMOTE_IP=""
REMOTE_ACCOUNT="root"
HTTP_SERVER_ACCOUNT="root" ##远程主机用户

projectName="" ##项目名称
logPath="`pwd`/logs"
RootPath="/data/sql/import" ##sql文件存放顶级目录   /data/sql + 项目名称 ／ +环境 ／+库名称 ／xx.sql

backupDataPath='/data/sql/backup' ## 数据库备份文件目录

mysqlDataLogSqlFile='/data/sql/log' ## 导入成功后的sql文件 会被迁移走 到log历史目录

updateMysqlFilePath="" ##需要更新的文件存放目录

tarsqlname=".tar.gz" ##压缩文件名称

#数据库主机地址
#host=""
#数据库用户名
username=""
#数据库密码
password=""
#数据库名
dbname=""
#数据库sql文件
#sqlFile=""

##请输入项目名称 根据项目名称判断文件目录是否存在 2
inputProjectName()
{
	printf "++------ %s ------++\n" $project_list
	read  -p $prefix"Please enter the name of the project that exists ！"$aftfix  projectName


	  #如果文件夹不存在，创建文件夹 ssh $REMOTE_ACCOUNT@$REMOTE_IP
	    if [ ! -d $RootPath/$projectName ]; then ## 本地操作
	    ##if [ "ssh $REMOTE_ACCOUNT@$REMOTE_IP -d $RootPath/$projectName" ]; then ## 远程操作
	   	 echo -e "1.检查你的远程文件目录是否存在\n"
	   	 echo -e "2.输入的项目名称不存在"
          exit -1;
	fi
}

## 请输入需要更新的环境  1
inputEnvironment()
{
	echo env_list;
	echo 'usage: -e < test | staging | pro >';
    read  -p $prefix"Please select the environment that needs to be updated ！"$aftfix  env_name

	if [ $env_name = "test" ];then
	 	REMOTE_IP='106.75.122.206';

	elif [ $env_name = "staging" ];then
		##REMOTE_IP='106.75.37.77' ##老得staging
		REMOTE_IP='106.75.93.33'

	elif [ $env_name = "pro" ];then
		REMOTE_IP='106.75.98.162'
	else
		 echo -e "你输入的环境名称有误，只能在给出的名称中选择\n";
		 exit -1;
	fi
}

## 选择对应的数据库 3
inputSelectMysqlDb()
{
	printf "========== databases ============"
	printf "++++++++++ %s +++++++++++\n" $db_list_str
	printf "============== END ==============="

	read -p $prefix"Select the database to operate on ！"$aftfix dbname


	if echo "${db_list_str[@]}" | grep -w "$dbname" &>/dev/null; then
	    echo "dbname select successful \n"
	else
		 echo "选择的数据库不存在  \n"
		 exit -1;
	fi
	#for i in ${db_list[@]}
	#do
	#   if [ "$i" -n "$dbname" ]; then
	#  	#statements
	#   	echo "输入的库名必须是当前给出的";
	#  	exit
	#   fi
	#done

    updateMysqlFilePath=$RootPath/$projectName/$env_name/$dbname
	## 判断组装的文件目录是否存在
	 ##if [ "ssh $REMOTE_ACCOUNT@$REMOTE_IP -d $updateMysqlFilePath" ]; then ## 远程操作
	 if [ ! -d $updateMysqlFilePath ]; then ## 本地操作
	   	 echo -e "1.检查你的远程文件目录是否存在 env or dbname \n"
	   	 echo -e "2.输入的项目名称不存在"
           exit -1;
	fi
}

## 备份数据库 4
backdatabase()
{
	read -p $prefix"请输入数据库登录账号:"$aftfix username

	read -p $prefix"请输入数据库登录密码:"$aftfix password
        #进行备份操作
        #备份的地质
        back_address_path=$backupDataPath/$projectName/$env_name/$dbname
    local date_path_name="`date '+%Y-%m-%d %H:%M:%S'`_DatabaseName.sql"

    mysqldump -u"${username}" -p"${password}" -h "${REMOTE_IP}" ${dbname} > $back_address_path/$date_path_name
    #将生成的SQL文件压缩
    tar zcf $back_address_path/$date_path_name$tarsqlname $back_address_path/$date_path_name &> /dev/null

    ##备份成功后删除 文件
    rm -rf $back_address_path/$date_path_name
} 

#Todo:  更新数据库
#Param: host(数据库主机地址),username(数据库用户名),password(数据库密码),dbname(数据库名),sqlFile(数据库sql文件)
updateSql()
{
	local p=$RootPath/$projectName/$env_name/$dbname ## 文件操作目录

	local logSqlPath=$mysqlDataLogSqlFile/$projectName/$env_name/$dbname ## sql文件迁移的历史文件目录

 	if [ -z $username ];then
        echo "[ERROR] Usage:updateSql host username password dbname sqlFile"
     
         exit -1;
    fi 

    if [ -z $password ];then
        echo "[ERROR] Usage:updateSql host username password dbname sqlFile"
     
        exit -1;
    fi 

	if [ "`ls -A ${p}`" = "" ];
	then 
	        echo "${p} is empty,终止后续操作";
	        exit -1;
	fi
	cd $p;
	for f in `ls $p/*.sql`
	do
	echo "++++++正在导入: ${f} 文件++++";
	## mysql -u $username -p$password -f $dbname -e "source $f";
	mysql -u"${username}" -p"${password}" -h "${REMOTE_IP}" ${dbname} < $f
	mv $f $logSqlPath; ## 导入成功后需要迁移当前目录文件
	done

    printf "!!!!!!更新的sql文件已经导入,为了确保准确性,需要核对更新的地方!!!!!!!\n"
}

## 删除数据库备份文件 目前定义七天以内
# delMysqlBackupFile()
# {
#	#参数解释
#	#   filepath：文件目录字符串，以英文;隔离
#	#   oldtime：天数，保留多少天以内的文件
#	local back_address_path=$backupDataPath/$projectName/$env_name/$dbname
#
#    echo "删除7天前的备份文件[${back_address_path}/${oldtime}]\n"
#    rm -rf ${back_address_path}/${delTime}
#    printf "删除7天前的备份文件[${back_address_path}/${oldtime}]\n"
#
# }

## 1.选择环境
inputEnvironment
## 2.选择项目名称
inputProjectName
## 3.选择库
inputSelectMysqlDb
## 4.更新之前先备份操作的库
backdatabase
## 5.更新数据操作
updateSql
## 6。删除数据库备份文件 历史数据
## delMysqlBackupFile

echo "==============脚本执行结束 END===============\n";

