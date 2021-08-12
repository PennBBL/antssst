#!/bin/bash

InDir=/data/input
OutDir=/data/output 

# Make tmp dir
tmpdir="${OutDir}/tmp"
mkdir -p ${tmpdir}

###############################################################################
#######################      0. Parse Cmd Line Args      ######################
###############################################################################
VERSION=0.1.0

usage () {
    cat <<- HELP_MESSAGE
      usage:  $0 [--help] [--version] 
                [--jlf] [--all-labels] 
                [--seed <RANDOM SEED>] 
                SES [SES2 ...]
      
      positional arguments:
      SES |               Session label

      optional arguments:
      -h  | --help        Print this message and exit.
      -j  | --jlf         Run JFL on the SST. (Default: False)
      -l  | --all-labels  Use non-cortical/whitematter labels for JLF. (Default: False.)
      -s  | --seed        Random seed for ANTs registration. 
      -v  | --version     Print version and exit.

HELP_MESSAGE
}

# Parse cmd line options
PARAMS=""
while (( "$#" )); do
  case "$1" in
    -h | --help)
        usage
        exit 0
      ;;
    -v | --version)
        echo $VERSION
        exit 0
      ;;
    -s | --seed)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        seed=$2
        shift 2
      else
        echo "$0: Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    -j | --jlf)
      runJLF=1
      shift
      ;;
    -l | --all-labels)
      useAllLabels=1
      shift
      ;;
    -*|--*=) # unsupported flags
      echo "$0: Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # parse positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done

# Set positional arguments (session list) in their proper place
eval set -- "$PARAMS"

