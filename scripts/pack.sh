#!/bin/sh

basepath="$1"
tmpdir=$basepath/temp

basepath=$(cd $(dirname $0); pwd)

source $basepath/scripts/set_value.sh

read -p "请输入版本号:" prjVer
[ -z $prjVer ] && echo "版本号不能为空" && exit 1
read -p "请输入versionCode:" prjVerCode
[ -z $prjVerCode ] && echo "versionCode不能为空" && exit 1
read -p "请输入zip保存路径(默认为 $basepath/flashable/$project_name.installer.$prjVer.zip):" zipPath
if [ -z $zipPath ]; then
	zipPath="$basepath/flashable/$project_name.installer.$prjVer.zip"
	mkdir $basepath/flashable
	flagCopyReadme=true
fi

echo "复制文件..."
mkdir $tmpdir
cd $tmpdir
cp -r $basepath/project/* ./

echo "写入相关信息..."
sed -i "s/(your_name)/$project_author/g" `grep "(your_name)" -rl .`
sed -i "s/(project_name)/$project_name/g" `grep "(project_name)" -rl .`
sed -i "s/(prj_vercode)/$prjVerCode/g" `grep "(prj_vercode)" -rl .`
sed -i "s/(prj_ver)/$prjVer/g" `grep "(prj_ver)" -rl .`
sed -i "s/\$linkToData/$linkToData/g" ./META-INF/com/google/android/update-binary

if [ $flagCopyReadme ]; then
	echo "复制 README"
	cp ./README.md $basepath/flashable/
fi

echo "打包文件..."
zip -r "$zipPath" ./*

echo "清理文件..."
cd $basepath
rm -rf $tmpdir

echo "完成"

exit 0

