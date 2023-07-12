FROM freesurfer/synthstrip as builder

############################
# Get ANTs from DockerHub
# Pick a specific version, once they starting versioning
#FROM pennbbl/ants:0.1.1 
FROM antsx/ants:v2.4.3
ENV ANTs_VERSION=2.4.3

############################

RUN mkdir /data/input
RUN mkdir /data/output
RUN mkdir /data/input/atlases
RUN mkdir /scripts
COPY antsMultivariateTemplateConstruction.sh /scripts/antsMultivariateTemplateConstruction.sh

# shell settings
WORKDIR /freesurfer

# install utils
RUN apt-get update
RUN apt-get install -y libgomp1 gcc python3 python3-dev python3-pip
RUN apt-get clean

# python packages
RUN python3 -m pip install -U pip
RUN python3 -m pip install scipy torch==1.10.2
RUN python3 -m pip install surfa
RUN python3 -m pip install cache purge

# configure model
ENV FREESURFER_HOME /freesurfer
COPY --from=builder /freesurfer/models /freesurfer/models
COPY mri_synthstrip /freesurfer


# clean up
RUN rm -rf /external /root/.cache/pip

COPY run.sh /scripts/run.sh
COPY OASIS_PAC /data/input/OASIS_PAC

RUN chmod +x /scripts/*
RUN chmod +x /freesurfer/*

# Set the entrypoint using exec format
ENTRYPOINT ["/scripts/run.sh"]
