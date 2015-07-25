#!/bin/bash

welcome="Welcome to the cubiescreen yocto auto builder script"
title="Select which yocto branch do you like to build"

PROJECT_DIR="$HOME/yocto"
DOWNLOAD_DIR="${PROJECT_DIR}/downloads"
IMAGE=cubiescreen-image

while getopts ":b:d:u:r" optname
  do
	case "$optname" in
	  "b")    
	        PROJECT_DIR="$OPTARG"
		echo "Setting Yocto base directory to $PROJECT_DIR ..." 
	  	;;
	  "d")   
		_DOWNLOAD_DIR="$OPTARG"
		echo "Setting Yocto download directory to $PROJECT_DIR ..." 
	  	;;
	   *) 
	    echo "Bad or missing argument!" 
	    echo "Usage: $0 -b dir -d dir "
            echo "	-b dir : Yocto base directory."
	    echo "	-d dir : Yocto download directory."
	   exit 0
	    ;;
	esac
done


options=("dizzy" "fido" )
echo "********************************************************"
echo "*" "$welcome" "*"
echo "*" "$title" "      *"
echo "********************************************************"

select opt in "${options[@]}" "Quit"; do 

    case "$REPLY" in

    1 ) echo "You choosed to build the $opt branch"; break ;;
    2 ) echo "You choosed to build the $opt branch"; break ;;
    $(( ${#options[@]}+1 )) ) echo "Goodbye!"; break;;
    *) echo "Invalid option. Try another one.";continue;;

    esac

done

POKY_BRANCH=$opt

# make sure we have all the necessary packages installed and the default shell is bash and not dash
# TODO: how to do this without user confirmation?
#       simply make a symlink /bin/sh -> /bin/bash ?
#sudo dpkg-reconfigure dash
echo "-------------------------------------------------------------------------"
echo 	"Step 1: Install missing host packages"
echo "-------------------------------------------------------------------------"
sudo sudo apt-get -y install gawk wget git-core diffstat unzip texinfo gcc-multilib \
     build-essential chrpath socat libsdl1.2-dev xterm


echo "-------------------------------------------------------------------------"
echo 	"Step 2: creating yocto directories"
echo "-------------------------------------------------------------------------"

# download the discovered version of yocto
echo "mkdir -p ${PROJECT_DIR}"
$RUN mkdir -p ${PROJECT_DIR}

# We need absolute paths not relative

PROJECT_DIR="$(readlink -e $PROJECT_DIR)"
BUILD_DIR="${PROJECT_DIR}/mybuilds/${IMAGE}-${POKY_BRANCH}"

if ( [ "${PROJECT_DIR}" != "$HOME/yocto" ] && [ "${_DOWNLOAD_DIR}" == "" ] ); then
	DOWNLOAD_DIR="${PROJECT_DIR}/downloads"
else
	if [ "$_DOWNLOAD_DIR" != "" ]; then
		DOWNLOAD_DIR=readlink -e "$_DOWNLOAD_DIR"
	fi
fi

# create directory where yocto should store all the downloaded sources
if [ ! -d "$DOWNLOAD_DIR" ]; then
   echo "mkdir -p ${DOWNLOAD_DIR}"
   $RUN mkdir -p $DOWNLOAD_DIR
fi

# create directory where yocto should store all the downloaded sources
if [ ! -d "$DOWNLOAD_DIR" ]; then
   echo "mkdir -p ${DOWNLOAD_DIR}"
   $RUN mkdir -p $DOWNLOAD_DIR
fi

if [ ! -d "${BUILD_DIR}" ]; then
   echo "mkdir -p ${BUILD_DIR}"
   $RUN mkdir -p ${BUILD_DIR}
fi

cd ${PROJECT_DIR}

echo "-------------------------------------------------------------------------"
echo 	"Step 3: Cloning yocto branch ${POKY_BRANCH} to poky_${POKY_BRANCH}    "
echo "-------------------------------------------------------------------------"

git clone git://git.yoctoproject.org/poky poky_${POKY_BRANCH}

cd poky_${POKY_BRANCH}
git checkout -b ${POKY_BRANCH} origin/${POKY_BRANCH}

echo "-----------------------------------------------------------------------------"
echo 	"Step 4: Cloning meta-openembedded branch ${POKY_BRANCH} to poky_${POKY_BRANCH}   "
echo "-----------------------------------------------------------------------------"
$RUN git clone git://github.com/openembedded/oe-core
cd oe-core
$RUN git checkout -b ${POKY_BRANCH} origin/${POKY_BRANCH}
cd ..

echo "-----------------------------------------------------------------------------"
echo 	"Step 5: Cloning meta-openembedded branch ${POKY_BRANCH} to poky_${POKY_BRANCH}   "
echo "-----------------------------------------------------------------------------"
$RUN git clone git://git.openembedded.org/meta-openembedded/
cd meta-openembedded
$RUN git checkout -b ${POKY_BRANCH} origin/${POKY_BRANCH}
cd ..

echo "-----------------------------------------------------------------------------"
echo 	"Step 6: Cloning meta-oe branch ${POKY_BRANCH} to poky_${POKY_BRANCH}   "
echo "-----------------------------------------------------------------------------"
$RUN git clone git://github.com/openembedded/meta-oe/
cd meta-oe
$RUN git checkout -b ${POKY_BRANCH} origin/${POKY_BRANCH}
cd ..

echo "-----------------------------------------------------------------------------"
echo 	"Step 7: Cloning meta-qt5 branch ${POKY_BRANCH} to poky_${POKY_BRANCH}   "
echo "-----------------------------------------------------------------------------"
$RUN git clone https://github.com/meta-qt5/meta-qt5
cd meta-qt5
$RUN git checkout -b ${POKY_BRANCH} origin/${POKY_BRANCH}
cd ..

echo "-----------------------------------------------------------------------------"
echo 	"Step 8: Cloning meta-sunxi branch ${POKY_BRANCH} to poky_${POKY_BRANCH}   "
echo "-----------------------------------------------------------------------------"
$RUN git clone https://github.com/linux-sunxi/meta-sunxi
cd meta-sunxi
$RUN git checkout -b ${POKY_BRANCH} origin/${POKY_BRANCH}
cd ..

echo "-----------------------------------------------------------------------------"
echo 	"Step 9: Cloning meta-cubiescreen branch ${POKY_BRANCH} to poky_${POKY_BRANCH}   "
echo "-----------------------------------------------------------------------------"
$RUN git clone https://github.com/messi1/meta-cubiescreen
#cd meta-cubiescreen
#$RUN git checkout -b ${POKY_BRANCH} origin/${POKY_BRANCH}
#cd ..

echo "-------------------------------------------------------------------------"
echo 	"Step 10: setup Yocto environment"
echo "-------------------------------------------------------------------------"
echo "source ${PROJECT_DIR}/poky_${POKY_BRANCH}/oe-init-build-env ${BUILD_DIR}/"
source ${PROJECT_DIR}/poky_${POKY_BRANCH}/oe-init-build-env ${BUILD_DIR}/


echo "-------------------------------------------------------------------------"
echo 	"Step 11: Create Conf Files in dir: ${BUILD_DIR}/conf"
echo "-------------------------------------------------------------------------"
$RUN mkdir -p ${BUILD_DIR}/conf/
echo "Create ${BUILD_DIR}/conf/local.conf and ${BUILD_DIR}/conf/bblayers.conf"
$RUN cat > ${BUILD_DIR}/conf/local.conf << EOL
CONF_VERSION = "1"
BB_NUMBER_THREADS = "5"
PARALLEL_MAKE = "-j 4"
MACHINE ?= "cubieboard2"

IMAGE_FSTYPES = "ext3 tar.gz sunxi-sdimg"

DL_DIR ?=  "${DOWNLOAD_DIR}"

DISTRO ?= "poky"

PACKAGE_CLASSES ?= "package_rpm"

DEFAULTTUNE = "cortexa7hf-neon-vfpv4"

# We default to enabling the debugging tweaks.
EXTRA_IMAGE_FEATURES = "debug-tweaks"


USER_CLASSES ?= "buildstats image-mklibs image-prelink"

PATCHRESOLVE = "noop"


BB_DISKMON_DIRS = "\\
    STOPTASKS,\${TMPDIR},1G,100K \\
    STOPTASKS,\${DL_DIR},1G,100K \\
    STOPTASKS,\${SSTATE_DIR},1G,100K \\
    ABORT,\${TMPDIR},100M,1K \\
    ABORT,\${DL_DIR},100M,1K \\
    ABORT,\${SSTATE_DIR},100M,1K" 

SOURCE_MIRROR_URL ?= "file://${DOWNLOAD_DIR}/"
INHERIT += "own-mirrors"

CONF_VERSION = "1"

PACKAGECONFIG_append_pn-qtbase = "linuxfb accessibility gles2 openss icu udev widgets pulseaudio sql-sqlite sql-sqlite2 alsa"
PACKAGECONFIG[gles2] = "-opengl es2 -eglfs -qpa eglfs,,virtual/libgles2 virtual/egl"
#PACKAGECONFIG_append_pn-qtmultimedia = " gstreamer010 "
PACKAGECONFIG_remove_pn-qtbase = "msse2"
DISTRO_FEATURES_remove = "x11"
DISTRO_FEATURES_append = " opengl wayland"

EOL
########################################################################################

$RUN cat > ${BUILD_DIR}/conf/bblayers.conf << EOL
# LAYER_CONF_VERSION is increased each time build/conf/bblayers.conf
# changes incompatibly
LCONF_VERSION = "6"

BBPATH = "\${TOPDIR}"
BBFILES ?= ""

PATH_TO_LAYERS = "${PROJECT_DIR}/poky_${POKY_BRANCH}"

BBLAYERS ?= " \\
  \${PATH_TO_LAYERS}/meta \\
  \${PATH_TO_LAYERS}/meta-yocto \\
  \${PATH_TO_LAYERS}/meta-sunxi \\
  \${PATH_TO_LAYERS}/meta-qt5 \\
  \${PATH_TO_LAYERS}/meta-oe/meta-oe \\
  \${PATH_TO_LAYERS}/meta-cubiescreen \\
  "
BBLAYERS_NON_REMOVABLE ?= " \\
  \${PATH_TO_LAYERS}/meta \\
  \${PATH_TO_LAYERS}/meta-yocto \\
  \${PATH_TO_LAYERS}/meta-sunxi \\
  \${PATH_TO_LAYERS}/meta-qt5 \\
  \${PATH_TO_LAYERS}/meta-oe/meta-oe \\
  "

EOL

echo "-------------------------------------------------------------------------"
echo 	"Step 12: Start Yocto image build"
echo "-------------------------------------------------------------------------"
$RUN bitbake ${IMAGE}


