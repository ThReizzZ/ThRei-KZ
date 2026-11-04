# ThRei GOKZ 插件安装

> 安装前请先停服，或至少不要在服务器运行时覆盖/移动 `.smx` 文件。

这套插件基于 **GOKZ 3.6.4 + SourceMod 1.11**，保留原版 GOKZ 全部功能，只把 GlobalAPI 后端换成 ThRei。

只提供一个完整安装包 `threi-kz-full.tar.gz`，包含所有 GOKZ 插件、GlobalAPI 桥接、翻译、gamedata、cfg、materials、models、sound，以及 `maps/gokz-replays.nav`。

## 服务器前置（不在本插件包内）

这些是服务器运行依赖，安装包只负责 GOKZ/ThRei 插件，不包含它们：

- SourceMod **1.11.0**
- DHooks **2.2.0**（SourceMod 1.11 使用；不要用 SourceMod 1.12 自带的 DHooks）
- MovementAPI **2.4.x**
- SteamWorks
- NoLobbyReservation（不装会导致独立版 CS:GO 客户端无法加入服务器）

DHooks 2.2.0 下载：

```text
https://github.com/peace-maker/DHooks2/releases/tag/v2.2.0-detours17
```

SourceMod 1.11 使用文件名带 `sm110` 的包。安装后检查：

```text
sm exts list
sm plugins list
```

- `sm exts list` 里应看到 `DHooks (2.2.0)` 且已加载
- `sm plugins list` 里应看到 `MovementAPI`、`GOKZ` 系列插件和 `NoLobbyReservation`

如果 DHooks 没加载，MovementAPI 和 GOKZ 模式插件会失败，服务器会退回普通 CS:GO 模式；如果没有 NoLobbyReservation，客户端会卡在大厅/无法直接连接。

## 获取服务器 Key

向 ThRei 管理员申请服务器 Key。Key 只发给服主，不要公开。

## 文件（安装包）

```text
addons/sourcemod/plugins/*.smx
addons/sourcemod/gamedata/*
addons/sourcemod/translations/*

cfg/sourcemod/gokz/*
cfg/sourcemod/globalapi-key.cfg.example
cfg/sourcemod/globalapi-convars.cfg.example

maps/gokz-replays.nav
```

## 一键安装（推荐）

解压后，在解压目录里执行。

### Linux

```bash
./install.sh /path/to/csgo
```

例如：

```bash
./install.sh /home/csgo/serverfiles/csgo
```

### Windows

双击：

```text
install.bat
```

或者在 PowerShell 里：

```powershell
.\install.ps1 -Target C:\path\to\csgo
```

脚本会：

- 备份旧的 GOKZ 插件、gamedata、翻译和 cfg 到 `plugins/disabled/threi-backup-*`
- 停用 `GlobalAPI-Core.smx` / `GlobalAPI-Jumpstats.smx`
- 停用 `threi-kz-uploader.smx`
- 复制全部 GOKZ 插件、gamedata、翻译、配置和 `maps/gokz-replays.nav`
- 如果 `globalapi-key.cfg` 不存在，自动创建

然后编辑：

```text
csgo/cfg/sourcemod/globalapi-key.cfg
```

第一行放 ThRei Key。

## 手动安装

1. 备份现有 GOKZ 插件和翻译。

2. 把 `addons/` 覆盖到：

   ```text
   csgo/addons/
   ```

3. 把 `maps/gokz-replays.nav` 放到：

   ```text
   csgo/maps/gokz-replays.nav
   ```

4. 把 ThRei 服务器 Key 写到：

   ```text
   csgo/cfg/sourcemod/globalapi-key.cfg
   ```

   第一行只放 Key：

   ```text
   threi_xxxxxxxxxxxxxxxxxxxxxxxx
   ```

5. 删除/停用旧的 GlobalAPI 插件（如果文件名不同）：

   ```text
   GlobalAPI-Core.smx
   GlobalAPI-Jumpstats.smx
   ```

   **不要删除新的 `GlobalAPI.smx`**，GOKZ 需要这个库名。

6. 停用 `threi-kz-uploader.smx`。现在 GOKZ 已经直接上传，两个同时开会重复上传。
   uploader 只保留用于手动历史回填。

7. 重启服务器。改 key 后必须重启，换图不会重新读取 key。

## 计分板格式

如果 `gokz-profile.cfg` 不存在，插件会自动生成。默认：

```cfg
sm_threi_clan_format "[{mode_initial} CN {rank}]"
```

效果：

```text
[K CN Amateur+]
[S CN Skilled+]
[V CN Regular+]
K CN Beginner+
```

聊天栏仍然是 `[KZT CN Beginner+]`。

## 检查

```text
sm plugins list
!gc
```

`!gc` 里 API Key / Plugins / Settings Enforcer / Map / You 都应该是绿色。

## 常用命令

```text
!gc / !globalcheck
!gpb
!gmaptop
!profile
!pb
!wr
```

## 说明

- `GlobalAPI.smx` 是 ThRei 兼容层，不是 kztimerglobal 插件。
- 新地图必须先加入 ThRei 地图池，否则 GOKZ 不会上传该地图的成绩。
- 地图文件大小会参与校验；请确保服务器地图版本与地图池一致。
- 回放需要 `csgo/maps/gokz-replays.nav`，安装包已经包含。
