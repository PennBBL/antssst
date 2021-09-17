#!/bin/bash

# Run docker container interactively
singularity shell --cleanenv --writable-tmpfs --containall \
  -B /project/ExtraLong/data/freesurferCrossSectional/fmriprep/sub-93811/:/data/input/fmriprep \
  -B ~/ants_pipelines/data/ANTsLongitudinal/subjects/sub-93811:/data/output \
  -B ~/ants_pipelines/data/mindboggleVsBrainCOLOR_Atlases:/data/input/atlases \
  ~/ants_pipelines/images/antssst_0.1.0.sif

# Run docker container (non-interactively)
singularity run --cleanenv --writable-tmpfs --containall \
  -B /project/ExtraLong/data/freesurferCrossSectional/fmriprep/sub-93811:/data/input/fmriprep \
  -B ~/ants_pipelines/data/test:/data/output \
  -B ~/ants_pipelines/data/mindboggleVsBrainCOLOR_Atlases:/data/input/atlases \
  ~/ants_pipelines/images/antssst_0.1.0.sif ses-PNC1 ses-PNC2 --seed 1 -m 1
