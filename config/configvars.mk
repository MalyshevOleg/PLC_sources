# Path and settings for build system
#
# Change the following values carefully
# to suit your locations and settings
#

# Target hardware specification
# (should be set to a valid directory 
# from config/platforms/platf.list) 

BUILDCONF=spk2xx_som02

# Target CPU and system
TARGET_CPU=arm
# Note: each config in the list should end with space
mach_am33_conf_list="som02 "
mach_am35_conf_list="spk207.04.web spk207.03.web spk207.03 spk207.04 spk210.04.web spk210.03.web spk210.03 spk210.04 "
mach_s3c_conf_list=" "
mach_qemu_conf_list="qemu qemu304 "
ifneq (,$(findstring $(BUILDCONF) ,$(mach_qemu_conf_list)))
  MACH=qemu
  echo "MACH=qemu"
else
  ifneq (,$(findstring $(BUILDCONF) ,$(mach_s3c_conf_list)))
    MACH=s3c
    echo "MACH=s3c"
  else
    ifneq (,$(findstring $(BUILDCONF) ,$(mach_am35_conf_list)))
      MACH=am35
      echo "MACH=am35"
    else
      ifneq (,$(findstring $(BUILDCONF) ,$(mach_am33_conf_list)))
        MACH=am35
	MACH_EXTRA=am33
        echo "MACH=am35.am33"
      else
        MACH=at91
      endif
    endif
  endif
endif

MACH_EXTRA?=$(MACH)

# Root directory for all runtime/build files
BUILD_ROOT=${BASEDIR}/build

# Directory to put unpacked sources
PKGSOURCE_DIR=${BUILD_ROOT}/src

# Directory to track unpacking/patching
PKGSTEPS_DIR=${BUILD_ROOT}/steps

# Directory to build packages in
PKGBUILD_DIR=${BUILD_ROOT}/target${MACH}

# Temp directory to install packages to
PKGINST_DIR=${BUILD_ROOT}/-+-+-

# Download(or copy) package tarballs here
# you can get the full list of required files with 
# make source-targets-list
DOWNLOAD_DIR=${BUILD_ROOT}/tarballs

# Whether to download files from mirror site only
MIRROR_ONLY=FALSE

# Mirror site to get tarballs from
MIRROR_SITE=http://localhost/tarballs

# Root directory for toolchain
# (must be an absolute path)
#TARGET_DIR=${BASEDIR}/cross
TARGET_DIR=${BASEDIR}/cross${MACH}

# Root directory for precompiled binaries
# (must be an absolute path)
BINARIES_DIR=${BASEDIR}/binaries

# Base folder to put final images & runtimes
BOOTSYS_DIR=${BASEDIR}/bootsys-${BUILDCONF}

# Folder to put final images
BOOTIMG_DIR=${BOOTSYS_DIR}/install

# Root directory for runtime image
RUNTIME_DIR=${BOOTSYS_DIR}/runtime

# Root directory for userfs runtime image
USERFS_DIR=${BOOTSYS_DIR}/userfs

# Get patches and buildSystem sources from here
SOURCES_DIR=${BASEDIR}/source

# Host system type
HOST_CPU=$(BUILDMACH)-pc-linux-gnu

# System library we use: glibc or uClibc
#LIBC_NAME=uclibc
LIBC_NAME=glibc

ifeq "$(LIBC_NAME)" "uclibc"
TARGET=${TARGET_CPU}-unknown-linux-uclibc
else
TARGET=${TARGET_CPU}-unknown-linux-gnueabi
endif

# Rebuild package on .mk file update
#MK_DEPS=FALSE
MK_DEPS=TRUE

# Rebuild package on patch file(s) update
#PATCH_DEPS=FALSE
PATCH_DEPS=TRUE

# Verbose messages (set to TRUE if yes)#
VERBOSE=FALSE
#VERBOSE=TRUE

# Whether to use sudo while installing cross-compiler
USE_SUDO=FALSE
#USE_SUDO=TRUE

# Should we build toolchain or use precompiled one
#BUILD_CROSS=FALSE
BUILD_CROSS=TRUE

# Whether to delete build directories
# automatically right after installing a package
# (to save disk space)
#AUTO_CLEAN=TRUE
AUTO_CLEAN=FALSE

export BASEDIR   \
    BUILDCONF    \
    BUILD_ROOT   \
    BUILDSTEPS_DIR \
    PKGSOURCE_DIR  \
    PKGSTEPS_DIR \
    PKGBUILD_DIR \
    PKGINST_DIR  \
    DOWNLOAD_DIR \
    TARGET_DIR   \
    BINARIES_DIR \
    BOOTSYS_DIR  \
    BOOTIMG_DIR  \
    RUNTIME_DIR  \
    USERFS_DIR   \
    SOURCES_DIR  \
    HOST_CPU     \
    TARGET_CPU   \
    MACH         \
    TARGET       \
    LIBC_NAME    \
    MK_DEPS      \
    PATCH_DEPS   \
    VERBOSE      \
    USE_SUDO     \
    BUILD_CROSS  \
    AUTO_CLEAN   \
    Q            \
    CP           
