#!/bin/bash
# powercfg generator
# Author: cjybyjk @ coolapk
# Licence: GPL v3

version="2.0.3"

# $1:name $2:value [$3:conf_file]
function write_value()
{
    [ -z "$(trim $1)" ] && return 1
    [ -z "$(trim $2)" ] && return 1
    local config_file="$3"
    [ -z "$config_file" ] && config_file="$config_path/config.sh"

    local tmp=$(grep "^$1=" $config_file)
    if [ -z "$tmp" ]; then
        echo "$1=\"$2\"" >> "$config_file"
    else
        sed -i "s#^$tmp#$1=\"$2\"#g" "$config_file"
    fi
    return $?
}

# $1:menuText $2:keyList
function showMenu()
{
    [ -z "$1" ] && return 1
    [ -z "$2" ] && return 1
    local menuItems="$1"
    local keyList=($2)
    local selected
    selectedKey=""
    while true
    do
        clear
        echo -e "${generatorInfo}${menuItems}\n"
        read -p "请输入选项: " selected
        selected=$(lcase $selected) 
        for i in ${!keyList[@]}
        do
            if [ "${keyList[$i]}" = "$selected" ]; then
                selectedKey="$selected"
                return 0
            fi
        done
    done
    return 0
}

function pause()
{
    read -n 1 -p "按任意键继续......"
    echo ""
}

# $1:text
function trim()
{
    echo "$1" | sed -e 's/^[ \t]*//g' -e 's/[ \t]*$//g'
}

# convert strings to lower case
function lcase()
{
    echo "$*" | tr '[A-Z]' '[a-z]'
}

# $1:text $2:default value
function readDefault()
{
    local tmpvalue
    read -p "请输入$1 (留空则使用 $2): " tmpvalue
    shift
    [ -z "$(trim $tmpvalue)" ] && tmpvalue="$*"
    echo $tmpvalue
}

function check_proj()
{
	if [ "(未指定)" = "$project_id" ]; then
		echo "错误：未指定项目"
		pause
		return 1
	fi
	return 0
}

# $1:text $2:default(y/n)
function yesNo()
{
    local tmpyn
    if [ "y" = "$(lcase $2)" ]; then
        read -p "$1 (Y/n) : " tmpyn
        [ "n" != "$(lcase $tmpyn)" ] && return 0
    else
        read -p "$1 (y/N) : " tmpyn
        [ "y" = "$(lcase $tmpyn)" ] && return 0
    fi
    return 1
}

# true -> false and false -> true
function toggle_boolean()
{
    if [ "true" = "$1" ]; then
        echo "false"
    else
        echo "true"
    fi
}

# $1:action flag
function project_manager()
{
    [ ! -d "$projects_path" ] && mkdir -p "$projects_path"
    echo "可用项目列表: "
    ls "$projects_path" | grep -v "^discarded$"
    local project_id_new=$(readDefault "项目id" $project_id)
    if [ -z "`echo $project_id_new | egrep '^[a-zA-Z][a-zA-Z0-9\._-]+$'`" ]; then
        echo "项目ID非法! 请确保项目ID符合这个正则表达式:"
        echo '  ^[a-zA-Z][a-zA-Z0-9\._-]+$'
        pause
        return 1
    fi
    if [ "discarded" = "`trim $project_id_new`" ]; then
        echo "项目ID不允许为 discarded"
        pause
        return 1
    fi
    conf_file="$projects_path/$project_id_new/project_config.sh"
    if [ "rm" = "$1" ]; then
        yesNo "你确定这么做吗" || return 0
        rm -rf "$projects_path/$project_id_new"
        [ "$prjPtr" = "$project_id_new" ] && rm "$config_path/project_pointer"
        if  yesNo "删除卡刷包?" ; then
            rm -rf "$zip_flashable_outpath/$project_id_new"
            sed -i "/^|${project_id_new}|/d" "$zip_flashable_outpath/README.md"
        fi
        return 0
    elif [ "discard" = "$1" ]; then
        yesNo "你确定这么做吗" || return 0
        mkdir -p "zip_flashable_outpath/discarded"
        mkdir -p "$projects_path/discarded"
        mv "$projects_path/$project_id_new" "$projects_path/discarded"
        [ "$prjPtr" = "$project_id_new" ] && rm "$config_path/project_pointer"
        mv "$zip_flashable_outpath/$project_id_new" "$zip_flashable_outpath/discarded/"
        sed -i "/^|${project_id_new}|/d" "$zip_flashable_outpath/README.md"
        echo "|${project_id_new}|$(echo `date`)|" >> "$zip_flashable_outpath/discarded/README.md"
        return 0
    elif [ "reset" = "$1" ]; then
        yesNo "你确定这么做吗" && rm -rf "$projects_path/$project_id_new/platforms"
        return 0
    elif [ "toggle" = "$1" ]; then
        if [ -f "$projects_path/$project_id_new/project_config.sh" ]; then
            echo "$project_id_new" > "$config_path/project_pointer"
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
        [ "$project_id" != "$project_id_new" ] && mv "$projects_path/$project_id" "$projects_path/$project_id_new"
        if [ -d "$projects_path/$project_id_new/platforms/" ]; then
            cd "$projects_path/$project_id_new/platforms/"
            local soc_name
            for soc_name in $(ls)
            do
                if [ -d $soc_name ]; then
                    write_value "project_name" "$project_name_new" "$soc_name/powercfg"
                    write_value "project_author" "$project_author_new" "$soc_name/powercfg"
                fi
            done
        fi
	    cd "$basepath"
	    if yesNo "移动卡刷包?" ; then
            mv "$zip_flashable_outpath/$project_id" "$zip_flashable_outpath/$project_id_new"
            sed -i "/^|${project_id}|/d" "$zip_flashable_outpath/README.md"
	    fi
        echo "$project_id_new" > $config_path/project_pointer
    elif [ "new" = "$1" ]; then
        if [ -f "$projects_path/$project_id_new/project_config.sh" ]; then
            echo "错误: 项目已存在!"
            pause
            return 1
        fi
        mkdir -p "$projects_path/$project_id_new/platforms"
        touch "$conf_file"
        write_value "project_name" "$project_name_new" "$conf_file"
        write_value "project_author" "$project_author_new" "$conf_file"
        write_value "project_id" "$project_id_new" "$conf_file"
    fi
    init
    return 0
}

