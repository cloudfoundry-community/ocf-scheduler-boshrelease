# Makefile
#
# One mechanism for pinning upstream artifacts, used identically by
# hand, by Concourse, and by GitHub Actions. All logic lives in
# ci/scripts/blobs; these targets only pass arguments to it.

include blobs.mk

.PHONY: help test testflight-env blobs $(addprefix blobs-,$(UPSTREAMS))

help:
	@echo "make test            run the test suites"
	@echo "make testflight-env  report director facts (read-only)"
	@echo "make blobs           bump every upstream to its latest release"
	@echo
	@echo "Per-source targets:"
	@$(foreach u,$(UPSTREAMS),echo "  make blobs-$(u)";)
	@echo
	@echo "Modes, for a per-source target:"
	@echo "  REF=v2.0.1     a release tag; v-2.0.1 and 2.0.1 also work"
	@echo "  URL=https://.. one explicit asset, leaving siblings alone"
	@echo "  FROM=<dir>     assets already on disk; reads <dir>/version"
	@echo "  no argument    the latest release"

test:
	./ci/scripts/test-blobs
	./ci/scripts/test-packaging
	./ci/scripts/test-manifest-vars
	./ci/scripts/test-testflight-cleanup

# Read-only. Reports what manifests/ocf-scheduler.yml must be written
# against, and what testflight injects on its own.
testflight-env:
	./ci/scripts/testflight-env

blobs: $(addprefix blobs-,$(UPSTREAMS))

$(addprefix blobs-,$(UPSTREAMS)): blobs-%:
ifneq ($(FROM),)
	./ci/scripts/blobs install $* "$(FROM)" \
	  "$$(if [ -n '$(REF)' ]; then ./ci/scripts/blobs normalize '$(REF)'; \
	      else ./ci/scripts/blobs dir-version '$(FROM)'; fi)"
else ifneq ($(URL),)
	./ci/scripts/blobs fetch-url $* "$(URL)"
else
	./ci/scripts/blobs fetch $* $(REF)
endif
