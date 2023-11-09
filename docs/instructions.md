# Problems Solved since the submission
- STDdata fixed but needs merge
- ACC is fixed

-----------------------------------------------
### Problems: 
- OpenCL
- STD-data

-----------------------------------------------
-----------------------------------------------
First do: 
```
module load gcc
module load cmake
```

In this document the tags used : 
```
`$SPACK_PACKAGE_PATH`` : the result address when you run the `echo $(spack location -i nvhpc)` or `echo $(spack location -i /PackageHash)`
```
First of all, for Isambard MACS we need to have the latest GCC compiler first to be able to install other compilers too.
Add/Modify your existing latest GCC compiler in this format:
```
- compiler:
    spec: gcc@=13.1.0
    paths:
      cc: /projects/bristol/modules/gcc/13.1.0/bin/gcc
      cxx: /projects/bristol/modules/gcc/13.1.0/bin/g++
      f77: /projects/bristol/modules/gcc/13.1.0/bin/gfortran
      fc: /projects/bristol/modules/gcc/13.1.0/bin/gfortran
    flags: {}
    operating_system: rhel8
    target: any
    modules:
    - PrgEnv-gnu
    - gcc/13.1.0
    environment: {}
    extra_rpaths: []
```
The default format is troublesome in offloading process where `cc : cc, CC: CC etc. `



We need to install nvhpc compiler via the following command 
```
spack install nvhpc%gcc@13.1.0
```
Then after the installation, `./spack/cray/compilers.yaml` and add the following because `module use ` and then spack compiler find method generates wrong targets and the spack keeps using CLANG instead of NVC++. 

```
- compiler:
    spec: nvhpc@=23.3
    paths:
      cc: $SPACK_PACKAGE_PATH/Linux_x86_64/2023/compilers/bin/nvcc
      cxx: $SPACK_PACKAGE_PATH/Linux_x86_64/2023/compilers/bin/nvc++
      f77: $SPACK_PACKAGE_PATH/Linux_x86_64/2023/compilers/bin/nvfortran
      fc: $SPACK_PACKAGE_PATH/Linux_x86_64/2023/compilers/bin/nvfortran
    flags: {}
    operating_system: rhel8
    target: any
    environment: {}
    extra_rpaths: []
```
 Now we are ready to test the Babelstream with Spack first:
 Replace the `~/spack/var/spack/repos/builtin/packages/babelstream/package.py` with the package.py provided since this is the latest version we have, the one on the github repository hasn't been merged yet.


Now we need to have Python >= 3.8 for Excalibur-tests repository to install and work. Unfortunately the Python inside the `module use /projects/bristol/modules/modulefiles` , `module load python/3.9.0` does not have openSSL configurations properly so it won't work when trying to install excalibur-tests benchmarking suite 
It will give this error message :
```
WARNING: pip is configured with locations that require TLS/SSL, however the ssl module in Python is not available.
WARNING: Retrying (Retry(total=4, connect=None, read=None, redirect=None, status=None)) after connection broken by 'SSLError("Can't connect to HTTPS URL because the SSL module is not available.")': /simple/pip/
WARNING: Retrying (Retry(total=3, connect=None, read=None, redirect=None, status=None)) after connection broken by 'SSLError("Can't connect to HTTPS URL because the SSL module is not available.")': /simple/pip/
WARNING: Retrying (Retry(total=2, connect=None, read=None, redirect=None, status=None)) after connection broken by 'SSLError("Can't connect to HTTPS URL because the SSL module is not available.")': /simple/pip/
WARNING: Retrying (Retry(total=1, connect=None, read=None, redirect=None, status=None)) after connection broken by 'SSLError("Can't connect to HTTPS URL because the SSL module is not available.")': /simple/pip/
```

The workaround is installing your own python 

```
git clone -b 3.10 https://github.com/python/cpython.git cpython
cd cpython
./configure --prefix=$HOME/python3.10
make 
```

BUT!!! We have a shorter method that we could make this process more automated and less troublesome! USE SPACK TO INSTALL PYTHON

`spack install python@3.10%gcc@13.1.0`


The rest will be taken care by the spack. Once this process is finished, we need to add alias of this python package to our `~/.bashrc` file to load it with custom name, like when you call `mypython --version` it should print `3.10`

Add this line to bashrc
```
alias mypython='$PYTHON_SPACK_PACKGE_DIR/bin/python3.10'
```

Then:
```
source ~/.bashrc
```

Create a bash script file `reframe_install.sh` and add following : 
```
mypython -m venv macs_venv
. macs_venv/bin/activate
pip install -U pip
cd excalibur-tests
pip install -e .
export RFM_CONFIG_FILES="${PWD}/benchmarks/reframe_config.py"; export RFM_USE_LOGIN_SHELL="true"
```
This will install the ReFrame and does the initial configurations. 

This would be done for the first time, after this create a script name it `reframe_init.sh` :
```
. spack/share/spack/setup-env.sh
macs_venv/bin/activate;cd excalibur-tests
export RFM_CONFIG_FILES="${PWD}/benchmarks/reframe_config.py"; export RFM_USE_LOGIN_SHELL="true"
```
This is the one you will run everytime you open a new terminal window from now on.

Since there are some compatibility issues with ICELAKE partition we will leave to the very end to test after ReFrame. 


For the tests, we are going to use 

CPU -> cascadelake
GPU -> Volta
AMD CPU -> Milan

# Let's Start Tests!

## OpenACC: 
CPU: 
```
Build:
$ spack install babelstream@option_for_vec%nvhpc +acc cpu_arch=skylake

Run:
$ export ACC_NUM_CORES=40
$ ./acc-stream --arraysize $((2**27))