function do_linkto()
{
    local sourceSoC
    local targetSoC
    read -p "输入源SoC:" sourceSoC
    [ -z "$sourceSoC" ] && echo "输入不能为空!" && return
    read -p "输入目标SoCs(使用空格分割):" targetSoC
    [ -z "$targetSoC" ] && echo "输入不能为空!" && return
    local target_socs=($targetSoC)
    local project_path="$project_path/platforms"
    for i in ${!target_socs[@]}
    do
        mkdir -p "$project_path/${target_socs[$i]}"
        echo "$sourceSoC" > "$project_path/${target_socs[$i]}/linkto"
        echo "This platform is ${target_socs[$i]}, but using ${sourceSoC}'s powercfg script." > "$project_path/${target_socs[$i]}/NOTICE"
        echo "linkto: $sourceSoC <- ${target_socs[$i]} "
    done
    pause
}

function make_flashable_zip()
{
    local tmpdir=$basepath/tmp
    local project_version
    local project_version_code
    read -p "请输入版本号:" project_version
    [ -z $project_version ] && echo "版本号不能为空" && exit 1
    read -p "请输入versionCode:" project_version_code
    [ -z $project_version_code ] && echo "versionCode不能为空" && exit 1
    local zip_path="$zip_flashable_outpath/$project_id/$project_id.Installer.$project_version.zip"
    local remover_path="$zip_flashable_outpath/$project_id/$project_id.Remover.zip"
    mkdir -p $zip_flashable_outpath/$project_id

    echo "复制文件..."
    mkdir $tmpdir
    cd $tmpdir
    cp -r "$template_path/*" ./
    cp -r "$project_path/*" ./
    cd ./platforms/
    local soc_name=""
    for soc_name in $(ls)
    do
        if [ -d $soc_name ]; then
            . "$config_path/soc/$soc_name/socinfo.sh"
            let "cluster_num-=1"
            echo "$soc_model:$soc_name:$cluster_num" >> ../common/list_of_soc
        fi
    done
    cd ../
    cp "$config_path/list_of_bootable" ./common/
    echo "写入相关信息..."
    sed -i "s/(project_author)/$project_author/g" `grep "(project_author)" -rl .`
    sed -i "s/(project_id)/$project_id/g" `grep "(project_id)" -rl .`
    sed -i "s/(project_name)/$project_name/g" `grep "(project_name)" -rl .`
    sed -i "s/(prj_vercode)/$project_version_code/g" `grep "(prj_vercode)" -rl .`
    sed -i "s/(prj_ver)/$project_version/g" `grep "(prj_ver)" -rl .`
    sed -i "s/(generator_ver)/$VER/g" `grep "(generator_ver)" -rl .`
    sed -i "/^|${project_id}|/d" $zip_flashable_outpath/README.md
    echo "|${project_id}|${project_name}|${project_author}|${project_version}|$(echo `ls $project_path/platforms`)|" >> $zip_flashable_outpath/README.md

    cp ./README.md $zip_flashable_outpath/$project_id/README.md

    echo "打包文件..."
    zip -r "$zip_path" ./* -x "remover/*"
    cd ./remover
    zip -r "$remover_path" ./*

    echo "清理文件..."
    cd "$basepath"
    rm -rf "$tmpdir"

    echo "完成"
    pause
}

function replace_line()
{
    local templateText
    mv "$3" "${3}.tmp"
    while read -r templateText
	do
		if [ "$templateText" == "$1" ]; then
			echo -e "$2" >> "$3"
		else
			echo "$templateText" >> "$3"
		fi
	done < "${3}.tmp"
    rm "${3}.tmp"
}

function generate_powercfg()
{
    local soc_name="$1"
    [ -z "$soc_name" ] && read -p "输入SoC型号: " soc_name
    local soc_maxfreq=${soc_name##*:}
    soc_name=${soc_name%:*}
    if [ -z "$soc_name" ]; then
        echo "错误：输入不能为空"
		pause
        return 1
    elif [ ! -f "$config_path/soc/$soc_name/socinfo.sh" ]; then
        echo "错误：找不到指定的SoC"
        pause
        return 1
    fi
    if [ ! -z "$soc_maxfreq" ]; then
        tmp_path="$project_path/platforms/$soc_name:$soc_maxfreq"
    else
        tmp_path="$project_path/platforms/$soc_name"
    fi
    mkdir "$tmp_path"
    rm "$tmp_path/powercfg"
    rm "$tmp_path/perf_text.tmp"
    $replace_perf_text && rm "$tmp_path/perf_text"
    cd "$tmp_path"
    cp "$template_path/powercfg_template.sh" powercfg
    cp "$template_path/perf_text_template" perf_text
    $text_editor perf_text
    local cluster_x
    . "$config_path/soc/$soc_name/socinfo.sh"
    . "$config_path/params_map"
    local global_dirs="SCHED_DIR=\"$SCHED_DIR\""
    let "cluster_num-=1"
    for n in $(seq 0 $cluster_num)
    do
        eval cluster_x="$"cluster_${n}
        global_dirs="${global_dirs}\nC${n}_DIR=\"/sys/devices/system/cpu/$cluster_x\"\nC${n}_GOVERNOR_DIR=\"\$C${n}_DIR/cpufreq/$governor\""
        GLOBAL_PARAMS_ADD="${GLOBAL_PARAMS_ADD}\n\${C$n_DIR}/online=1\n\${C$n_DIR}/cpufreq/scaling_governor=\"$governor\""
    done
    replace_line "[GLOBAL_DIRS]" "$global_dirs" powercfg
    
    cp perf_text perf_text.tmp
    for n in $(seq 0 6)
    do
        replace_line "[level $n]" "[level $n]\n$GLOBAL_PARAMS_ADD" perf_text.tmp
    done

    local sysfs_obj
    local param_num=0
    local param_flag=false
    local arr_param
    local arr_name
    local param_vals
    local obj_tmp
    local level=-1
    local OLD_IFS="$IFS" 
    IFS="="

    while read -r lineinText
    do
        [ -z "$lineinText" ] && continue
        [ "${lineinText:0:1}" = "#" ] && continue
        arr_param=""
        # cut string like [level X]
        lineinText="`trim \"$lineinText\"`"
        if [ "${lineinText:0:1}" = "[" ] && [ "${lineinText:0-1:1}" = "]" ]; then
            level="${lineinText:0-2:1}"
            if ! $param_flag && [ "$param_num" -gt 0 ] ; then
                replace_line "[sysfs_obj]" "$sysfs_obj" powercfg
                sysfs_obj=""
                write_value "PARAM_NUM" "$param_num" powercfg
                param_flag=true
            fi
            param_vals="${param_vals}\n"
            param_num=0
            continue
        fi
        let "param_num+=1"
        arr_param=($lineinText)
        if ! $param_flag ; then
            IFS=","
            arr_name=(${arr_param[0]})
            eval obj_tmp="$"${arr_name[0]}
            if [ "${obj_tmp:0:1}" = "$" ]; then
                obj_tmp=${arr_name[0]}
            else
                obj_tmp=${obj_tmp//"[GOVERNOR_DIR]"/"\$C${arr_name[1]}_GOVERNOR_DIR"}
                obj_tmp=${obj_tmp//"[CPU_DIR]"/"\$C${arr_name[1]}_DIR"}
            fi
            sysfs_obj="${sysfs_obj}\n\$sysfs_obj$param_num=\"$obj_tmp\""
            IFS="="
        fi
        param_vals="${param_vals}level${level}_val$param_num=${arr_param[1]}\n"
    done < ./perf_text.tmp
    replace_line "[levels]" "$param_vals" powercfg
    IFS="$OLD_IFS"
    rm ./perf_text.tmp
    
    write_value "project_name" "$project_name" powercfg
    write_value "project_author" "$project_author" powercfg
    write_value "generate_date" "$(date)" powercfg
    if [ ! -z "$soc_maxfreq" ]; then
        write_value "soc_name" "$soc_name:$soc_maxfreq" powercfg
    else
        write_value "soc_name" "$soc_name" powercfg
    fi
    echo "$soc_name 生成完毕"
}

function mainMenu()
{
    while true
    do
        showMenu "
主菜单

g) 生成powercfg
r) 生成所有powercfg
l) 指定SoCs共用powercfg
z) 制作卡刷包
m) 项目管理
s) 设置
x) 退出" "g r l z m s x"
        case $selectedKey in
            "g") 
                check_proj && generate_powercfg
                [ $? -eq 0 ] && pause
            ;;
            "r") check_proj
                if [ $? -eq 0 ]; then
                    cd $project_path/platforms/
                    local soc_name=""
                    for soc_name in $(ls)
                    do
                        [ -d $soc_name ] && generate_powercfg $soc_name
                    done
                    cd $basepath
                    pause
                fi
                ;;
            "l") check_proj && do_linkto ;;
            "z") check_proj && make_flashable_zip ;;
            "m") prjManageMenu ;;
            "s") settingsMenu ;;
            "x") exit 0 ;;
        esac
    done
}

function settingsMenu()
{
    while true
    do
        showMenu "
设置

e) 编辑参数映射表
g) 修改调速器: $governor
l) 使用中文版template: $use_template_cn
r) 生成时覆盖perf_text: $replace_perf_text
o) zip卡刷包输出路径: $zip_flashable_outpath
b) 编辑附加启动列表
p) 编辑powercfg模板
v) 修改文本编辑器: $text_editor
x) 返回" "e g l r o b p v x"
        case $selectedKey in
            "e") $text_editor "$config_path/params_map" ;;
            "g") 
                 governor=$(readDefault "调速器" "$governor")
                 write_value "governor" "$governor" ;;
            "l")
                 use_template_cn=$(toggle_boolean $use_template_cn)
                 write_value "use_template_cn" $use_template_cn ;;
            "r")
                 replace_perf_text=$(toggle_boolean $replace_perf_text)
                 write_value "replace_perf_text" $replace_perf_text ;;
            "o") 
                 zip_flashable_outpath=$(readDefault "生成目录" $zip_flashable_outpath)
                 write_value "zip_flashable_outpath" $zip_flashable_outpath ;;
            "b") $text_editor "$config_path/list_of_bootable" ;;
            "p") $text_editor "$template_path/powercfg_template.sh" ;;
            "v")
                 text_editor=$(readDefault "编辑器" "$text_editor")
                 write_value "text_editor" "$text_editor" ;;
            "x") return 0 ;;
        esac 
    done
}


function prjManageMenu()
{
    while true
    do
        showMenu "
项目管理

t) 切换项目
i) 修改项目信息
n) 新建项目
d) 删除项目
c) 弃用项目
r) 重置项目
x) 返回" "t i n d c r x"
        case $selectedKey in
            "t") project_manager toggle ;;
            "i") project_manager modify ;;
            "n") project_manager new ;;
            "d") project_manager rm ;;
            "c") project_manager discard ;;
            "r") project_manager reset ;;
            "x") return 0 ;;
        esac
    done
}

function init()
{
    config_path="$basepath/config"
    . "$config_path/config.sh"
    projects_path="$basepath/projects"
    project_id="(未指定)"
    [ -f "$config_path/project_pointer" ] && prjPtr=$(cat $config_path/project_pointer)
    [ -f "$projects_path/$prjPtr/project_config.sh" ] && . "$projects_path/$prjPtr/project_config.sh"
    project_path="$projects_path/$project_id"
    if $use_template_cn ; then
        template_path="$basepath/template_cn"
    else
        template_path="$basepath/template"
    fi
    generatorInfo="powercfg_generator version:$version
by cjybyjk @ coolapk
License: GPL v3

当前项目: $project_id
  项目名称：$project_name
  项目作者：$project_author
"
}

basepath="$(cd $(dirname $0); pwd)"
cd "$basepath"
init

mainMenu

exit 0
