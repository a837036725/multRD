# multRD
Modify the dll file to make windows10 support multi-person login for remote desktop

win10远程桌面破解脚本

#install为破解主程序，程序会从termsrv文件夹读取需要用到的dll文件，格式为：termsrv.dll.版本号

#若后续版本更新可添加相应的文件，并在安装时手动输入版本号

#若脚本提示需要选择是否允许，请输入Y并按回车即可

#在安装时会自动备份dll文件为dll.bak，若已存在dll.bak，会生成带时间的dll.bak避免重名


#uninstall为恢复脚本，会将dll.bak替代dll，若有多个版本并想恢复指定版本的dll请手动至C:\Windows\System32重命名termsrv.dll_yyyy_mm_dd_hh_.bak为termsrv.dll.bak

###请注意：###

！！！！！termservice服务未必能正常关闭，但不妨碍安装进行，强烈建议安装或复原后进行重启！！！！！

###测试是成功###

用管理员权限打开cmd并添加测试账户（若有可跳过创建）：

net user test password /add
net localgroup "remote desktop users" test /add

打开远程桌面：
mstsc

输入地址测试：127.0.0.2
用刚才创建的账户登录
若能成功登录，则证明成功

删除测试账号：
net user test /del
