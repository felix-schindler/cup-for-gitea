# Privacy

This app does not collect any data for itself. All the data collected is managed by the Gitea instance you configured yourself.

Diese App sammelt keine Daten für sich selbst. Alle gesammelten Daten werden von der Gitea-Instanz verwaltet, die Sie selbst konfiguriert haben.

# Icon

* License: CC0 - Creative Commons License
* Source: https://3dicons.co/icons/845bf0-tea-cup

# Useful commands

## Swagger → OpenAPI

```
curl https://git.schindlerfelix.de/swagger.v1.json > swagger.json
npx swagger2openapi swagger.json --targetVersion 3.0.3 --yaml --resolve --patch --outfile openapi.yaml
npx @redocly/cli@latest bundle openapi.yaml -o openapi.required.yaml
mv openapi.required.yaml ./Gitea/Gitea/openapi.yaml
```

## Bundle Licenses

```
license-plist --config-path license_plist.yml
```

## Add GitHub remote

```
git remote add github git@github.com:felix-schindler/cup-for-gitea.git
```

# Release a new version

1. Change app version in Xcode → Targets → Gitea → Identity → Version
2. Add changelog in `changelogs/v<verison>.md`
3. Tag branch `git push origin v<version>`
