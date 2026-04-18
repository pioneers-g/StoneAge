# 石器时代服务端 2.28 部署文档

> 本文档对应版本：龙zoro版GMSV服务端 v2.2.2.28 + SAAC 账号服务端
> 适用系统：Ubuntu 24.04（其他 Linux 发行版类似）

---

## 一、环境要求

### 1.1 硬件
- CPU：任意 x86_64
- 内存：建议 4GB+
- 磁盘：约 500MB（不含客户端）

### 1.2 依赖软件

```bash
# Ubuntu / Debian
sudo apt update
sudo apt install -y \
    build-essential \
    gcc \
    make \
    default-libmysqlclient-dev \
    zlib1g-dev \
    libssl-dev \
    mariadb-server \    # 或 mysql-server
    git
```

**说明：**
- `gcc` / `make` — 编译工具链
- `default-libmysqlclient-dev` — MySQL/MariaDB 客户端库（编译 saac 需要的 `-lmysqlclient`）
- `zlib1g-dev` — zlib 压缩库（编译需要）
- `libssl-dev` — OpenSSL 开发库
- `mariadb-server` — 数据库服务（saac 需要连接数据库）

---

## 二、目录结构

```
StoneAge/
├── gmsv/                    # 游戏服务端
│   ├── src/                # 源代码
│   │   ├── Makefile        # 编译规则
│   │   └── *.c *.h         # 源文件
│   ├── data/               # 游戏数据（地图、NPC、道具等）
│   ├── log/                 # 运行日志
│   ├── lock/                # 锁文件
│   ├── setup.cf            # GMSV 配置文件
│   ├── sql.cf              # 数据库配置（saac 用）
│   └── gmsv                # 编译好的可执行文件
│
├── saac/                    # 账号服务端
│   ├── src/                # 源代码
│   │   ├── Makefile        # 编译规则
│   │   └── *.c *.h         # 源文件
│   ├── char/               # 角色存档目录
│   ├── char_sleep/         # 离线角色目录
│   ├── db/                 # 数据库初始化脚本
│   ├── data/               # 账号数据（家族、庄园等）
│   ├── log/                # 日志目录
│   ├── lock/               # 锁文件目录
│   ├── mail/               # 邮件目录
│   ├── acserv.cf           # SAAC 配置文件
│   └── saac                # 编译好的可执行文件
```

---

## 三、编译

### 3.1 克隆代码（如需）

```bash
git clone https://github.com/pioneers-g/StoneAge.git
cd StoneAge
```

### 3.2 编译 saac（账号服务端）

```bash
cd saac/src
make clean
make -j$(nproc)
```

编译产物：`../saac`

### 3.3 编译 gmsv（游戏服务端）

```bash
cd gmsv/src
make clean
make -j$(nproc)
```

编译产物：`../gmsv`

### 3.4 编译常见问题

| 问题 | 解决 |
|------|------|
| `fatal error: mysql/mysql.h: No such file` | 安装 `default-libmysqlclient-dev` |
| `undefined reference to mysql_*` | 链接顺序问题，Makefile 里已有 `-lmysqlclient` |
| `ld: cannot find -lmysqlclient` | 确认安装了 `libmysqlclient-dev` 或 `default-libmysqlclient-dev` |
| `undefined reference to compress` | 确认安装了 `zlib1g-dev` |

---

## 四、数据库初始化

### 4.1 启动 MariaDB

```bash
sudo systemctl start mariadb
sudo systemctl enable mariadb
```

### 4.2 创建数据库和用户

```bash
sudo mysql
```

```sql
CREATE DATABASE sa CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'root'@'127.0.0.1' IDENTIFIED BY '123456789';
GRANT ALL PRIVILEGES ON sa.* TO 'root'@'127.0.0.1';
FLUSH PRIVILEGES;
USE sa;

-- 建表（参考 saac/src/ 下的 SQL 文件）
-- 以下为基础表结构示例：
CREATE TABLE logindata (
    username VARCHAR(64) PRIMARY KEY,
    passwd VARCHAR(128) NOT NULL,
    online INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 如有更多表，执行 db/ 目录下的 sql 文件
-- SOURCE /path/to/StoneAge/saac/db/*.sql;
```

### 4.3 验证连接

```bash
mysql -h 127.0.0.1 -u root -p123456789 -e "USE sa; SHOW TABLES;"
```

---

## 五、配置

### 5.1 SAAC 配置文件（saac/acserv.cf）

```ini
sql_IP        127.0.0.1
sql_Port      3306
sql_ID        root
sql_PS        123456789
sql_DataBase  sa
sql_Table     logindata
sql_LOCK      user_lock
sql_Name      username
sql_PassWord  passwd
sql_OnlineName online
AutoReg       1

port          9301          # SAAC 监听端口
pass          test          # SAAC 连接密码（gmsv setup.cf 里要一致）
rotale_internal 1000

dbdir         db
logdir        log
lockdir       lock
chardir       char
sleepchardir  char_sleep
wklogdir      data/wklog
maildir       mail
familydir     data/family
fmpointdir    data/fmpointdir
fmsmemodir    data/fmsmemodir

Total_Charlist   3600
Expired_mail     600
Del_Family_or_Member 3600
Write_Family     600
```

### 5.2 GMSV 配置文件（gmsv/setup.cf）

关键配置项：

```ini
# 连接 SAAC
acserv     = 127.0.0.1          # SAAC 服务器地址
acservport = 9301              # SAAC 端口
acpasswd   = test              # SAAC 密码（必须和 acserv.cf 一致）

# 游戏服务器
gameservname = 石器时代          # 服务器名称
gameservid   = 1               # 服务器 ID
port         = 1234            # GMSV 监听端口
servernumber = 1

# 路径配置（相对路径，相对于 gmsv/ 目录）
storedir      = ../saac/char    # 角色存档目录（写到这里）
npcdir        = data/npc        # NPC 目录
mapdir        = data/map        # 地图目录
logdir        = ./log           # 日志目录
```

