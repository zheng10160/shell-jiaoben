#! /bin/bash
#发布脚本
## 严格注意 rsync 同步时需要过滤缓存的文件 不然每次都会有大量文件
#脚本参数
NOW_PATH=$(pwd)

#本地参数
TAGS_PATH=/home/www/mysql_db
TOOL="shell"

#目标服务器参数
REMOTE_IP="106.75.122.206"
REMOTE_ACCOUNT="root"
REMOTE_PATH=/data/www/mysql_db
REMOTE_ROOT_PATH=/data/www  ## 项目根目录
REMOTE_PROJECT_NAME=mysql_db ## 远程项目名称
HTTP_SERVER_ACCOUNT="root" ##远程主机用户
REMOTE_BAK_PATH=/data/project.bak/mysql_db

prefix="============";
aftfix="============>>>";

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
            torrent) REMOTE_PATH=/data/www/mysql_db;;
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
                     rsync -vruta --progress --delete --exclude-from=//home/www/pro_script/exclude-from.list   $TAGS_PATH/* $REMOTE_ACCOUNT@${REMOTE_IP}:${REMOTE_PATH};return 0;;
                *) usage "Please use svn or git to deploy";;
        esac;
        cd $NOW_PATH

        #用户自修改
        #modify_deploy


}


#发布
do_deploy

if [ $? -eq 0 ]
then
       modify_deploy
        echo "deploy success";
else
        echo "deploy failed";
fi
