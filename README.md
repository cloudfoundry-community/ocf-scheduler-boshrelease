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
| `scheduler` | Pre-built scheduler and tzlist, linux amd64 and arm64 |
| `scheduler-cf-plugin` | CF CLI plugin: the native binary, plus every published platform under `dist/` |
| `scheduler-crossbuilds` | Darwin scheduler builds. Referenced by no job, so carried in the release but never compiled |
| `golang-1.22-linux` | Go toolchain (used by smoke-tests at runtime) |
| `cf-cli-8-linux` | CF CLI v8 (used by smoke-tests) |
| `smoke-tests` | Go acceptance test source and vendored dependencies |

The architecture is selected at compile time from `uname -m`, so one
release deploys to both amd64 and arm64 stemcells.

## Development

### Creating a Dev Release

```shell
bosh create-release --force
bosh upload-release
```

### Updating Blobs

`make blobs` pins the upstream artifacts. The same targets are used by
hand, by Concourse, and by GitHub Actions — run `make help` for the
full list.

```shell
make blobs                                  # every source, latest release
make blobs-ocf-scheduler REF=v2.0.1         # one source, a specific tag
make blobs-ocf-scheduler FROM=./downloaded  # assets already on disk
```

Both upstream tag schemes resolve: `v2.0.1`, `v-2.0.1`, and a bare
`2.0.1` all find the same release. A missing linux asset is fatal; a
missing darwin or windows asset warns and continues.

Each bump removes that source's stale blobs, adds the new ones, uploads
them, and commits the change.

### Blobstore Credentials

S3 credentials reach `bosh` only through `config/private.yml`, which is
gitignored. Two ways to supply them:

- **Keep your own `config/private.yml`.** It is used as-is and never
  modified or removed.
- **Set `AWS_ACCESS_KEY` and `AWS_SECRET_KEY`.** A temporary
  `config/private.yml` is generated and deleted when the run finishes.

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

