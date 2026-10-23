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
      - uses: fleetlint/action@main   # no release yet: pin a commit SHA
        with:
          version: v0.2.0      # pin it; Renovate keeps it current
```

## Inputs

| Input | Default | |
|---|---|---|
| `mode` | `check` | `check`: check, annotate and gate; `pr`: propose changes as a pull request (below) |
| `token` | `${{ github.token }}` | the token `mode: pr` opens the pull request and pushes with |
| `version` | `latest` | fleetlint release to install, such as `v0.2.0` |
| `path` | `.` | repository root to check, relative to the workspace |
| `fail-on` | `error` | lowest severity that fails the step: `error`, `warning`, `info`, `never` |
| `annotations` | `auto` | one annotation per finding, on the file and line when the finding has them (needs `jq`, which GitHub's runners have); `auto` is on for GitHub and off for Gitea and Forgejo, which print workflow commands into the log instead |
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
      - uses: fleetlint/action@main   # pin a commit SHA
        with:
          version: v0.2.0
          fail-on: never
          sarif-file: fleetlint.sarif
      - uses: github/codeql-action/upload-sarif@v4
        with:
          sarif_file: fleetlint.sarif
```

## Pull requests

`mode: pr` proposes changes as a pull request on the repository the workflow runs in, with the run's own token. A repository without a `.fleetlint.yaml` gets the onboarding pull request (`fleetlint init --pr`: the configuration, with the report as its description); one that has it gets the mechanical fixes of its default branch (`fleetlint fix --apply --pr`: committed on `fleetlint/fixes`, the open pull request updated on every run). The working tree of the job is not changed, so it does not matter that the default branch is protected.

```yaml
name: fleetlint fixes
on:
  schedule:
    - cron: "0 6 * * 1"
  workflow_dispatch:
permissions:
  contents: write
  pull-requests: write
jobs:
  fleetlint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
        with:
          persist-credentials: false   # fleetlint pushes with the token itself
      - uses: fleetlint/action@main   # pin a commit SHA
        with:
          mode: pr
```

- On GitHub, *Allow GitHub Actions to create and approve pull requests* must be on (repository or organization settings, Actions, General).
- A pull request opened with the run's `GITHUB_TOKEN` starts no workflows, so its checks do not run until someone pushes to it. Pass a token of a GitHub App (`actions/create-github-app-token`) or a fine-grained token with *contents* and *pull requests* write access as `token:` when the checks should run.
- The commit is authored by `github-actions[bot]` unless the job sets `GIT_AUTHOR_NAME` and `GIT_AUTHOR_EMAIL`.
- In Gitea and Forgejo Actions the same step works: fleetlint takes the instance and its API from the job (`GITHUB_SERVER_URL`, `GITHUB_API_URL`), `github.token` is the instance's token, and the commit is authored by the instance's Actions user (`forgejo-actions` or `gitea-actions`).
- `mode: pr` needs a fleetlint release with `fix --pr` (after 0.8.1).

## Gitea and Forgejo

The action is plain bash and `curl`, so it runs on Gitea and Forgejo runners. Name it by its full URL, since Forgejo resolves a short `uses:` against its own default actions instance:

```yaml
# .forgejo/workflows/fleetlint.yml (Gitea: .gitea/workflows/)
on: [push, pull_request]
jobs:
  fleetlint:
    runs-on: ubuntu-latest
    steps:
      - uses: https://data.forgejo.org/actions/checkout@v4
        with:
          persist-credentials: false
      - uses: https://github.com/fleetlint/action@<commit SHA>
        with:
          version: v0.2.0
```

- The runner needs `bash`, `curl` and `tar`.
- The report goes into the job summary, which Forgejo shows from v17 with runner v13.2. Annotations are off (`annotations: auto`): neither forge shows them.
- There is no code scanning, so leave `sarif-file` empty.
- `mode: pr` works with the job's own token. On Forgejo 17 it can push and open pull requests on the repository it runs in without further settings.

Tested on Forgejo 17.0 with runner 13.2 (check, job summary, the onboarding and the fixes pull request, and a second run updating it). Gitea runs the same commands but is not tested.

## Releases

No release yet; until the first tag, pin a commit SHA. Tags will follow semantic versioning.
