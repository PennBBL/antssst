#!/bin/bash

export LOGS_DIR=/home/kzoner/logs/ExtraLong/ANTsSST-0.1.0
mkdir -p ${LOGS_DIR}

scripts="/project/ExtraLong/scripts/process/datafreeze-2021/ANTsLongitudinal"
jsDir=${scripts}/jobscripts
mkdir -p ${jsDir}

data="/project/ExtraLong/data/datafreeze-2021/"
fmriprep_dir=${data}/fmriprep/
antslong_dir=${data}/ANTsLongitudinal
atlas_dir=${data}/../mindboggleVsBrainCOLOR_Atlases

# gt_subs_csv=~/ants_pipelines/subjects_for_gt.csv
# exclude_csv=/project/ExtraLong/data/qualityAssessment/antssstExclude.csv
exclude_csv="/project/ExtraLong/data/datafreeze-2021/QC/exclusion_datafreeze-2021_cutoff-212.csv"

subList=$(cat ${exclude_csv} | grep False | cut -d , -f 1 | uniq)
echo "ANTsSST will be run on $(echo $subList | wc -w) subjects"

for subject in $subList; do

  sessions=$(cat ${exclude_csv} | grep ${subject} | grep False | cut -d , -f 2 | sed "s/^/ses-/" | tr "\n" " ")
  subject=sub-${subject}
  echo SUBJECT: $subject
  echo SESSIONS: $sessions

  out_dir=${antslong_dir}/subjects/${subject}
  mkdir -p ${out_dir}

  jobscript=${jsDir}/${subject}.sh

  cat <<-JOBSCRIPT >${jobscript}
		#!/bin/bash
	
		singularity run --writable-tmpfs --cleanenv --containall \\
			-B ${fmriprep_dir}/${subject}:/data/input/fmriprep \\
			-B ${out_dir}:/data/output \\
			-B ${atlas_dir}:/data/input/atlases \\
			/project/ExtraLong/images/antssst_0.1.0.sif --seed 1 ${sessions}
	
	JOBSCRIPT

  chmod +x ${jobscript}
  bsub -e $LOGS_DIR/${subject}.e -o $LOGS_DIR/${subject}.o ${jobscript}

done
