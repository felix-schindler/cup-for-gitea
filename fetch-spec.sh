#!/bin/sh
# Regenerate Gitea/openapi.json from the server, re-applying local fixes that the
# server spec is missing. Requires curl and jq.
set -eu

SPEC_URL="${SPEC_URL:-https://git.schindlerfelix.de/openapi3.v1.json}"
OUT="Gitea/openapi.json"

curl -sS "$SPEC_URL" | jq '
  # Fix 1: repoGetRawFile serves the file with its mime type (text/plain for
  # markdown etc.), not application/octet-stream as declared by the server spec.
  # Without this the generated client throws unexpectedContentTypeHeader at runtime.
  .paths["/repos/{owner}/{repo}/raw/{filepath}"].get.responses["200"].content =
    {"text/plain": {"schema": {"type": "string"}}} |
  # Fix 2: plain-string responses (raw diffs/patches, markup rendering, gpg token)
  # are served as text/plain, not application/json.
  .components.responses.string.content =
    {"text/plain": {"schema": {"type": "string"}}} |
  # Fix 3: asset-upload request bodies lack `required: true`, which makes the
  # generator skip the multipart body (warning at build time).
  (.paths["/repos/{owner}/{repo}/issues/{index}/assets"].post.requestBody.required = true) |
  (.paths["/repos/{owner}/{repo}/issues/comments/{id}/assets"].post.requestBody.required = true) |
  (.paths["/repos/{owner}/{repo}/releases/{id}/assets"].post.requestBody.required = true)
' > "$OUT"

echo "updated $OUT (server version $(jq -r .info.version "$OUT"))"
