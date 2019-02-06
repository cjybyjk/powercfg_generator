#!/bin/sh
# powercfg_generator
# by cjybyjk @ coolapk
# License: GPL v3

basepath=$(cd $(dirname $0); pwd)
cd $basepath
source $basepath/scripts/util_functions.sh

function mainMenu()
{
    while true
    do
        showMenu "
主菜单

g) 生成powercfg
r) 生成所有powercfg
l) 指定SoCs共用powercfg
c) 执行旧生成器兼容性脚本
e) 转换 EX Kernel Manager 配置文件 
z) 制作卡刷包
t) 切换项目
m) 项目管理
s) 设置
x) 退出" "g r l c e z t m s x"
        case $selectedKey in
            "g") check_proj && sh $scripts_path/generate_powercfg.sh ;;
	        "r")
		        check_proj
                if [ $? -eq 0 ]; then
                    cd $projects_path/$project_id/platforms/
                    for socModel in $(ls)
                    do
                        [ -d $socModel ] && sh $scripts_path/generate_powercfg.sh "$socModel" "true"
                    done
                    cd $basepath
                fi
		    ;;
            "l") check_proj && sh $scripts_path/linkto.sh ;;
            "c") check_proj && sh $scripts_path/compat_perf.sh ;;
	        "e") check_proj && sh $scripts_path/exkernel_profile_convert.sh ;;
            "z") check_proj && sh $scripts_path/pack.sh ;;
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

l) 检查(interactive)参数合法性(严重影响生成速度): $param_allowance_check
e) 编辑SoCs列表
d) powercfg调试开关: $powercfg_debug_flag
o) zip卡刷包输出路径: $zip_flashable_outpath
a) 编辑合法参数列表
b) 编辑附加启动列表
p) 编辑powercfg模板
v) 修改文本编辑器: $text_editor
x) 返回" "l e d o a b p v x"
        case $selectedKey in
            "l") write_value "param_allowance_check" `toggle_boolean $param_allowance_check` ;;
            "e") $text_editor $config_path/list_of_socs ;;
            "d") write_value "powercfg_debug_flag" `toggle_boolean $powercfg_debug_flag` ;;
            "o") 
                zip_flashable_outpath=$(readDefault "生成目录" $zip_flashable_outpath)
                write_value "zip_flashable_outpath" $zip_flashable_outpath ;;
            "a") $text_editor $config_path/list_of_allowed_params ;;
            "b") $text_editor $config_path/list_of_bootable ;;
            "p") $text_editor $template_path/powercfg_template ;;
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
    ls "$projects_path" | grep -v "^discarded$"
    local project_id_new=$(readDefault "项目id" $project_id)
    if [ "discarded" = "`trim $project_id_new`" ]; then
        echo "项目ID不允许为 discarded"
	pause
	return 1
    fi
    conf_file=$projects_path/$project_id_new/project_config.sh
    if [ "rm" = "$1" ]; then
        yesNo "你确定这么做吗" || return 0
        rm -rf $projects_path/$project_id_new
        [ "$prjPtr" = "$project_id_new" ] && rm $config_path/project_pointer
        if  yesNo "删除卡刷包?" ; then
            rm -rf $zip_flashable_outpath/$project_id_new
            sed -i "/^|${project_id_new}|/d" $zip_flashable_outpath/README.md
        fi
        return 0
    elif [ "discard" = "$1" ]; then
        yesNo "你确定这么做吗" || return 0
        mkdir -p $zip_flashable_outpath/discarded
        mkdir -p $projects_path/discarded
        mv $projects_path/$project_id_new $projects_path/discarded
        [ "$prjPtr" = "$project_id_new" ] && rm $config_path/project_pointer
        mv $zip_flashable_outpath/$project_id_new $zip_flashable_outpath/discarded/
        sed -i "/^|${project_id_new}|/d" $zip_flashable_outpath/README.md
        echo "|${project_id_new}|$(echo `date`)|" >> $zip_flashable_outpath/discarded/README.md
        return 0
    elif [ "reset" = "$1" ]; then
        yesNo "你确定这么做吗" && rm -rf $projects_path/$project_id_new/platforms
        return 0
    elif [ "toggle" = "$1" ]; then
        if [ -f "$projects_path/$project_id_new/project_config.sh" ]; then
            echo "$project_id_new" > $config_path/project_pointer
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
        [ "$project_id" != "$project_id_new" ] && mv projects/$project_id projects/$project_id_new
        if [ -d "$projects_path/$project_id_new/platforms/" ]; then
            cd $projects_path/$project_id_new/platforms/
            for socModel in $(ls)
            do
                if [ -d $socModel ]; then
                    write_value "project_name" "$project_name_new" "$socModel/powercfg"
                    write_value "project_author" "$project_author_new" "$socModel/powercfg"
                fi
            done
        fi
	    cd $basepath
	    if yesNo "移动卡刷包?" ; then
            mv projects/$project_id projects/$project_id_new
            sed -i "/^|${project_id}|/d" $basepath/flashable/README.md
	    fi
        echo "$project_id_new" > $config_path/project_pointer
    elif [ "new" = "$1" ]; then
        if [ -f projects/$project_id_new/project_config.sh ]; then
            echo "错误: 项目已存在!"
            pause
            return 1
        fi
        mkdir -p projects/$project_id_new/platforms
        touch "$conf_file"
    fi
    write_value "project_name" "$project_name_new" "$conf_file"
    write_value "project_author" "$project_author_new" "$conf_file"
    write_value "project_id" "$project_id_new" "$conf_file"
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
c) 弃用项目(保留存档)
r) 重置项目
x) 返回" "i n d c r x"
        case $selectedKey in
            "i") project_manager modify ;;
            "n") project_manager new ;;
            "d") project_manager rm ;;
            "c") project_manager discard ;;
            "r") project_manager reset ;;
            "x") return 0 ;;
        esac 
    done
}

init
mainMenu
