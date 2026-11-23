.DEFAULT_GOAL := help

CONFIG := {"lineLength":120,"tabWidth":4,"indentation":{"tabs":1}}
SIMULATOR   := iPhone 17e
DESTINATION := platform=iOS Simulator,name=$(SIMULATOR)

URL ?= https://git.schindlerfelix.de
SPEC_OUT := Gitea/openapi.json
EMOJI_OUT := Gitea/Core/emoji.json

.DEFAULT_GOAL := help
.PHONY: help fmt spec emoji build licenses

help:
	@echo "Gitea iOS — available targets:"
	@echo "  make fmt       Format Swift sources in place (swift format)"
	@echo "  make spec      Regenerate $(SPEC_OUT) from the server"
	@echo "  make emoji     Regenerate $(EMOJI_OUT) from the server"
	@echo "  make build     Build for the $(SIMULATOR) simulator"
	@echo "  make licenses  Regenerate Settings.bundle licenses"

fmt:
	swift format -p -r -i --configuration '$(CONFIG)' ./Gitea

spec:
	curl -sS "$(URL)/openapi3.v1.json" | jq '.paths["/repos/{owner}/{repo}/raw/{filepath}"].get.responses["200"].content = {"text/plain": {"schema": {"type": "string"}}} | .components.responses.string.content = {"text/plain": {"schema": {"type": "string"}}} | (.paths["/repos/{owner}/{repo}/issues/{index}/assets"].post.requestBody.required = true) | (.paths["/repos/{owner}/{repo}/issues/comments/{id}/assets"].post.requestBody.required = true) | (.paths["/repos/{owner}/{repo}/releases/{id}/assets"].post.requestBody.required = true)' > $(SPEC_OUT)
	@echo "updated $(SPEC_OUT) (server version $$(jq -r .info.version $(SPEC_OUT)))"

emoji:
	curl -sS "$(URL)/assets/emoji.json" | jq -c 'map(.aliases[] as $$a | {(":" + $$a + ":"): .emoji}) | add' > $(EMOJI_OUT)
	@echo "updated $(EMOJI_OUT) ($$(jq length $(EMOJI_OUT)) aliases)"

build:
	xcodebuild -project Gitea.xcodeproj -scheme Gitea -destination '$(DESTINATION)' build

licenses:
	license-plist --config-path license_plist.yml
