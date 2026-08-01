# Icon

* License: CC0 - Creative Commons License
* Source: https://3dicons.co/icons/845bf0-tea-cup

# Useful commands

## Regenerate API client

The server serves an OpenAPI 3.0.3 spec as JSON; the swift-openapi-generator build plugin reads JSON natively, so no conversion is needed.

```
./fetch-spec.sh
```

The script downloads the raw spec and re-applies two local fixes the server spec is missing (the raw-file and plain-string endpoints serve `text/plain`, not `application/octet-stream`/`application/json` as declared), so the generated client works against the real server. Then rebuild. (`jq` is required.)

## Bundle Licenses

```
license-plist --config-path license_plist.yml
```

## GitHub contributions

```
git remote add github git@github.com:felix-schindler/cup-for-gitea.git
git fetch github pull/<id>/head:pr-<id>
```

# Release a new version

1. Change app version in Xcode → Targets → Gitea → Identity → Version
2. Add changelog in `changelogs/v<verison>.md`
3. Tag branch `git push origin v<version>`
