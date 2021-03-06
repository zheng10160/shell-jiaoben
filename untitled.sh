#! /bin/bash
#发布脚本
## 严格注意 rsync 同步时需要过滤缓存的文件 不然每次都会有大量文件
#脚本参数
NOW_PATH=$(pwd)

#本地参数
TAGS_PATH=/home/www/admin-sso
ENV=""
TAG=""
BUSINESS=""
TOOL="shell"

#目标服务器参数
REMOTE_IP="106.75.122.206"
REMOTE_ACCOUNT="root"
REMOTE_PATH=/data/www/admin-sso
REMOTE_ROOT_PATH=/data/www  ## 项目根目录
REMOTE_PROJECT_NAME=admin-sso ## 远程项目名称
HTTP_SERVER_ACCOUNT="root" ##远程主机用户
REMOTE_BAK_PATH=/data/project.bak/admin-sso

prefix="============";
aftfix="============>>>";
usage()
{
        echo "usage: -e <test|dev|pro> -b <domain1|domain2> -v <v0.1> -p <file://..> -t <svn|git|shell>";
        echo "tip :: $1";
        exit 1;
}

set_remote_server()
{
        case "$ENV" in
                dev)
                        REMOTE_IP='127.0.0.1';
                        REMOTE_ACCOUNT="root";
                ;;
                test);;
                pro)
                    REMOTE_IP=$REMOTE_IP;
                    REMOTE_ACCOUNT="root";
                ;;
                *) usage "invalid EVN , Please change it in the deploy.sh/set_remote_server";;
        esac;
}

set_remote_path()
{
        case "$BUSINESS" in
            torrent) REMOTE_PATH=/data/www/admin-sso;;
                *) usage "invalid BUSINESS , Please change it in the deploy.sh/set_remote_path";;
        esac;
}

chekc_par()
{
        if [ -z $TAGS_PATH ]
                then
                usage "use -p TAGS_PATH or change it in the deploy.sh file";
        elif [ -z $ENV ]
                then
                usage "-e ENV";
        elif [ -z $TAG ]
                then
                usage "-v TAG";
        elif [ -z $BUSINESS ]
                then
                usage "-b BUSINESS";
        elif [ -z $TOOL ]
                then
                usage "use -t TOOL or change it in the deploy.sh file";
        fi
}

