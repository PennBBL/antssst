############################
# Get ANTs from DockerHub
# Pick a specific version, once they starting versioning
FROM pennbbl/ants:0.0.1
MAINTAINER Ellyn Butler <ellyn.butler@pennmedicine.upenn.edu>
ENV ANTs_VERSION 0.0.1

############################

RUN mkdir /data/input
RUN mkdir /data/output
RUN mkdir /scripts
COPY run.sh /scripts/run.sh
RUN chmod +x /scripts/*

# Set the entrypoint
ENTRYPOINT /scripts/run.sh
