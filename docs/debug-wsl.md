# Debug Environment Setup

這份文件整理目前專案在 `VS Code + Remote WSL` 下的 debug 建立方式。

適用對象：

- 想在 WSL 內直接 source-level debug Fastify API
- 想在 VS Code 裡 attach 到 Docker 內的 API debugger
- 想讓 Flutter Web 走本機 API 做聯調

目前建議把 VS Code 開在 `Remote WSL` 視窗內操作，不要直接用 Windows 本機視窗跑這套設定。

## 1. 先確認你要走哪條路

本 repo 目前有兩條 debug 路徑：

1. `WSL Local Debug`
   - API 直接在 WSL 內跑 source code
   - Flutter Web 也直接在 WSL 內啟動
   - 適合日常開發與單步除錯
2. `Docker API Debug`
   - Postgres + API 跑在 Docker
   - VS Code attach 到 API container 的 Node inspector
   - 適合驗證容器環境與 API 問題

注意：

- Flutter 容器目前只是 nginx 靜態 preview，不是 source-level Flutter debugger
- 所以 Docker 路線目前只支援 API debug，不支援 Flutter source debug

## 2. 前置條件

### 2.1 WSL

先確認 WSL 可用：

```bash
wsl -l -v
```

需要看到你的 Linux 發行版，例如 `Ubuntu-22.04`。

### 2.2 用 Remote WSL 開專案

在 VS Code 中：

1. 安裝 `Remote - WSL`
2. 使用 `Remote-WSL: Open Folder in WSL...`
3. 打開專案目錄：

```text
<path_to_your_project>
```

不要直接在 Windows 視窗打開 `<path_to_your_project>` 版本來跑這份 debug 設定。

### 2.3 WSL 內的 Node.js

API debug 預設使用 Node 20。

在 WSL 裡確認：

```bash
source ~/.nvm/nvm.sh
nvm ls
```

如果沒有 Node 20：

```bash
nvm install 20
```

### 2.4 Docker Desktop

Windows 端要有 Docker Desktop，且 WSL 內可呼叫：

```bash
docker.exe version
docker.exe compose version
```

這個 repo 目前的 VS Code tasks 會優先透過 `docker.exe compose` 啟動容器。

### 2.5 Flutter SDK

如果你要跑 Flutter source debug，必須在 WSL 內安裝 Flutter，並確保 `flutter` 在 PATH 中：

```bash
flutter --version
```

如果這一步失敗，`Flutter: Web Debug (WSL)` 會無法啟動。

## 3. 專案內已準備好的 debug 設定


可用的 launch configurations：

- `API: Local Debug (WSL)`
- `Flutter: Web Debug (WSL)`
- `Full Stack: WSL Debug`
- `API: Attach Docker Debug`

## 4. Step By Step: 建立 WSL 本機 Debug 環境

這條流程會讓你在 WSL 內直接 debug API，並可再接 Flutter Web。

### Step 1. 用 Remote WSL 開啟 repo

確認工作目錄是：

```bash
pwd
```

應該是：

```text
<path_to_your_project>
```

### Step 2. 準備 API 環境檔

VS Code task 會自動做，但你也可以手動確認：

```bash
cd services/api
ls .env
```

如果沒有，就建立：

```bash
cp .env.example .env
```

目前 `services/api/.env.example` 已對齊 WSL local DB port，會連到：

```text
postgresql://postgres:postgres@localhost:5433/bat_dating_app
```

### Step 3. 在 WSL 內安裝 API 依賴

這一步很重要，不要沿用 Windows 安裝的 `node_modules`。

原因：

- `tsx` 依賴 `esbuild`
- `esbuild` 是 native binary
- Windows 安裝的 binary 不能直接在 WSL Linux 使用

在 WSL 中執行：

```bash
cd services/api
source ~/.nvm/nvm.sh
nvm use 20
npm install
```

### Step 4. 產生 Prisma Client

```bash
cd services/api
npm run prisma:generate
```

### Step 5. 啟動 Postgres

這個專案目前把 local DB 啟動交給 Docker Desktop：

```bash
cd <path_to_your_project>
cp .env.example .env
docker.exe compose -f docker-compose.yml up -d postgres
```

如果 `.env` 不存在，VS Code 的 `api:db up (WSL)` task 現在也會自動從 `.env.example` 建立。

確認狀態：

```bash
docker.exe compose -f docker-compose.yml ps postgres
```

你應該看到 `bat-dating-postgres` 正常運行，對外 port 為 `5433`。

### Step 6. 避免 `3000` 被容器 API 佔用

如果你之前有跑過 preview stack 或 docker API，先把它停掉：

```bash
cd <path_to_your_project>
docker.exe compose -f docker-compose.yml stop api
```

否則本機 API debug 啟動時會遇到：

```text
EADDRINUSE: address already in use 0.0.0.0:3000
```

### Step 7. 在 VS Code 啟動 API debug

打開 VS Code Debug 面板，選：

```text
API: Local Debug (WSL)
```

這個 launch 會先自動執行：

- `api:prepare (WSL)`
- `api:db up (WSL)`
- `api:free port 3000 (WSL)`

然後再以 Node 20 + `tsx` 啟動：

```text
services/api/src/server.ts
```

### Step 8. 驗證 API 是否啟動成功

在 WSL 或 Windows 任一端確認：

```bash
curl http://127.0.0.1:3000/
```

如果成功，應可拿到 API 根路由回應。

## 5. Step By Step: 建立 Flutter Web Debug 環境

