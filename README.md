# Self-Hosted Runner

这个仓库用于本地构建并运行 GitHub Actions self-hosted runner。

当前默认行为：

- 不再拉取远端可变的 `latest` 镜像。
- 通过本仓库的 Dockerfile 本地构建镜像。
- 基础镜像使用固定 digest。
- GitHub Actions runner 压缩包使用固定版本和 SHA-256 校验。
- Linux runner 镜像内已包含常用 CI 工具：`git`、`bash`、`sh`、`tar`、`unzip`、`make`、`node`、`npm`、`go`。

## 仓库内容

- `docker-compose.yml`: Linux x64 runner 的启动配置
- `docker-compose.mac.yml`: macOS 上构建 Linux ARM64 runner 的启动配置
- `.env.example`: 环境变量示例
- `Docker Image/Dockerfile`: Linux x64 runner 镜像
- `Docker Image/start.sh`: Linux x64 runner 启动脚本
- `Dockerfile.mac`: Linux ARM64 runner 镜像
- `start-mac.sh`: Linux ARM64 runner 启动脚本

## 前置要求

- Docker
- Docker Compose v2
- 具备目标仓库或组织的 runner 管理权限

## 启动方式

### Linux

1. 克隆仓库

```sh
git clone https://github.com/BetterAndBetterII/self-hosted-runner.git
cd self-hosted-runner
```

2. 如果你希望从固定源码版本构建，请切到你信任的 commit

```sh
git checkout <trusted-commit-sha>
```

3. 准备环境变量文件

```sh
cp .env.example .env
```

4. 编辑 `.env`

```dotenv
REPO=OWNER/REPO
REG_TOKEN=replace-with-a-fresh-registration-token
NAME=my-runner
```

5. 构建并启动

```sh
docker compose up -d --build
```

6. 查看日志

```sh
docker compose logs -f
```

7. 停止并移除容器

```sh
docker compose down
```

### Linux 同时运行多个 runner

如果你要同时跑两个或更多 runner，不要共用项目根目录下的同一个 `.env`。最简单的做法是：

- 为每个 runner 准备单独的 env 文件
- 为每次 `docker compose` 指定不同的 project name
- 为每个 runner 使用不同的 `NAME`

示例：

`runner.repo-a.env`

```dotenv
REPO=OWNER_A/REPO_A
REG_TOKEN=replace-with-a-fresh-registration-token-a
NAME=runner-repo-a
```

`runner.repo-b.env`

```dotenv
REPO=OWNER_B/REPO_B
REG_TOKEN=replace-with-a-fresh-registration-token-b
NAME=runner-repo-b
```

先构建镜像：

```sh
docker compose build
```

分别启动两个 runner：

```sh
docker compose -p runner-a --env-file runner.repo-a.env up -d
docker compose -p runner-b --env-file runner.repo-b.env up -d
```

查看各自日志：

```sh
docker compose -p runner-a logs -f
docker compose -p runner-b logs -f
```

分别停止：

```sh
docker compose -p runner-a down
docker compose -p runner-b down
```

说明：

- `-p` 会让 Compose 为每一组容器生成独立的容器名、网络名和状态，不会互相覆盖
- `--env-file` 让每个 runner 读取各自的 `REPO`、`REG_TOKEN`、`NAME`
- `REG_TOKEN` 可以不同；如果目标仓库或组织不同，本来就必须分别生成
- `NAME` 必须全局唯一，不能两个容器都叫同一个 runner 名
- 如果两个 runner 都注册到同一个仓库或组织，也建议用不同名字，例如 `runner-ci-1` 和 `runner-ci-2`

### macOS

macOS 这里运行的仍然是 Linux ARM64 runner 容器，不是原生 macOS runner。

```sh
cp .env.example .env
docker compose -f docker-compose.mac.yml up -d --build
```

停止：

```sh
docker compose -f docker-compose.mac.yml down
```

## 环境变量

Compose 文件默认从项目根目录的 `.env` 读取以下变量：

- `REPO`: 目标仓库或组织
  - 仓库级 runner: `owner/repo`
  - 组织级 runner: `owner`
- `REG_TOKEN`: GitHub 下发的 runner registration token
- `NAME`: runner 名称。必须唯一；如果远端已有同名 runner，启动脚本会使用 `--replace` 进行替换

可以先用下面命令检查配置是否齐全：

```sh
docker compose config
```

## 如何获取 REG_TOKEN

`REG_TOKEN` 不是 PAT，也不是长期 token。它是 GitHub 为 self-hosted runner 注册生成的短期 token。根据 GitHub 官方文档，这个 token 只在 1 小时内有效。

### 通过 GitHub Web UI 获取仓库级 token

1. 打开目标仓库
2. 进入 `Settings`
3. 进入 `Actions`
4. 进入 `Runners`
5. 点击 `New self-hosted runner`
6. 页面上会展示当前可用的 registration token

### 通过 GitHub Web UI 获取组织级 token

1. 打开目标组织
2. 进入 `Settings`
3. 进入 `Actions`
4. 进入 `Runners`
5. 点击 `New self-hosted runner`
6. 页面上会展示当前可用的 registration token

### 通过 GitHub CLI 获取仓库级 token

需要对目标仓库有管理员权限。

- fine-grained PAT 需要仓库 `Administration: write`
- classic PAT 需要 `repo` scope

```sh
gh api \
  --method POST \
  repos/OWNER/REPO/actions/runners/registration-token \
  --jq .token
```

### 通过 GitHub CLI 获取组织级 token

需要对目标组织有管理员权限。

- fine-grained PAT 需要组织 runner 相关管理权限
- classic PAT 通常需要 `admin:org`

```sh
gh api \
  --method POST \
  orgs/ORG/actions/runners/registration-token \
  --jq .token
```

拿到 token 后，立刻写入 `.env` 并执行 `docker compose up -d --build`。如果启动时出现 404 或注册失败，优先怀疑 token 已经过期，重新生成一个新的 token 即可。

## 当前镜像内容

Linux x64 runner 镜像当前内置以下常用工具：

- `git`
- `bash`
- `sh`
- `tar`
- `unzip`
- `zip`
- `make`
- `node`
- `npm`
- `go`
- `python3`
- `curl`
- `jq`
- `openssh-client`

## 安全说明

- Linux 镜像固定到 `ubuntu:24.04@sha256:67efaecc0031a612cf7bb3c863407018dbbef0a971f62032b77aa542ac8ac0d2`
- macOS 侧 ARM64 镜像固定到 `ubuntu:24.04@sha256:288ce2836bbcbed87626f077b10acb99006be8c3df12e21dda4f21ccbc58cc0b`
- GitHub Actions runner 固定为 `v2.331.0`
- runner 压缩包下载后会在镜像构建时校验 SHA-256
- `docker-compose.mac.yml` 默认不挂载 `/var/run/docker.sock`

## 常见问题

### runner 名称冲突

如果远端已经有同名 runner，本仓库启动脚本会使用 `--replace`。这会让新的 runner 替换远端已有的同名 runner。

### token 无效或过期

如果日志里出现类似下面的错误，通常是 token 已过期：

- `Response status code does not indicate success: 404 (Not Found)`

重新生成新的 registration token 并重启即可：

```sh
docker compose down
docker compose up -d --build
```

### 查看 runner 是否已上线

```sh
docker compose logs -f
```

正常情况下会看到：

```text
Runner successfully added
Listening for Jobs
```
