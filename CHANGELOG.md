# Changelog

## Unreleased

### Changed

- Allow to pass custom options to exec of dir commands.

## 1.1.5 - 2026-08-04

### Added

- Add »sort« command sorting the versions in CHANGELOG.md, newest first, to
neutralize merge artifacts
- Add »has-version« command checking if a version is already in CHANGELOG.md

### Changed

- »release« sorts the versions in CHANGELOG.md, also when the version is
already released
- Fix issues with CHANGELOG.md

## 1.1.4 - 2026-08-03

### Changed

- Improve error logging

## 1.1.3 - 2026-07-29

### Changed

- Fix publish error when version in CHANGELOG.md already exists

## 1.1.2 - 2026-07-29

### Fixed

- Do not escape the markdown characters `_ * ~ | [ ]` in CHANGELOG.md anymore
- Repair CHANGELOG.md files damaged by previous runs

## 1.1.1 - 2026-07-29

### Changed

- do publish waits until version is published and pull request is merged

## 1.1.0 - 2026-06-08

### Added

- Add .gitattributes file

### Changed

- fix: skip CHANGELOG format check when no pubspec.yaml (TypeScript projects)

## 1.0.12 - 2025-06-05

### Changed

- Update to latest dart version

## 1.0.11 - 2024-08-30

### Changed

- Run unit tests on MacOS

## 1.0.10 - 2024-04-13

### 1.0.9 - 2024-04-11

- Upgrade to latest dependencies

### Changed

- Adjusted version

### Removed

- dependency to gg_install_gg, remove ./check script
- dependency pana

## 1.0.8 - 2024-04-11

- Updated latest dependencies

## 1.0.7 - 2024-04-10

### Fixed

- error happening with CHANGELOG.md created by gg_create_package

## 1.0.6 - 2024-04-10

### Removed

- 'Pipline: Disable cache'

## 1.0.5 - 2024-04-09

### Added

- Preapre publish

### Changed

- Kidney: Auto check all repos
- 'Github Actions Pipeline'
- 'Github Actions Pipeline: Add SDK file containing flutter into .github/workflows to make github installing flutter and not dart SDK'

### Fixed

- Prevent CideProject logging URLs on init
- Link in CHANGELOG.md was broken

## 1.0.4 - 2024-04-05

### Fixed

- Diff URL did contain a wrong .git part

## 1.0.3 - 2024-04-05

### Added

- Pretty print changelog

## 1.0.2 - 2024-04-05

### Added

- Mocks

## 1.0.1 - 2024-04-05

### Added

- Add Release to public API

## 1.0.0 - 2024-04-05

### Added

- Initial version
