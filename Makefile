# Makefile
#
# One mechanism for pinning upstream artifacts, used identically by
# hand, by Concourse, and by GitHub Actions. All logic lives in
# ci/scripts/blobs; these targets only pass arguments to it.

include blobs.mk

.PHONY: help test blobs $(addprefix blobs-,$(UPSTREAMS))

help:
	@echo "make test                       run the test suites"
	@echo "make blobs                      bump every upstream to latest"
	@echo "make blobs-ocf-scheduler        bump one source"
	@echo "  REF=v2.0.1 | REF=v-2.0.1 | REF=2.0.1"
	@echo "  URL=https://...  explicit asset"
	@echo "  FROM=<dir>       assets already on disk"

test:
	./ci/scripts/test-blobs
	./ci/scripts/test-packaging

blobs: $(addprefix blobs-,$(UPSTREAMS))

$(addprefix blobs-,$(UPSTREAMS)): blobs-%:
ifneq ($(FROM),)
	./ci/scripts/blobs install $* "$(FROM)" \
	  "$$(if [ -n '$(REF)' ]; then ./ci/scripts/blobs normalize '$(REF)'; \
	      else ./ci/scripts/blobs dir-version '$(FROM)'; fi)"
else ifneq ($(URL),)
	@test -n "$(REF)" || { echo "URL= also needs REF= to name the version"; exit 2; }
	./ci/scripts/blobs fetch-url $* "$(URL)" "$$(./ci/scripts/blobs normalize $(REF))"
else
	./ci/scripts/blobs fetch $* $(REF)
endif
