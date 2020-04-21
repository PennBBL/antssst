docker run --rm -ti \
  --entrypoint=/bin/bash \
  -v ~/Documents/flywheel/antssstbids_fw_debug/input:/flywheel/v0/input \
  -v ~/Documents/flywheel/antssstbids_fw_debug/output:/flywheel/v0/output \
  -v ~/Documents/flywheel/antssstbids_fw_debug/config.json:/flywheel/v0/config.json \
  pennbbl/antssstbids:latest

# TO DO:
# 1) Need to create input and output directories in Dockerfile


  #docker run --rm -ti \
  #  --entrypoint=/bin/bash \
  #  -v ~/projects/upenn/flywheel/qsiprep_fw_debug/qsiprep-fw-0.1.9_0.3.3_5cc208951da4270028a43115/input:/flywheel/v0/input \
  #  -v ~/projects/upenn/flywheel/qsiprep_fw_debug/qsiprep-fw-0.1.9_0.3.3_5cc208951da4270028a43115/output:/flywheel/v0/output \
  #  -v ~/projects/upenn/flywheel/qsiprep_fw_debug/qsiprep-fw-0.1.9_0.3.3_5cc208951da4270028a43115/config.json:/flywheel/v0/config.json \
  #  pennbbl/antssstbids:latest
