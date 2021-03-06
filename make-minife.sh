#!/bin/bash
cd $benchpath

if [[ ! -d miniFE-$cc$ccver-$libc ]]; then
  benchfile=$(ls $benchpath/*.tar.gz | grep -i minife)
  tar -xf $benchfile
  benchfolder=$(echo $benchfile | sed -e 's/.tar.gz$//')
  mv $benchfolder miniFE-$cc$ccver-$libc
  cd miniFE-$cc$ccver-$libc/src
else
  rm -r miniFE-$cc$ccver-$libc
  benchfile=$(ls $benchpath/*.tar.gz | grep -i minife)
  tar -xf $benchfile
  benchfolder=$(echo $benchfile | sed -e 's/.tar.gz$//')
  mv $benchfolder miniFE-$cc$ccver-$libc
  cd miniFE-$cc$ccver-$libc/src
fi

if [ -e "Makefile-$cc$ccver-$libc" ]
 then
   mv Makefile-$cc$ccver-$libc Makefile-$cc$ccver-$libc.$(date -I).$(date +%k%M)
   touch Makefile-$cc$ccver-$libc
 else
   touch Makefile-$cc$ccver-$libc
 fi

echo $LD64SO
echo -e 'MINIFE_TYPES =  \' >> Makefile-$cc$ccver-$libc
echo -e '        -DMINIFE_SCALAR=double   \' >> Makefile-$cc$ccver-$libc
echo -e '        -DMINIFE_LOCAL_ORDINAL=int      \' >> Makefile-$cc$ccver-$libc
echo -e '        -DMINIFE_GLOBAL_ORDINAL="int"' >> Makefile-$cc$ccver-$libc
echo -e '' >> Makefile-$cc$ccver-$libc
echo -e 'MINIFE_MATRIX_TYPE = -DMINIFE_CSR_MATRIX' >> Makefile-$cc$ccver-$libc
echo 'CFLAGS = -O3 -fopenmp -lm '-L$TOOLDIR/$TOOLCHAIN/sysroot/lib64/ >> Makefile-$cc$ccver-$libc
echo 'CXXFLAGS = -O3 -fopenmp -lm '-L$TOOLDIR/$TOOLCHAIN/sysroot/lib64/ >> Makefile-$cc$ccver-$libc
echo 'CPPFLAGS = -DHAVE_MPI -DMINIFE_REPORT_RUSAGE -I. -I../utils -I../fem $(MINIFE_TYPES) $(MINIFE_MATRIX_TYPE)' -I$MPICHPATH/mpich-$cc$ccver-$libc/include >> Makefile-$cc$ccver-$libc
echo "LDFLAGS = -O3 -fopenmp -lm -lgomp -Wl,--dynamic-linker=$LD64SO,-rpath,"$TOOLDIR"/"$TOOLCHAIN"/sysroot/lib64,-rpath,$MPICHPATH/mpich-$cc$ccver-$libc/lib,-L$toollibs/,-L$MPICHPATH/mpich-$cc$ccver-$libc/lib" >> Makefile-$cc$ccver-$libc
echo "TOOLCHAIN=$TOOLCHAIN" >> Makefile-$cc$ccver-$libc
echo "TOOLDIR=$TOOLDIR" >> Makefile-$cc$ccver-$libc
echo "LD64SO=$LD64SO" >> Makefile-$cc$ccver-$libc
echo "CC=$MPICHPATH/mpich-$cc$ccver-$libc/bin/mpicc" >> Makefile-$cc$ccver-$libc
echo "LD=$TOOLDIR/bin/$TOOLCHAIN-ld" >> Makefile-$cc$ccver-$libc
echo "CPP = $TOOLDIR/bin/$TOOLCHAIN-cpp" >> Makefile-$cc$ccver-$libc
echo "CXX=$MPICHPATH/mpich-$cc$ccver-$libc/bin/mpic++" >> Makefile-$cc$ccver-$libc
echo 'LIBS =' >> Makefile-$cc$ccver-$libc
echo "include make_targets" >> Makefile-$cc$ccver-$libc
echo "Makefile-$cc$ccver-$libc has been configured"
echo "Begin compilation!"
make -f Makefile-$cc$ccver-$libc
echo "Finished with miniFE!"
echo "Path to spec:"
echo "$benchpath/miniFE-$cc$ccver-$libc/src/"
status=2