Results:
BabelStream
Version: 4.0
Implementation: OpenACC
Running kernels 100 times
Precision: double
Array size: 1073.7 MB (=1.1 GB)
Total size: 3221.2 MB (=3.2 GB)
Validation failed on a[]. Average error 0.00168703
Validation failed on b[]. Average error 0.00070293
Validation failed on c[]. Average error 0.00246025
Function    MBytes/sec  Min (sec)   Max         Average     
Copy        131639.720  0.01631     0.03563     0.01776     
Mul         139198.972  0.01543     0.02906     0.01861     
Add         149944.626  0.02148     0.03637     0.02519     
Triad       142721.016  0.02257     0.03838     0.02556     
Dot         181731.619  0.01182     0.02851     0.01391   
```
GPU:
```
Build:
==========
$ spack install babelstream@option_for_vec%nvhpc +acc cuda_arch=70
Run:
==========
$ ./acc-stream --arraysize $((2**27))
Results:
==========
BabelStream
Version: 4.0
Implementation: OpenACC
Running kernels 100 times
Precision: double
Array size: 1073.7 MB (=1.1 GB)
Total size: 3221.2 MB (=3.2 GB)
Validation failed on a[]. Average error 0.00168703
Validation failed on b[]. Average error 0.00070293
Validation failed on c[]. Average error 0.00246025
Function    MBytes/sec  Min (sec)   Max         Average     
Copy        810043.502  0.00265     0.00267     0.00265     
Mul         809968.649  0.00265     0.00266     0.00265     
Add         837547.987  0.00385     0.00385     0.00385     
Triad       833886.148  0.00386     0.00387     0.00387     
Dot         852501.151  0.00252     0.00254     0.00252     
```

## CUDA
```
Build:
==========
$ spack install babelstream@option_for_vec%gcc@9.2.0 +cuda cuda_arch=70
Run:
==========
$  ./cuda-stream --arraysize $((2**27))
Results:
==========
/lustre/home/br-kolgu/spack/opt/spack/cray-rhel8-broadwell/gcc-9.2.0/babelstream-option_for_vec-tputukmdp6ystcgklisi3y3tq3bcgwwi/bin/cuda-stream: Relink `/opt/gcc/8.1.0/snos/lib64/libgfortran.so.5' with `/lib64/librt.so.1' for IFUNC symbol `clock_gettime'
BabelStream
Version: 4.0
Implementation: CUDA
Running kernels 100 times
Precision: double
Array size: 1073.7 MB (=1.1 GB)
Total size: 3221.2 MB (=3.2 GB)
Using CUDA device Tesla V100-PCIE-16GB
Driver: 11020
Function    MBytes/sec  Min (sec)   Max         Average     
Copy        811678.756  0.00265     0.00265     0.00265     
Mul         809970.787  0.00265     0.00265     0.00265     
Add         845820.537  0.00381     0.00381     0.00381     
Triad       846497.130  0.00381     0.00381     0.00381     
Dot         887385.537  0.00242     0.00244     0.00243  
```



## HIP (ROCM)

- No idea since I couldn't get ROCM working on Isambard


## Kokkos
It used to work but now it is not building!
```
15 errors found in build log:
     93     [ 69%] Building CXX object core/src/CMakeFiles/kokkoscore.dir/impl/Kokkos_Stacktrace.cpp.o
     94     cd /tmp/br-kolgu/spack-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-build-agvn4y7/core/src && /lustre/home/br-kolgu/spack/lib/spack/e
            nv/gcc/g++ -DKOKKOS_DEPENDENCE -Dkokkoscore_EXPORTS -I/tmp/br-kolgu/spack-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-build-agvn4y7/
            core/src -I/tmp/br-kolgu/spack-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-src/core/src -I/tmp/br-kolgu/spack-stage/spack-stage-kokk
            os-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-build-agvn4y7 -I/tmp/br-kolgu/spack-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-src
            /core/src/../../tpls/desul/include -O3 -DNDEBUG -std=gnu++17 -fPIC -march=core-avx2 -mtune=core-avx2 -mrtm -MD -MT core/src/CMakeFiles/kokkoscore.dir/impl/Kokk
            os_Stacktrace.cpp.o -MF CMakeFiles/kokkoscore.dir/impl/Kokkos_Stacktrace.cpp.o.d -o CMakeFiles/kokkoscore.dir/impl/Kokkos_Stacktrace.cpp.o -c /tmp/br-kolgu/spa
            ck-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-src/core/src/impl/Kokkos_Stacktrace.cpp
     95     [ 73%] Building CXX object core/src/CMakeFiles/kokkoscore.dir/impl/Kokkos_hwloc.cpp.o
     96     cd /tmp/br-kolgu/spack-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-build-agvn4y7/core/src && /lustre/home/br-kolgu/spack/lib/spack/e
            nv/gcc/g++ -DKOKKOS_DEPENDENCE -Dkokkoscore_EXPORTS -I/tmp/br-kolgu/spack-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-build-agvn4y7/
            core/src -I/tmp/br-kolgu/spack-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-src/core/src -I/tmp/br-kolgu/spack-stage/spack-stage-kokk
            os-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-build-agvn4y7 -I/tmp/br-kolgu/spack-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-src
            /core/src/../../tpls/desul/include -O3 -DNDEBUG -std=gnu++17 -fPIC -march=core-avx2 -mtune=core-avx2 -mrtm -MD -MT core/src/CMakeFiles/kokkoscore.dir/impl/Kokk
            os_hwloc.cpp.o -MF CMakeFiles/kokkoscore.dir/impl/Kokkos_hwloc.cpp.o.d -o CMakeFiles/kokkoscore.dir/impl/Kokkos_hwloc.cpp.o -c /tmp/br-kolgu/spack-stage/spack-
            stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-src/core/src/impl/Kokkos_hwloc.cpp
     97     [ 76%] Building CXX object core/src/CMakeFiles/kokkoscore.dir/Serial/Kokkos_Serial.cpp.o
     98     cd /tmp/br-kolgu/spack-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-build-agvn4y7/core/src && /lustre/home/br-kolgu/spack/lib/spack/e
            nv/gcc/g++ -DKOKKOS_DEPENDENCE -Dkokkoscore_EXPORTS -I/tmp/br-kolgu/spack-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-build-agvn4y7/
            core/src -I/tmp/br-kolgu/spack-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-src/core/src -I/tmp/br-kolgu/spack-stage/spack-stage-kokk
            os-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-build-agvn4y7 -I/tmp/br-kolgu/spack-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-src
            /core/src/../../tpls/desul/include -O3 -DNDEBUG -std=gnu++17 -fPIC -march=core-avx2 -mtune=core-avx2 -mrtm -MD -MT core/src/CMakeFiles/kokkoscore.dir/Serial/Ko
            kkos_Serial.cpp.o -MF CMakeFiles/kokkoscore.dir/Serial/Kokkos_Serial.cpp.o.d -o CMakeFiles/kokkoscore.dir/Serial/Kokkos_Serial.cpp.o -c /tmp/br-kolgu/spack-sta
            ge/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-src/core/src/Serial/Kokkos_Serial.cpp
  >> 99     /tmp/br-kolgu/spack-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-src/core/src/impl/Kokkos_MemoryPool.cpp:116:48: error: 'uint32_t' ha
            s not been declared
     100      116 | void _print_memory_pool_state(std::ostream& s, uint32_t const* sb_state_ptr,
     101          |                                                ^~~~~~~~
  >> 102    /tmp/br-kolgu/spack-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-src/core/src/impl/Kokkos_MemoryPool.cpp:117:49: error: 'uint32_t' ha
            s not been declared
     103      117 |                               int32_t sb_count, uint32_t sb_size_lg2,
     104          |                                                 ^~~~~~~~
  >> 105    /tmp/br-kolgu/spack-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-src/core/src/impl/Kokkos_MemoryPool.cpp:118:31: error: 'uint32_t' ha
            s not been declared
     106      118 |                               uint32_t sb_state_size, uint32_t state_shift,
     107          |                               ^~~~~~~~
  >> 108    /tmp/br-kolgu/spack-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-src/core/src/impl/Kokkos_MemoryPool.cpp:118:55: error: 'uint32_t' ha
            s not been declared
     109      118 |                               uint32_t sb_state_size, uint32_t state_shift,
     110          |                                                       ^~~~~~~~
  >> 111    /tmp/br-kolgu/spack-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-src/core/src/impl/Kokkos_MemoryPool.cpp:119:31: error: 'uint32_t' ha
            s not been declared
     112      119 |                               uint32_t state_used_mask) {
     113          |                               ^~~~~~~~
     114    /tmp/br-kolgu/spack-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-src/core/src/impl/Kokkos_MemoryPool.cpp: In function 'void Kokkos::I
            mpl::_print_memory_pool_state(std::ostream&, const int*, int32_t, int, int, int, int)':
  >> 115    /tmp/br-kolgu/spack-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-src/core/src/impl/Kokkos_MemoryPool.cpp:125:13: error: 'uint32_t' do
            es not name a type
     116      125 |       const uint32_t block_count_lg2 = (*sb_state_ptr) >> state_shift;
     117          |             ^~~~~~~~
     118    /tmp/br-kolgu/spack-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-src/core/src/impl/Kokkos_MemoryPool.cpp:53:1: note: 'uint32_t' is de
            fined in header '<cstdint>'; did you forget to '#include <cstdint>'?
     119       52 | #include <sstream>
     120      +++ |+#include <cstdint>
     121       53 |
  >> 122    /tmp/br-kolgu/spack-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-src/core/src/impl/Kokkos_MemoryPool.cpp:126:13: error: 'uint32_t' do
            es not name a type
     123      126 |       const uint32_t block_size_lg2  = sb_size_lg2 - block_count_lg2;
     124          |             ^~~~~~~~
     125    /tmp/br-kolgu/spack-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-src/core/src/impl/Kokkos_MemoryPool.cpp:126:13: note: 'uint32_t' is 
            defined in header '<cstdint>'; did you forget to '#include <cstdint>'?
  >> 126    /tmp/br-kolgu/spack-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-src/core/src/impl/Kokkos_MemoryPool.cpp:127:13: error: 'uint32_t' do
            es not name a type
     127      127 |       const uint32_t block_count     = 1u << block_count_lg2;
     128          |             ^~~~~~~~
     129    /tmp/br-kolgu/spack-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-src/core/src/impl/Kokkos_MemoryPool.cpp:127:13: note: 'uint32_t' is 
            defined in header '<cstdint>'; did you forget to '#include <cstdint>'?
  >> 130    /tmp/br-kolgu/spack-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-src/core/src/impl/Kokkos_MemoryPool.cpp:128:13: error: 'uint32_t' do
            es not name a type
     131      128 |       const uint32_t block_used      = (*sb_state_ptr) & state_used_mask;
     132          |             ^~~~~~~~
     133    /tmp/br-kolgu/spack-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-src/core/src/impl/Kokkos_MemoryPool.cpp:128:13: note: 'uint32_t' is 
            defined in header '<cstdint>'; did you forget to '#include <cstdint>'?
  >> 134    /tmp/br-kolgu/spack-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-src/core/src/impl/Kokkos_MemoryPool.cpp:131:36: error: 'block_size_l
            g2' was not declared in this scope; did you mean 'sb_size_lg2'?
     135      131 |         << " block_size(" << (1 << block_size_lg2) << ")"
     136          |                                    ^~~~~~~~~~~~~~
     137          |                                    sb_size_lg2
  >> 138    /tmp/br-kolgu/spack-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-src/core/src/impl/Kokkos_MemoryPool.cpp:132:32: error: 'block_used' 
            was not declared in this scope
     139      132 |         << " block_count( " << block_used << " / " << block_count << " )"
     140          |                                ^~~~~~~~~~
  >> 141    /tmp/br-kolgu/spack-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-src/core/src/impl/Kokkos_MemoryPool.cpp:132:55: error: 'block_count'
             was not declared in this scope
     142      132 |         << " block_count( " << block_used << " / " << block_count << " )"
     143          |                                                       ^~~~~~~~~~~
  >> 144    make[2]: *** [core/src/CMakeFiles/kokkoscore.dir/build.make:205: core/src/CMakeFiles/kokkoscore.dir/impl/Kokkos_MemoryPool.cpp.o] Error 1
     145    make[2]: *** Waiting for unfinished jobs....
     146    make[2]: Leaving directory '/tmp/br-kolgu/spack-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-build-agvn4y7'
  >> 147    make[1]: *** [CMakeFiles/Makefile2:233: core/src/CMakeFiles/kokkoscore.dir/all] Error 2
     148    make[1]: Leaving directory '/tmp/br-kolgu/spack-stage/spack-stage-kokkos-3.7.01-agvn4y7zgdezzevi4ei7g43wwrjdess7/spack-build-agvn4y7'
  >> 149    make: *** [Makefile:139: all] Error 2

```


## OpenCL
- Haven't tested it all, but removed the need for a function to extract the package version.
```
Build:
==========
spack install babelstream@develop%gcc@13.1.0 +ocl backend=intel
spack install babelstream@develop%oneapi@2021.4.0 +ocl backend=intel
Run Error:
==========
ClplatformID not found


Build:
==========
spack install babelstream@develop%gcc@13.1.0 +ocl backend=pocl

Build Error:
==========
During the installation LLVM 10.0.1 package couldn't be build

```



## TBB
```
Build:
==========
$ spack install babelstream@option_for_vec%gcc@13.1.0 +tbb partitioner=auto
Run:
==========
$ ./bin/tbb-stream --arraysize $((2**27))
Results:
==========
BabelStream
Version: 4.0
Implementation: TBB
Running kernels 100 times
Precision: double
Array size: 1073.7 MB (=1.1 GB)
Total size: 3221.2 MB (=3.2 GB)
Using TBB partitioner: auto_partitioner
Backing storage typeid: Pd
Function    MBytes/sec  Min (sec)   Max         Average     
Copy        90440.436   0.02374     0.02857     0.02600     
Mul         88813.645   0.02418     0.02863     0.02614     
Add         100313.147  0.03211     0.03852     0.03498     
Triad       101585.688  0.03171     0.03853     0.03471     
Dot         134336.843  0.01599     0.02066     0.01840 
```

## std-data
https://github.com/UoB-HPC/BabelStream/pull/165 this fixes the issue. So in order to make it run we need to change the 

`git: github.com/UOB-HPC/Babelstream.git` to `git : github.com/kaanolgu/Babelstream.git`so that it gets the changes I made to the CMake file.

The branch is called `update_stddata` or `stddata` in my repository 

```
Build:
==========
$ spack install babelstream@stddata%gcc@13.1.0 +stddata
Run:
==========
./bin/std-data-stream --arraysize $((2**27))

Results:
==========
BabelStream
Version: 4.0
Implementation: STD (data-oriented)
Running kernels 100 times
Precision: double
Array size: 1073.7 MB (=1.1 GB)
Total size: 3221.2 MB (=3.2 GB)
Function    MBytes/sec  Min (sec)   Max         Average     
Copy        84800.789   0.02532     0.04282     0.03101     
Mul         82584.055   0.02600     0.04181     0.03126     
Add         91190.829   0.03532     0.05735     0.04236     
Triad       93170.046   0.03457     0.05681     0.04421     
Dot         122850.656  0.01748     0.03015     0.02326   
```

## std-data
https://github.com/UoB-HPC/BabelStream/pull/165 this fixes the issue. So in order to make it run we need to change the 

`git: github.com/UOB-HPC/Babelstream.git` to `git : github.com/kaanolgu/Babelstream.git`so that it gets the changes I made to the CMake file.

The branch is called `update_stddata` or `stddata` in my repository 

```
Build:
==========
$ spack install babelstream@stddata%gcc@13.1.0 +stddata
Run:
==========
./bin/std-data-stream --arraysize $((2**27))

Results:
==========
BabelStream
Version: 4.0
Implementation: STD (data-oriented)
Running kernels 100 times
Precision: double
Array size: 1073.7 MB (=1.1 GB)
Total size: 3221.2 MB (=3.2 GB)
Function    MBytes/sec  Min (sec)   Max         Average     
Copy        84800.789   0.02532     0.04282     0.03101     
Mul         82584.055   0.02600     0.04181     0.03126     
Add         91190.829   0.03532     0.05735     0.04236     
Triad       93170.046   0.03457     0.05681     0.04421     
Dot         122850.656  0.01748     0.03015     0.02326   
```

## OpenMP
- Intel offload gives an error while running libimf.so not found 
- In order to fix it manually when running load the `source /lustre/projects/bristol/intel-oneapi-2023.1.0/setvars.sh` script to have `LD_LIBRARY_PATH` properly set
```
Build:
==========
$ spack install babelstream@develop%oneapi@2023.1.0 +omp intel_target=cascadelake
Run:
==========
$ ./omp-stream --arraysize $((2**27)
Results:
==========
BabelStream
Version: 4.0
Implementation: OpenMP
Running kernels 100 times
Precision: double
Array size: 1073.7 MB (=1.1 GB)
Total size: 3221.2 MB (=3.2 GB)
Function    MBytes/sec  Min (sec)   Max         Average     
Copy        141910.323  0.01513     0.03381     0.02070     
Mul         138375.862  0.01552     0.03528     0.02079     
Add         155874.103  0.02067     0.04958     0.02989     
Triad       155907.487  0.02066     0.04703     0.03164     
Dot         220908.782  0.00972     0.03005     0.01985     
```
```
Build:
==========
$ spack install babelstream@develop%oneapi@2023.1.0 +omp intel_target=cascadelake
Run:
==========
$ ./omp-stream --arraysize $((2**27)
Results:
==========
BabelStream
Version: 4.0
Implementation: OpenMP
Running kernels 100 times
Precision: double
Array size: 1073.7 MB (=1.1 GB)
Total size: 3221.2 MB (=3.2 GB)
Function    MBytes/sec  Min (sec)   Max         Average     
Copy        141910.323  0.01513     0.03381     0.02070     
Mul         138375.862  0.01552     0.03528     0.02079     
Add         155874.103  0.02067     0.04958     0.02989     
Triad       155907.487  0.02066     0.04703     0.03164     
Dot         220908.782  0.00972     0.03005     0.01985     
```



-------------------------------

## RAJA
- RAJA gives error w/wo offload, it used to work 

Build:
==========

`[br-kolgu@volta-002 RAJA-v2023.06.1]$ spack install babelstream@main%gcc@9.2.0 +raja dir=/home/br-kolgu/RAJA-v2023.06.1/ offload=nvidia cuda_arch=70`
`$ spack install babelstream@main%gcc@9.2.0 +raja dir=/home/br-kolgu/RAJA-v2023.06.1/ offload=cpu`
Error (NO OFFLOAD):
==========
```
>> 339    /home/br-kolgu/RAJA-v2023.06.1/include/RAJA/pattern/forall.hpp:163:10: error: use of undeclared identifier 'forall_impl'
```

Error (OFFLOAD):
==========
```
25 errors found in build log:
     208    make[2]: Entering directory '/var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-build-seuxu
            i6'
     209    [ 84%] Building CXX object CMakeFiles/raja-stream.dir/src/main.cpp.o
     210    [ 92%] Building CXX object CMakeFiles/raja-stream.dir/src/raja/RAJAStream.cpp.o
     211    /lustre/home/br-kolgu/spack/lib/spack/env/gcc/g++ -DRAJA_TARGET_GPU -DUSE_RAJA -I/var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-mai
            n-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja -I/var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvk
            cipop4mnq/spack-src/src -I/home/br-kolgu/RAJA-v2023.06.1/include -I/var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdto
            gcrw5siqpvkcipop4mnq/spack-build-seuxui6/raja/include -I/home/br-kolgu/RAJA-v2023.06.1/tpl/camp/include -I/var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/sp
            ack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-build-seuxui6/raja/tpl/camp/include -DNDEBUG -std=c++14 -O3 -march=native -MD -MT CMakeFil
            es/raja-stream.dir/src/main.cpp.o -MF CMakeFiles/raja-stream.dir/src/main.cpp.o.d -o CMakeFiles/raja-stream.dir/src/main.cpp.o -c /var/tmp/pbs.81492.gw4head
            /br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/main.cpp
     212    /lustre/home/br-kolgu/spack/lib/spack/env/gcc/g++ -DRAJA_TARGET_GPU -DUSE_RAJA -I/var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-mai
            n-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja -I/var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvk
            cipop4mnq/spack-src/src -I/home/br-kolgu/RAJA-v2023.06.1/include -I/var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdto
            gcrw5siqpvkcipop4mnq/spack-build-seuxui6/raja/include -I/home/br-kolgu/RAJA-v2023.06.1/tpl/camp/include -I/var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/sp
            ack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-build-seuxui6/raja/tpl/camp/include -DNDEBUG -std=c++14 -O3 -march=native -MD -MT CMakeFil
            es/raja-stream.dir/src/raja/RAJAStream.cpp.o -MF CMakeFiles/raja-stream.dir/src/raja/RAJAStream.cpp.o.d -o CMakeFiles/raja-stream.dir/src/raja/RAJAStream.cp
            p.o -c /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp
     213    In file included from /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAS
            tream.cpp:10:
  >> 214    /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.hpp:32:15: error
            : no template named 'cuda_exec' in namespace 'RAJA'
     215    typedef RAJA::cuda_exec<block_size> policy;
     216            ~~~~~~^
  >> 217    /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.hpp:33:15: error
            : no type named 'cuda_reduce' in namespace 'RAJA'
     218    typedef RAJA::cuda_reduce reduce_policy;
     219            ~~~~~~^
  >> 220    /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:28:57: error
            : use of undeclared identifier 'cudaMemAttachGlobal'
     221      cudaMallocManaged((void**)&d_a, sizeof(T)*ARRAY_SIZE, cudaMemAttachGlobal);
     222                                                            ^
  >> 223    /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:29:57: error
            : use of undeclared identifier 'cudaMemAttachGlobal'
     224      cudaMallocManaged((void**)&d_b, sizeof(T)*ARRAY_SIZE, cudaMemAttachGlobal);
     225                                                            ^
  >> 226    /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:30:57: error
            : use of undeclared identifier 'cudaMemAttachGlobal'
     227      cudaMallocManaged((void**)&d_c, sizeof(T)*ARRAY_SIZE, cudaMemAttachGlobal);
     228                                                            ^
  >> 229    /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:31:3: error:
             use of undeclared identifier 'cudaDeviceSynchronize'
     230      cudaDeviceSynchronize();
     231      ^
  >> 232    /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:43:3: error:
             use of undeclared identifier 'cudaFree'
     233      cudaFree(d_a);
     234      ^
     235    /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:162:16: note
            : in instantiation of member function 'RAJAStream<float>::~RAJAStream' requested here
     236    template class RAJAStream<float>;
     237                   ^
  >> 238    /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:44:3: error:
             use of undeclared identifier 'cudaFree'
     239      cudaFree(d_b);
     240      ^
  >> 241    /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:45:3: error:
             use of undeclared identifier 'cudaFree'
     242      cudaFree(d_c);
     243      ^
  >> 244    /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:134:37: erro
            r: implicit instantiation of undefined template 'RAJA::ReduceSum<int, float>'
     245      RAJA::ReduceSum<reduce_policy, T> sum(T{});
     246                                        ^
     247    /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:162:16: note
            : in instantiation of member function 'RAJAStream<float>::dot' requested here
     248    template class RAJAStream<float>;
     249                   ^
     250    /home/br-kolgu/RAJA-v2023.06.1/include/RAJA/pattern/reduce.hpp:182:7: note: template is declared here
     251    class ReduceSum;
     252          ^
  >> 253    /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:43:3: error:
             use of undeclared identifier 'cudaFree'
     254      cudaFree(d_a);
     255      ^
     256    /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:163:16: note
            : in instantiation of member function 'RAJAStream<double>::~RAJAStream' requested here
     257    template class RAJAStream<double>;
     258                   ^
  >> 259    /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:44:3: error:
             use of undeclared identifier 'cudaFree'
     260      cudaFree(d_b);
     261      ^
  >> 262    /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:45:3: error:
             use of undeclared identifier 'cudaFree'
     263      cudaFree(d_c);
     264      ^
  >> 265    /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:134:37: erro
            r: implicit instantiation of undefined template 'RAJA::ReduceSum<int, double>'
     266      RAJA::ReduceSum<reduce_policy, T> sum(T{});
     267                                        ^
     268    /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:163:16: note
            : in instantiation of member function 'RAJAStream<double>::dot' requested here
     269    template class RAJAStream<double>;
     270                   ^
     271    /home/br-kolgu/RAJA-v2023.06.1/include/RAJA/pattern/reduce.hpp:182:7: note: template is declared here
     272    class ReduceSum;
     273          ^
     274    In file included from /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAS
            tream.cpp:10:
     275    In file included from /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAS
            tream.hpp:11:
     276    In file included from /home/br-kolgu/RAJA-v2023.06.1/include/RAJA/RAJA.hpp:44:
  >> 277    /home/br-kolgu/RAJA-v2023.06.1/include/RAJA/pattern/forall.hpp:163:10: error: use of undeclared identifier 'forall_impl'
     278      return forall_impl(r,
     279             ^
     280    /home/br-kolgu/RAJA-v2023.06.1/include/RAJA/pattern/forall.hpp:537:41: note: in instantiation of function template specialization 'RAJA::wrap::forall<camp::
            resources::v1::Host, int, const RAJA::TypedRangeSegment<long, long> &, (lambda at /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-ma
            in-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:77:25), RAJA::expt::ForallParamPack<> &>' requested here
     281      resources::EventProxy<Res> e =  wrap::forall(
     282                                            ^
     283    /home/br-kolgu/RAJA-v2023.06.1/include/RAJA/pattern/forall.hpp:578:45: note: in instantiation of function template specialization 'RAJA::policy_by_value_int
            erface::forall<int, camp::resources::v1::Host, const RAJA::TypedRangeSegment<long, long> &, (lambda at /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack
            -stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:77:25)>' requested here

     ...

     286    /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:77:3: note: 
            in instantiation of function template specialization 'RAJA::forall<int, const RAJA::TypedRangeSegment<long, long> &, (lambda at /var/tmp/pbs.81492.gw4head/b
            r-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:77:25), camp::resources::v1::Host>' requ
            ested here
     287      forall<policy>(range, [=] RAJA_DEVICE (RAJA::Index_type index)
     288      ^
     289    In file included from /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAS
            tream.cpp:10:
     290    In file included from /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAS
            tream.hpp:11:
     291    In file included from /home/br-kolgu/RAJA-v2023.06.1/include/RAJA/RAJA.hpp:44:
  >> 292    /home/br-kolgu/RAJA-v2023.06.1/include/RAJA/pattern/forall.hpp:163:10: error: use of undeclared identifier 'forall_impl'
     293      return forall_impl(r,
     294             ^
     295    /home/br-kolgu/RAJA-v2023.06.1/include/RAJA/pattern/forall.hpp:537:41: note: in instantiation of function template specialization 'RAJA::wrap::forall<camp::
            resources::v1::Host, int, const RAJA::TypedRangeSegment<long, long> &, (lambda at /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-ma
            in-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:101:25), RAJA::expt::ForallParamPack<> &>' requested here
     296      resources::EventProxy<Res> e =  wrap::forall(
     297                                            ^
     298    /home/br-kolgu/RAJA-v2023.06.1/include/RAJA/pattern/forall.hpp:578:45: note: in instantiation of function template specialization 'RAJA::policy_by_value_int
            erface::forall<int, camp::resources::v1::Host, const RAJA::TypedRangeSegment<long, long> &, (lambda at /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack
            -stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:101:25)>' requested here

     ...

     301    /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:101:3: note:
             in instantiation of function template specialization 'RAJA::forall<int, const RAJA::TypedRangeSegment<long, long> &, (lambda at /var/tmp/pbs.81492.gw4head/
            br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:101:25), camp::resources::v1::Host>' re
            quested here
     302      forall<policy>(range, [=] RAJA_DEVICE (RAJA::Index_type index)
     303      ^
     304    In file included from /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAS
            tream.cpp:10:
     305    In file included from /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAS
            tream.hpp:11:
     306    In file included from /home/br-kolgu/RAJA-v2023.06.1/include/RAJA/RAJA.hpp:44:
  >> 307    /home/br-kolgu/RAJA-v2023.06.1/include/RAJA/pattern/forall.hpp:163:10: error: use of undeclared identifier 'forall_impl'
     308      return forall_impl(r,
     309             ^
     310    /home/br-kolgu/RAJA-v2023.06.1/include/RAJA/pattern/forall.hpp:537:41: note: in instantiation of function template specialization 'RAJA::wrap::forall<camp::
            resources::v1::Host, int, const RAJA::TypedRangeSegment<long, long> &, (lambda at /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-ma
            in-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:89:25), RAJA::expt::ForallParamPack<> &>' requested here
     311      resources::EventProxy<Res> e =  wrap::forall(
     312                                            ^
     313    /home/br-kolgu/RAJA-v2023.06.1/include/RAJA/pattern/forall.hpp:578:45: note: in instantiation of function template specialization 'RAJA::policy_by_value_int
            erface::forall<int, camp::resources::v1::Host, const RAJA::TypedRangeSegment<long, long> &, (lambda at /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack
            -stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:89:25)>' requested here

     ...

     316    /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:89:3: note: 
            in instantiation of function template specialization 'RAJA::forall<int, const RAJA::TypedRangeSegment<long, long> &, (lambda at /var/tmp/pbs.81492.gw4head/b
            r-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:89:25), camp::resources::v1::Host>' requ
            ested here
     317      forall<policy>(range, [=] RAJA_DEVICE (RAJA::Index_type index)
     318      ^
     319    In file included from /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAS
            tream.cpp:10:
     320    In file included from /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAS
            tream.hpp:11:
     321    In file included from /home/br-kolgu/RAJA-v2023.06.1/include/RAJA/RAJA.hpp:44:
  >> 322    /home/br-kolgu/RAJA-v2023.06.1/include/RAJA/pattern/forall.hpp:163:10: error: use of undeclared identifier 'forall_impl'
     323      return forall_impl(r,
     324             ^
     325    /home/br-kolgu/RAJA-v2023.06.1/include/RAJA/pattern/forall.hpp:537:41: note: in instantiation of function template specialization 'RAJA::wrap::forall<camp::
            resources::v1::Host, int, const RAJA::TypedRangeSegment<long, long> &, (lambda at /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-ma
            in-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:114:25), RAJA::expt::ForallParamPack<> &>' requested here
     326      resources::EventProxy<Res> e =  wrap::forall(
     327                                            ^
     328    /home/br-kolgu/RAJA-v2023.06.1/include/RAJA/pattern/forall.hpp:578:45: note: in instantiation of function template specialization 'RAJA::policy_by_value_int
            erface::forall<int, camp::resources::v1::Host, const RAJA::TypedRangeSegment<long, long> &, (lambda at /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack
            -stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:114:25)>' requested here

     ...

     331    /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:114:3: note:
             in instantiation of function template specialization 'RAJA::forall<int, const RAJA::TypedRangeSegment<long, long> &, (lambda at /var/tmp/pbs.81492.gw4head/
            br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:114:25), camp::resources::v1::Host>' re
            quested here
     332      forall<policy>(range, [=] RAJA_DEVICE (RAJA::Index_type index)
     333      ^
     334    In file included from /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAS
            tream.cpp:10:
     335    In file included from /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAS
            tream.hpp:11:
     336    In file included from /home/br-kolgu/RAJA-v2023.06.1/include/RAJA/RAJA.hpp:44:
  >> 337    /home/br-kolgu/RAJA-v2023.06.1/include/RAJA/pattern/forall.hpp:163:10: error: use of undeclared identifier 'forall_impl'
     338      return forall_impl(r,
     339             ^
     340    /home/br-kolgu/RAJA-v2023.06.1/include/RAJA/pattern/forall.hpp:537:41: note: in instantiation of function template specialization 'RAJA::wrap::forall<camp::
            resources::v1::Host, int, const RAJA::TypedRangeSegment<long, long> &, (lambda at /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-ma
            in-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:55:25), RAJA::expt::ForallParamPack<> &>' requested here
     341      resources::EventProxy<Res> e =  wrap::forall(
     342                                            ^
     343    /home/br-kolgu/RAJA-v2023.06.1/include/RAJA/pattern/forall.hpp:578:45: note: in instantiation of function template specialization 'RAJA::policy_by_value_int
            erface::forall<int, camp::resources::v1::Host, const RAJA::TypedRangeSegment<long, long> &, (lambda at /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack
            -stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:55:25)>' requested here

     ...

     345                                                ^
     346    /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:55:3: note: 
            in instantiation of function template specialization 'RAJA::forall<int, const RAJA::TypedRangeSegment<long, long> &, (lambda at /var/tmp/pbs.81492.gw4head/b
            r-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.cpp:55:25), camp::resources::v1::Host>' requ
            ested here
     347      forall<policy>(range, [=] RAJA_DEVICE (RAJA::Index_type index)
     348      ^
     349    fatal error: too many errors emitted, stopping now [-ferror-limit=]
     350    20 errors generated.
  >> 351    make[2]: *** [CMakeFiles/raja-stream.dir/build.make:79: CMakeFiles/raja-stream.dir/src/raja/RAJAStream.cpp.o] Error 1
     352    make[2]: *** Waiting for unfinished jobs....
     353    In file included from /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/main.cpp:4
            1:
  >> 354    /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.hpp:32:15: error
            : no template named 'cuda_exec' in namespace 'RAJA'
     355    typedef RAJA::cuda_exec<block_size> policy;
     356            ~~~~~~^
  >> 357    /var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-src/src/raja/RAJAStream.hpp:33:15: error
            : no type named 'cuda_reduce' in namespace 'RAJA'
     358    typedef RAJA::cuda_reduce reduce_policy;
     359            ~~~~~~^
     360    2 errors generated.
  >> 361    make[2]: *** [CMakeFiles/raja-stream.dir/build.make:93: CMakeFiles/raja-stream.dir/src/main.cpp.o] Error 1
     362    make[2]: Leaving directory '/var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-build-seuxui
            6'
  >> 363    make[1]: *** [CMakeFiles/Makefile2:144: CMakeFiles/raja-stream.dir/all] Error 2
     364    make[1]: Leaving directory '/var/tmp/pbs.81492.gw4head/br-kolgu/spack-stage/spack-stage-babelstream-main-seuxui6mmdtogcrw5siqpvkcipop4mnq/spack-build-seuxui
            6'
  >> 365    make: *** [Makefile:139: all] Error 2
  ```
Results:
==========

```



## THRUST
- Changed the CUDA_ARCH value to be only `70` etc. instead of `sm_70` because it is no longer needed since the change to `CMAKE_CUDA_ARCHITECTURE``
```
Build:
==========
spack install babelstream@main%gcc@9.2.0 +thrust implementation=cuda cuda_arch=70 backend=cuda
spack install babelstream@main%gcc@13.1.0 +thrust implementation=rocm amdgpu_target=gfx701 (did not work hip compiler does not install properly on isambard)

Run:
==========
./thrust-stream --arraysize $((2**27))

Results:
==========
BabelStream
Version: 5.0
Implementation: Thrust
Running kernels 100 times
Precision: double
Array size: 1073.7 MB (=1.1 GB)
Total size: 3221.2 MB (=3.2 GB)
Using CUDA device: Tesla V100-PCIE-16GB
Driver: 11020
Thrust version: 101501
Thrust backend: CUDA
Init: 0.714356 s (=4509.269714 MBytes/sec)
Read: 0.003615 s (=891033.601869 MBytes/sec)
Function    MBytes/sec  Min (sec)   Max         Average     
Copy        813163.869  0.00264     0.00264     0.00264     
Mul         813590.550  0.00264     0.00264     0.00264     
Add         848021.642  0.00380     0.00380     0.00380     
Triad       847954.449  0.00380     0.00380     0.00380     
Dot         833531.732  0.00258     0.00262     0.00259   
```



## SYCL
- Remember to use build_system=cmake because it gets confused with Fortran version.
```
Build:
==========
 spack install babelstream@main%oneapi@2023.1.0 +sycl implementation=ONEAPI-ICPX  build_system=cmake
Run:
==========
source /projects/bristol/modules/intel-oneapi-2023.1.0/setvars.sh 
.bin/sycl-stream --device 1
Results:
==========
sycl-stream --device 1
BabelStream
Version: 5.0
Implementation: SYCL
Running kernels 100 times
Precision: double
Array size: 268.4 MB (=0.3 GB)
Total size: 805.3 MB (=0.8 GB)
Using SYCL device Intel(R) Xeon(R) Gold 6338 CPU @ 2.00GHz
Driver: 2023.15.3.0.20_160000
Reduction kernel config: 40 groups of size 16
Init: 0.142539 s (=5649.714983 MBytes/sec)
Read: 2.974602 s (=270.727411 MBytes/sec)
Function    MBytes/sec  Min (sec)   Max         Average     
Copy        152039.450  0.00353     0.00518     0.00425     
Mul         152923.307  0.00351     0.00441     0.00410     
Add         164584.030  0.00489     0.00643     0.00584     
Triad       164859.268  0.00488     0.00686     0.00586     
Dot         141886.704  0.00378     0.00980     0.00413  
```



# SYCL2020-acc / SYCL2020-usm
- Notes
```
Build:
==========
spack install babelstream@main%oneapi@2023.1.0 +sycl2020acc
spack install babelstream@main%oneapi@2023.1.0 +sycl2020usm
Run:
==========
./bin/sycl2020-acc-stream --arraysize $((2**27)) --device 1
./bin/sycl2020-usm-stream --arraysize $((2**27)) --device 1
Results:
==========
BabelStream
Version: 5.0
Implementation: SYCL2020 accessors
Running kernels 100 times
Precision: double
Array size: 1073.7 MB (=1.1 GB)
Total size: 3221.2 MB (=3.2 GB)
Using SYCL device Intel(R) Xeon(R) Gold 6338 CPU @ 2.00GHz
Driver: 2023.15.3.0.20_160000
Init: 0.606804 s (=5308.508484 MBytes/sec)
Read: 1.998636 s (=1611.712224 MBytes/sec)
Function    MBytes/sec  Min (sec)   Max         Average     
Copy        139147.209  0.01543     0.01878     0.01691     
Mul         137765.853  0.01559     0.01709     0.01650     
Add         150785.675  0.02136     0.02533     0.02347     
Triad       158399.839  0.02034     0.02491     0.02355     
Dot         164879.618  0.01302     0.01935     0.01648  

-------

BabelStream
Version: 5.0
Implementation: SYCL2020 USM
Running kernels 100 times
Precision: double
Array size: 1073.7 MB (=1.1 GB)
Total size: 3221.2 MB (=3.2 GB)
Using SYCL device Intel(R) Xeon(R) Gold 6338 CPU @ 2.00GHz
Driver: 2023.15.3.0.20_160000
Init: 0.370516 s (=8693.888952 MBytes/sec)
Read: 0.369080 s (=8727.706277 MBytes/sec)
Function    MBytes/sec  Min (sec)   Max         Average     
Copy        146916.612  0.01462     0.01879     0.01718     
Mul         152629.284  0.01407     0.01852     0.01671     
Add         162881.392  0.01978     0.03072     0.02397     
Triad       167202.192  0.01927     0.02726     0.02394     
Dot         159971.309  0.01342     0.02055     0.01614




```
bin/sycl2020-acc-stream --arraysize $((2**27)) --device 1


# HIP ROCM
This is a bit tricky. The hip is installed when I changed the compiler to gcc for libffi package which wasn't installing with clang
I used the default provided rocmcc-5.4.1

This is the compilers.yaml file: 
compilers:
- compiler:
    spec: cce@=15.0.1
    paths:
      cc: /opt/cray/pe/craype/2.7.20/bin/cc
      cxx: /opt/cray/pe/craype/2.7.20/bin/CC
      f77: /opt/cray/pe/craype/2.7.20/bin/ftn
      fc: /opt/cray/pe/craype/2.7.20/bin/ftn
    flags: {}
    operating_system: rhel8
    target: x86_64
    modules: []
    environment: {}
    extra_rpaths: []
- compiler:
    spec: clang@=15.0.1
    paths:
      cc: /opt/cray/pe/cce/15.0.1/cce-clang/x86_64/bin/clang
      cxx: /opt/cray/pe/cce/15.0.1/cce-clang/x86_64/bin/clang++
      f77: null
      fc: null
    flags: {}
    operating_system: rhel8
    target: x86_64
    modules: []
    environment: {}
    extra_rpaths: []
- compiler:
    spec: gcc@=8.5.0
    paths:
      cc: /usr/bin/gcc
      cxx: /usr/bin/g++
      f77: /usr/bin/gfortran
      fc: /usr/bin/gfortran
    flags: {}
    operating_system: rhel8
    target: x86_64
    modules: []
    environment: {}
    extra_rpaths: []
- compiler:
    spec: rocmcc@=5.4.1
    paths:
      cc: /opt/rocm-5.4.1/bin/amdclang
      cxx: /opt/rocm-5.4.1/bin/amdclang++
      f77: /opt/rocm-5.4.1/bin/amdflang
      fc: /opt/rocm-5.4.1/bin/amdflang
    flags: {}
    operating_system: rhel8
    target: x86_64
    modules: []
    environment: {}
    extra_rpaths: []
- compiler:
    spec: clang@15.0.0
    paths:
      cc: /opt/rocm-5.4.1/llvm/bin/clang
      cxx: /opt/rocm-5.4.1/llvm/bin/clang++
      f77:
      fc:
    flags: {}
    operating_system: rhel7
    target: x86_64
    modules: []
    environment: {}
    extra_rpaths: []



    This is the packages.yaml file;
    packages:
    libffi:
      externals:
      - spec: libffi@3.2.1
        prefix: /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen/gcc-8.5.0/libffi-3.4.4-ram3ozjs2ekvt2doq26l76y3rnv2ofcc
#   hip:
#     externals:
#     - spec: hip
#       prefix: /opt/rocm-5.4.1/hip
#       extra_attributes:
#         compilers:
#           c: /opt/rocm-5.4.1/llvm/bin/clang++
#           c++: /opt/rocm-5.4.1/llvm/bin/clang++
#           hip: /opt/rocm-5.4.1/hip/bin/hipcc
#     buildable: false
#   hsa-rocr-dev:
#     externals:
#     - spec: hsa-rocr-dev
#       prefix: /opt/rocm-5.4.1
#       extra_attributes:
#         compilers:
#           c: /opt/rocm-5.4.1/llvm/bin/clang++
#           cxx: /opt/rocm-5.4.1/llvm/bin/clang++
#     buildable: false
#   llvm-amdgpu:
#     externals:
#     - spec: llvm-amdgpu
#       prefix: /opt/rocm-5.4.1/llvm
#       extra_attributes:
#         compilers:
#           c: /opt/rocm-5.4.1/llvm/bin/clang++
#           cxx: /opt/rocm-5.4.1/llvm/bin/clang++
#     buildable: false



[br-kolgu@p3-login spack]$ spack install babelstream@main%rocmcc@5.4.1 build_system=cmake +rocm amdgpu_target=gfx701
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/nghttp2-1.52.0-2rhtmclug4qlyrvupjyvwigzp5qhnouo
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/zlib-1.2.13-ud33dmjtp4xtgw42q6v2aov3qeivrnwb
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/ncurses-6.4-bmv77mhkutszynn2uq2jqk5tpk4yu2pw
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/gmake-4.4.1-jtfkelf3t7nr5wnr4thgms6sw6bzjvr3
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/libmd-1.0.4-x4iablujwuk36of5qrq5iqgl3ytbvnzv
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/glproto-1.4.17-bc3itoedykkwppm4xlhcdj7ade2ztkrh
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/libunwind-1.6.2-ijcdgm4mq3nigev5swmkmozdn3ehbgld
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/inputproto-2.3.2-oxotspxnqrh33m7b7x3emcmq2xhfrenx
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/kbproto-1.0.7-r6klgt47epxqjfsasmdp7peavl5pboiw
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/libpthread-stubs-0.4-o2gfvf6pffgkmqtd36qimrpvtdw5wl4m
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/xproto-7.0.31-qzux7sptvww34jk6wkpm6zxsuiepa2c7
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/bzip2-1.0.8-erok4mece23ucexdo2nl7ro5iwthymxt
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/libiconv-1.17-xffamkvpjylez325htxtkrwjmn4i2vjz
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/xz-5.4.1-etmzmtvstfzxbnb5drhqdbhbma3kj7z4
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/zstd-1.5.5-jnbivbo6oh57rtur7gon66wiisu3vxkt
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen/gcc-8.5.0/libffi-3.4.4-ram3ozjs2ekvt2doq26l76y3rnv2ofcc (external libffi-3.2.1-tsctglrs6m2tqdzrqwn7agqlfpifvloc)
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/libxcrypt-4.4.35-wsc5pbmqg2kdgd3pwkq3bejajhhaf22v
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/util-linux-uuid-2.38.1-dag7oel46kf6hgsb55uxzdwohksfgklt
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/xextproto-7.3.0-bmxsu6xuh2wctv2j4225flvimm6c26fp
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/xtrans-1.4.0-tnrlkrg7f35kimo4c2fcqzrlvcyvtixs
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/renderproto-0.11.1-n7bh4tmcuo3uq3n5ralt3hrvxubryzqu
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/randrproto-1.5.0-xve53r6uerawfxyo6hzbveezu6elc6uu
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/pkgconf-1.9.5-pc2yzrmma44m7qiqyhx7zmbxj5b5onfe
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/numactl-2.0.14-mdahbk7w4rcdc5254wj7xtkgq5upy647
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/berkeley-db-18.1.40-ksbs7icjipaxfgbxsu7f5p3jb7k5zuxb
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/roctracer-dev-api-5.5.1-rmjg2ds43dwturz7k4elojild55huqmp
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/pigz-2.7-dzvdpmx3nkpj2iccfwjmgqfnli5leic7
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/openssl-3.1.2-rqg6ujr4yw2kruglq23uqcq7na7jvolb
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/readline-8.2-ctf3avy6witxexghk2etlamwkqq2fg4v
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/rocm-core-5.5.1-nyza2s5uhc7ztjsebfnyhecxtobopini
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/z3-4.11.2-hqdvlt6zk6ue6frggkgeto65qjuh26pe
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/libbsd-0.11.7-yvejvinz6fzxxf2knwwmqpwamc7eqgmy
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/libxau-1.0.8-ol77k6yytigkjplyh6dvulq6ks3rrdow
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/libxml2-2.10.3-tury2drlmzqhcyzb64ehwt4rbih5otjm
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/libpciaccess-0.17-hmph4axqwqwf6bslivpm3qv6v2ul7iwt
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/libice-1.0.9-46mcjz3kntxkry34lo7yb2wjsbb26vtv
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/tar-1.34-rtd7duf4fntkymydnqsef7t43eavmaf4
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/curl-8.1.2-3fvcmzaoy5zhusmql7k7oohbbsggyc76
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/sqlite-3.42.0-nfei3lc4kfx4km6nujvepgqhul2a5773
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/gdbm-1.23-5auc2hhcsmzxggk4qsiughziqygr4mns
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/llvm-amdgpu-5.5.1-u7dauswxqczjzqfniidb722gucgpcvob
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/libxdmcp-1.1.4-4n6gj35lky6i7ysgs73kcozocitvjkyf
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/expat-2.5.0-3u4t2ri5k2f63d2lpxe3zqsf3t77tpv7
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/libdrm-2.4.115-pgr7ycsa2fdqhguxxpzzgnybkp65i5u4
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/libsm-1.2.3-qfoj7xlfrcm66b5qozgpkedquzlvtjx2
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/gettext-0.21.1-lggpdluijaamf5nw7qiphygrlzcqxj4x
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/cmake-3.26.3-iwpsetwrdejockipjojxwcxsni35jilm
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/perl-5.38.0-y7tzemlfjbh25hbcxbnus6ysiw5xp33j
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/python-3.10.12-cuy3j6dre4bphe2bbd46mrgu5bwbaz4k
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/elfutils-0.189-xmeq6bgsfacfgd7otxwaolwf5zaolasb
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/hipify-clang-5.5.1-saqspcw3o2cdlggz4lv3s77ewpqhmpyv
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/comgr-5.5.1-dqb565tt2lpyc6og2gmy2wl5hudvkzjg
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/hsakmt-roct-5.5.1-bz2vwfxdf376jjdqlypj2i3ye2yxlbse
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/perl-uri-encode-1.1.1-xfitmkohcwfktnn2hnuweznclcb5of53
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/perl-file-which-1.27-i4nh7ysqfm5qbw4dflbyfpf5agip6knw
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/xcb-proto-1.15.2-nyfapuwr3zxsgrrkuuqre6bt3d3fx23u
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/hsa-rocr-dev-5.5.1-kdd2rdonggbktomorfarwyhu7eipe6ez
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/libxcb-1.14-suqib665lusnc2snzjabdwys5dshbidw
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/rocminfo-5.5.1-2var6eoestt7vmxtg3qin7k5bmz5uwe7
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/libx11-1.8.4-z6i6ozfkqwotvwsas5jw62ybronao7xj
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/libxrender-0.9.10-lomwzzododtjgxyyjg7w43cdvoswtqgh
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/libxext-1.3.3-pcc5dauyruw2yvic6excw4e6xjlabh6v
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/libxt-1.1.5-rgsw24ko74ai4prqfsevhkmtsurqok5n
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/libxrandr-1.5.3-ukfnd3haonttokusbeh537mhb76o346f
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/xrandr-1.5.0-msbmvmwpqyrcrfxlffykyfdkapwuwzah
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/mesa-23.0.3-ihwg26j7htwtbqld4wvlecyl6nd46d72
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/glx-1.4-52azkade4lmphk3kmgkmlrdh2zpyocwd
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/hip-5.5.1-ayrpw73c365quq42iqzjljiamtpqnnzp
==> Installing babelstream-main-4u5vdmcquajqld53u6zjftgnmvgtgufl [69/69]
==> No binary for babelstream-main-4u5vdmcquajqld53u6zjftgnmvgtgufl found: installing from source
==> No patches needed for babelstream
==> babelstream: Executing phase: 'cmake'
==> babelstream: Executing phase: 'build'
==> babelstream: Executing phase: 'install'
==> babelstream: Successfully installed babelstream-main-4u5vdmcquajqld53u6zjftgnmvgtgufl
  Stage: 2.08s.  Cmake: 2.01s.  Build: 2.33s.  Install: 0.07s.  Post-install: 0.67s.  Total: 11.85s
[+] /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/babelstream-main-4u5vdmcquajqld53u6zjftgnmvgtgufl


[br-kolgu@p3-gpu03-compute ~]$ /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/babelstream-main-pv632qddzngmgqvephipc5zwis5uerei/bin/hip-stream -s $((2**27))
BabelStream
Version: 5.0
Implementation: HIP
Running kernels 100 times
Precision: double
Array size: 1073.7 MB (=1.1 GB)
Total size: 3221.2 MB (=3.2 GB)
Error: invalid device ordinal
[br-kolgu@p3-gpu03-compute ~]$ /lustre/home/br-kolgu/spack/opt/spack/linux-rhel8-zen3/rocmcc-5.4.1/babelstream-main-pv632qddzngmgqvephipc5zwis5uerei/bin/hip-stream --device
Invalid device index.

# Issues
- Kokkos is not building now  ( Error Message in the TOP)
- RAJA not building now  (Error Message in the TOP)
- OpenMP Cuda offload not working!
- OpenCL has issues with POCL 

=========Should I make an environment variable which would call the commands in the README for these ?
- SCALA 
- RUST 
- Julia
- Java
Only viable one seems to be futhark but that also requires exporting an external path


* Fortran to be tested today and tomorrow since on friday the isambard login nodes were down

// // My project // //
now compile times are 9 hrs
not getting the performance we want still II = 30 
Tried lots of hack arounds last week but no luck
Will meet Tobias from Paderborn today after this meeting to see if he has new ideas
Is it ok to get in touch with Joe Garvey to ask him what we are missing ? 



Intel asked me to do a workshop for oneapi and Simon said next year march could be good time for HPC students too
-------------------------------
Template for each model
## ModelName
- Notes
```
Build:
==========

Run:
==========

Results:
==========

```

=================================================
FORTRAN TESTS
=================================================
Initial Setup Stage
```
[br-kolgu@ilake-002 ~]$ export OMP_NUM_THREADS=40
[br-kolgu@ilake-002 ~]$ export OMP_PROC_BIND=close
[br-kolgu@ilake-002 ~]$ export OMP_PLACES=threads
[br-kolgu@ilake-002 ~]$ export ACC_NUM_CORES=${OMP_NUM_THREADS}
[br-kolgu@ilake-002 ~]$ export ARRAY_SIZE=1024*1024*128
```

Makefile Changes :
```
else ifeq ($(COMPILER),cce)
    include make.inc.cce
else ifeq ($(COMPILER),fj)
    include make.inc.fj
else
    $(info Set COMPILER={nvhpc,oneapi,amd,arm,cce,fj,gcc}. Default is gcc.)
   ```

* DoConcurrent 
** gcc
Install:
```
$ spack install babelstream@main%gcc@13.1.0 build_system=makefile impl=DoConcurrent
```
Run:
```
$ /lustre/home/br-kolgu/spack/opt/spack/cray-rhel8-cascadelake/gcc-13.1.0/babelstream-main-4l7swoutgk4eo7wpcqtu5ts5yofpascg/bin/BabelStream.gcc.DoConcurrent -s $((ARRAY_SIZE))
``


** Cray compiler complains about environment

** Oneapi
$ spack install babelstream@fortran_tests%oneapi build_system=makefile impl=DoConcurrent

bin/BabelStream.oneapi.DoConcurrent -s $((2**27))
BabelStream Fortran
Version:  4.0
Implementation: DoConcurrent
Running kernels 100 times                       
Precision: REAL64
Array size:    1073.7MB 
Total size:    3221.2MB 
      Validation failed on Sum. Error   0.100000000000E+01
Sum was   0.000000000000E+00 but should be   0.100000000000E+01
Function    MBytes/sec  Min (sec)   Max         Average     
Copy        247036.539  0.00869     0.01750     0.01277     
Mul         167041.268  0.01286     0.01925     0.01632     
Add         204951.289  0.01572     0.02346     0.02008     
Triad       207300.328  0.01554     0.02393     0.02020     
Dot         51177268.4930.00004     0.00235     0.00074

// ThunderX2 : my previous steps did not work I emailed thomas green to ask about it 
// He suggested some changes previously but they didn't work now
spack install python@3.10.8%gcc@9.3.0 arch=cray-cnl7-thunderx2
==> Error: concretization failed for the following reasons:

   1. python compiler '%gcc@9.3.0' incompatible with 'os=cnl7'
   2. No valid value for variant 'libxml2' of package 'python'
   3. Cannot find valid provider for virtual pkgconfig


