# 调整 macOS CPU 性能

[English](README.md) | **中文**

## 简介

**这个脚本目前只支持大部分5代-10代U。** 如果需要，将来我会尝试添加更多机型。

这个脚本能修改低频率模式和性能模式，然后用 [ResourceConverter.sh](https://github.com/acidanthera/CPUFriend/tree/master/ResourceConverter) 来生成定制的 `CPUFriendDataProvider.kext`。

此脚本不会修改系统文件夹下的任何文件。如果你对调整不满意，可以删除 `/CLOVER/kexts/Other/` 里的 `CPUFriend*.kext`，再重启来恢复原样。


## 使用前提

- 阅读 [CPUFriend WARNING](https://github.com/acidanthera/CPUFriend/blob/master/Instructions.md#warning)
- 网络环境良好
- 如果你的 `config.plist` 有 `FakeCPUID` 参数，这个脚本可能会导致问题
- 确保 `IOPlatformPluginFamily.kext` 未经修改
- 确保 [Lilu](https://github.com/acidanthera/Lilu) 在工作
- 确保你在使用正确的 SMBIOS 机型
- `plugin-type=1`，通常由 [SSDT-PLUG](https://github.com/acidanthera/OpenCorePkg/blob/master/Docs/AcpiSamples/SSDT-PLUG.dsl) 或者 [SSDT-XCPM](https://github.com/RehabMan/OS-X-Clover-Laptop-Config/blob/master/hotpatch/SSDT-XCPM.dsl) 来注入


## 使用方法

- 在终端输入以下命令并回车：

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/stevezhengshiqi/one-key-cpufriend/master/one-key-cpufriend_cn.sh)"
```

- **如果是 Clover 用户：**
  - 把桌面上的 `CPUFriend.kext` 和 `CPUFriendDataProvider.kext` 复制进 `/CLOVER/kexts/Other/` 并重启。

- **如果是 OC 用户：**
  - 把桌面上的 `CPUFriend.kext` 和 `CPUFriendDataProvider.kext` 复制进 `/OC/Kexts/`。
  - 打开 `/OC/config.plist` 并添加以下代码到 `Kernel - Add`：
```xml
<dict>
    <key>Arch</key>
    <string>x86_64</string>
    <key>BundlePath</key>
    <string>CPUFriend.kext</string>
    <key>Comment</key>
    <string>Power management data injector</string>
    <key>Enabled</key>
    <true/>
    <key>ExecutablePath</key>
    <string>Contents/MacOS/CPUFriend</string>
    <key>MaxKernel</key>
    <string></string>
    <key>MinKernel</key>
    <string>12.0.0</string>
    <key>PlistPath</key>
    <string>Contents/Info.plist</string>
</dict>
<dict>
    <key>Arch</key>
    <string>x86_64</string>
    <key>BundlePath</key>
    <string>CPUFriendDataProvider.kext</string>
    <key>Comment</key>
    <string>Power management data</string>
    <key>Enabled</key>
    <true/>
    <key>ExecutablePath</key>
    <string></string>
    <key>MaxKernel</key>
    <string></string>
    <key>MinKernel</key>
    <string>12.0.0</string>
    <key>PlistPath</key>
    <string>Contents/Info.plist</string>
</dict>
```


## 恢复

- **如果是 Clover 用户：**
  - 如果你对调整不满意，删除 `/CLOVER/kexts/Other/` 里的 `CPUFriend.kext` 和 `CPUFriendDataProvider.kext`，再重启来恢复原样。

  - 如果很不幸，你无法进入系统，而且你确定是由 `CPUFriend*.kext` 导致的，

    - 当你进入 Clover 界面时，按 `空格键` 
    - 用键盘来选择 `Block Injected kexts` - `Other` 
    - 勾选 `CPUFriend.kext` 和 `CPUFriendDataProvider.kext`
    - `Return` 到主界面并启动系统，然后从你的 CLOVER 文件夹删除 `CPUFriend*.kext`

- **如果是 OC 用户：**
  - 逆向操作[使用方法](#使用方法)小节并重启


## 鸣谢

- 感谢 [Acidanthera](https://github.com/acidanthera) 和 [PMHeart](https://github.com/PMHeart) 提供 [CPUFriend](https://github.com/acidanthera/CPUFriend)。

- 感谢 [shuhung](https://www.tonymacx86.com/members/shuhung.957282) 提供[配置修改思路](https://www.tonymacx86.com/threads/skylake-hwp-enable.214915/page-7)。

- 感谢 [PMheart](https://github.com/PMheart) 和 [xzhih](https://github.com/xzhih) 提供一些建议。
