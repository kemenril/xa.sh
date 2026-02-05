#!/bin/sh

#####################################
#  xa.sh
#    A cross-assembler in Bourne,
#
#  Copyright (c) 2025, Chris Smith
#  All rights reserved.
#####################################

# Defaults
ARCH=8080
DEFOUT=a.bin

#Assumes that, relative to the script, HOME is ../, which means lib is 
# ../lib/xa.sh, ... and so on.
if [ -z "${XASH_HOME}" ];then
	XASH_BIN=$(cd `dirname $0` && pwd)
	XASH_HOME=$(cd `dirname $0`/.. && pwd)
fi

XASH_LIB=${XASH_HOME}/lib/xa.sh
XASH_CORE=${XASH_LIB}/core
XASH_COMMON=${XASH_LIB}/common

usage() {
cat <<EOM
  $0: An assembler in Bourne.

    Usage:
      $0 [<-a|-m|--arch|--machine> <ARCH>][-d|--debug][-s|--stream] <INPUT> [OUTPUT]

    Options:
      -a | --arch | -m | --machine  <ARCH>
          Generate code for <ARCH>, in case multiple architectures are 
        available.

      -d | --debug        
          If this option is present, print extra debugging infomation to
        stderr.	

      -s | --stream       
          Write output to STDOUT, rather than to a file.

EOM
}

#Ensure we get minimally reasonable arguments
if [ -z "$1" ];then
        usage
        exit 1
fi

while [ -n "$1" ]; do
	case "$1" in
		-d | --debug )
			DEBUG="ON"
			shift
			;;
		-a | --arch | -m | --machine )
			shift
			ARCH=$1
			shift
			;;
		-s | --stream )
			STREAM="ON"
			shift
			;;
		*)
			if [ -z "${INFILE}" ];then
				INFILE=$1
				shift
			else
				if [ -z "${OUTFILE}" ];then
					OUTFILE=$1
					shift
				else	# Too many positional parameters
					shift
					usage
					exit 1
				fi
			fi
			;;
	esac		
done

if [ -z "${INFILE}" ];then
	errmsg "No input file specified."
	exit 1
fi

if [ -z "${OUTFILE}" ];then
	OUTFILE="${DEFOUT}"
fi


#Load modules:
#This contains errmsg, among other things
. ${XASH_COMMON}/util
errmsg "Utility module loaded."

# ... and the rest.
for MOD in ${XASH_COMMON}/bytes ${XASH_COMMON}/params ${XASH_COMMON}/memory ${XASH_COMMON}/preprocess;do
        errmsg "Load ${MOD}"
        . ${MOD}
done

errmsg "Architecture: ${ARCH}"
for INST in ${XASH_CORE}/${ARCH}/*;do
	iList="${iList} `basename ${INST}`"
	. ${INST}
done
errmsg Instructions: $iList


if [ ! -r "${INFILE}" ];then
	errmsg "Can't read input file: ${INFILE}"
	exit 1
fi

if [ -z "${STREAM}" ];then
	if [ -e "${OUTFILE}" ];then 
		errmsg "Output file ${OUTFILE} already exists.  Won't overwrite."
		exit 1
	fi
fi

#Process an input file

if [ -z "${STREAM}" ];then
	errmsg "Assemble ${INFILE} -> ${OUTFILE}"
else
	errmsg "Assemble ${INFILE} -> STDOUT"
fi


INPUT=`cat ${INFILE}|preprocess`

if [ -n "${DEBUG}" ];then
	errmsg "Preprocessed input: ${INPUT}"
fi

#Initialize the PC
addr__PC=0

# ... and the line count
sourceLine=1

#Basic two-pass operation.  First time through, we'll just calculate the
#addresses of all the labels.
PASS=1
eval ${INPUT} > /dev/null

if [ -n "${DEBUG}" ];then
	errmsg "Label map:"
	set|grep ^addr__ >&2
fi

addr__PC=0
sourceLine=1

PASS=2
if [ -z ${STREAM} ];then
	eval ${INPUT} > ${OUTFILE}
else
	eval ${INPUT}
fi



