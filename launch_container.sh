# This script launches the ANTS container with the correct binding points
# The home directory will serve as the output directory

#docker run --rm -ti --entrypoint=/bin/bash \
#  -v /Users/butellyn/Documents/ExtraLong/data/freesurferCrossSectional/fmriprep/sub-100088:/data \
#  -v /Users/butellyn/Documents/ExtraLong/data/singleSubjectTemplates:/home \
#  antsx/ants


# ANTsSST
docker run --rm -ti --entrypoint="/bin/sh" \
  -v /Users/butellyn/Documents/ExtraLong/data/freesurferCrossSectional/fmriprep/sub-100088:/data/input \
  -v /Users/butellyn/Documents/ExtraLong/data/singleSubjectTemplates/antssst5:/data/output \
  pennbbl/antssst /scripts/run.sh ses-CONTE1 ses-NODRA1 ses-ONM1 ses-PNC1 ses-PNC2

# Singularity
singularity exec --writable-tmpfs --cleanenv \
  -B /project/ExtraLong/data/freesurferCrossSectional/fmriprep/sub-10410:/data/input \
  -B /project/ExtraLong/data/singleSubjectTemplates/antssst/sub-10410:/data/output \
  /project/ExtraLong/images/antssst_0.0.2.sif /scripts/run.sh ses-FNDM11 ses-FNDM21
