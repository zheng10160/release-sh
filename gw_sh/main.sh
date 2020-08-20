#!/bin/bash
## 该路径地址 根据自己的脚本位置定义

SCRIPT_PATH="/data/gw_sh" ## 脚本存放目录
. ${SCRIPT_PATH}/help/fun.sh ## 帮助函数

## 项目根目录 这里注意 远程与本地目录结构应该相同
ROOT_PATH="/data/www"
#本地参数
TAGS_PATH=""
ENV="" ## test环境
TAG=""
BUSINESS=""
TOOL="shell"

## 远程
REMOTE_IP="" ## 远程地址
REMOTE_ACCOUNT="root" ## 远程登录用户
HTTP_SERVER_ACCOUNT="root"
REMOTE_BAK_PATH="/data/project.bak" ## 远程备份根目 $dir / $projectName

every_project_filter_list="project_filter_list" ## 某个项目都有一份过滤列表清单  

replace_config_dir="replace_config" ## 在线替换的一些内容

projectName="" ## 项目名称

project_version_log="project_version_log" ## 记录每个版本当前的版本号 目录

prefix="============";
aftfix="============>>>";

## 检验输入的参数 是否正确
chekc_par()
{
       TAGS_PATH=${ROOT_PATH}/${projectName}
        if [ -z $TAGS_PATH ]
                then
                echoColor red "缺少本地原始路径地址"
                 exit -1
        elif [ -z $ENV ]
                then
                echoColor red "发布环境地质不明确 < test | staging | pro >"
                 exit -1
        elif [ -z $projectName ]
                then
               echoColor red "发布的项目名称不能为空,请核对"
                 exit -1
        elif [ -z $TAG ]
                then
                 echoColor red "发布项目的版本信息不能为空 EG:v0.0.1"
                 exit -1
        fi
}


## 根据输入的 -e 参数 设置当前环境
set_env_config()
{
    if [ $ENV = "test" ];then
        REMOTE_IP='127.0.0.1';

    elif [ $ENV = "staging" ];then
    
        REMOTE_IP='127.0.0.2'

    elif [ $ENV = "pro" ];then
        REMOTE_IP='127.0.0.3'
    else
          echoColor red "你输入的环境名称有误，只能在给出的名称中选择 < test | staging | pro > \n"
         exit -1;
    fi
}


## 发布的提示信息 1
last_check()
{
        local current_ver="" ## 上一次版本名称

        if [ ! -f $project_version_log/$projectName ]; then ## 检测是否存在历史版本 log信息 如果没有说明是第一次版本 可以默认为 v0.0.1
            ##if [ "ssh $REMOTE_ACCOUNT@$REMOTE_IP -d $RootPath/$projectName" ]; then ## 远程操作
             current_ver='初始版本' ## 第一没有历史版本 为出事版本
        else
            current_ver=`cat "$project_version_log/$projectName"`
        fi

        echo;
        echo $prefix"deploy list::"$aftfix
        printf "%-17s => %-s\n" "本地项目路径" $TAGS_PATH;
        printf "%-19s => %-s\n" "上一次版本" $current_ver;
        printf "%-15s => %-s\n" "发布环境" $ENV;
        printf "%-15s => %-s\n" "发布脚本工具" "shell";
        printf "%-14s => %-s\n" "远程服务器IP" $REMOTE_IP;
        printf "%-13s => %-s\n" "发布使用账户" $HTTP_SERVER_ACCOUNT;
        printf "%-15s => %-s\n" "远程路径" "${ROOT_PATH}/${projectName}";
        # echo $HTTP_SERVER_ACCOUNT|gawk '{printf "%-15s => %-s\n","http服务账户",$1}';
        echo;

}

## 备份老的项目
backup_depoly()
{       
        local remote_project_address="$ROOT_PATH/$projectName" ## 远程项目地址
        local remote_backup_project_address="$REMOTE_BAK_PATH/$projectName" ## 远程备份项目地址

        local DATE=$(date '+%Y%m%d%H%M%S')
         echo;
         echoColor blue $prefix"create remote bak dir"$aftfix"\n";
    
        ssh $REMOTE_ACCOUNT@$REMOTE_IP "mkdir -p $REMOTE_BAK_PATH/$projectName && chmod -R 777 $REMOTE_BAK_PATH/$projectName" ## 创建远程备份目录 

        pre_ver=`cat "$project_version_log/$projectName"`
        
        if [ -z pre_ver ];then
            return 0;
        fi
        
        PACKAGE="${pre_ver}"_"${DATE}.tar.gz"; ## 备份的版本名称
        #tar czvf $PACKAGE $tmpPath > /dev/null &
         echoColor blue "\n $prefix 压缩历史版本 $aftfix";
       
        ssh $REMOTE_ACCOUNT@$REMOTE_IP "cd $ROOT_PATH && tar czvf $PACKAGE $remote_project_address && mv ${ROOT_PATH}/${PACKAGE} $remote_backup_project_address"
        #scp $PACKAGE $REMOTE_ACCOUNT@$REMOTE_IP:$REMOTE_PATH/$PACKAGE
        #scp $PACKAGE $REMOTE_ACCOUNT@$REMOTE_IP:$REMOTE_PATH/$PACKAGE
        #ssh $REMOTE_ACCOUNT@$REMOTE_IP "cd $REMOTE_PATH; tar zxvf $PACKAGE --strip-components 1 >> /dev/null "
        #ssh $REMOTE_ACCOUNT@$REMOTE_IP "cd $REMOTE_PATH; rm $REMOTE_PATH/$PACKAGE;chown -R $HTTP_SERVER_ACCOUNT:$HTTP_SERVER_ACCOUNT ./"

        #[修改]log、runtime之类的目录权限
        #ssh $REMOTE_ACCOUNT@$REMOTE_IP "chmod -R 777 $REMOTE_PATH/"
         echoColor green "\n $prefix 备份成功 $aftfix";

         echo $PACKAGE > "${project_version_log}/${projectName}.log" ## 件备份包写入 log文件 当回退版本时会用到
        return 0;
}