# Check that at least two sessions were provided.
if [[ $# -lt 2 ]]; then
  echo "Error: Please provide at least two session labels for single subject template creation."
  exit 1
fi 

# Default: set random seed to 1.
if [[ -z "$seed" ]]; then
  seed=1
fi

# Set env vars for ANTs
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1
export ANTS_RANDOM_SEED=$seed 

###############################################################################
########  1. Preprocessing. N4 bias correction, padding, and scaling.  ########
###############################################################################

# List of session is passed in through container creation call.
sessions="$@"

# Get subject label.
ses=`echo ${sessions} | cut -d ' ' -f 1`
sub=`find ${InDir}/fmriprep/ -name "*${ses}.html" -exec basename {} \; | cut -d _ -f 1`

# For each session, preprocess the T1w image and brain mask.
for ses in ${sessions}; do

  # Make output directory per session.
  mkdir -p ${OutDir}/${ses};

  # Copy T1w image to session output dir.
  t1w="${OutDir}/${ses}/${sub}_${ses}_T1w.nii.gz"
  find ${InDir}/fmriprep/${ses}/anat -name "${sub}_${ses}_desc-preproc_T1w.nii.gz" \
    -exec cp {} "${t1w}" \;
  
  # Copy T1w brain mask to session output dir.
  mask="${OutDir}/${ses}/${sub}_${ses}_brain-mask.nii.gz"
  find ${InDir}/fmriprep/${ses}/anat -name "${sub}_${ses}_desc-brain_mask.nii.gz" \
    -exec cp {} "${mask}" \;

  # Dialate and smooth brain mask from fMRIPrep to use as weight image in N4
  n4weight=`echo ${mask} | sed "s/mask/mask-DS/"`
  ImageMath 3 ${n4weight} MD ${mask} 5     # Dialate x5
  SmoothImage 3 ${n4weight} 3 ${n4weight}   # Smooth x3

  # Threshold T1w image to get mask of non-zero intensities for N4.
  n4mask="${tmpdir}/${sub}_${ses}_N4Mask.nii.gz"
  ThresholdImage 3 ${t1w} ${n4mask} 0.01 Inf

  # N4 Bias correction with weighted with mask. 
  # TODO: parameter tuning??
  # t1w_n4=`echo ${t1w} | sed "s/T1w/T1w-N4/"` 
  N4BiasFieldCorrection -d 3 \
    -b [ 200 ] \
    -c [ 100x100x100x100 ] \
    --input-image ${t1w} \
    --mask-image ${n4mask} \
    --weight-image ${n4weight} \
    --output ${t1w} 
  
  # Pad and scale the N4-corrected T1w image.
  ImageMath 3 ${t1w} PadImage ${t1w} 25;    # Pad x 25 voxels
  ImageMath 3 ${t1w} Normalize ${t1w} 1;    # Normalize to [0, 1]

done

###############################################################################
###############  2. Single Subject Template (SST) Construction  ###############
###############################################################################

# Generate csv of t1w images to pass to template construction script.
find $OutDir/ -name "*T1w.nii.gz" >> ${tmpdir}/t1w_list.csv

# Construct the single subject template.
  # -d 3 --> 3 dimensions
  # -n 0 --> don't do N4 bias field correction
  # -m   --> max-iterations in each registration
  # -i 5 --> iteration limit
  # -c 0 --> use localhost
  # -z   --> initial template/target volume/starting point
/scripts/antsMultivariateTemplateConstruction.sh -d 3 \
  -o "${OutDir}/" \
  -n 0 \
  -m 40x60x30 \
  -i 5 \
  -c 0 \
  -z ${t1w} \
  ${tmpdir}/t1w_list.csv
# TODO: test without -z reference? or with MNI ref temp?

# Clean-up: 
# Move session-level output into individual session output dirs.
for ses in ${sessions} ; do
  
  # Rename native-to-sst inverse warp and move to session dir
  mv ${OutDir}/*${ses}*InverseWarp.nii.gz "${OutDir}/${ses}/${sub}_${ses}_toSST_InverseWarp.nii.gz"
  
  # Rename native-to-sst inverse warp and move to session dir
  mv ${OutDir}/*${ses}*Warp.nii.gz "${OutDir}/${ses}/${sub}_${ses}_toSST_Warp.nii.gz"
  
  # Rename native-to-sst inverse warp and move to session dir
  mv ${OutDir}/*${ses}*Affine.txt "${OutDir}/${ses}/${sub}_${ses}_toSST_Affine.txt"
  
  # Rename T1w images warped to SST and move to session dir
  mv ${OutDir}/*${ses}*WarpedToTemplate.nii.gz "${OutDir}/${ses}/${sub}_${ses}_WarpedToSST.nii.gz"

done

# Rename SST and transform files to include subject label.
mv ${OutDir}/template0.nii.gz ${OutDir}/${sub}_template0.nii.gz
mv ${OutDir}/templatewarplog.txt ${OutDir}/${sub}_templatewarplog.txt
mv ${OutDir}/template0Affine.txt ${OutDir}/${sub}_template0Affine.txt
mv ${OutDir}/template0warp.nii.gz ${OutDir}/${sub}_template0warp.nii.gz

# Remove tmp files.
rm -rf ${tmpdir}

###############################################################################
#############   3. (Optional) Run joint label fusion on SSTs.       ###########
#############      Transform labels to Native T1w space.            ###########
###############################################################################

SST=${OutDir}/${sub}_template0.nii.gz
BrainExtractionTemplate=${InDir}/OASIS_PAC/T_template0.nii.gz
BrainExtractionProbMask=${InDir}/OASIS_PAC/T_template0_BrainCerebellumProbabilityMask.nii.gz

# Skull-strip the SST to get brain mask.
antsBrainExtraction.sh -d 3 -a ${SST} \
  -e ${BrainExtractionTemplate} \
  -m ${BrainExtractionProbMask} \
  -o ${OutDir}/${sub}_

# Move jobscripts into jobs sub dir
  mkdir -p ${OutDir}/jobs
  mv ${OutDir}/job_* ${OutDir}/jobs

# Optionally, run JLF on the SST.
if [[ ${runJLF} ]]; then

  # Construct atlas arguments for call to antsJointLabelFusion.sh
  # by looping through each atlas dir in OASIS dir to get brain and labels.
  atlas_args=""

  # If using mindboggleVsBrainCOLOR atlases...
  if [[ -d "${InDir}/atlases/mindboggleHeads" ]]; then

    # Loop thru mindboggle brains to build arglist of atlas brains + labels
    while read brain; do
      labels=`basename ${brain} | sed "s/.nii.gz/_DKT31.nii.gz/"`
      labels=${InDir}/atlases/mindboggleLabels/${labels}

      # Append current atlas and label to argument string
      atlas_args=${atlas_args}"-g ${brain} -l ${labels} "
    done <<< $(find ${InDir}/atlases/mindboggleHeads -name "OASIS-TRT*")

  # Else if using OASIS-TRT-20_volumes...
  else

    # Loop thru OASIS atlas dirs to build arglist of atlas brains + labels
    while read atlas_dir; do

      # Get T1w brain
      brain="${atlas_dir}/t1weighted_brain.nii.gz"
      
      if [[ ${useAllLabels} ]]; then
        # Get corresponding labels if using all labels (cort, wm, non-cort).
        labels=${atlas_dir}/labels.DKT31.manual+aseg.nii.gz;
      else
        # Get corresponding labels if using only cortical labels (default).
        labels=${atlas_dir}/labels.DKT31.manual.nii.gz;
      fi

      # Append current atlas and label to argument string
      atlas_args=${atlas_args}"-g ${brain} -l ${labels} ";
    done <<< $(find ${InDir}/atlases/OASIS-TRT* -type d)

  fi

  # Make output directory for malf
  mkdir ${OutDir}/malf

  # Run JLF to map DKT labels onto the single-subject templates.
  antsJointLabelFusion.sh \
    -d 3 -c 2 -j 8 -k 1 \
    -t ${SST} \
    -o ${OutDir}/malf/${sub}_malf \
    -x ${OutDir}/malf/${sub}_BrainExtractionMask.nii.gz \
    -p ${OutDir}/malf/malfPosteriors%04d.nii.gz \
    ${atlas_args} 

  # Move DKT-labeled SST to main output dir and rename to match other DKT-labeled images.
  SST_labels=${OutDir}/${sub}_DKT.nii.gz
  mv ${OutDir}/malf/${sub}_malfLabels.nii.gz ${SST_labels}

  # For each session, warp DKT labels from the SST space to Native T1w space.
  for ses in ${sessions}; do

    t1w_labels=${OutDir}/${ses}/${sub}_${ses}_DKT.nii.gz
    SST_to_Native_warp=`find ${OutDir}/${ses} -name "*InverseWarp.nii.gz"`
    Native_to_SST_affine=`find ${OutDir}/${ses} -name "*Affine.txt"`

    # Transform labels from SST to T1w space
    # Multilabel interpolation for labeled image to maintain integer labels!!
    antsApplyTransforms \
      -d 3 -e 0 -n Multilabel \
      -i ${SST_labels} \
      -o [${t1w_labels}, 0] \
      -r ${t1w} \
      -t [${Native_to_SST_affine}, 1] \
      -t ${SST_to_Native_warp} 
  done

fi

# NOTE: Finish DKT labeling in antslongct by using 
# cortical thickness mask to generate DKTIntersection image.

# # JLF cleanup:
# if [[ ${runJLF} ]]; then

#   # Rename DKT-labeled SST to match name of DKT-labeled T1w img.
#   mv ${SST_labels} ${OutDir}/${sub}_DKT.nii.gz

#   # Make subdir for joint label fusion output
#   mkdir -p ${OutDir}/malf
#   mv ${OutDir}/malfPosterior* ${OutDir}/malf
#   mv ${OutDir}/*_malfOASIS-* ${OutDir}/malf
#   mv ${OutDir}/*malf*.txt ${OutDir}/malf

# fi

