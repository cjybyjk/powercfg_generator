#!/bin/sh

basepath=$(cd $(dirname $0); pwd)

source $basepath/scripts/set_value.sh
get_values

function pause() {
	read -n 1 -p "按任意键继续..."
}

function do_linkto() {
	read -p "输入源SoC:" sourceSoC
	[ -z "$sourceSoC" ] && echo "输入不能为空!" && return
	read -p "输入目标SoCs(使用空格分割):" targetSoC
        [ -z "$targetSoC" ] && echo "输入不能为空!" && return
	target_socs=($targetSoC)
	for i in ${!target_socs[@]}
	do
		$basepath/scripts/linkto.sh ${target_socs[$i]} $sourceSoC
	done
}

function set_linkToData_flag() {
	if [ "$linkToData" = "true" ]; then
		tmpLinkToData=false
	else
		tmpLinkToData=true
	fi
	set_value "linkToData" "$tmpLinkToData"
}

function edit_prjinfo() {
	read -p "输入项目名称(默认为 $project_name):" tmpPrjName
        [ -z "$tmpPrjName" ] || set_value "project_name" "$tmpPrjName"
        read -p "输入项目作者(默认为 $project_author):" tmpPrjAuthor
        [ -z "$tmpPrjAuthor" ] || set_value "project_author" "$tmpPrjAuthor"
}

function rm_all_powercfg() {
	read -p "你确定要这么做? (y/n)" flagYN
	[ "y" = "$flagYN" ] && rm -rf $basepath/project/platforms
}

function mainMenu() {
	while true
	do
		clear
		flagNoPause=false
		read -n 1 -p "powercfg 调度脚本生成工具 VER:$VER
by cjybyjk @ coolapk
License: GPL v3

项目信息:
项目名称: $project_name
项目作者: $project_author

g) 生成powercfg
l) 指定SoCs共用powercfg (linkto)
z) 制作卡刷包
s) 一些设置
d) 删除生成的所有powercfg
x) 退出

请选择一个操作: " selected
		echo ""
		case "$selected" in
			"g") $basepath/scripts/generate_powercfg.sh  ;;
			"z") $basepath/scripts/pack.sh ;;
			"s") settingsMenu ;;
			"l") do_linkto ;;
			"d") rm_all_powercfg ;;
			"x") exit 0 ;;
			*) flagNoPause=true ;;
		esac
		$flagNoPause || pause
	done
}

function settingsMenu() {
	while true
	do
		clear
		flagNoPause=false
		read -n 1 -p "powercfg_generator 设置

s) 查看并编辑支持SoC列表
p) 编辑项目信息
t) 切换 将powercfg软链接到/data ($linkToData)
f) 编辑powercfg模板
x) 返回

请选择一个操作: " selected
		echo ""
		case "$selected" in
			"s") vim $basepath/project/common/list_of_socs ;;
			"l") list_values ;;
			"p") edit_prjinfo;;
			"t") set_linkToData_flag ;;
			"f") vim $basepath/powercfg_template ;;
			"x") flagNoPause=true ; break ;;
			*) flagNoPause=true ;;
		esac
		$flagNoPause || pause
	done
}

mainMenu

