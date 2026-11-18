# P0 环境记录（2026-11-18，Asia/Shanghai）

用户已批准以现有截断规范为基线、项目本地工具安装以及初始化 `chore/p0-bootstrap` 分支；本阶段不修改任何 AGENTS.md 或 SRS。

| 项目 | 实际结果 |
|---|---|
| 系统 | Windows 11，PowerShell 5.1 |
| JDK | PATH 的 Oracle JDK 17.0.1，包含 javac；Maven 原 JAVA_HOME 为 JDK 21，脚本仅进程级选用 JDK 17 |
| Maven | 3.8.8；Spring Boot 3.5.7；Enforcer 限定 Java [17,18)、Maven >=3.8.8 |
| Node/npm | 22.22.1 / 11.12.1 |
| Python | 默认 Miniconda 3.13.11 不用于工程；uv 0.9.17 安装本地 CPython 3.12.12，ai-engine/.venv |
| Docker | 客户端/引擎 29.2.1，desktop-linux context |
| Compose | 官方 V2 2.39.4，本地 .tools/docker/cli-plugins/docker-compose.exe |
| Compose SHA256 | 6b3bccfabcdd172e1d9e15d011b54c9b5b13b93b1153148108f55e4349055955；与官方 .sha256 一致 |
| PostgreSQL | postgres:17.6-bookworm，宿主绑定 127.0.0.1:5432，Compose healthy |
| FFmpeg | 8.1 essentials，仅检查未执行媒体生产 |
| Git | 初始化 chore/p0-bootstrap；已按用户提供的信息配置仓库本地提交身份 z2hYtwo；origin 为 https://github.com/z2hYtwo/acr.git |

## 环境问题与处理

- Python launcher 的 E:/python/python.exe 登记失效：不修全局登记，使用工程本地 Python。
- 原 PyPI 镜像未返回 uv 版本：本次改为官方 https://pypi.org/simple 下载。
- 原 Docker Compose 缺失：下载官方插件，校验 SHA256；本地 DOCKER_CONFIG 复制既有 config/contexts，避免破坏用户 context。副本均被忽略。
- npm 官方 registry 对包元数据下载停滞：本次安装使用 npmmirror，随后将 lockfile resolved URL 归一为官方 registry，`npm ci` 已单独执行；未更改用户 registry 配置。
- Windows PowerShell 将 native stderr 警告提升为终止错误：Invoke-Checked 暂时允许输出，最后按 LASTEXITCODE 判断成功。
- Vite 运行时 npm ci 无法删除占用的 esbuild.exe：verify 脚本先停止本工程拥有的应用，再安装/验证，最后重新启动。
- PowerShell 管道输出 JSON 数组需先赋值再枚举；Python 虚拟环境 Windows launcher 会产生子进程：停止脚本核对记录 PID 启动时间并停止其子进程，不按进程名批量结束。
- Python 脚本 BOM 经默认工具编码读写产生异常：工程测试文件使用 UTF-8；使用本地 Python 3.12 校验。

## 范围

未配置任何 LLM、图片、视频、音频供应商，能力清单均为未验证；没有真实付费模型调用。完整 Linux 启动尚未执行，仅 Bash 语法检查，不报告跨平台运行已通过。
