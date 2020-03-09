# Use Ubuntu 16.04 LTS
FROM nvidia/cuda:9.1-runtime-ubuntu16.04

# Prepare environment
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
                    curl \
                    bzip2 \
                    ca-certificates \
                    build-essential \
                    autoconf \
                    libtool \
                    pkg-config \
                    wget \
                    libboost-all-dev \
                    unzip \
                    libgl1-mesa-dev \
                    libglu1-mesa-dev \
                    freeglut3-dev \
                    mesa-utils \
                    g++ \
                    jq \
                    tar \
                    zip \
                    gcc \
                    make \
                    python \
                    zlib1g-dev \
                    imagemagick \
                    software-properties-common \
                    git && \
    curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get install -y --no-install-recommends \
      nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# Installing freesurfer
RUN curl -sSL https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/6.0.1/freesurfer-Linux-centos6_x86_64-stable-pub-v6.0.1.tar.gz | tar zxv --no-same-owner -C /opt \
    --exclude='freesurfer/trctrain' \
    --exclude='freesurfer/subjects/fsaverage_sym' \
    --exclude='freesurfer/subjects/fsaverage3' \
    --exclude='freesurfer/subjects/fsaverage4' \
    --exclude='freesurfer/subjects/cvs_avg35' \
    --exclude='freesurfer/subjects/cvs_avg35_inMNI152' \
    --exclude='freesurfer/subjects/bert' \
    --exclude='freesurfer/subjects/V1_average' \
    --exclude='freesurfer/average/mult-comp-cor' \
    --exclude='freesurfer/lib/cuda' \
    --exclude='freesurfer/lib/qt'

  ENV FSLDIR="/opt/fsl-6.0.3" \
      PATH="/opt/fsl-6.0.3/bin:$PATH"
  RUN echo "Downloading FSL ..." \
      && mkdir -p /opt/fsl-6.0.3 \
      && curl -fsSL --retry 5 https://fsl.fmrib.ox.ac.uk/fsldownloads/fsl-6.0.3-centos6_64.tar.gz \
      | tar -xz -C /opt/fsl-6.0.3 --strip-components 1 \
      --exclude='fsl/doc' \
      --exclude='fsl/data/atlases' \
      --exclude='fsl/data/possum' \
      --exclude='fsl/src' \
      --exclude='fsl/extras/src' \
      --exclude='fsl/bin/fslview*' \
      --exclude='fsl/bin/FSLeyes' \
      && echo "Installing FSL conda environment ..." \
      && sed -i -e "/fsleyes/d" -e "/wxpython/d" \
         ${FSLDIR}/etc/fslconf/fslpython_environment.yml \
      && bash /opt/fsl-6.0.3/etc/fslconf/fslpython_install.sh -f /opt/fsl-6.0.3 \
      && find ${FSLDIR}/fslpython/envs/fslpython/lib/python3.7/site-packages/ -type d -name "tests"  -print0 | xargs -0 rm -r \
      && ${FSLDIR}/fslpython/bin/conda clean --all

ENV FREESURFER_HOME=/opt/freesurfer \
    SUBJECTS_DIR=/opt/freesurfer/subjects \
    FUNCTIONALS_DIR=/opt/freesurfer/sessions \
    MNI_DIR=/opt/freesurfer/mni \
    LOCAL_DIR=/opt/freesurfer/local \
    FSFAST_HOME=/opt/freesurfer/fsfast \
    MINC_BIN_DIR=/opt/freesurfer/mni/bin \
    MINC_LIB_DIR=/opt/freesurfer/mni/lib \
    MNI_DATAPATH=/opt/freesurfer/mni/data \
    FMRI_ANALYSIS_DIR=/opt/freesurfer/fsfast
ENV PERL5LIB=$MINC_LIB_DIR/perl5/5.8.5 \
    MNI_PERL5LIB=$MINC_LIB_DIR/perl5/5.8.5 \
    PATH=$FREESURFER_HOME/bin:$FSFAST_HOME/bin:$FREESURFER_HOME/tktools:$MINC_BIN_DIR:$PATH

# Installing ANTs latest from source
ARG ANTS_SHA=e00e8164d7a92f048e5d06e388a15c1ee8e889c4
ADD https://cmake.org/files/v3.11/cmake-3.11.4-Linux-x86_64.sh /cmake-3.11.4-Linux-x86_64.sh
ENV ANTSPATH="/opt/ants-latest/bin" \
    PATH="/opt/ants-latest/bin:$PATH" \
    LD_LIBRARY_PATH="/opt/ants-latest/lib:$LD_LIBRARY_PATH"
