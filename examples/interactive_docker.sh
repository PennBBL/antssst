#!/bin/bash

# Run docker container interactively
docker run -it --rm --entrypoint=/bin/bash \
  -v /Users/kzoner/BBL/projects/ANTS/data/fmriprep/sub-93811/:/data/input/fmriprep \
  -v /Users/kzoner/BBL/projects/ANTS/data/singleSubjectTemplates/antssst-0.1.0/sub-93811:/data/output \
  -v /Users/kzoner/BBL/projects/ANTS/data/mindboggleVsBrainCOLOR_Atlases:/data/input/atlases \
  katjz/antssst:0.1.0 -i
#  -v /Users/kzoner/BBL/projects/ANTS/test_data/OASIS-TRT-20_volumes:/data/input/atlases \

# Run docker container
docker run -it --rm \
  -v /Users/kzoner/BBL/projects/ANTS/data/fmriprep/sub-93811/:/data/input/fmriprep \
  -v /Users/kzoner/BBL/projects/ANTS/data/singleSubjectTemplates/testing/sub-93811:/data/output \
  -v /Users/kzoner/BBL/projects/ANTS/data/mindboggleVsBrainCOLOR_Atlases:/data/input/atlases \
  katjz/antssst:0.1.0 ses-PNC1 ses-PNC2 --seed 1
#  -v /Users/kzoner/BBL/projects/ANTS/test_data/OASIS-TRT-20_volumes:/data/input/atlases \