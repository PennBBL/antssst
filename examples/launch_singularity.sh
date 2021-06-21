#!/bin/bash

# Run docker container interactively
singularity shell --cleanenv --writable-tmpfs --containall \
  -B ~/ants_pipelines/test_data/fmriprep/sub-93811:/data/input/fmriprep \
  -B ~/ants_pipelines/test_data/singleSubjectTemplates/sub-93811:/data/output \
  -B ~/ants_pipelines/test_data/mindboggleVsBrainCOLOR_Atlases:/data/input/mindboggleVsBrainCOLOR_Atlases \
  ~/ants_pipelines/images/antssst_0.0.8.sif
