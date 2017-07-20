#!/bin/bash
cc=
libc=
ccver=
status=0

error_in () {
  echo "Correct libC and Compiler inputs not passed to make.sh"
  echo "Did you spell the libC and compiler names right?"
  exit
}

help () {
  echo "make-hpcg.sh compiles the HPCG benchmark using various toolchains"
  echo "Usage: specify a compiler, version and a libc. make.sh does the rest."
  exit
}

getinput () { #$1 - variable to set, $2 variable to read, $3 variable default $4 option2
input=$2
default=$3
option2=$4
read input
      if [ -z "$input" ] || [ "$input" == "$3" ]
       then
        export $1=$default
      elif [ "$input" == "$option2" ]
       then
        export $1=$option2
      else
        echo "input malformed. please input correct gcc version -- 7.1.0 or [6.4.0]"
        getinput $1 $input $default $option2
      fi
}

help=$(grep -o help <<< $*)
if [ "$help" == "help" ] || [ -z $1 ]
 then
   help
fi

libc=$(grep -Eow 'musl|glibc|uclibc|gnu' <<< "$*")
cc=$(grep -Eow 'gcc|clang' <<< "$*")

if [ -z "$libc" ] || [ -z "$cc" ]
 then
  error_in
elif [[ "$libc" == "glibc" ]]; then
  libc=gnu
fi

if [ "$cc" == "gcc" ]
 then
  ccver=$(grep -Eow '6.4.0|7.1.0' <<< "$*")
   if [ -z "$ccver" ]
    then
     echo "gcc version not specified or malformed, please input gcc version [6.4.0]"
    getinput ccver defaultgcc 6.4.0 7.1.0
   fi
 elif [ "$cc" == "clang" ]
 then
  echo "Clang unavailable at this time!"
  exit
fi

echo "Are these specifications okay? [y]"
echo "$libc $cc (version $ccver)"
rdy () {
read ready
if [ "$ready" == "y" ] || [ -z "$ready" ]
 then
  echo "Begin configuration!"
  status=1 #track status across the compile process
elif [ "$ready" == "n" ]
 then
  echo "Compilation cancelled."
  exit
else
  echo "Malformed input. Please use y/n."
  rdy
fi
}
rdy
cd setup

if [ $status != 1 ] #check that explicit directive to compile has been given
 then
  exit
fi
if [ -e "Make.$cc-$libc" ]
 then
   mv Make.$cc-$libc Make.$cc-$libc.$(date -I).$(date +%k%M)
   touch Make.$cc-$libc
 else
   touch Make.$cc-$libc
 fi

TOOLCHAIN=x86_64-unknown-linux-$libc
TOOLDIR=/soft/compilers/experimental/x-tools/$cc/$ccver/$TOOLCHAIN



if [[ "$libc" == "musl" ]]; then
  LD64SO=$(ls $TOOLDIR/$TOOLCHAIN/sysroot/lib64/ | grep ld)
else
  LD64SO=$(ls $TOOLDIR/$TOOLCHAIN/sysroot/lib64/*.so | grep ld)
fi
echo $LD64SO
echo -e 'SHELL        = /bin/sh\nCD           = cd\n\nCP           = cp\nLN_S         = ln -s -f\nMKDIR        = mkdir -p\nRM           = /bin/rm -f\nTOUCH        = touch' >> Make.$cc-$libc
echo -e 'TOPdir       = .\nSRCdir       = $(TOPdir)/src\nINCdir       = $(TOPdir)/src\nBINdir       = $(TOPdir)/bin' >> Make.$cc-$libc
echo -e 'MPdir        =\nMPinc        =\nMPlib        =' >> Make.$cc-$libc
echo -e 'HPCG_INCLUDES = -I$(INCdir) -I$(INCdir)/$(arch) $(MPinc)\nHPCG_LIBS     =' >> Make.$cc-$libc
echo -e 'HPCG_OPTS     = -DHPCG_NO_MPI' >> Make.$cc-$libc
echo -e 'HPCG_DEFS     = $(HPCG_OPTS) $(HPCG_INCLUDES)' >> Make.$cc-$libc

echo "TOOLCHAIN=$TOOLCHAIN" >> Make.$cc-$libc
echo "TOOLDIR=$TOOLDIR" >> Make.$cc-$libc
echo "LD64SO=$LD64SO" >> Make.$cc-$libc
echo "CC=$TOOLDIR/bin/$TOOLCHAIN-$cc" >> Make.$cc-$libc
echo "CXX=$TOOLDIR/bin/$TOOLCHAIN-g++" >> Make.$cc-$libc
echo "LINKER=$TOOLDIR/bin/$TOOLCHAIN-ld" >> Make.$cc-$libc
echo 'CXXFLAGS =  $(HPCG_DEFS) -O3 -ffast-math -ftree-vectorize -ftree-vectorizer-verbose=0 -fopenmp -lm' >> Make.$cc-$libc
echo 'LINKFLAGS = $(HPCG_DEFS) -O3 -ffast-math -ftree-vectorize -ftree-vectorizer-verbose=0 -fopenmp -lm -lgomp' -Wl,--dynamic-linker=$LD64SO >> Make.$cc-$libc
echo "CPP = $TOOLDIR/bin/$TOOLCHAIN-cpp" >> Make.$cc-$libc
echo 'LIBS =' >> Make.$cc-$libc
echo -e "ARCHIVER     = ar\nARFLAGS      = r\nRANLIB       = echo" >> Make.$cc-$libc

echo "Make.$cc-$libc has been configured"
echo "Begin compilation!"
cd ..
if [[ ! -d "build-$cc-$libc" ]]; then
  mkdir build-$cc-$libc
  cd build-$cc-$libc
elif [[ -d "build-$cc-$libc" ]]; then
  cd build-$cc-$libc
  make clean
  cd ..
  rm -r build-$cc-$libc
  mkdir build-$cc-$libc
  cd build-$cc-$libc
fi
../configure $cc-$libc
make
status=2