RUN mkdir /opt/cmake \
  && sh /cmake-3.11.4-Linux-x86_64.sh --prefix=/opt/cmake --skip-license \
  && ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake \
  && apt-get update -qq \
    && mkdir /tmp/ants \
    && cd /tmp \
    && git clone https://github.com/ANTsX/ANTs.git \
    && mv ANTs /tmp/ants/source \
    && cd /tmp/ants/source \
    && git checkout ${ANTS_SHA} \
    && mkdir -p /tmp/ants/build \
    && cd /tmp/ants/build \
    && mkdir -p /opt/ants-latest \
    && git config --global url."https://".insteadOf git:// \
    && cmake -DBUILD_TESTING=OFF -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=/opt/ants-latest /tmp/ants/source \
    && make -j2 \
    && cd ANTS-build \
    && make install \
    && rm -rf /tmp/ants \
    && rm -rf /opt/cmake /usr/local/bin/cmake

ENV C3DPATH="/opt/convert3d-nightly" \
    PATH="/opt/convert3d-nightly/bin:$PATH"
RUN echo "Downloading Convert3D ..." \
    && mkdir -p /opt/convert3d-nightly \
    && curl -fsSL --retry 5 https://sourceforge.net/projects/c3d/files/c3d/Nightly/c3d-nightly-Linux-x86_64.tar.gz/download \
    | tar -xz -C /opt/convert3d-nightly --strip-components 1

# Create a shared $HOME directory
RUN useradd -m -s /bin/bash -G users antslong
WORKDIR /home/antslong
ENV HOME="/home/antslong"

# Installing SVGO
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get install -y nodejs
RUN npm install -g svgo

# Installing bids-validator
RUN npm install -g bids-validator@1.2.3

# Installing and setting up miniconda
RUN curl -sSLO https://repo.continuum.io/miniconda/Miniconda3-4.5.12-Linux-x86_64.sh && \
    bash Miniconda3-4.5.12-Linux-x86_64.sh -b -p /usr/local/miniconda && \
    rm Miniconda3-4.5.12-Linux-x86_64.sh

ENV PATH=/usr/local/miniconda/bin:$PATH \
    CPATH="/usr/local/miniconda/include/:$CPATH" \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONNOUSERSITE=1

# Installing precomputed python packages
RUN conda install -y python=3.7.1 && \
    chmod -R a+rX /usr/local/miniconda; sync && \
    chmod +x /usr/local/miniconda/bin/*; sync && \
    conda build purge-all; sync && \
    conda clean -tipsy && sync

WORKDIR /root/


RUN find $HOME -type d -exec chmod go=u {} + && \
    find $HOME -type f -exec chmod go=u {} +

RUN ln -s /opt/fsl-6.0.3/bin/eddy_cuda9.1 /opt/fsl-6.0.3/bin/eddy_cuda

ENV FSLOUTPUTTYPE=NIFTI_GZ

RUN ldconfig
WORKDIR /tmp/

# Make singularity mount directories
RUN  mkdir -p /sngl/data \
  && mkdir /sngl/out \
  && mkdir /sngl/scratch \
  && chmod a+rwx /sngl/*


  ############################
  # Install the Flywheel SDK
  RUN pip install flywheel-sdk
  RUN pip install heudiconv
  RUN pip install --upgrade fw-heudiconv ipython


  ############################
  # Make directory for flywheel spec (v0)
  ENV FLYWHEEL /flywheel/v0
  RUN mkdir -p ${FLYWHEEL}
  COPY run ${FLYWHEEL}/run
  COPY prepare_run.py ${FLYWHEEL}/prepare_run.py
  COPY move_to_project.py ${FLYWHEEL}/move_to_project.py
  COPY manifest.json ${FLYWHEEL}/manifest.json
  RUN chmod a+rx ${FLYWHEEL}/*

  # Set the entrypoint
  ENTRYPOINT ["/flywheel/v0/run"]

  ############################
  # ENV preservation for Flywheel Engine
  RUN env -u HOSTNAME -u PWD | \
    awk -F = '{ print "export " $1 "=\"" $2 "\"" }' > ${FLYWHEEL}/docker-env.sh

  WORKDIR /flywheel/v0
