REGISTRY ?= ghcr.io
NAMESPACE ?= 104corp
IMAGE_NAME ?= agent-chat-ui
IMAGE_TAG ?=
IMAGE ?= $(REGISTRY)/$(NAMESPACE)/$(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: docker/build docker/push docker/login docker/publish docker/scan _check-tag help test

help:
	@echo "可用指令："
	@echo "  make test                         # 執行 lint 與 build 驗證"
	@echo "  make docker/build IMAGE_TAG=<tag>   # 使用 Dockerfile 建置映像"
	@echo "  make docker/push  IMAGE_TAG=<tag>   # 登入 GHCR 後推送映像"
	@echo "  make docker/scan IMAGE_TAG=<tag>    # 使用 Trivy 掃描映像 CRITICAL 漏洞"
	@echo "  make docker/publish IMAGE_TAG=<tag> # 建置、掃描並推送映像"

test: ## 執行 lint 與 build 驗證
	pnpm run lint
	pnpm run build

_check-tag:
	@if [ -z "$(IMAGE_TAG)" ]; then echo "IMAGE_TAG 未設定，請以 IMAGE_TAG=<tag> 呼叫 make"; exit 1; fi

docker/login: ## 登入 GHCR 供推送使用
	@if [ -z "$(GITHUB_PAT)" ]; then echo "GITHUB_PAT 未設定，請於環境變數提供"; exit 1; fi
	echo "$$GITHUB_PAT" | docker login $(REGISTRY) -u devops --password-stdin

docker/build: _check-tag ## 建置 Docker 映像
	docker build -f Dockerfile -t $(IMAGE) .

docker/push: docker/login _check-tag ## 將映像推送至 GHCR
	docker push $(IMAGE)

docker/scan: _check-tag ## 使用 Trivy 掃描映像
	trivy image --severity "CRITICAL" --vuln-type=os --ignore-unfixed $(IMAGE)

docker/publish: docker/build docker/scan docker/push ## 建置後掃描並推送
