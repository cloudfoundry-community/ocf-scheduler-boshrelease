# OCF Scheduler BOSH Release

A [BOSH](https://bosh.io) release for deploying the [OCF Scheduler](https://github.com/cloudfoundry-community/ocf-scheduler), which provides cron-style job and HTTP call scheduling for Cloud Foundry applications.

## Jobs

### `scheduler`

The long-running OCF Scheduler process, managed by monit. Runs the pre-built scheduler binary from `/var/vcap/packages/scheduler/bin/scheduler`. On startup, the control script also invokes `tzlist` to initialize timezone data before launching the main process.

### `smoke-tests`

An errand that authenticates to Cloud Foundry, creates a temporary space, installs the OCF Scheduler CF CLI plugin, runs Go acceptance tests, and tears down the space on exit.

## Architecture

```mermaid
graph TD
    BOSH["BOSH Director"] -->|deploys| VM["Scheduler VM"]
    VM -->|runs| Scheduler["scheduler job"]
    Scheduler -->|connects| PG["PostgreSQL"]
    Scheduler -->|connects| CF["CF API"]
    Scheduler -->|authenticates via| UAA["UAA"]
    BOSH -->|runs errand| ST["smoke-tests"]
    ST -->|exercises scheduler via| CF
```

## Deployment

### Prerequisites

- A BOSH Director

- A Cloud Foundry deployment with UAA

- A PostgreSQL database (external or co-located)

- A UAA client configured with appropriate scopes for the scheduler

### Upload the Release

```shell
bosh upload-release https://github.com/cloudfoundry-community/ocf-scheduler-boshrelease/releases/download/v1.0.0/ocf-scheduler-1.0.0.tgz
```

### Properties Reference

#### `scheduler` job

| Property | Required | Default | Description |
|---|---|---|---|
| `scheduler.uaa.client_id` | Yes | | UAA client ID |
| `scheduler.uaa.client_secret` | Yes | | UAA client secret |
| `scheduler.uaa.endpoint` | Yes | | UAA endpoint URL |
| `scheduler.cf.api` | Yes | | Cloud Foundry API endpoint |
| `scheduler.postgres.uri` | Yes | | PostgreSQL connection URI (`postgres://user:pass@host:port/db`) |
| `scheduler.workers` | No | `20` | Number of scheduling workers |

#### `smoke-tests` errand

| Property | Required | Description |
|---|---|---|
| `cf.api` | Yes | Cloud Foundry API endpoint |
| `cf.username` | Yes | CF admin username |
| `cf.password` | Yes | CF admin password |
| `cf.organization` | Yes | CF organization for test space |
| `cf.space` | Yes | CF space (a temporary sub-space is created) |

### Running Smoke Tests

```shell
bosh run-errand smoke-tests
```

## Packages

| Package | Contents |
|---|---|
| `scheduler` | Pre-built OCF Scheduler Linux binary |
| `scheduler-cf-plugin` | Pre-built OCF Scheduler CF CLI plugin |
| `golang-1.20-linux` | Go toolchain (used by smoke-tests at runtime) |
| `cf-cli-8-linux` | CF CLI v8 (used by smoke-tests) |
| `smoke-tests` | Go acceptance test source and vendored dependencies |

## Development

### Creating a Dev Release

```shell
bosh create-release --force
bosh upload-release
```

### Updating Blobs

The `ci/scripts/update-blob` script automates blob updates from upstream GitHub releases. It removes outdated blobs, adds the new version, and uploads to the blobstore.

`config/private.yml` must contain S3 credentials for blobstore access during final release creation:

```yaml
---
blobstore:
  provider: s3
  options:
    access_key_id: YOUR_ACCESS_KEY
    secret_access_key: YOUR_SECRET_KEY
```

## Contributing

Issues and pull requests are welcome on [GitHub](https://github.com/cloudfoundry-community/ocf-scheduler-boshrelease). Please target the `develop` branch for pull requests.

