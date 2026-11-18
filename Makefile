.DEFAULT_GOAL := help

CONFIG := {"lineLength":120,"tabWidth":4,"indentation":{"tabs":1}}
SIMULATOR   := iPhone 17e
DESTINATION := platform=iOS Simulator,name=$(SIMULATOR)

SPEC_URL ?= https://git.schindlerfelix.de/openapi3.v1.json
SPEC_OUT := Gitea/openapi.json

.DEFAULT_GOAL := help
.PHONY: help fmt spec build licenses

help:
	@echo "Gitea iOS — available targets:"
	@echo "  make fmt       Format Swift sources in place (swift format)"
	@echo "  make spec      Regenerate $(SPEC_OUT) from the server"
	@echo "  make build     Build for the $(SIMULATOR) simulator"
	@echo "  make licenses  Regenerate Settings.bundle licenses"

fmt:
	swift format -p -r -i --configuration '$(CONFIG)' ./Gitea

spec:
	curl -sS "$(SPEC_URL)" | jq '.paths["/repos/{owner}/{repo}/raw/{filepath}"].get.responses["200"].content = {"text/plain": {"schema": {"type": "string"}}} | .components.responses.string.content = {"text/plain": {"schema": {"type": "string"}}} | (.paths["/repos/{owner}/{repo}/issues/{index}/assets"].post.requestBody.required = true) | (.paths["/repos/{owner}/{repo}/issues/comments/{id}/assets"].post.requestBody.required = true) | (.paths["/repos/{owner}/{repo}/releases/{id}/assets"].post.requestBody.required = true)' > $(SPEC_OUT)
	@echo "updated $(SPEC_OUT) (server version $$(jq -r .info.version $(SPEC_OUT)))"

build:
	xcodebuild -project Gitea.xcodeproj -scheme Gitea -destination '$(DESTINATION)' build

licenses:
	license-plist --config-path license_plist.yml
