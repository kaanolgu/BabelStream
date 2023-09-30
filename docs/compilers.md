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

# TODO : 
- Download Manually the PGI compiler and test it



# Issues
- Couldn't test HIP since I couldn't get ROCM working on Isambard ?
- Kokkos is not building now  







```
Build:
==========

Run:
==========

Results:
==========

```