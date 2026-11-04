# ThRei KZ GOKZ 插件包

ThRei KZ 的 CS:GO GOKZ 服务端插件包。基线为 **GOKZ 3.6.4 + SourceMod 1.11**，保留原版 GOKZ 的全部功能，只把 GlobalAPI 后端替换为 ThRei API。

不依赖 `kztimerglobal.com`，也不需要安装 GlobalAPI 官方服务。

## 功能

- GOKZ 成绩直接上传到 ThRei
- `!pb` / `!gpb` / `!gmaptop` / `!profile` / `!wr`
- TP / PRO 分开计分和排名
- 地图过滤、封禁、回放、公告
- 红色 `CN` 前缀 + ThRei 段位
- 计分板模式首字母 `K` / `S` / `V` + 完整段位
- 计分板 clan tag 格式可配置
- 地图池白名单校验，未知地图不会自动创建
- 自带 `maps/gokz-replays.nav`，回放不需要现场生成 nav

## 环境要求

- CS:GO dedicated server
- SourceMod 1.11.0
- GOKZ 3.6.4（完整包已包含）
- MovementAPI 2.4.x
- DHooks 2.2.0
- SteamWorks
- 一个 ThRei 服务器 Key

## 下载

最新发布页：

```text
https://github.com/ThReizzZ/ThRei-KZ/releases/latest
```

```text
https://github.com/ThReizzZ/ThRei-KZ/releases/download/v2.0.0/threi-kz-full.tar.gz
```

只提供一个完整安装包，包含所有 GOKZ 插件、GlobalAPI 桥接、翻译、gamedata、cfg、materials、models、sound，以及 `maps/gokz-replays.nav`。

> Windows 可以用 7-Zip 解压 `.tar.gz`。

## 获取服务器 Key

向 ThRei 管理员申请服务器 Key。Key 只发给服主，不要公开到仓库、截图或聊天记录里。

## 一键安装

解压后运行：

```bash
# Linux
./install.sh /path/to/csgo
```

```text
# Windows
双击 install.bat
```

脚本会自动：

- 备份旧的四个插件和两个翻译
- 停用旧的 `GlobalAPI-Core.smx` / `GlobalAPI-Jumpstats.smx`
- 停用 `threi-kz-uploader.smx`
- 复制新插件、翻译、配置示例和 `maps/gokz-replays.nav`

然后编辑：

```text
csgo/cfg/sourcemod/globalapi-key.cfg
```

第一行只放 Key：

```text
threi_xxxxxxxxxxxxxxxxxxxxxxxx
```

最后换图或重启服务器。

## 手动安装

1. 备份现有的 GOKZ 插件和翻译。
2. 把 `addons/`、`cfg/`、`maps/` 覆盖到 `csgo/`。
3. 写入 `csgo/cfg/sourcemod/globalapi-key.cfg`。
4. 停用旧的 `GlobalAPI-Core.smx`、`GlobalAPI-Jumpstats.smx`。
5. 停用 `threi-kz-uploader.smx`（只在手动历史回填时使用）。
6. 换图或重启。
7. 进服输入 `!gc`，确认 API Key / Plugins / Settings Enforcer / Map / You 都是绿色。

详细说明见 `INSTALL.md`。

## 配置

### `cfg/sourcemod/globalapi-key.cfg`

```cfg
threi_xxxxxxxxxxxxxxxxxxxxxxxx
```

### `cfg/sourcemod/globalapi-convars.cfg`

```cfg
sm_globalapi_url "https://api.threi.cn/api/v2.0"
```

一般不需要改。

### `cfg/sourcemod/gokz/gokz-profile.cfg`

计分板 clan tag 格式：

```cfg
sm_threi_clan_format "[{mode_initial} CN {rank}]"
```

占位符：

```text
{cn}            CN
{rank}          段位名，例如 Beginner+
{mode}          KZTimer / SimpleKZ / Vanilla
{mode_short}    KZT / SKZ / VNL（聊天栏使用）
{mode_initial}  K / S / V（计分板模式首字母）
```

默认效果：

```text
[K CN Amateur+]
[S CN Skilled+]
[V CN Regular+]
```

`Beginner+` / `Beginner-` 这类 9 字符段位会让总长度超过 15 字符，插件会自动去掉外层方括号：

```text
K CN Beginner+
```

聊天栏仍然是：

```text
[KZT CN Beginner+] 玩家名 : gg
```

## 常用命令

| 命令 | 说明 |
| --- | --- |
| `!gc` / `!globalcheck` | 检查 API Key、插件、地图和模式状态 |
| `!pb` | 查看自己的本地 PB，并追加 ThRei 全服 PB |
| `!gpb` | 查看 ThRei 全服 PB |
| `!gmaptop` | 查看当前地图的 ThRei 榜单 |
| `!profile` | 查看 ThRei 积分和段位 |
| `!wr` | 查看当前地图纪录 |
| `!bhopcheck` | 检查 bhop 作弊标记 |

更多 GOKZ 命令见 `COMMANDS.md`。

## 段位

段位名称和阈值沿用 GOKZ 的 23 级：

```text
New
Beginner-
Beginner
Beginner+
Amateur-
Amateur
Amateur+
Casual-
Casual
Casual+
Regular-
Regular
Regular+
Skilled-
Skilled
Skilled+
Expert-
Expert
Expert+
Semipro
Pro
Master
Legend
```

积分按 ThRei 自己的排名计算，不再使用 kztimerglobal 的全球排名。

## 包内容

### 完整包

- 全部 GOKZ 插件
- ThRei 版 `GlobalAPI.smx`
- 翻译、gamedata、cfg
- materials / models / sound
- `maps/gokz-replays.nav`
- 安装脚本

### 可选 uploader

`optional/uploader/` 里是历史回填工具，只用于把旧 GOKZ SQLite 成绩补传到 ThRei。

正常运行时不要和 GOKZ 直传同时开启，否则会重复上传。

## 从源码编译

需要 SourceMod 1.11 的 `spcomp64`：

```bash
export SM_INCLUDE=/path/to/sourcemod/addons/sourcemod/scripting/include
export SPCOMP=/path/to/sourcemod/addons/sourcemod/scripting/spcomp64
./build.sh
```

生成安装包：

```bash
./package.sh
```

产物在 `release/`。

## 地图池

- 只有已经在 ThRei 地图池里的地图才会被接受
- 未知地图返回 `MAP_NOT_FOUND`
- 地图文件大小会参与校验，请确保服务器地图版本和地图池一致
- 新地图需要先加入地图池，不能靠上传自动创建

## 故障排查

### `!gc` 有红色

- API Key 是否写对
- 服务器是否能访问 `https://api.threi.cn`
- `GlobalAPI.smx` 是否加载
- 旧的 `GlobalAPI-Core.smx` / `GlobalAPI-Jumpstats.smx` 是否已停用

### 成绩没有上传

- 地图是否在地图池内
- `threi-kz-uploader.smx` 是否和 GOKZ 直传同时运行
- 查看服务器控制台的 `gokz-global` / `GlobalAPI` 报错

### 回放提示缺少 nav

确认：

```text
csgo/maps/gokz-replays.nav
```

存在。安装包已经包含这个文件。

## License

GOKZ 和 GlobalAPI 的修改遵循 GPL。详见 `LICENSE` 和 `NOTICE.md`。
