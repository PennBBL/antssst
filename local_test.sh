docker run --rm -ti \
  --entrypoint=/bin/bash \
  -v /Users/mcieslak/projects/upenn/flywheel/qsiprep_fw_debug/qsiprep-fw-0.1.9_0.3.3_5cc208951da4270028a43115/input:/flywheel/v0/input \
  -v /Users/mcieslak/projects/upenn/flywheel/qsiprep_fw_debug/qsiprep-fw-0.1.9_0.3.3_5cc208951da4270028a43115/output:/flywheel/v0/output \
  -v /Users/mcieslak/projects/upenn/flywheel/qsiprep_fw_debug/qsiprep-fw-0.1.9_0.3.3_5cc208951da4270028a43115/config.json:/flywheel/v0/config.json \
  pennbbl/qsiprep-fw:0.2.4_0.6.3-1
