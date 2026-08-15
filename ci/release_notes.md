The first release since 0.1.3, and the first that can be bumped without editing
files by hand. The major version moves to 2 so the scheduler, the CF CLI plugin
and this BOSH release share one.

# Upstream artifacts

* **ocf-scheduler 2.0.2** (was a hand-placed build that never corresponded to any
  published release) — brings timezone support and the CAPI V3 job fields, and on
  top of 2.0.1 a dependency refresh carrying the echo fix for GHSA-vfp3-v2gw-7wfq.
  The scheduler serves no static files, so that advisory never reached it.
* **ocf-scheduler-cf-plugin 2.0.0** (was 1.0.0) — upstream renamed every asset
  from `-linux-amd64` to `+linux.amd64`, which the old glob could not match, so
  this blob had been pinned by breakage rather than by choice. 2.0.0 adds the
  `--timezone` flag, `cf scheduler-time-zones`, a `--log-rate-limit` flag on
  `create-job`, and execution-history filtering. Its major bump is version
  alignment, not a compatibility break: every 1.2.0 command and flag is unchanged.

# arm64

The scheduler package now ships both `linux/amd64` and `linux/arm64` and selects
between them with `uname -m` at compile time, so one release deploys to either
stemcell. Groundwork for the ARM64 RFC (cloudfoundry/community#1530).

The vendored `cf-cli-8-linux` and `golang-1.22-linux` packages are unchanged and
almost certainly amd64-only; the smoke-tests errand depends on both, so smoke
tests on an arm64 stemcell are not yet supported.

# Packaging

* The upstream version no longer appears in any tracked file. Package specs glob
  on it and the packaging scripts derive the tarball's inner directory from the
  matched filename, so a bump touches `config/blobs.yml` and nothing else.
* `scheduler-cf-plugin` now carries every published platform — linux, darwin and
  windows — installed under `dist/` alongside the native binary the smoke-tests
  errand executes. It is also a dependency of the `scheduler` job now, not only
  of smoke-tests, so the binaries reach the scheduler VM.
* A new `scheduler-crossbuilds` package carries the darwin scheduler builds. No
  job references it, so it ships in the release tarball without ever being
  compiled on a linux stemcell.

# Fixed

* `jobs/smoke-tests` declared `templates: run: bin/run` — the errand convention —
  but the deployment manifest is where BOSH reads `lifecycle: errand`. The
  restored testflight manifest declares it there.
* `manifests/ocf-scheduler.yml` is restored. It had never existed under that
  name: the only manifest ever committed was `manifests/scheduler.yml`, added in
  May 2022 and deleted two days later as collateral in an unrelated commit. The
  pipeline added a year afterwards has looked for the missing filename ever
  since, so `testflight` could never run.

# Known gaps

`testflight` builds and uploads a release but cannot deploy: the manifest needs a
Postgres URI and a UAA client that the test environment does not yet provide.
Deployments through the Genesis kit are unaffected — the kit supplies both.

The bundled plugin 2.0.0 was itself cut by hand rather than by its pipeline, whose
`test` job cannot authenticate to the test Cloud Foundry. Its artifacts were
verified with `go build` and `go vet` only; no integration test ran against a live
scheduler.

This release was cut without a passing `testflight`.
