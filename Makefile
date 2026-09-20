# Developer tasks for the Gitea iOS app.
#
# `make` (or `make help`) lists the targets. See README.md for the tasks and
# AGENTS.md for the codegen gotchas behind `make spec`.

SHELL := /bin/sh

PROJECT     := Gitea.xcodeproj
SCHEME      := Gitea
SIMULATOR   := iPhone 15 Pro
DESTINATION := platform=iOS Simulator,name=$(SIMULATOR)

SPEC_URL ?= https://git.schindlerfelix.de/openapi3.v1.json
SPEC_OUT := Gitea/openapi.json

.DEFAULT_GOAL := help
.PHONY: help format spec build licenses

help:
	@echo "Gitea iOS — available targets:"
	@echo "  make format    Format Swift sources in place (swift format)"
	@echo "  make spec      Regenerate $(SPEC_OUT) from the server"
	@echo "  make build     Build for the $(SIMULATOR) simulator"
	@echo "  make licenses  Regenerate Settings.bundle licenses"

# Format all Swift sources in place (tabs, lineLength 200 via format.json).
# Run before committing.
format:
	swift format -irp --configuration ./format.json ./Gitea

# Regenerate $(SPEC_OUT) from the server, re-applying the three local fixes the
# server spec is missing. Never fetch the spec with raw curl: without these the
# generated client throws unexpectedContentTypeHeader at runtime (fixes 1-2) or
# the generator skips multipart asset upload bodies (fix 3).
#   1. repoGetRawFile serves the file with its own mime type (text/plain for
#      markdown etc.), not application/octet-stream as the spec declares.
#   2. Plain-string responses (raw diffs/patches, markup rendering, gpg token)
#      are served as text/plain, not application/json.
#   3. Asset-upload request bodies lack `required: true`.
# Requires curl and jq. Then rebuild.
spec:
	curl -sS "$(SPEC_URL)" | jq '.paths["/repos/{owner}/{repo}/raw/{filepath}"].get.responses["200"].content = {"text/plain": {"schema": {"type": "string"}}} | .components.responses.string.content = {"text/plain": {"schema": {"type": "string"}}} | (.paths["/repos/{owner}/{repo}/issues/{index}/assets"].post.requestBody.required = true) | (.paths["/repos/{owner}/{repo}/issues/comments/{id}/assets"].post.requestBody.required = true) | (.paths["/repos/{owner}/{repo}/releases/{id}/assets"].post.requestBody.required = true)' > $(SPEC_OUT)
	@echo "updated $(SPEC_OUT) (server version $$(jq -r .info.version $(SPEC_OUT)))"

build:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination '$(DESTINATION)' build

licenses:
	license-plist --config-path license_plist.yml
