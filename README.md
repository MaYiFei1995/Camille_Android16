# Camille

Android App隐私合规检测辅助工具

## Fork 新增特性

本仓库基于 [zhengjim/camille](https://github.com/zhengjim/camille) fork，新增以下特性（由 AI 辅助生成并经实际设备验证）：

- **Frida 17.x 兼容**：通过 `frida-compile` 将 `frida-java-bridge` 打包进 `script_compiled.js`，解决 frida 17.x 不再自动注入 Java bridge 的问题。
- **Android 16 JNI crash 修复**：对 `frida-java-bridge` 的 `android.js` 和 `class-factory.js` 应用补丁，手动解码 JNI transition frame reference 并通过 `AddGlobalRef` 提升为全局引用，绕过 CheckJNI 对 frida trampoline 帧的校验失败。
- **stripped libart.so 符号查找**：Android 16 libart.so 已 strip `.symtab`，改用 `enumerateSymbols()` 解析 `.gnu_debugdata` mini-debuginfo 中的符号。
- **JIT 编译竞争规避指引**：文档记录了 frida 修改 ArtMethod 后 JIT 线程可能崩溃的竞争窗口及临时关闭 JIT 的方法。
- **脚本加载改进**：camille 自动优先加载 `script_compiled.js`，并通过 `recv('start')` 模式替代 `setTimeout`/`setImmediate` 控制启动时机。
- **场景控制系统**：移除原屏幕截图/模拟点击机制，改为运行时键盘输入切换 5 个检测场景（同意隐私政策前/后、IDLE、初始化中、请求业务中），所有告警标注当前场景标签。
- **检测项扩展**：补充 MSA SDK OAID、DRM 设备 ID、GAID、NAI、账户信息、传感器注册监听等检测项。
- **模块配置系统**：新增 `utlis/modules.json` 配置表和 `-mc`/`--module-config` 参数，支持检测项级别的启用/禁用控制，与 `-u`/`-nu` 模块级控制正交组合。

## 简介

现如今APP隐私合规十分重要，各监管部门不断开展APP专项治理工作及核查通报，不合规的APP通知整改或直接下架。camille可以hook住Android敏感接口，检测是否第三方SDK调用。根据隐私合规的场景，辅助检查是否符合隐私合规标准。

## 隐私合规资料及政策

[隐私资料政策wiki](https://github.com/zhengjim/camille/wiki/APP-%E4%BE%B5%E5%AE%B3%E7%94%A8%E6%88%B7%E6%9D%83%E7%9B%8A%E4%B8%93%E9%A1%B9%E6%95%B4%E6%B2%BB%E8%A1%8C%E5%8A%A8%E6%81%A2%E5%A4%8D%E4%B8%8A%E6%9E%B6%E6%B5%81%E7%A8%8B)

## 安装

环境：

python3、frida 、一台已root手机(我测试机为Redmi 3s，刷机成魔趣Android 8.1，感觉问题挺多的)，并在手机上运行`frida-server`。

测试了Android 8.1(还测试了魔趣Android 10)，其他版本安卓可能会有bug。

更新日志：

```
2023-03-14：新增敏感接口

2022-12-12：修复android 13有兼容性问题

2022-11-25：修复截图bug、优化hook方法支持传参数过滤

2022-11-21：新增可指定frida-server用于对抗frida检测，参数-H、修复模拟器没有sdcard目录报错问题

2022-11-16：感谢@ysrfeng 添加wiki，添加隐私合规相关资料和政策文档。

2022-11-15：合并@RebornQ PR，新增多设备可指定设备功能

2022-11-11：修复Android7报错、Frida12报错、优化异常处理便于排查

2022-11-10: 合并@RebornQ PR、修复部分问题、优化初始化异常提示

2022-11-03: 添加同意隐私合规状态(需人工确认)、第三方SDK识别、可hook构造函数，`methodName`传`'$init'`。方便大家交流，创建交流群。 新增文件接口，感谢@LiuXinzhi94提供。 新增敏感接口，感谢群里师傅@WYY提供

2022-10-26：新增支持加载外部脚本文件，填相对路径或绝对路径均可（用于 pyinstaller 打包二进制执行文件后使用）感谢@RebornQ pr

2022-09-07：添加讨论群，新增敏感接口，感谢群里师傅@410提供。

2022-07-08: 默认不开启绕过TracerPid,添加attach hook，避免有些加固包不能hook问题。

2022-06-22：修复程序异常退出、冗余度高、hook接口不全有遗落、新增多个Android版本接口；封装hook方法，新增用户自定义hook方法。

2022-01-14：删除hook短信接口。新增：可指定模块hook或不hook哪些模块。默认不传，全扫描。
```

下载：

```
git clone https://github.com/zhengjim/camille.git
cd camille
pip install -r requirements.txt
python camille.py -h
```

![img.png](images/img.png)

## Tips

> 以下内容由 AI 辅助生成并经实际设备验证（OnePlus GM1911, Android 16 userdebug, frida-server 17.16.4）。

### Frida 17.x 兼容（重要）

frida 17.x 起，Python API **不再自动包含 Java bridge**，直接使用 `script.js` 会报 `ReferenceError: 'Java' is not defined`。项目内置了通过 `frida-compile` 编译打包的 `script_compiled.js`（已包含 `frida-java-bridge`），camille 会自动优先加载该文件，**无需额外操作**。

如果修改了 `script.js` 中的 hook 逻辑，需要重新编译：

```bash
cd agent
npm install
frida-compile agent/index.ts -o ../script_compiled.js -c
```

首次编译前需安装工具链（已包含在项目 agent 目录中）：
```bash
cd agent
npm install frida-java-bridge @types/frida-gum
```

> 编译环境需要 Node.js 和 npm。

### Android 16 JNI crash 修复

Android 16 的 ART 启用了更严格的 JNI 校验，官方 frida-java-bridge（截至 7.0.13）在 hook 任意 Java 方法并调用时会崩溃：

```
JNI DETECTED ERROR IN APPLICATION: jobject is an invalid JNI transition frame reference
in call to CallNonvirtualObjectMethod / NewLocalRef / IsInstanceOf
```

这是上游已知问题（frida/frida#3700、#3745）。本项目已对 `agent/node_modules/frida-java-bridge` 应用以下补丁并编译进 `script_compiled.js`：

1. **lib/android.js**（参考上游 PR [frida-java-bridge#388](https://github.com/frida/frida-java-bridge/pull/388)）：为 Android 16 的 `VisiblyInitializedCallback` 流程添加静态 trampoline 重新同步的回退路径。
2. **lib/android.js**：Android 16 的 libart.so 已被 strip（无 `.symtab`，符号仅存于 `.gnu_debugdata` mini-debuginfo），`findSymbolByName` 找不到回退符号，改用 `enumerateSymbols()` 查找（参考 PR [frida-java-bridge#394](https://github.com/frida/frida-java-bridge/pull/394) 的分析）。
3. **lib/class-factory.js**：`handleMethodInvocation` 中，hook 回调收到的 `this` 和对象参数在 Android 14+ 上是 JNI transition frame reference（`kJniTransition`，低 2 位为 0，指向调用方 quick frame 中的压缩引用槽）。该校验属 CheckJNI（userdebug/eng 系统在 zygote 启动时强制开启，故任何带校验的 JNI 调用——包括 `NewLocalRef` 本身——都会拒绝它，因为 `IsJniTransitionReference()` 无法穿过 frida 的 trampoline 帧做栈回溯）。补丁改为手动解码：读取槽内 uint32 压缩引用，加上堆基址还原对象指针（堆基址利用 `java.lang.Class` 的 klass 字段指向自身这一特性自举计算），再调用不做校验的 `art::JavaVMExt::AddGlobalRef` 提升为真实全局引用，调用结束后在 finally 中 `DeleteGlobalRef` 释放。

补丁文件存放在 `agent/patches/`，重新执行 `npm install` 后可用脚本一键重新应用并编译：

```bash
cd agent
npm install
sh apply-patches.sh    # 重新应用 frida-java-bridge 补丁
frida-compile agent/index.ts -o ../script_compiled.js -c
```

### JIT 编译竞争导致崩溃

应用上述 JNI 补丁后，在 userdebug 系统（如 OnePlus GM1911）上仍可能出现 SIGSEGV，崩溃栈在 JIT 线程：

```
SIGSEGV in Jit thread pool
  art::HBasicBlockBuilder::Build(...)
  art::optimizing_compiler.cc:...
```

原因：frida 修改 ArtMethod（置 `kAccNative` + `kAccCompileDontBother` + quick generic JNI trampoline）后，若 JIT 在标志生效前已将该方法入队，JIT 仍会编译已被改写的 ArtMethod，读取到清零的 CompilerMetadata 而崩溃。这是 frida 与 ART JIT 的已知竞争窗口，非本项目补丁引入。

临时关闭 JIT 即可规避（需 root，重启后恢复默认）：

```bash
adb shell "setprop dalvik.vm.usejit false"
adb shell stop && adb shell start
```

### Python 版本

frida 17.x 官方要求 Python 3.11+。如果使用 Python 3.9/3.10，frida 会因 `typing.NotRequired` 和 `typing.ParamSpec` 导入失败而报错 `ImportError`。需要修补 frida 包中的以下两个文件，将这两个符号的导入从 `typing` 改为 `typing_extensions`（需先 `pip install typing_extensions`）：
  - `<python>/Lib/site-packages/frida/__init__.py`
  - `<python>/Lib/site-packages/frida/aio.py`

  将：
  ```python
  from typing import (..., NotRequired, ..., ParamSpec, ...)
  ```
  改为：
  ```python
  from typing import (...)  # 移除 NotRequired 和 ParamSpec
  from typing_extensions import NotRequired, ParamSpec
  ```

  > 注意：此补丁在 frida 重新安装或升级后会丢失，届时需重新修补。

### frida 版本匹配

PC 端 frida bindings 版本必须与设备端 frida-server 主版本一致（如都是 17.x），否则会出现 `agent connection closed unexpectedly` 等错误。

### SELinux

启动 frida-server 前建议先执行 `setenforce 0` 关闭 SELinux，避免策略格式不兼容导致 hook 失败。

## 用法

[使用说明文档](docs/use.md)

## 后记

本来想使用uiautomator2或appium来模拟点击制定场景，~~但后续调研发现纯自动化的检测是不全的，最多也就检测20-30%，还是得结合人工来检测。索性就删除了模拟点击这块。~~(其实就是懒，不定期更新)

## 场景

[百度史宾格的检测场景](docs/detection_scene.md)

## 参考链接

- https://github.com/Dawnnnnnn/APPPrivacyDetect
- https://github.com/r0ysue/r0capture/
- https://github.com/ChenJunsen/Hegui3.0

## 讨论群

感谢[@ysrfeng](https://github.com/ysrfeng) 提供的App合规检测交流群，有需要的可以加群交流~

为方便大家交流，创建交流群有需要的加群。App隐私合规交流群满200，需要的加V，备注github。就会拉进群。

<img src="https://github.com/zhengjim/camille/raw/master/images/v.png" width = "300" height = "450" alt="" align=center />


## 404星链计划
<img src="https://github.com/knownsec/404StarLink-Project/raw/master/logo.png" width="30%">

camille项目 现已加入 [404星链计划](https://github.com/knownsec/404StarLink)

## Stargazers over time

[![Top Langs](https://profile-counter.glitch.me/zhengjim/count.svg)](https://www.zhengjim.com)

[![Stargazers over time](https://starchart.cc/zhengjim/camille.svg)](https://starchart.cc/zhengjim/camille)
