#!/bin/sh

VER="0.0.1"
basepath=$(cd $(dirname $0); pwd)

function runsh() {
	sh "$1" "$basepath" "$2" "$3"
}

function do_linkto() {
	read -p "输入源SoC:" sourceSoC
	[ -z "$sourceSoC" ] && echo "输入不能为空!" && return
	read -p "输入目标SoCs(使用空格分割):" targetSoC
        [ -z "$targetSoC" ] && echo "输入不能为空!" && return
	target_socs=($targetSoC)
	for i in ${!target_socs[@]}
	do
		runsh scripts/linkto.sh ${target_socs[$i]} $sourceSoC
	done
}

function edit_prjinfo() {
	read -p "输入项目名称(默认为 $project_name):" tmpPrjName
        [ -z "$tmpPrjName" ] || sed -i "s/project_name=\"$project_name\"/project_name=\"$tmpPrjName\"/" $basepath/prjinfo.sh
        read -p "输入项目作者(默认为 $project_author):" tmpPrjAuthor
        [ -z "$tmpPrjAuthor" ] || sed -i "s/project_author=\"$project_author\"/project_author=\"$tmpPrjAuthor\"/" $basepath/prjinfo.sh
        source $basepath/prjinfo.sh
}

function rm_all_powercfg() {
	read -p "你确定要这么做? (y/n)" flagYN
	[ "y" = "$flagYN" ] && rm -rf $basepath/project/platforms
}

source $basepath/prjinfo.sh

while true
do
	clear
	flagNoPause=false
	read -n 1 -p "powercfg 调度脚本生成工具 VER:$VER
$prjInfo

g) 生成powercfg
l) 指定SoCs共用powercfg (linkto)
z) 制作卡刷包
s) 查看并编辑支持SoC列表
p) 编辑项目信息
d) 删除生成的所有powercfg
x) 退出

请选择一个操作: " selected
	echo ""
	case "$selected" in
		"g") runsh scripts/generate_powercfg.sh  ;;
		"z") runsh scripts/pack.sh ;;
		"s") vim project/common/list_of_socs ;;
		"l") do_linkto ;;
		"p") edit_prjinfo;;
		"d") rm_all_powercfg ;;
		"x") exit 0 ;;
		*) flagNoPause=true ;;
	esac
	$flagNoPause || read -n 1 -p "按任意键继续..."
done

