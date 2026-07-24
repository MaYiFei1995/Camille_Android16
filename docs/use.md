# 目录

* [使用](#使用)
* [输出堆栈信息文件](#输出堆栈信息文件)
* [延迟hook](#延迟hook)
* [使用attach hook](#使用attach)
* [选择Hook模块](#选择Hook模块)
* [指定设备](#指定设备)
* [自定义hook接口](#自定义hook接口)
* [是否同意隐私政策](#是否同意隐私政策)
* [跳过隐私政策检测](#跳过隐私政策检测)
* [加载外部脚本](#加载外部脚本)
* [指定Frida-sever](#指定Frida-sever)
* [Frida 17.x 脚本编译](#frida-17x-脚本编译)
* [PyInstaller 打包二进制可执行文件](#PyInstaller打包二进制可执行文件)

# 使用：

```
python camille.py com.zhengjim.myapplication
```

![img.png](../images/img1.png)

`com.zhengjim.myapplication`为测试app的包名，会显示时间、行为和调用堆栈。可以根据场景来判断是否合规，如：获取敏感信息是否是在同意隐私政策之前等。

# 输出堆栈信息文件

```
python camille.py com.zhengjim.myapplication -ns -f demo01.xls
```

- -ns：不显示日志。默认显示
- -f： 保存app行为轨迹(堆栈信息)到execl里。默认不保存。

![img.png](../images/img2.png)

# 延迟hook

```
python camille.py com.zhengjim.myapplication -t 3
```

- -t： hook应用自己的函数或含壳时，建议使用setTimeout并给出适当的延时(1-5s，需要根据不同app进行调整)。以免hook失败。默认不延迟。

如下图：不加延迟hook失败。

![img.png](../images/img3.png)

加了延迟hook成功。

![img_1.png](../images/img4.png)

# 使用attach

- -ia：使用attach hook

假如还是hook不上，可以使用`-ia`，指定包名或运行进程ID。 有些包有同名进程，frida会hook失败，需要使用进程ID。

找进程ID，进入安卓运行`ps -A | grep com.zhengjim.myapplication`

![img_6.png](../images/img6.png)

# 选择Hook模块

- -u： 扫描指定模块。与命令`-nu`互斥。多个模块用','隔开。例如：phone,permission

**模块列表：**

| 模块名 | 备注 |
| ------ | ------ |
|permission|申请权限|
|phone|电话、基站|
|system|系统信息(AndroidId/标识/content敏感信息)|
|app|其他app信息|
|location|位置信息|
|network|getNetwork|
|camera|照相机|
|bluetooth|蓝牙|
|file|文件|
|media|麦克风|
|sensor|传感器|
|custom| 用户自定义接口|

- -nu：跳过扫描指定模块。与命令`-u`互斥。多个模块用','隔开。例如：phone,permission 模块列表同上

# 指定设备

```
python camille.py com.zhengjim.myapplication -s emulator-5556
```

- -s：指定连接设备，可通过 `adb devices` 获取设备 id

# 自定义hook接口

在`script.js`文件里的`customHook`方法里可自行添加需要hook的接口。

如hook`com.zhengjim.myapplication.HookTest`类的`getPassword`和`getUser`方法。如下：

```
hook('com.zhengjim.myapplication.HookTest', [
    {'methodName': 'getPassword', 'action': action, 'messages': '获取zhengjim密码'},
    {'methodName': 'getUser', 'action': action, 'messages': '获取zhengjim用户名'},
]);
```

如果需要过滤参数，使用args参数，如下，只记录参数为`android_id`：
```
hook('android.provider.Settings$Secure', [
    {'methodName': 'getString', 'args': [ 'android_id' ], 'action': action, 'messages': '获取安卓ID'}
]);
```

`-u custom`是只检测自定义接口，如图：
![img.png](../images/img5.png)

# 是否同意隐私政策

**手机设置要打开USB模拟按键点击开关**

默认开启， 如不需要改功能加`-npp` 参数关闭（不开启的话就默认是同意隐私合规后）。采用半自动模式，启动后会弹出当前屏幕。

![img.png](../images/img7.png)

同意隐私协议请`鼠标左键`点击对应同意位置如无隐私协议，如不是隐私协议界面继续获取屏幕请按键盘`n`, 退出请按`q`

![img.png](../images/img8.png)

![img.png](../images/img9.png)

查看报告

![img.png](../images/img10.png)

# 指定Frida-sever

- -H: 指定Frida-sever

对抗Frida检测，换端口启动，配合[hluda server](https://github.com/CrackerCat/strongR-frida-android) 使用，可过很多检测。hluda server更改了frida的很多特征。

服务端：
```
./hlu15 -l 0.0.0.0:30000
# 转发端口
adb forward tcp:30000 tcp:30000
```

使用：
```
python camille.py com.zhengjim.myapplication -H 127.0.0.1:30000
```

![img.png](../images/img11.png)

# 跳过隐私政策检测

> 本节及以下新增章节（加载外部脚本、Frida 17.x 脚本编译）由 AI 辅助生成。

- -npp：跳过隐私协议检测

不需要同意隐私协议流程，默认状态为已同意隐私合规后。适用于不需要检测隐私协议前后行为的场景，或目标应用没有隐私协议弹窗的情况。

```
python camille.py com.zhengjim.myapplication -npp
```

> 注意：使用 `-ia`（attach 模式）时也会自动跳过隐私协议检测。

# 加载外部脚本

- -es：加载外部 frida 脚本文件

默认加载项目目录下的 `script_compiled.js`（如存在）或 `script.js`。可以通过 `-es` 指定自定义脚本路径，支持相对路径和绝对路径。

```
python camille.py com.zhengjim.myapplication -es /path/to/my_script.js
```

# Frida 17.x 脚本编译

frida 17.x 起，Python API 不再自动包含 Java bridge。如果直接使用 `script.js`，会报 `ReferenceError: 'Java' is not defined`。

项目内置了编译好的 `script_compiled.js`（通过 `frida-compile` 将 `frida-java-bridge` 打包进脚本），camille 启动时会自动优先加载该文件，**正常使用无需额外操作**。

**修改 `script.js` 后需要重新编译：**

1. 安装 Node.js 和 npm（如未安装）
2. 进入 agent 目录安装依赖：
```
cd agent
npm install
```
3. 编译脚本：
```
frida-compile agent/index.ts -o ../script_compiled.js -c
```

编译产物 `script_compiled.js` 包含了 `frida-java-bridge` 和 `script.js` 的全部逻辑，可直接被 camille 加载。

> 如果未安装 `frida-compile`，可通过 `pip install frida-tools` 获取。

# PyInstaller打包二进制可执行文件

目前仅在 Windows 下测试过，其他平台请自行测试能否正常使用~

```shell
pyinstaller -F .\camille.py -p .\venv\Lib\site-packages\ -i .\images\icon.ico --add-data "script_compiled.js;." --add-data "script.js;." --add-data "utlis\sdk.json;.\utlis"
```

> 注意：打包时务必包含 `script_compiled.js`，否则在 frida 17.x 环境下会因缺少 Java bridge 而报错。（此行及上方命令的 `script_compiled.js` 参数为 AI 辅助新增）

**可能出现的问题：**

ImportError: DLL load failed while importing _frida: %1 不是有效的 Win32 应用程序。

**解决方案：**

切换项目所用的 Python 环境为 32 位，移除 venv 后重新初始化项目环境为 Python 32 位即可。

**问题原因：**

这是 PyInstaller 与项目环境不一致的问题。

我安装 PyInstaller 的时候，系统的 Python 环境是 32 位，导致 PyInstaller 也是 32 位。

后来装了 64 位的 Python，这个项目环境初始化就是用 64 位 Python，环境冲突导致了这个问题。