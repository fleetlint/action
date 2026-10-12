# fleetlint action

Runs [fleetlint](https://fleetlint.org) in GitHub Actions (and Gitea or Forgejo Actions): installs a verified release, annotates every finding, writes the report into the job summary and fails the step at the severity you choose.

```yaml
name: fleetlint
on: [push, pull_request]
permissions:
  contents: read
jobs:
  fleetlint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
        with:
          persist-credentials: false
      - uses: fleetlint/action@v1
        with:
          version: v0.2.0      # pin it; Renovate keeps it current
```

## Inputs

| Input | Default | |
|---|---|---|
| `version` | `latest` | fleetlint release to install, such as `v0.2.0` |
| `path` | `.` | repository root to check, relative to the workspace |
| `fail-on` | `error` | lowest severity that fails the step: `error`, `warning`, `info`, `never` |
| `annotations` | `true` | one annotation per finding, on the file and line when the finding has them (needs `jq`, which GitHub's runners have) |
| `summary` | `true` | the Markdown report in the job summary |
| `sarif-file` | | also write SARIF to this path |
| `verify` | `auto` | `auto`: the cosign signature of `checksums.txt` when `cosign` is on PATH, otherwise the checksum only; `cosign`: require the signature; `checksum`: checksum only |

The output `version` is the release that ran.

## Code scanning

```yaml
    permissions:
      contents: read
      security-events: write
    steps:
      - uses: actions/checkout@v7
      - uses: sigstore/cosign-installer@v4   # optional: verify the release signature
      - uses: fleetlint/action@v1
        with:
          version: v0.2.0
          fail-on: never
          sarif-file: fleetlint.sarif
      - uses: github/codeql-action/upload-sarif@v4
        with:
          sarif_file: fleetlint.sarif
```

## Gitea and Forgejo

The action is plain bash and `curl`, so it runs on Gitea and Forgejo runners as `uses: https://github.com/fleetlint/action@v1`. The runner needs `bash`, `curl`, `tar` (or `unzip` on Windows) and, for annotations, `jq`.

## Releases

Tags follow semantic versioning; `v1` moves to the latest `v1.x.y`.