do_deploy()
{
        if [ -z $TAGS_PATH ];then
            echo -e "\n 当前目录下项目目录不存在"
            echo -e "\n ${TAGS_PATH}"
            exit 0
        fi
        #检查文件
        DATE=$(date '+%Y%m%d%H%M%S')
        tmpPath=$TAG"_"$DATE

         #确认发布
        last_check
         read -n1 -p $prefix"Please confirm these release documents, deploy now? [Y|N]"$aftfix -s answer
        case "$answer" in
                Y|y)post_depoly
                    ;;
                *) echo ; exit 0;;
        esac;


        case "$TOOL" in
                #svn) svn export $TAGS_PATH/$TAG $tmpPath > /dev/null &
                #       loop_process "svn check out from $TAGS_PATH/$TAG"
           #       ;;
        #       git)
                #       mkdir -p $tmpPath;
                #       cd $tmpPath;
                #       git init;
                #       git remote add dep $TAGS_PATH;
                #       git pull dep &
                #       loop_process $prefix"git check out from $TAGS_PATH/$TAG"$aftfix;
                #       git checkout $TAG;
                #       rm .git -rf;
                #       ;;
                shell)
                     echo -e "\n 开始远程同步项目"
                     ssh $REMOTE_ACCOUNT@$REMOTE_IP "mkdir -p $REMOTE_PATH"; ## 创建远程备份目录
                     echo -e "\n ---------------------------rsync start---------------------------"
                     rsync -vrut --progress --delete --exclude "messages" --exclude "public/upload"  --exclude "public/uploads" --exclude "public/download" --exclude "deploy"   $TAGS_PATH/* $REMOTE_ACCOUNT@${REMOTE_IP}:${REMOTE_PATH};return 0;;
                *) usage "Please use svn or git to deploy";;
        esac;
        cd $NOW_PATH

        #用户自修改
        #modify_deploy


}

last_check()
{
        echo;
        echo $prefix"deploy list::"$aftfix
        echo $TAGS_PATH|gawk '{printf "%-17s => %-s\n","tag路径",$1}';
        echo $TAG|gawk '{printf "%-19s => %-s\n","tag",$1}';
        echo $ENV|gawk '{printf "%-15s => %-s\n","发布环境",$1}';
        echo $BUSINESS|gawk '{printf "%-15s => %-s\n","发布域名",$1}';
        echo $TOOL|gawk '{printf "%-15s => %-s\n","版本工具",$1}';
        echo $REMOTE_IP|gawk '{printf "%-14s => %-s\n","远程服务器IP",$1}';
        echo $REMOTE_ACCOUNT|gawk '{printf "%-13s => %-s\n","发布使用账户",$1}';
        echo $REMOTE_PATH|gawk '{printf "%-15s => %-s\n","远程路径",$1}';
        echo $HTTP_SERVER_ACCOUNT|gawk '{printf "%-15s => %-s\n","http服务账户",$1}';
        echo;
}

post_depoly()
{       return 0;##ls
        echo;
        echo $prefix"craete remote bak dir"$aftfix;
  ssh $REMOTE_ACCOUNT@$REMOTE_IP "cd $REMOTE_ROOT_PATH && tar czvf $PACKAGE $REMOTE_PROJECT_NAME && mv $REMOTE_ROOT_PATH/$PACKAGE $REMOTE_BAK_PATH"


        #scp $PACKAGE $REMOTE_ACCOUNT@$REMOTE_IP:$REMOTE_PATH/$PACKAGE
        #scp $PACKAGE $REMOTE_ACCOUNT@$REMOTE_IP:$REMOTE_PATH/$PACKAGE
        #ssh $REMOTE_ACCOUNT@$REMOTE_IP "cd $REMOTE_PATH; tar zxvf $PACKAGE --strip-components 1 >> /dev/null "
        #ssh $REMOTE_ACCOUNT@$REMOTE_IP "cd $REMOTE_PATH; rm $REMOTE_PATH/$PACKAGE;chown -R $HTTP_SERVER_ACCOUNT:$HTTP_SERVER_ACCOUNT ./"

        #[修改]log、runtime之类的目录权限
        #ssh $REMOTE_ACCOUNT@$REMOTE_IP "chmod -R 777 $REMOTE_PATH/"
        return 0;
}

modify_deploy()
{
        ssh $REMOTE_ACCOUNT@$REMOTE_IP "sed -i \"s/'password'=>'root'/'password'=>'Aa123.321aA'/g\" /data/www/admin-sso/config/db.php"
        ssh $REMOTE_ACCOUNT@$REMOTE_IP "sed -i \"s/'password'=>'123456'/'password'=>'HelloSenseThink'/g\" /data/www/admin-sso/config/db.php"
         ssh $REMOTE_ACCOUNT@$REMOTE_IP "sed -i 's/http:\/\/local/http:\/\/test/g' /data/www/admin-sso/config/params.php"
        return 0
        #[修改]根据不同框架进行修改
        #echo;
        #echo $prefix"User-defined changes:"$aftfix;
        #mkdir -p $tmpPath/app/Common/Conf/
        #rm $tmpPath/deploy.sh
        #cp app/Common/Conf/config.php $tmpPath/app/Common/Conf/config.php
        #cp ThinkPHP/Library/Org/WeiXin/EncryptUtil.class.php $tmpPath/ThinkPHP/Library/Org/WeiXin/EncryptUtil.class.php
        #cp app/Common/Common/function.php.run $tmpPath/app/Common/Common/function.php
        #mv $tmpPath/index.php.run $tmpPath/index.php
        #rm $tmpPath/index.php.*
}


loop_process()
{
        echo;
        echo $1;
        while [ 1 ]
        do
                job=$(jobs | gawk '!/Running/{print 0}')
                if [ "$job" == "0" ];
                then
                        break;
                fi
                echo -e "..\c";
                sleep 0.5
        done
        echo;
}

##===================##
#说明：
#1：建议至少在脚本中配置(避免每次发布都带上参数)：TAGS_PATH 、TOOL
#2：并且在set_remote_server\set_remote_path中配置不同环境的:REMOTE_IP、REMOTE_ACCOUNT、REMOTE_PATH、HTTP_SERVER_ACCOUNT
#usage:: ./deploy.sh -e test -v 20170504-1658-export-finance-for-admin -b torrent
##==================##

#接收用户输入参数
while getopts p:e:b:t:v: opt
do
        case "$opt" in
                p)TAGS_PATH=${OPTARG};;
                e)ENV=${OPTARG};;
                b)BUSINESS=${OPTARG};;
                v)TAG=${OPTARG};;
                t)TOOL=${OPTARG};;
                *);;
        esac;
done;

#检查基本参数是否存在
chekc_par

#设置服务器连接方式
set_remote_server

#设置目标发布路径
set_remote_path

#发布
do_deploy

if [ $? -eq 0 ]
then
       modify_deploy
        echo "deploy success";
else
        echo "deploy failed";
fi
