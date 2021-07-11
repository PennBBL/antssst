#!/bin/bash

# Run docker container interactively
docker run -it --rm --entrypoint=/bin/bash \
  -v /Users/kzoner/BBL/projects/ANTS/test_data/fmriprep/sub-93811/:/data/input/fmriprep \
  -v /Users/kzoner/BBL/projects/ANTS/test_data/singleSubjectTemplates/sub-93811:/data/output \
  -v /Users/kzoner/BBL/projects/ANTS/test_data/mindboggleVsBrainCOLOR_Atlases:/data/input/atlases \
#  -v /Users/kzoner/BBL/projects/ANTS/test_data/OASIS-TRT-20_volumes:/data/input/atlases \
  pennbbl/antssst -i
