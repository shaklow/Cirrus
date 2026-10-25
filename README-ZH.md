<h1 align='center'>
  <image src='assets/Application Icon.png' width='128' />
  <br/>
  Cirrus
  <br/>
  <a href="https://github.com/brandonw3612/Cirrus/blob/main/LICENSE">
    <img alt="GitHub" src="https://img.shields.io/github/license/brandonw3612/Cirrus">
  </a>
  <br/>
  <a href="https://github.com/brandonw3612/Cirrus/blob/main/README.md">
    <img alt="GitHub ReadMe English" src="https://img.shields.io/badge/README-English-lightgray?logo=github">
  </a>
  <a href="https://github.com/brandonw3612/Cirrus/blob/main/README-ZH.md">
    <img alt="GitHub ReadMe Chinese" src="https://img.shields.io/badge/README-中文-lightgray?logo=github">
  </a>
  <br/>
</h1>

Cirrus（前身为 LyricEase）是一款网易云音乐第三方客户端。Cirrus 基于最新的 WinUI 框架构建，旨在为 Windows 11 平台提供现代原生的用户体验。

## 构建

### 本 fork 的安装包

从 [Releases](https://github.com/shaklow/Cirrus/releases/latest) 下载 `Cirrus-版本-x64.zip`（Intel/AMD 电脑）或 `Cirrus-版本-ARM64.zip`（Windows on ARM）。完整解压后双击 `Install.cmd`，在 Windows 提示时授权导入此版本的签名证书，安装完成后从开始菜单打开 Cirrus。推荐 Windows 11，最低 Windows 10 版本 2004（内部版本 19041）。安装包包含 .NET 与 Windows App SDK，无需安装 Visual Studio 或在本地构建。

本 fork 使用独立的包标识和发布者 `shaklow.Cirrus`，属于非官方版本。默认每次构建自动生成自签名证书，只分发公钥证书，不分发私钥；后续版本可能需要重新信任证书。卸载可在 Windows 设置的“应用”中完成。

[Build Windows installers](https://github.com/shaklow/Cirrus/actions/workflows/build-installers.yml) 在推送代码至 `main` 或手动运行时，使用 GitHub 托管的 Windows / Visual Studio 2026 / .NET 10 环境构建 x64 和 ARM64 的 Release NativeAOT MSIX，验证签名后发布到 Releases。失败日志保留 7 天，安装包构建产物保留 30 天，Releases 中的文件不受该保留期限制。

可选仓库 Actions secrets：

- `SIGNING_PFX_BASE64` 和 `SIGNING_PFX_PASSWORD`：固定的代码签名 PFX（Base64）及其密码。证书 Subject 必须是 `CN=shaklow.Cirrus`；不配置时自动生成临时签名证书。
- `LASTFM_API_KEY` 和 `LASTFM_API_SECRET`：自己的 Last.fm 应用凭据。不配置仍可构建和使用网易云功能，但无法使用 Last.fm 听歌记录同步。与上游一致，这些凭据会嵌入客户端，不能当作分发后仍保密的服务端凭据。

以下是上游项目的自行构建说明。

目前该项目处于活跃开发阶段。我们尚未提供官方预编译版本，但你可以使用此仓库自行构建项目。请注意，该项目尚处于早期阶段，代码库可能不稳定。

### 前置要求

请确保你的设备已按照 [Microsoft 文档](https://learn.microsoft.com/en-us/windows/apps/get-started/start-here) 的建议安装了以下工具并进行了配置：

- 已启用 **开发者模式**。
- 已安装 **[Visual Studio 2026](https://visualstudio.microsoft.com/downloads/)**，并包含 **Windows App SDK** 工作负载。
- 已安装 **[.NET 10 SDK](https://dotnet.microsoft.com/en-us/download/dotnet/10.0)**。

### 构建提示

- 如果你想为项目做出贡献，请在 `Debug` 配置下构建。
- 如果你只是想使用该软件，请在 `Release` 配置下创建应用程序包。这需要一个签名证书来对包进行签名，你可以自行创建，也可以从受信任的证书颁发机构获取。我们已使项目支持 NativeAOT，预计生成的安装包体积更小，性能表现也更好。

## 许可与商业用途

本项目采用 Apache License 2.0 协议授权 — 详见 [LICENSE](LICENSE) 文件。
根据 Apache-2.0 协议，你被允许使用、复制、修改和分发本软件（包括用于商业目的），前提是你必须遵守协议条款（例如，保留版权声明并包含必要的声明）。

作者请求：项目作者恳请在未经明确许可的情况下，不要将本软件用于商业产品或服务。此请求并非法律限制，也不会更改 Apache-2.0 协议本身。如果你计划将本项目用于商业产品，请联系维护者讨论许可事宜或获取明确的商业授权。

## 贡献

欢迎参与贡献！在提交 Issue 或 Pull Request 之前，请阅读本仓库的[贡献指南](CONTRIBUTING.md)。贡献指南解释了如何报告 Bug、提议功能、运行构建和测试以及准备 Pull Request。

快速贡献步骤：

- Fork 本仓库并创建一个特性分支（例如 `feat/<名称>` 或 `fix/<名称>`）。
- 保持你的分支与上游默认分支同步。
- 在提交 PR 前，请在本地运行构建和测试（具体命令请参阅 `CONTRIBUTING.md`）。
- 开启一个 PR 并关联任何相关的 Issue。

## 社区

我们也欢迎你订阅以下 Telegram 频道和讨论组，以获取最新消息、参与讨论或寻求帮助。

<a href="https://t.me/project_cirrus">
  <img alt="Telegram" src="https://img.shields.io/badge/Telegram-频道-lightblue?style=flat&logo=telegram&logoColor=white&labelColor=blue">
</a>
<br/>
<a href="https://t.me/project_cirrus">
  <img alt="Telegram" src="https://img.shields.io/badge/Telegram-讨论组-lightblue?style=flat&logo=telegram&logoColor=white&labelColor=blue">
</a>
