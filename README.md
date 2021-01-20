# Modify macOS CPU Performance

**English** | [中文](README_CN.md)

## Instruction

**The script is only for most 5th-10th generation CPU yet.** I will try to add support for more models if needed.

The script can modify low frequency mode and energy performance preference, and use [ResourceConverter.sh](https://github.com/acidanthera/CPUFriend/tree/master/ResourceConverter) to generate customized `CPUFriendDataProvider.kext`.

By using this script, no file under the System folder will be edited. If you are not happy with the modification, just remove `CPUFriend*.kext` from `/CLOVER/kexts/Other/` and restart.


## Before install

- Read [CPUFriend WARNING](https://github.com/acidanthera/CPUFriend/blob/master/Instructions.md#warning)
- Good network
- If you have `FakeCPUID` argument in `config.plist`, this script may cause issue
- Make sure `IOPlatformPluginFamily.kext` untouched
- Make sure [Lilu](https://github.com/acidanthera/Lilu) is working
- Make sure you are using correct SMBIOS model
- `plugin-type=1`, often injected by [SSDT-PLUG](https://github.com/acidanthera/OpenCorePkg/blob/master/Docs/AcpiSamples/Source/SSDT-PLUG.dsl) or [SSDT-XCPM](https://github.com/RehabMan/OS-X-Clover-Laptop-Config/blob/master/hotpatch/SSDT-XCPM.dsl)


## How to install

- Run the following command in Terminal:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/stevezhengshiqi/one-key-cpufriend/main/one-key-cpufriend.sh)"
```

- **For Clover users:**
  - Copy `CPUFriend.kext` and `CPUFriendDataProvider.kext` from desktop to `/CLOVER/kexts/Other/` and restart.

- **For OC users:**
  - Copy `CPUFriend.kext` and `CPUFriendDataProvider.kext` from desktop to `/OC/Kexts/`.
  - Open `/OC/config.plist` and add the following code into `Kernel - Add`:
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


## Recovery

- **For Clover users:**
  - If you are not happy with the modification, just remove `CPUFriend.kext` and `CPUFriendDataProvider.kext` from `/CLOVER/kexts/Other/` and restart.

  - If unfortunately, you can't boot into the system, and you are sure the issue is caused by `CPUFriend*.kext`,

    - Press `Space` when you are in Clover page
    - Use keyboard to choose `Block Injected kexts` - `Other`
    - Check `CPUFriend.kext` and `CPUFriendDataProvider.kext`
    - Return to the main menu and boot into the system, then delete `CPUFriend*.kext` from your CLOVER folder

- **For OC users:**
  - Reverse the [How to install](#how-to-install) part and restart


## Credits

- Thanks to [Acidanthera](https://github.com/acidanthera) and [PMHeart](https://github.com/PMHeart) for providing [CPUFriend](https://github.com/acidanthera/CPUFriend).

- Thanks to [shuhung](https://www.tonymacx86.com/members/shuhung.957282) for providing [configuration modification ideas](https://www.tonymacx86.com/threads/skylake-hwp-enable.214915/page-7).

- Thanks to [PMheart](https://github.com/PMheart) and [xzhih](https://github.com/xzhih) for giving me advice.
