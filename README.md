# Icon

![](./symbol.svg)

* Author: Jack Liu
* License: Public Domain
* Source: https://www.svgrepo.com/svg/477069/tea

# Swagger -> OpenAPI (mit Fehlerkorrektur)

```
curl https://git.schindlerfelix.de/swagger.v1.json > swagger.json
npx swagger2openapi swagger.json --targetVersion 3.0.3 --yaml --resolve --patch --outfile openapi.yaml
npx @redocly/cli@latest bundle openapi.yaml -o openapi.required.yaml
mv openapi.required.yaml ./Gitea/Gitea/openapi.yaml
```
