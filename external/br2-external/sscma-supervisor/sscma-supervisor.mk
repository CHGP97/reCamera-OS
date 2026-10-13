################################################################################
#
# sscma-supervisor
#
################################################################################

# CHGP97 fork of sscma-example-sg200x, pinned on fix/ae-feedback:
# 98201f6 fixes start_service "nodered" to call S92node-red (reCamera-OS
# 7118b9e renamed the init script; upstream 0.2.4 still calls S03 and
# leaves node-red killed on every web-UI service toggle)
SSCMA_SUPERVISOR_VERSION = 98201f6a72dfa469358f57fe2e5eeb617d88da5a
SSCMA_SUPERVISOR_SITE = https://github.com/CHGP97/sscma-example-sg200x.git
SSCMA_SUPERVISOR_SITE_METHOD = git
SSCMA_SUPERVISOR_GIT_SUBMODULES = YES
SSCMA_SUPERVISOR_LICENSE = Apache-2.0
SSCMA_SUPERVISOR_DEPENDENCIES = libhv

# Configure step: prepare the build environment and run CMake to configure the build
define SSCMA_SUPERVISOR_CONFIGURE_CMDS
	mkdir -p $(@D)/solutions/supervisor/build && \
	cd $(@D)/solutions/supervisor/build && \
	$(BR2_CMAKE) -DSG200X_SDK_PATH=$(shell realpath $(BUILD_DIR)/../../../../) -DWEB=ON -DSYSROOT=${STAGING_DIR} -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$(TARGET_DIR) ..
endef

# Build step: compile the package using the Makefile in the build directory
define SSCMA_SUPERVISOR_BUILD_CMDS
    $(MAKE) -C $(@D)/solutions/supervisor/build
endef

# Install step: copy the built files to the target directory
define SSCMA_SUPERVISOR_INSTALL_TARGET_CMDS
	# Install the executable file
	$(INSTALL) -D -m 0755 $(@D)/solutions/supervisor/build/supervisor $(TARGET_DIR)/usr/local/bin/supervisor

	# Copy other files from the source directory to the target directory
	cp -r $(@D)/solutions/supervisor/rootfs/* $(TARGET_DIR)/

endef

$(eval $(generic-package))
