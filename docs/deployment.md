# Deployment / 發佈流程

## 事前準備

- CI/CD 透過 Travis CI 執行，請在 Travis 專案設定中建立環境變數 `GITHUB_PAT`（需具備 `write:packages` 與 `repo` 權限），登入 GHCR 時會使用固定帳號 `devops`。
- 建置完成的容器映像會推送到 `ghcr.io/104corp/agent-chat-ui:<tag>`，並自動帶上 `org.opencontainers.image.source=https://github.com/104corp/agent-chat-ui` 標籤，方便在 GHCR 與 GitHub Repo 建立關聯。

## 驗證流程（Verify Stage）

- 針對 `main` 分支與 Pull Request，Travis 會執行 `make test`：
  - `pnpm run lint`
  - `pnpm run build`

若任一指令失敗，整個 verify 階段會中止。

## Tag Release 流程（Release Stage）

1. 確認 `main` 分支已是最新且測試通過。
2. 建立版本標籤並推送：
   ```bash
   git tag 0.0.x
   git push origin 0.0.x
   ```
3. Travis 收到 tag 後會執行：
   - 安裝 Trivy。
   - `make docker/publish IMAGE_TAG="$TRAVIS_TAG"`，其中包含：
     - `docker build` 依據 `Dockerfile` 建置映像。
     - `trivy image --severity "CRITICAL" --vuln-type=os --ignore-unfixed` 掃描 OS 層 CRITICAL 漏洞。
     - `docker push` 以 `devops` + `GITHUB_PAT` 登入 GHCR 後推送映像。
4. 完成後，可至 GitHub Packages (GHCR) 確認 `agent-chat-ui:<tag>` 是否成功發佈，並檢視 Trivy 掃描結果。

## 本地輔助指令

- `make test`：執行 lint 與 build。
- `make docker/build IMAGE_TAG=<tag>`：僅建置映像。
- `make docker/scan IMAGE_TAG=<tag>`：使用 Trivy 掃描已建置的映像。
- `make docker/publish IMAGE_TAG=<tag>`：建置 → 掃描 → 推送的整合流程（需提供 `GITHUB_PAT`）。
- `make help`：列出 Makefile 的主要指令。

> 若需清除 GHCR 的舊版本，可在 GitHub Packages 介面或透過 GitHub API 刪除對應版本。
