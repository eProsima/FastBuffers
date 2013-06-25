#!/bin/sh

#: This script pack FastBuffers product for any platform in Linux.
#
# This script needs the next programs to be run.
# - subversion
# - libreoffice
# - ant
# - doxygen
# Also this script needs the eProsima.documentation.changeVersion macro installed in the system.

errorstatus=0

source $EPROSIMADIR/scripts/common_pack_functions.sh


function setPlatform
{
    platforms=`cat src/platforms`
    if [[ $platforms != *$1* ]]; then
        echo $1 >> src/platforms
    fi
}

function package
{
    # Get current version of GCC.
    getGccVersion

    # Update and compile CDR library.
    cd ../CDR
    # Update CDR library.
    svn update
    errorstatus=$?
    if [ $errorstatus != 0 ]; then return; fi
    # Compile CDR library for i86.
    rm -rf output
    EPROSIMA_TARGET="i86Linux2.6gcc${gccversion}"
    make
    errorstatus=$?
    if [ $errorstatus != 0 ]; then return; fi
    # Compile CDR library for x64.
    rm -rf output
    EPROSIMA_TARGET="x64Linux2.6gcc${gccversion}"
    make
    errorstatus=$?
    if [ $errorstatus != 0 ]; then return; fi
    cd ../FastBuffers

    # Get the current version of FastBuffers
    getVersionFromCPP

    # Try to add platform
    setPlatform "i86Linux2.6gcc${gccversion}"
    setPlatform "x64Linux2.6gcc${gccversion}"

    # Update and compile FastBuffers application.
    # Update FastBuffers application
    svn update
    errorstatus=$?
    if [ $errorstatus != 0 ]; then return; fi
    # Compile FastBuffers for target.
    rm -rf build
    ant jar
    errorstatus=$?
    if [ $errorstatus != 0 ]; then return; fi

    # Create PDFS from documentation.
    cd doc
    # Installation manual
    soffice --headless "macro:///eProsima.documentation.changeVersion($PWD/Installation Manual.odt,$version)"
    errorstatus=$?
    if [ $errorstatus != 0 ]; then return; fi
    # User manual
    soffice --headless "macro:///eProsima.documentation.changeVersion($PWD/Users Manual.odt,$version)"
    errorstatus=$?
    if [ $errorstatus != 0 ]; then return; fi
    cd ..

    # Create doxygen information.
    #Export version
    export VERSION_DOX=$version
    mkdir -p output
    mkdir -p output/doxygen
    doxygen utils/doxygen/doxyfile
    errorstatus=$?
    if [ $errorstatus != 0 ]; then return; fi
    # Compile the latex document
    cd output/doxygen/latex
    make
    cd ../../../

    # Create installers
    cd utils/installers/linux
    ./setup_linux.sh $version
    errorstatus=$?
    cd ../../..
    if [ $errorstatus != 0 ]; then return; fi

    # Remove the doxygen tmp directory
    rm -rf output
}

# Check that the environment.sh script was run.
if [ "$EPROSIMADIR" == "" ]; then
    echo "environment.sh must to be run."
    exit -1
fi

# Go to root
cd ../..

package

if [ $errorstatus == 0 ]; then
    echo "PACKAGING SUCCESSFULLY"
else
    echo "PACKAGING FAILED"
fi

exit $errorstatus