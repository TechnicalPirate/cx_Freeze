#!/bin/bash

if [ -z "${VIRTUAL_ENV}" ] && [ -z "${GITHUB_WORKSPACE}" ] ; then
	echo "Required: use of a virtual environment."
	exit 1
fi

if [ -z "$1" ] ; then
	echo "Usage: $0 sample"
	echo "Where:"
	echo "  sample is the name in samples directory (e.g. cryptography)"
	exit 1
fi
TEST_SAMPLE=$1

set -e -x

# Get script directory (without using /usr/bin/realpath)
pushd $(dirname "${BASH_SOURCE[0]}")
CI_DIR=$(pwd)
# This script is on ci subdirectory
cd ..
TOP_DIR=$(pwd)
popd

# Constants
PY_PLATFORM=$(python -c "import sysconfig; print(sysconfig.get_platform())")
PY_VERSION=$(python -c "import sysconfig; print(sysconfig.get_python_version())")

echo "Install dependencies for ${TEST_SAMPLE} sample"
TEST_REQUIRES=$(python ${CI_DIR}/build-test-json.py ${TEST_SAMPLE} req)
if ! [ -z "${TEST_REQUIRES}" ] ; then
    echo "Requirements installed: ${TEST_REQUIRES}"
fi
if ! python -c "import cx_Freeze; print(cx_Freeze.__version__)" 2>/dev/null
then
    if [ -d "${TOP_DIR}/wheelhouse" ] ; then
        echo "Install cx-freeze from wheelhouse"
        pip install --no-deps --no-index -f "${TOP_DIR}/wheelhouse" cx_Freeze
    fi
fi

echo "Freeze ${TEST_SAMPLE} sample"
# Check if the samples is in current directory or in a cx_Freeze tree
if [ -d "${TEST_SAMPLE}" ] ; then
    pushd ${TEST_SAMPLE}
    TEST_DIR=$(pwd)
else
    TEST_DIR=${TOP_DIR}/cx_Freeze/samples/${TEST_SAMPLE}
    if ! [ -d "${TEST_DIR}" ] ; then
        echo "Sample's directory not found"
        exit 1
    fi
    pushd $TEST_DIR
fi
# Freeze the sample
python setup.py build_exe --excludes=tkinter --include-msvcr=true --silent
popd

echo "Run ${TEST_SAMPLE} sample"
BUILD_DIR="${TEST_DIR}/build/exe.${PY_PLATFORM}-${PY_VERSION}"
pushd ${BUILD_DIR}
count=0
TEST_NAME=$(python ${CI_DIR}/build-test-json.py ${TEST_SAMPLE} ${count})
TEST_PIDS=
until [ -z "${TEST_NAME}" ] ; do
    if [[ ${TEST_NAME} == gui:* ]] || [[ ${TEST_NAME} == svc:* ]] ; then
        # GUI app and service app are started in backgound and killed after 10s
        TEST_NAME=${TEST_NAME:4}
        ./${TEST_NAME} &> ${TEST_NAME}.log &
        TEST_PIDS="${TEST_PIDS}$! "
    else
        # CUI app outputs on current console
        if [ "${OSTYPE}" == "msys" ] && [ -z "${GITHUB_WORKSPACE}" ] ; then
            # except in msys2 (use mintty to simulate a popup)
            mintty --hold always -e "./${TEST_NAME}" &
            TEST_PIDS="${TEST_PIDS}$! "
        else
            ./${TEST_NAME}
        fi
    fi
    if [ "${TEST_SAMPLE}" == "simple" ] ; then
        echo "test - rename the executable"
        if [ "${OSTYPE}" == "msys" ] ; then
            cp hello.exe Test_Hello.exe
        else
            cp hello Test_Hello
        fi
        ./Test_Hello ação ótica côncavo peña
    fi
    count=$(( $count + 1 ))
    TEST_NAME=$(python ${CI_DIR}/build-test-json.py ${TEST_SAMPLE} ${count})
done
# check for backgound process
which sleep
sleep 10
#ps
TEST_EXITCODE=0
for TEST_PID in ${TEST_PIDS} ; do
    if kill -0 $TEST_PID ; then
        kill -9 $TEST_PID
        echo "Process $TEST_PID killed after 10 seconds"
    fi
    if wait $TEST_PID ; then
        echo "Process $TEST_PID success"
    else
        TEST_EXITCODE=$?
        ls -l *.log
        TEST_LOG_IS_EMPTY=Y
        for TEST_LOG in *.log; do
            TEST_LOG_SIZE=$(wc -c ${TEST_LOG} | awk '{print $1}')
            if ! [ ${TEST_LOG_SIZE} == 0 ] ; then
                TEST_LOG_IS_EMPTY=N
                echo "${TEST_LOG}"
                cat ${TEST_LOG}
            fi
        done
        if [ ${TEST_LOG_IS_EMPTY} == Y ]; then
            TEST_EXITCODE=0
        else
            echo "Process $TEST_PID fail with error $TEST_EXITCODE"
        fi
    fi
done
popd
exit $TEST_EXITCODE
