# blobs.mk
#
# Upstream artifact sources. Each source declares where it comes from,
# which platforms are wanted, which are mandatory, and how an asset
# filename is built from a version plus an os/arch pair.
#
# The two upstreams name their assets differently on purpose: the
# scheduler ships per-platform tarballs, the plugin ships flat binaries
# because `cf install-plugin` needs each individually downloadable.

UPSTREAMS := ocf-scheduler ocf-scheduler-cf-plugin

ocf-scheduler_REPO      := cloudfoundry-community/ocf-scheduler
ocf-scheduler_BLOBDIR   := ocf-scheduler
ocf-scheduler_PLATFORMS := linux/amd64 linux/arm64 darwin/amd64 darwin/arm64
ocf-scheduler_REQUIRED  := linux/amd64 linux/arm64
# $(1)=version $(2)=os $(3)=arch
ocf-scheduler_ASSET      = ocf-scheduler-$(2)-$(3)-$(1).tar.gz

ocf-scheduler-cf-plugin_REPO      := cloudfoundry-community/ocf-scheduler-cf-plugin
ocf-scheduler-cf-plugin_BLOBDIR   := ocf-scheduler-cf-plugin
ocf-scheduler-cf-plugin_PLATFORMS := linux/amd64 linux/arm64 \
                                     darwin/amd64 darwin/arm64 windows/amd64
ocf-scheduler-cf-plugin_REQUIRED  := linux/amd64 linux/arm64
# Only the windows asset carries a .exe suffix.
ocf-scheduler-cf-plugin_ASSET      = ocf-scheduler-cf-plugin-$(1)+$(2).$(3)$(if $(filter windows,$(2)),.exe,)
