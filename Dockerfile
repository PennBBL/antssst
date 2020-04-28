############################
# Get ANTs from DockerHub
# Pick a specific version, once they starting versioning
FROM antsx/ants:latest
MAINTAINER Ellyn Butler <ellyn.butler@pennmedicine.upenn.edu>
ENV ANTs_VERSION latest

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
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create a shared $HOME directory
RUN useradd -m -s /bin/bash -G users antssstbids
WORKDIR /home/antssstbids
ENV HOME="/home/antssstbids"

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
