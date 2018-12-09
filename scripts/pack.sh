#!/bin/sh

basepath=$(cd $(dirname $0); pwd)/../
source $basepath/scripts/util_functions.sh
tmpdir=$basepath/temp
init

read -p "请输入版本号:" prjVer
[ -z $prjVer ] && echo "版本号不能为空" && exit 1
read -p "请输入versionCode:" prjVerCode
[ -z $prjVerCode ] && echo "versionCode不能为空" && exit 1
zipPath="$basepath/flashable/$project_name/$project_name.Installer.$prjVer.zip"
removerPath="$basepath/flashable/$project_name/$project_name.Remover.zip"
mkdir -p $basepath/flashable/$project_name

echo "复制文件..."
mkdir $tmpdir
cd $tmpdir
cp -r $basepath/template/* ./
cp -r $basepath/projects/$project_id/* ./
cp $basepath/config/list_of_socs ./common/
cp $basepath/config/list_of_socs ./remover/
rm ./powercfg_template
rm ./project_config.sh

echo "写入相关信息..."
sed -i "s/(project_author)/$project_author/g" `grep "(project_author)" -rl .`
sed -i "s/(project_id)/$project_id/g" `grep "(project_id)" -rl .`
sed -i "s/(project_name)/$project_name/g" `grep "(project_name)" -rl .`
sed -i "s/(prj_vercode)/$prjVerCode/g" `grep "(prj_vercode)" -rl .`
sed -i "s/(prj_ver)/$prjVer/g" `grep "(prj_ver)" -rl .`
sed -i "s/(generator_ver)/$VER/g" `grep "(generator_ver)" -rl .`
sed -i "|${project_id}|${project_name}|${project_author}/d" $basepath/flashable/README.md
echo "|${project_id}|${project_name}|${project_author}|${prjVer}|$(echo `ls $basepath/projects/$project_id/platforms`)|" >> $basepath/flashable/README.md

cp ./README.md $basepath/flashable/$project_name/README.md

echo "打包文件..."
zip -r "$zipPath" ./* -x "remover/*"
cd ./remover
zip -r "$removerPath" ./*

echo "清理文件..."
cd $basepath
rm -rf $tmpdir

echo "完成"
pause

exit 0