**注意：** `acserv`、`acservport`、`acpasswd` 必须和 saac/acserv.cf 里的配置完全一致。

---

## 六、部署运行

### 6.1 创建运行用户（建议）

```bash
sudo useradd -m -s /bin/bash stoneage
sudo chown -R stoneage:stoneage /path/to/StoneAge
```

### 6.2 准备目录权限

```bash
mkdir -p saac/log saac/lock saac/char saac/char_sleep saac/mail
mkdir -p gmsv/log gmsv/lock
chmod 777 saac/lock saac/char saac/char_sleep gmsv/lock
```

### 6.3 启动顺序（重要！）

**必须先启动 saac，等 saac 完全启动后再启动 gmsv。**

#### 第一步：启动 saac（账号服务端）

```bash
cd /path/to/StoneAge/saac
rm -f lock/saac.*           # 清理旧锁文件
./saac
```

或后台运行：

```bash
cd /path/to/StoneAge/saac
nohup ./saac > saac.log 2>&1 &
```

验证 saac 启动成功：

```bash
ss -tlnp | grep 9301
# 应该看到：LISTEN 0.0.0.0:9301
```

#### 第二步：启动 gmsv（游戏服务端）

```bash
cd /path/to/StoneAge/gmsv
./gmsv
```

或后台运行：

```bash
nohup ./gmsv > gmsv.log 2>&1 &
```

验证 gmsv 启动成功：

```bash
ss -tlnp | grep 1234
# 应该看到：LISTEN 0.0.0.0:1234
```

### 6.4 查看日志

```bash
# saac 日志
tail -f /path/to/StoneAge/saac/saac.log

# gmsv 日志
tail -f /path/to/StoneAge/gmsv/gmsv.log
```

成功启动的标志：

```
SAAC 日志：端口:9301 + 数据库连接成功
GMSV 日志：SAAC登陆成功 + 新服务器! + 玩家=0 ...
```

---

## 七、防火墙

如果需要远程访问（客户端不在本机），开放端口：

```bash
sudo ufw allow 3306   # MySQL（仅限内网）
sudo ufw allow 9301    # SAAC
sudo ufw allow 1234    # GMSV
```

**注意：** 生产环境建议 SAAC 只对内网开放，不要暴露到公网。

---

## 八、Systemd Service（开机自启）

### 8.1 saac.service

```ini
# /etc/systemd/system/saac.service
[Unit]
Description=StoneAge Account Server (SAAC)
After=mariadb.service
Wants=mariadb.service

[Service]
Type=simple
User=stoneage
WorkingDirectory=/path/to/StoneAge/saac
ExecStart=/path/to/StoneAge/saac/saac
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### 8.2 gmsv.service

```ini
# /etc/systemd/system/gmsv.service
[Unit]
Description=StoneAge Game Server (GMSV)
After=saac.service
Wants=saac.service

[Service]
Type=simple
User=stoneage
WorkingDirectory=/path/to/StoneAge/gmsv
ExecStart=/path/to/StoneAge/gmsv/gmsv
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### 8.3 启用

```bash
sudo systemctl daemon-reload
sudo systemctl enable saac
sudo systemctl enable gmsv
sudo systemctl start saac
# 等 3 秒
sudo systemctl start gmsv
```

---

## 九、故障排查

### 9.1 gmsv 启动后立即崩溃

**检查 saac 是否在运行：**
```bash
ss -tlnp | grep 9301
```
如果 saac 没运行，gmsv 会因为连不上账号服务器而退出。

**检查连接配置：**
确认 `gmsv/setup.cf` 里的 `acserv`、`acservport`、`acpasswd` 和 `saac/acserv.cf` 完全一致。

### 9.2 数据库连接失败

```
数据库连接失败！
```

- 确认 MariaDB 正在运行：`sudo systemctl status mariadb`
- 确认账号密码正确（检查 acserv.cf 和 sql.cf）
- 确认数据库和表已创建

### 9.3 端口被占用

```
不能开启TCP: -3
bind: Address already in use
```

```bash
# 查找占用端口的进程
ss -tlnp | grep 9301
ss -tlnp | grep 1234
# 杀掉旧进程
sudo kill -9 <PID>
```

### 9.4 地图传送点错误（不影响启动）

```
object.c:65 MAP_addNewObj error
2.map 传送点错误 NONE:NULL:...
```

这些警告不影响服务器启动和正常游戏，属于数据文件格式问题。

### 9.5 编译报错

详见"编译常见问题"表格。

---

## 十、客户端连接

服务端运行后，客户端配置：

```
服务器地址：<运行服务器的 IP>
SAAC 端口：9301
GMSV 端口：1234
```

---

## 十一、文件说明

| 文件/目录 | 说明 |
|-----------|------|
| `gmsv/setup.cf` | GMSV 主配置 |
| `saac/acserv.cf` | SAAC 主配置 |
| `gmsv/data/` | 地图、NPC、道具、宠物等游戏数据 |
| `saac/char/` | 玩家角色存档（重要！） |
| `saac/db/` | 数据库相关文件 |
| `saac/mail/` | 离线邮件 |
| `saac/data/` | 家族、庄园等数据 |

---

## 十二、版本信息

- **GMSV 版本：** 龙zoro版GMSV服务端 v2.2.2.28
- **SAAC 版本：** 2.27
- **编译环境：** Ubuntu 24.04 LTS / GCC 13
- **依赖：** MySQL/MariaDB, zlib, OpenSSL
