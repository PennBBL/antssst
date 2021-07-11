#!/bin/bash

# Run docker container interactively
docker run -it --rm --entrypoint=/bin/bash \
  -v /Users/kzoner/BBL/projects/ANTS/test_data/fmriprep/sub-93811/:/data/input/fmriprep \
  -v /Users/kzoner/BBL/projects/ANTS/test_data/singleSubjectTemplates/sub-93811:/data/output \
  -v /Users/kzoner/BBL/projects/ANTS/test_data/mindboggleVsBrainCOLOR_Atlases:/data/input/mindboggleVsBrainCOLOR_Atlases \
#  -v /Users/kzoner/BBL/projects/ANTS/test_data/OASIS-TRT-20_volumes:/data/input/OASIS-TRT-20_volumes \
  pennbbl/antssst -i
