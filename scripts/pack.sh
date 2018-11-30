#!/bin/sh

basepath=$(cd $(dirname $0); pwd)/../
source $basepath/scripts/util_functions.sh
tmpdir=$basepath/temp
init

read -p "请输入版本号:" prjVer
[ -z $prjVer ] && echo "版本号不能为空" && exit 1
read -p "请输入versionCode:" prjVerCode
[ -z $prjVerCode ] && echo "versionCode不能为空" && exit 1
zipPath="$basepath/flashable/$project_name.installer.$prjVer.zip"
mkdir $basepath/flashable

echo "复制文件..."
mkdir $tmpdir
cd $tmpdir
cp -r $basepath/template/* ./
cp -r $basepath/project/$project_id/* ./
cp $basepath/config/list_of_socs ./common/
rm ./powercfg_template

echo "写入相关信息..."
sed -i "s/(project_author)/$project_author/g" `grep "(project_author)" -rl .`
sed -i "s/(project_id)/$project_id/g" `grep "(project_id)" -rl .`
sed -i "s/(project_name)/$project_name/g" `grep "(project_name)" -rl .`
sed -i "s/(prj_vercode)/$prjVerCode/g" `grep "(prj_vercode)" -rl .`
sed -i "s/(prj_ver)/$prjVer/g" `grep "(prj_ver)" -rl .`

cp ./README.md $basepath/flashable/README_$project_name.md

echo "打包文件..."
zip -r "$zipPath" ./*

echo "清理文件..."
cd $basepath
rm -rf $tmpdir

echo "完成"
pause

exit 0
