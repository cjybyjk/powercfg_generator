#!/bin/sh
# powercfg_generator
# by cjybyjk @ coolapk
# License: GPL v3

basepath=$(cd $(dirname $0); pwd)
cd $basepath
source scripts/util_functions.sh

function mainMenu()
{
    while true
    do
        showMenu "
主菜单

g) 生成powercfg
l) 指定SoCs共用powercfg
c) 执行旧生成器兼容性脚本
e) 转换 EX Kernel Manager 配置文件 
z) 制作卡刷包
t) 切换项目
m) 项目管理
s) 设置
x) 退出" "g l c e z t m s x"
        case $selectedKey in
            "g") sh scripts/generate_powercfg.sh ;;
            "l") sh scripts/linkto.sh ;;
            "c") sh scripts/compat_perf.sh ;;
	    "e") sh scripts/exkernel_profile_convert.sh ;;
            "z") sh scripts/pack.sh ;;
            "t") project_manager toggle ;;
            "m") prjManageMenu ;;
            "s") settingMenu ;;
            "x") exit 0 ;;
        esac
    done
}

function settingMenu()
{
    while true
    do
        init
        showMenu "
设置

l) 检查(interactive)参数合法性: $param_allowance_check
e) 编辑SoCs列表
a) 编辑合法参数列表
b) 编辑附加启动列表
p) 编辑powercfg模板
v) 修改文本编辑器: $text_editor
x) 返回" "l e a b p v x"
        case $selectedKey in
            "l") write_value "param_allowance_check" `toggle_boolean $param_allowance_check` ;;
            "e") $text_editor config/list_of_socs ;;
            "a") $text_editor config/list_of_allowed_params ;;
            "b") $text_editor config/list_of_bootable ;;
            "p") $text_editor template/powercfg_template ;;
            "v")
                text_editor=$(readDefault "编辑器" $text_editor)
                write_value "text_editor" $text_editor ;;
            "x") return 0 ;;
        esac 
    done
}

# $1:action flag
function project_manager()
{
    echo "可用项目列表: "
    ls "$basepath/projects"
    local project_id_new=$(readDefault "项目id" $project_id)
    if [ "rm" = "$1" ]; then
        yesNo "你确定这么做吗" || return 0
        rm -rf projects/$project_id_new
        [ "$prjPtr" = "$project_id_new" ] && rm config/project_pointer
	if [ yesNo "删除卡刷包?" ]; then
		rm -rf projects/$project_id_new
		sed -i "/^|${project_id_new}|/d" $basepath/flashable/README.md
	fi
        return 0
    elif [ "reset" = "$1" ]; then
        yesNo "你确定这么做吗" && rm -rf projects/$project_id_new/platforms
        return 0
    elif [ "toggle" = "$1" ]; then
        if [ -f "projects/$project_id_new/project_config.sh" ]; then
            echo "$project_id_new" > config/project_pointer
            init
        else
            echo "错误: 项目不存在!"
            pause
        fi 
        return 0
    fi
    local project_name_new=$(readDefault "项目名称" "$project_name")
    local project_author_new=$(readDefault "项目作者" "$project_author")
    if [ "modify" = "$1" ]; then
        mv projects/$project_id projects/$project_id_new
        echo "$project_id_new" > config/project_pointer
    elif [ "new" = "$1" ]; then
        if [ -f projects/$project_id_new/project_config.sh ]; then
            echo "错误: 项目已存在!"
            pause
            return 1
        fi
        mkdir -p projects/$project_id_new
        touch projects/$project_id_new/project_config.sh
    fi
    write_value "project_name" "$project_name_new" "$project_id_new"
    write_value "project_author" "$project_author_new" "$project_id_new"
    write_value "project_id" "$project_id_new" "$project_id_new"
    init
}

function prjManageMenu()
{
    while true
    do
        showMenu "
项目管理

i) 修改项目信息
n) 新建项目
d) 删除项目
r) 重置项目
x) 返回" "i n d r x"
    case $selectedKey in
            "i") project_manager modify ;;
            "n") project_manager new ;;
            "d") project_manager rm ;;
            "r") project_manager reset ;;
            "x") return 0 ;;
        esac 
    done
}

init
mainMenu
