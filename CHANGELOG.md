# Changelog

All notable changes to this action are documented here.
Format: Keep a Changelog. Versioning: Semantic Versioning, independent of fleetlint's.

## [Unreleased]

## [0.1.1] - 2026-10-30

### Changed

- Installs fleetlint v0.10.0 by default, whose `init` writes the detected stacks and published artifacts into `.fleetlint.yaml`, so the onboarding pull request shows what is checked.

## [0.1.0] - 2026-10-24

The first release. It installs fleetlint v0.9.0 by default.

### Added

- Installs a fleetlint release, verified by its checksum and, with cosign, its signature (`verify`).
- Annotations per finding (`annotations`, off on Gitea and Forgejo), the report in the job summary (`summary`), SARIF for code scanning (`sarif-file`), the gate at `fail-on`.
- `pr: true`: a run of the default branch opens the onboarding pull request, or the fixes pull request, with the run's token or `token:` (needs fleetlint 0.9.0 or newer).
- Runs on Gitea and Forgejo Actions, the commit authored by the instance's Actions user.
