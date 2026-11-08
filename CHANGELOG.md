# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.2.0] - 2026-11-08

### Added

- `vpc_connector` and `vpc_connector_egress_settings`: route function egress
  through a Serverless VPC Access connector, e.g. to reach Cloud SQL private
  IP. Both default to `null`, so existing functions plan unchanged. The
  connector must be given as its full resource name, and egress settings
  without a connector are rejected at plan time.

### Changed

- CI: bump actions to their current majors, pin tool versions, and restrict the
  workflow token to `contents: read`.
- CI: add Dependabot for GitHub Actions and the Terraform provider.
- Docs: pin the README usage `source` to a release tag; fix the LICENSE year.

## [1.0.0]

Initial release (`v0.1.0` points at the same commit).

[Unreleased]: https://github.com/moveeeax/terraform-google-cloud-functions/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/moveeeax/terraform-google-cloud-functions/compare/v1.1.0...v1.2.0
[1.0.0]: https://github.com/moveeeax/terraform-google-cloud-functions/releases/tag/v1.0.0
