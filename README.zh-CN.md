# 奶龙 · 你的桌面拼写小助手

[在线入门指南](https://toby0228.github.io/nailong/START-HERE.zh-CN.html)

[Click here to switch to English](README.md) · **中文** · [打开入门指南](START-HERE.zh-CN.html)

奶龙是一只可以拖动的 macOS 桌面宠物。发现疑似英文拼写错误后，它会跑过去指向单词；修正后，它会回到待机位置。

**macOS 14.2+ · 美式英文拼写 · 本地处理。** Google Docs 和视觉扫描使用 OCR，支持情况因编辑器和显示设置而异。

## 先试试内置练习区

1. 下载或克隆本仓库。如果下载的是 ZIP，请先解压，并保留整个文件夹。
2. 双击 `Start-Nailong.command`。如果还没有编译好的应用，启动器会先编译再打开；之后直接使用已有版本。
3. 在设置窗口点击 **Try the playground**。这是最简单的首次体验，不需要浏览器扩展或额外隐私权限。
4. 输入 `This is a beautifull day. `，末尾加一个空格。奶龙应跑向 **beautifull**；把它改成 **beautiful**，奶龙就会回家。

拖动奶龙可以设置待机位置。右键点击宠物，或点击菜单栏里的黄色图标，可以打开控制菜单。HTML 入门页面只提供说明，不会启动桌面应用。

## 首次编译前

编译需要 Xcode Command Line Tools。如果尚未安装，打开终端，运行 `xcode-select --install`，完成 macOS 安装提示后再次启动奶龙。

如果启动脚本无法运行，打开终端，输入 `cd `，把解压后的项目文件夹拖进终端，按回车。运行 `bash build.sh`，然后打开 `build/Nailong.app`。已有编译版本时可直接打开该应用。请仅打开来源可信的开发版本；macOS 可能要求在“隐私与安全性”中确认。

## 选择使用场景

| 输入位置 | 需要开启什么 |
| --- | --- |
| 内置练习区 | 无额外要求 |
| 支持的原生应用，例如 TextEdit | 辅助功能 |
| Chrome 普通网页文本框 | 浏览器扩展 + 本地助手 |
| Chrome 中的 Google Docs（实验性） | 扩展 + 本地助手 + 屏幕录制 |
| 手动 3 秒视觉扫描 | 屏幕录制 |
| 其他应用的自动视觉检查 | 屏幕录制 + 辅助功能 + 单独启用该应用 |

这些是独立的设置。开启屏幕录制不会自动安装 Chrome 扩展。语言切换只改变指南，应用界面和拼写检查仍使用英文。

## 设置 Chrome

1. 保持奶龙运行，在设置窗口点击 **Connect / repair browser…**，选择 **Chrome**。程序会安装本地助手并复制扩展文件夹路径。
2. 在扩展管理页面开启 **开发者模式**，选择 **加载已解压的扩展程序**，然后选择本仓库中的 `BrowserExtension` 文件夹。在文件夹选择窗口中，可按 Shift–Command–G 粘贴刚复制的路径。
3. 刷新已经打开的网页标签页。
4. 点击奶龙的 **Test browser connection**。测试页应显示 **Connected. Nailong is running.**。点击页面中的文本框，试着输入示例句。

已经安装过？重新加载已有扩展即可，不必安装第二份，然后刷新网页。Edge、Brave 和 Chromium 也提供助手设置选项，但发布前请分别测试。请将仓库保留在固定位置；移动后需要重新连接助手并重新加载扩展。

## 试用 Google Docs 或视觉扫描

使用 Google Docs 前，点击奶龙的 **Enable Screen Recording…**，在 macOS 中允许奶龙，并按提示重启。完成 Chrome 设置后刷新文档，在测试文档里输入示例句。保持输入光标可见，暂停约 2–3 秒。奶龙通过本地图像文字识别（OCR）检查光标附近，而不是检查整篇文档。

手动检查时，保持目标应用在前台，在黄色菜单栏图标的菜单中选择 **Check around pointer in 3 seconds**，倒计时结束前将鼠标移到错误文字上。虚线框显示选中的区域，检查持续约 25 秒。橙色单词框必须覆盖真实单词。换行或移动到其他位置后，请重新发起扫描。

要在其他应用中自动视觉检查，请开启屏幕录制和辅助功能，切换到目标应用，然后选择 **Toggle visual checking for current app**。再次选择同一菜单项可以关闭。

## 遇到问题怎么办

- **看不到宠物：** 打开 `build/Nailong.app` 或使用启动器，然后在黄色菜单栏图标中选择 **Reset position**。
- **浏览器显示未连接：** 保持奶龙运行且未暂停，使用 **Connect / repair browser…**，重新加载扩展并刷新网页。请用浏览器测试页确认连接。设置窗口中的 Browser 状态依据近期消息更新，空闲时可能显示未连接。
- **系统开关已开启，奶龙仍显示未启用：** 替换或重新编译开发版应用可能使旧授权失效。退出奶龙，在对应的 macOS 隐私权限列表删除旧条目，添加当前的 `build/Nailong.app`，开启后重新打开。Touch ID 或密码提示请自行完成。正常使用时不要反复重新编译。
- **橙色框指向空白处：** 记录当时的检测方式、窗口位置、浏览器与文档缩放比例，并用测试文字截图。在窗口静止时重试。扩展弹窗中的偏移设置只影响扩展的文字目标，不会校准手动 OCR 扫描。
- **Docs 没有响应：** 确认屏幕录制权限，重新加载扩展并刷新网页，点击文档，在完成一个单词后暂停。另行尝试 3 秒扫描。

## 项目文档

- [入门指南](START-HERE.zh-CN.html)：安装、浏览器连接与日常使用。下载后在浏览器中打开 HTML 文件。
- [贡献指南](CONTRIBUTING.md)：开发环境、检查与问题反馈。
- [维护者测试清单](docs/TESTING.zh-CN.md)：回归检查步骤。
- [发布准备](docs/RELEASE.md)：发布记录与待办事项。

## 隐私与限制

拼写通过 macOS 在本地检查，视觉识别使用 Apple Vision。应用和扩展不发起网络请求，不保存文档文字或截图。本地助手及短期坐标/状态文件位于 `~/Library/Application Support/Nailong`；macOS 偏好设置保存待机位置、忽略词及启用视觉检查的应用。浏览器注册文件位于对应浏览器的 Application Support 文件夹。

目前只检查英文拼写，不检查语法。OCR 可能误读人名、代码和未输入完成的单词。密码框和无痕窗口的排除规则适用于浏览器扩展；视觉检查不能可靠识别所有画布内的敏感内容。请只在希望检查可见文字时启用。嵌入框架、封闭 Shadow DOM、受保护窗口及部分自定义编辑器不支持或不可靠。不支持 Windows 和 Linux。

## 开发

可在 VS Code 或其他编辑器打开项目。`bash build.sh` 重新编译应用。`bash Tests/run-tests.sh` 会重新编译并执行原生、浏览器和通信检查；浏览器检查需要 Node、Playwright 和 Chrome。使用 `npm install --no-save playwright` 安装浏览器测试依赖。重新编译后可能需要再次批准 macOS 权限。

`build/Nailong.app/Contents/MacOS/Nailong --capture-test` 会在临时测试窗口的两个位置检查 OCR 坐标，需要屏幕录制权限，不会修改文档。受控测试不能替代真实 Google Docs 流程测试。

主要目录：`Sources/` 为原生应用，`BrowserExtension/` 为浏览器集成，`Assets/` 为宠物图片，`Tests/` 为测试。

## 图片来源

奶龙图片素材由 AI 图像生成工具全部生成。跑步动画通过交替显示两个姿势并上下摆动实现。生成提示词和来源说明见 [ARTWORK.md](ARTWORK.md)。

本地编译产物、运行状态文件和参考资料不会包含在仓库中。代码、文档和 AI 生成的奶龙图片均采用下方的 MIT 许可证。

---

[Switch to English](README.md)

## 许可证

源代码、文档和项目中包含的 AI 生成图片均采用 [MIT 许可证](LICENSE)。
