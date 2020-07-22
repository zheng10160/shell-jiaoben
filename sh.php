#!/bin/bash
################################################
#   Todo:自动部署项目代码。
#   Author:xiaozheng
################################################

ip="106.75.122.206" ## 远程服务器地址

#local_base_dir = /home/www/a ## 本地项目整个目录

#app_base_dir = /data/www/  ## 远程项目根目录

#app_name = av ## 线上项目名称

#bak_dir = /data/project.bak／a/ ##线上项目打包备份目录

local_base_dir = /Applications/senseplay/ttt/a/ ## 本地项目整个目录

app_base_dir = /home/www/  ## 远程项目根目录

app_name = av ## 线上项目名称

bak_dir = /home/www/project.bak／a/ ##线上项目打包备份目录

cat <<update
    +------------------------------------------+
    +                 U) 发布项目               +
    +                 C) 回退上一版本            +
    +                 Q) 退出                   +
    +------------------------------------------+
    update

    read -p "请输入 (U|C|Q) ,再按ENTER键: " INPUT ##选择操作

if [ $INPUT = "U"];then
    backup
    rsync_project

elif [ $INPUT ="C" ];then


elif [ $INPUT ="Q" ];then
echo "\n ---------------bye bye--------------"
    exit 0
else
    exit 0

fi

##备份在线项目函数 打包
function backup()
{
    ## 如果备份目录下存在备份包 需要展示最后一次文件修改
    last_bak_filename=`ls $bak_dir -ltr | tail -1 | awk '{print $NF}'`

    if [ $last_bak_filename = "" ]
        echo "\n please input 0.0.1"
    else
       echo "\n 当前版本为 $last_bak_filename"
     fi

    read -p "请输入 新升级版本号[ x.x.x ] ,再按ENTER键: " VER ##选择操作

    if [ ! -z ${app_base_dir}${app_name} ];then
        echo "\n first one sync project,no have project pack"
        return 0
    else
        ssh root@${ip} "tar -zcvf $app_base_dir$app_name-${VER}.tar.gz $app_base_dir$app_name && mkdir -p $bak_dir && mv $app_base_dir$app_name.tar.gz $bak_dir;rm -rf $app_base_dir$app_name-${VER}.tar.gz"
        return 1
    fi
}


##备份完成 使用rsync 同步项目
function rsync_project()
{
    echo -e "\e[1;33m\n-----------rsync  from $ip------------\e[0m"
    rsync -vrtL --progress $local_base_dir/* root@${ip}:${app_base_dir}${app_name}
    echo -e "\e[1;32m\n------rsync success--------\e[0m\n"
}


