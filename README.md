# StoneAge 石器时代服务端

> **龙zoro版 GMSV v2.2.2.28 + SAAC 2.27**
> 石器时代 8.0 服务端源码，适配现代 Linux + MySQL/MariaDB 环境

---

## 📖 文档

**[📦 部署指南（新手必看）](docs/deploy.md)**

包含完整的依赖安装、编译、数据库配置、部署运行、开机自启等说明。

---

## 🚀 快速启动

### 1. 下载编译好的发布包

```
https://github.com/pioneers-g/StoneAge/releases/download/v2.28/StoneAge-v2.28-release.tar.gz
```

### 2. 依赖安装（Ubuntu 24.04）

```bash
sudo apt update
sudo apt install -y build-essential gcc make default-libmysqlclient-dev zlib1g-dev mariadb-server
```

### 3. 初始化数据库

```bash
sudo mysql
```
```sql
CREATE DATABASE sa CHARACTER SET utf8mb4;
CREATE USER 'root'@'127.0.0.1' IDENTIFIED BY '123456789';
GRANT ALL ON sa.* TO 'root'@'127.0.0.1';
```

### 4. 启动顺序（关键！）

```bash
# 第一步：启动账号服务器 SAAC
cd saac && ./saac

# 第二步：启动游戏服务器 GMSV（另开终端）
cd gmsv && ./gmsv
```

> ⚠️ **必须先启动 saac，等 saac 完全启动后再启动 gmsv**

### 5. 连接验证

服务端正常运行标志：
- SAAC 日志显示：`端口:9301` + `数据库连接成功！`
- GMSV 日志显示：`SAAC登陆成功` + `新服务器!`

---

## 📁 目录结构

```
StoneAge/
├── gmsv/           # 游戏服务端（端口 1234）
│   ├── gmsv        # 编译好的二进制
│   ├── data/       # 游戏数据（地图、NPC、道具、宠物等）
│   ├── setup.cf    # GMSV 主配置
│   └── log/        # 运行日志
├── saac/           # 账号服务端（端口 9301）
│   ├── saac        # 编译好的二进制
│   ├── char/       # 玩家角色存档
│   ├── db/         # 数据库相关
│   └── acserv.cf   # SAAC 主配置
└── docs/
    └── deploy.md   # 详细部署文档
```

---

## 🔧 编译源码

```bash
# 编译 SAAC
cd saac/src && make clean && make -j$(nproc)

# 编译 GMSV
cd gmsv/src && make clean && make -j$(nproc)
```

详细说明见 [部署指南](docs/deploy.md)。

---

## 🛠 配置说明

| 文件 | 说明 | 关键配置 |
|------|------|---------|
| `saac/acserv.cf` | SAAC 账号服务器配置 | `port`, `pass`, 数据库账号 |
| `gmsv/setup.cf` | GMSV 游戏服务器配置 | `acserv`, `acservport`, `acpasswd` 必须和 saac 一致 |

---

## ⚙ Systemd 开机自启

详见 [部署指南 - 第八节](docs/deploy.md#八systemd-service开机自启)

---

## ❓ 常见问题

| 问题 | 解决 |
|------|------|
| gmsv 启动后立即退出 | 检查 saac 是否在运行，gmsv 需要先连接 saac |
| 数据库连接失败 | 确认 MariaDB 启动，账号密码正确 |
| 端口被占用 | `ss -tlnp \| grep 1234` 查找并 kill |

完整故障排查见 [部署指南 - 第九节](docs/deploy.md#九故障排查)

---

## 📝 版本信息

- **GMSV：** 龙zoro版 v2.2.2.28
- **SAAC：** 2.27
- **编译环境：** Ubuntu 24.04 LTS / GCC 13
- **依赖：** MySQL/MariaDB, zlib, OpenSSL

---

## 📜 License

本项目仅供学习研究使用。石器时代版权归原厂商所有。
