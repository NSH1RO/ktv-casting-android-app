# ktv-casting-for-android

---

使用教程见[飞书文档](https://idol-zju.feishu.cn/wiki/Ytt1wNh88i6E9jkEndhcxNmYnBd)

---

本项目是 [ktv-casting](https://github.com/KARAOKE-MASTER-ZJU/ktv-casting) 的安卓前端

## 本 fork 的媒体传输选择

在“连接”页面的 DLNA 卡片中选择“反向代理（默认）”或“传原链接”。选择自动保存，重新连接设备后生效。原链接模式由设备直接访问源站；需要设备支持源站的协议、媒体格式与鉴权。反向代理模式保留手机侧转发、缓存与混流。

Debug CI 从 `native/ktv-casting` 固定的本 fork 提交构建 `.so`，并检查新 JNI 接口，避免误用旧原生库。手动运行 **Build Debug APK** 时勾选“检查全部四种 ABI”，可导出四种架构及 universal 通用 APK。

### Windows 本地打包

需要 JDK 17、Android SDK 36、Build Tools 36.0.0，以及当前固定 Rust 提交对应的 `.so`。CI 的原生库下载后，放入 `app/src/main/jniLibs/<abi>/libktv_casting_lib.so`。

```powershell
# 在仓库目录运行；可通过 JAVA_HOME / ANDROID_HOME 指定现有工具链。
# 默认也会查找仓库旁 android-dev/jdk 与 android-dev/sdk。
./scripts/build-local.ps1
# 仅构建常见手机架构：
./scripts/build-local.ps1 -Abis arm64-v8a
```

脚本运行单元测试、构建 debug 签名 APK、检查原生库是否打包，并导出到 `apks/`。这些安装包使用本地 debug 密钥，不是上游 release 签名。签名密钥与构建缓存保留在仓库旁 `android-dev/` 中。

## 环境配置

如果你有本地构建发布的需求，复制 `app/local.properties.example` 为 `app/local.properties`，填写你的仓库信息：

```properties
repo_owner=你的GitHub用户名
repo_name=你的仓库名
```

未配置时默认使用 `KARAOKE-MASTER-ZJU/ktv-casting-android-app`。如果你使用 GitHub Actions 构建，CI 会自动注入当前仓库的 owner/name，无需手动配置 `local.properties`。

应用内更新检查读取 `https://<repo_owner>.github.io/<repo_name>/release.json`，需在仓库 Settings 中启用 GitHub Pages（source 选 `gh-pages` 分支），并配置 CI（见 `.github/workflows/build-and-release.yml` 顶部注释）。

## 环境准备

---

```shell
# 克隆 android-app分支的rust源码
git clone -b android-app --single-branch https://github.com/KARAOKE-MASTER-ZJU/ktv-casting.git

cd ktv-casting

rustup target add aarch64-linux-android
cargo ndk -t arm64-v8a build --lib --release
# 产物输出在 ./target/aarch64-linux-android/release/libktv_casting_lib.so

# 下面是更多版本

# rustup target add armv7-linux-androideabi
# cargo ndk -t armeabi-v7a build --lib --release

# rustup target add i686-linux-android
# cargo ndk -t x86 build --lib --release

# rustup target add x86_64-linux-android
# cargo ndk -t x86_64 build --lib --release

cd ..
```
这样就得到了`libktv_casting_lib.so`

接下来克隆本项目
```shell
# 主仓库
git clone https://github.com/KARAOKE-MASTER-ZJU/ktv-casting-android-app.git

# 如果你 fork 了项目，改为你自己的仓库地址，并按上面的 Fork 配置步骤设置 local.properties

cd ktv-casting-android-app
```

打开 [Android Studio](https://developer.android.google.cn/studio?hl=zh-cn) 将文件夹打开为项目

把上一步得到的编译产物放到`app/src/main/jniLibs/arm64-v8a/libktv_casting_lib.so`(这里的架构版本根据上面-t参数选择)

直接在android studio运行调试即可
