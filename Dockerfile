############################
# Get ANTs from DockerHub
# Pick a specific version, once they starting versioning
FROM pennbbl/ants:0.0.1
ENV ANTs_VERSION=0.0.1

############################

RUN mkdir /data/input
RUN mkdir /data/output
RUN mkdir /data/input/fmriprep
RUN mkdir /data/input/atlases
RUN mkdir /scripts

COPY run.sh /scripts/run.sh
COPY antsMultivariateTemplateConstruction.sh /scripts/antsMultivariateTemplateConstruction.sh
COPY OASIS_PAC /data/input/OASIS_PAC

RUN chmod +x /scripts/*

# Set the entrypoint using exec format
ENTRYPOINT ["/scripts/run.sh"]