這條流程依賴前面的 API local debug 已可用。

### Step 1. 確認 WSL 內 Flutter 可用

```bash
flutter --version
```

如果沒有安裝，先把 Flutter SDK 裝到 WSL，並把執行檔路徑加入 PATH。

### Step 2. 安裝 Flutter 依賴

```bash
cd <path_to_your_project>/apps/mobile_flutter
flutter pub get
```

### Step 3. 在 VS Code 啟動 Flutter debug

選：

```text
Flutter: Web Debug (WSL)
```

或直接選：

```text
Full Stack: WSL Debug
```

這個設定會使用：

- `deviceId = web-server`
- `--web-hostname 0.0.0.0`
- `--web-port 7357`
- `--dart-define=API_BASE_URL=http://localhost:3000`

### Step 4. 驗證 Flutter Web

啟動後可在瀏覽器打開：

```text
http://localhost:7357
```

如果 API 也已啟動，Flutter 會直接打本機 API：

```text
http://localhost:3000
```

## 6. Step By Step: 建立 Docker API Debug 環境

這條流程會讓 API 跑在 Docker 裡，然後由 VS Code attach debugger。

### Step 1. 確認 Docker 可正常 build API

在 WSL 內執行：

```bash
cd <path_to_your_project>
docker.exe compose -f docker-compose.yml -f docker-compose.debug.yml build api
```

### Step 2. 啟動 Docker debug API

在 VS Code Debug 面板選：

```text
API: Attach Docker Debug
```

這個設定會先執行：

```text
docker:api debug up
```

其效果等同：

```bash
docker.exe compose -f docker-compose.yml -f docker-compose.debug.yml up -d --build postgres api
```

### Step 3. 確認 debug port

目前本機對外埠是：

```text
127.0.0.1:19239 -> container 9229
```

確認方式：

```bash
docker.exe ps --filter name=bat-dating-api
```

你應該看到類似：

```text
127.0.0.1:3000->3000/tcp, 127.0.0.1:19239->9229/tcp
```

### Step 4. Attach debugger

VS Code 會自動 attach 到：

```text
127.0.0.1:19239
```

對應容器內的：

```text
node --inspect=0.0.0.0:9229 --import tsx src/server.ts
```

### Step 5. 結束 Docker debug

停止 debug 後，VS Code 會自動執行：

```text
docker:api debug down
```

等同：

```bash
docker.exe compose -f docker-compose.yml -f docker-compose.debug.yml stop api postgres
```

## 7. 推薦的日常使用方式

如果你是日常開發，建議：

1. 用 `API: Local Debug (WSL)` 跑 API
2. 用 `Flutter: Web Debug (WSL)` 跑 Flutter
3. 需要容器驗證時，再切到 `API: Attach Docker Debug`

也就是說：

- 平常除錯優先用 WSL local
- 容器相關問題再用 Docker attach

## 8. 常見錯誤與排查

### 8.1 `flutter: command not found`

原因：

- WSL 尚未安裝 Flutter
- Flutter 不在 WSL PATH

處理：

```bash
flutter --version
```

先讓這條指令在 WSL 能執行。

### 8.2 `EADDRINUSE: 0.0.0.0:3000`

原因：

- Docker 版 API 還佔著 `3000`

處理：

```bash
docker.exe compose -f docker-compose.yml stop api
```

### 8.3 `esbuild for another platform`

原因：

- `services/api/node_modules` 是在 Windows 安裝的
- WSL 啟動時需要 Linux 版 native binary

處理：

```bash
cd services/api
npm install
```

要在 WSL 裡重新安裝一次。

### 8.4 Postgres 起在錯的 port

原因：

- root `.env` 不存在時，`docker-compose.yml` 會退回 fallback 值
- `services/api/.env` 預設期待的是 `localhost:5433`

處理：

- 確認 repo root 有 `.env`
- 或直接先建立：

```bash
cd <path_to_your_project>
cp .env.example .env
```

再啟動 Postgres：

```bash
cd <path_to_your_project>
docker.exe compose -f docker-compose.yml up -d postgres
```

### 8.5 Docker debug 綁不到 9229

原因：

- 這台 Windows 對部分 9xxx port 有限制或排除範圍

處理：

- 目前已改成使用本機 `19239`
- 不要再手動改回 `9229`

## 9. 快速清單

### WSL Local API Debug

1. 用 Remote WSL 開 repo
2. `cd services/api`
3. `source ~/.nvm/nvm.sh && nvm use 20`
4. `npm install`
5. `npm run prisma:generate`
6. `docker.exe compose -f docker-compose.yml up -d postgres`
7. `docker.exe compose -f docker-compose.yml stop api`
8. VS Code 選 `API: Local Debug (WSL)`

### WSL Full Stack Debug

1. 先完成 API local debug 前置
2. 確認 `flutter --version`
3. `cd apps/mobile_flutter && flutter pub get`
4. VS Code 選 `Full Stack: WSL Debug`

### Docker API Debug

1. `docker.exe compose -f docker-compose.yml -f docker-compose.debug.yml build api`
2. VS Code 選 `API: Attach Docker Debug`
3. 確認 `127.0.0.1:19239 -> 9229`

## 10. 目前限制

- Flutter source debug 仍要求你先在 WSL 安裝 Flutter SDK
- Docker 路線目前只支援 API debug，不支援 Flutter source debug
- API 本機 debug 與 Docker API debug 不應同時佔用 `3000`
