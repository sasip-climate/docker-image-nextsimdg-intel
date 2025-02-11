# Build stage with Spack pre-installed and ready to be used
FROM spack/ubuntu-jammy:0.21 as builder


# What we want to install and how we want to install it
# is specified in a manifest file (spack.yaml)
RUN mkdir /opt/spack-environment \
&&  (echo spack: \
&&   echo '  packages:' \
&&   echo '    all:' \
&&   echo '      compiler: [intel-oneapi-compilers@2023.2.1]' \
&&   echo '  specs:' \
&&   echo '  - boost@1.80.0+log+program_options' \
&&   echo '  - cmake@3.27.7' \
&&   echo '  - eigen@3.4.0' \
&&   echo '  - intel-oneapi-compilers@2023.2.1' \
&&   echo '  - hdf5@1.14.3' \
&&   echo '  - netcdf-c@4.9.2+mpi+parallel-netcdf' \
&&   echo '  - netcdf-cxx4@4.3.1' \
&&   echo '  - netcdf-fortran' \
&&   echo '  - openmpi@4.1.6' \
&&   echo '  - zlib-ng@2.1.4' \
&&   echo '  concretizer:' \
&&   echo '    unify: true' \
&&   echo '  config:' \
&&   echo '    install_missing_compilers: false' \
&&   echo '    install_tree: /opt/software' \
&&   echo '  view: /opt/views/view') > /opt/spack-environment/spack.yaml

# Install the software, remove unnecessary deps
RUN cd /opt/spack-environment && spack env activate . && spack install --fail-fast && spack gc -y

# install perl URI lib
RUN apt update && apt install -y libany-uri-escape-perl

# download and install xios
#COPY install-xios.sh .
RUN spack env activate /opt/spack-environment 
#&& bash install-xios.sh

# Strip all the binaries
RUN find -L /opt/views/view/* -type f -exec readlink -f '{}' \; | \
    xargs file -i | \
    grep 'charset=binary' | \
    grep 'x-executable\|x-archive\|x-sharedlib' | \
    awk -F: '{print $1}' | xargs strip

# Modifications to the environment that are necessary to run
RUN cd /opt/spack-environment && \
    spack env activate --sh -d . > activate.sh

# Bare OS image to run the installed executables
FROM ubuntu:22.04

COPY --from=builder /opt/spack-environment /opt/spack-environment
COPY --from=builder /opt/software /opt/software
#COPY --from=builder /xios /xios
COPY --from=builder /usr /usr

# paths.view is a symlink, so copy the parent to avoid dereferencing and duplicating it
COPY --from=builder /opt/views /opt/views

RUN { \
      echo '#!/bin/sh' \
      && echo '.' /opt/spack-environment/activate.sh \
      && echo 'exec "$@"'; \
    } > /entrypoint.sh \
&& chmod a+x /entrypoint.sh \
&& ln -s /opt/views/view /opt/view \
&& apt update && apt install -y ca-certificates python3-dev python3-netcdf4


ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/bin/bash" ]
