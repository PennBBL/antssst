# This script launches the ANTS container with the correct binding points
# The home directory will serve as the output directory

docker run --rm -ti --entrypoint=/bin/bash \
  -v /Users/butellyn/Documents/ExtraLong/data/freesurferCrossSectional/fmriprep/sub-100088:/data \
  -v /Users/butellyn/Documents/ExtraLong/data/singleSubjectTemplates:/home \
  antsx/ants


# ANTsSST
docker run --rm -ti \
  -v /Users/butellyn/Documents/ExtraLong/data/freesurferCrossSectional/fmriprep/sub-100088:/data/input \
  -v /Users/butellyn/Documents/ExtraLong/data/singleSubjectTemplates:/data/output \
  pennbbl/antssst:0.0.1