## 发布项目
do_deploy()
{
        if [ ! -d $TAGS_PATH ];then
            echoColor yellow "\n 当前目录下项目目录不存在"
            echoColor yellow "\n ${TAGS_PATH}"
             exit -1;
        fi

        local filter_file="${every_project_filter_list}/${projectName}-from.list" ## 过滤文件名
        ## 当过滤文件不存在的时候 系统自动创建文件  过滤的文件只需添加在文件中
        if [  ! -f "${filter_file}" ];then
            touch "${filter_file}" && chmod 777 "${filter_file}"
        fi
        #检查文件
        DATE=$(date '+%Y%m%d%H%M%S')
        tmpPath=$TAG"_"$DATE

         read -n1 -p $prefix"Please confirm these release documents, deploy now? [Y|N]"$aftfix -s answer
        case "$answer" in
                Y|y)backup_depoly
                    ;;
                *) echo ; exit 0;;
        esac;


        case "$TOOL" in
                shell)
                     echoColor blue "\n 开始远程同步项目";
                      ssh $REMOTE_ACCOUNT@$REMOTE_IP "mkdir -p ${ROOT_PATH}/${projectName}"; ## 创建远程备份目录
                      echoColor blue "\n ---------------------------rsync start---------------------------";

                     rsync -vrut --progress --delete --exclude-from="${SCRIPT_PATH}/${filter_file}"   $TAGS_PATH/* $REMOTE_ACCOUNT@${REMOTE_IP}:${ROOT_PATH}/${projectName}; return 0;;
                       ## 项目同步成功之后 需要改写版本log 文件。更新
                *) usage "Please use shell to deploy";;
        esac;
        ## cd $NOW_PATH
       
}

## 项目发布成功后 需要在线替换一些配置文件的内容
remote_replace_deploy()
{
       
        local replae_config_file="${replace_config_dir}/${projectName}.sh"

        if [ ! -f $replae_config_file ];then
            return 0
        fi

        sh "${replace_config_dir}/${projectName}.sh" -h ${REMOTE_IP} -u $REMOTE_ACCOUNT ## 执行配置文件替换

        return 0
}

## 回退版本
backup_deploy()
{
       read -n1 -p $prefix"你确认回退上一版本吗? [Y|N]"$aftfix -s log_name
        case "$log_name" in
                Y|y)fallback_project
                    ;;
                *) echo ; exit 0;;
        esac;
}

## 回退项目到上一个版本
## 注意每次发布之后只能回退版本一次
fallback_project()
{
    local backProject="${project_version_log}/${projectName}.log" ## 该文件记录上一次的备份版本名称

    if [ ! -f $backProject ];then
         echoColor red "\n --亲！你没有历史版本,不能回退,如果不能解决你的问题,只能人工手动去解决----"
         exit -1
    fi

    ## 判断文件是否为空 为空的话无法进行回退版本
    if [ -s $backProject ]; then
        echo "hi"
    else
        echoColor red "\n --亲！你没有历史版本,不能回退,如果不能解决你的问题,只能人工手动去解决----"
         exit -1
    fi

    local ver_name=`cat "$backProject"` ## 获取版本号

    ssh $REMOTE_ACCOUNT@$REMOTE_IP "rm -rf ${ROOT_PATH}/${projectName}" ## 先删除在线版本

    ## 流程  先将备份文件迁移到项目根目  在解压包。   在将包文件删除
    ssh $REMOTE_ACCOUNT@$REMOTE_IP "cd $REMOTE_BAK_PATH && cp -r ${ver_name} $ROOT_PATH/ && tar zxvf ${ROOT_PATH}/${ver_name} && rm -rf ${ROOT_PATH}/${ver_name}"

    ## 回退成功后 需要将版本回退log 信息删除  不能重复回退两次
    echo "" >  $backProject ## 写入空数据

     echoColor green "\n --亲！回退上一版本成功----"
}


#接收用户输入参数
while getopts p:e:b:v: opt
do
        case "$opt" in
                p)TAGS_PATH=${OPTARG};;
                e)ENV=${OPTARG};;
                b)projectName=${OPTARG};;
                v)TAG=${OPTARG};;
                *);;
        esac;
done;

## 后续流程
cat <<update
+------------------------------------------+
+                 U) 发布项目               +
+                 C) 回退上一版本            +
+                 Q) 退出                   +
+------------------------------------------+
update

read -p "请输入 (U|C|Q) ,再按ENTER键: " INPUT ##选择操作

if [ $INPUT = "U" ];then
    ## 发布项目流程

    ## 检验输入参数
    chekc_par

    ## 根据 -e 设置远程ip
    set_env_config

    ## 显示发布时相关信息
    last_check

    ## 发布项目 
    do_deploy

      ## 1.将当前的版本号写入log
    echo $TAG > $project_version_log/$projectName; ## 当前版本log

      #用户自修改
    remote_replace_deploy 

     echoColor green "\n ---------------亲！你的项目发布成功----------------------"

    echoColor blue "为了确保发布成功 1.可以检查备份文件是否备份成功 2.检查更新的功能或者文件是否成功"

elif [ $INPUT = "C" ];then
   ## 版本回退流程
   #last_check ## 提示当前发布相关信息

   ## 回退版本操作
   backup_deploy

elif [ $INPUT = "Q" ];then
echo "\n ---------------bye bye--------------"
    exit 0
else
    exit 0

fi



