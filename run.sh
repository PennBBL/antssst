#!/bin/bash

InDir=/data/input
OutDir=/data/output 

###############################################################################
#######################      0. Parse Cmd Line Args      ######################
###############################################################################
VERSION=0.0.9

usage () {
    cat <<- HELP_MESSAGE
      usage:  $0 [--help] [--version] 
                 [--all-labels] [--seed <RANDOM SEED>] 
                SES [SES2 ...]
      
      positional arguments:
      SES |               Session label

      optional arguments:
      -h  | --help        Print this message and exit.
      -v  | --version     Print version and exit.
      -s  | --seed        Random seed for ANTs registration. 
      -l  | --all-labels  Use non-cortical/whitematter labels. Default: False.

HELP_MESSAGE
}

# Display usage message if no args are given
if [[ $# -eq 0 ]] ; then
  usage
  exit 1
fi

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
########  1. Get session list, find relevant files, make output dir.   ########
###############################################################################

# List of session is passed in through container creation call.
sessions="$@"

# Get subject label.
ses=`echo ${sessions} | cut -d ' ' -f 1`
sub=`find ${InDir}/${ases}/ -name "*${ses}.html" | cut -d '/' -f 5 | cut -d '_' -f 1`

# Get T1w image per session from input dir.
t1wimages=""
for ses in $sessions; do
  t1wimage=`find ${InDir}/${ses}/anat -name "${sub}_${ses}_desc-preproc_T1w.nii.gz"`;
  t1wimages="${t1wimages} ${t1wimage}";
done

# Make output directory per session.
for ses in ${sessions}; do
  mkdir ${OutDir}/${ses};
done

###############################################################################
#####################  2. Pad and scale each T1w image.   #####################
###############################################################################

######## Pad and scale the T1w images ########
for image in ${t1wimages}; do

  ses=`echo $image | cut -d "/" -f 4`;
  imagename=`echo $image | cut -d "/" -f 6`;
  imagename=$(echo "$imagename" | sed "s/T1w/T1w_padscale/");
  
  # Mask
  #mask=${InDir}/${ses}/anat/${sub}_${ses}_desc-brain_mask.nii.gz;
  #ImageMath 3 ${OutDir}/${ses}/${imagename} m ${image} ${mask};

  # Pad
  ImageMath 3 ${OutDir}/${ses}/${imagename} PadImage ${image} 25;

  # Scale
  ImageMath 3 ${OutDir}/${ses}/${imagename} Normalize ${OutDir}/${ses}/${imagename} 1;

done

t1wpsm=""
for ses in $sessions; do
  t1wimage=`find ${OutDir}/${ses} -name "${sub}_${ses}_desc-preproc_T1w_padscale.nii.gz"`;
  t1wpsm="${t1wpsm} ${t1wimage}";
done

###############################################################################
###############  3. Single Subject Template (SST) Construction  ###############
###############################################################################

# Generate csv of t1w images to pass to template construction script.
for image in ${t1wpsm}; do echo "${image}" >> ${OutDir}/tmp_subjlist.csv ; done

# Run single subject template construction.
# Images used are bias-field corrected, but not skull-stripped.
/scripts/antsMultivariateTemplateConstruction.sh -d 3 -o "${OutDir}/" -n 0 \
  -m 40x60x30 -i 5 -c 0 -z ${image} ${OutDir}/tmp_subjlist.csv

## NEW! TODO: Test out running JLF on SST's! Then convert to session space.
# i.e. instead of JLF on GT then transforming back to session space.
###############################################################################
####################  4. Run joint label fusion on SSTs.        ###############
####################     Transform labels to Native T1w space.  ###############
###############################################################################

SST=${OutDir}/${sub}_template0.nii.gz
BrainExtractionTemplate=${InDir}/OASIS_PAC/T_template0.nii.gz
BrainExtractionProbMask=${InDir}/OASIS_PAC/T_template0_BrainCerebellumProbabilityMask.nii.gz

# Skull-strip the SST
antsBrainExtraction.sh -d 3 -a ${SST} \
  -e ${BrainExtractionTemplate} \
  -m ${BrainExtractionProbMask} \
  -o ${OutDir}/${sub}_

# Construct atlas arguments for call to antsJointLabelFusion.sh
atlas_args=""

# Loop through each atlas dir in OASIS dir
find ${InDir}/OASIS-TRT-20_volumes/OASIS-TRT* -type d | while read atlas_dir; do
  # Get T1w brain
  brain="${atlas_dir}/t1weighted_brain.nii.gz"
  
  # Get corresponding labels if using all labels (cort, wm, non-cort).
  if [[ ${useAllLabels} ]]; then
    labels=${atlas_dir}/labels.DKT31.manual+aseg.nii.gz;
  
  # Get corresponding labels if using only cortical labels. (Default)
  else
    labels=${atlas_dir}/labels.DKT31.manual.nii.gz;
  fi

  # Append current atlas and label to argument string
  atlas_args=${atlas_args}"-g ${brain} -l ${labels} ";
done

# Run JLF to map DKT labels onto the single-subject templates
antsJointLabelFusion.sh -d 3 -t ${SST} \
  -o ${OutDir}/${sub}_malf -c 2 -j 4 -k 1 -q 1 \
  -x ${OutDir}/${sub}_BrainExtractionMask.nii.gz \
  -p ${OutDir}/malfPosteriors%04d.nii.gz ${atlas_args}

# 5/16/2021: 
# Warp DKT labels from the SST space to Native T1w space
RefImg=${OutDir}/${ses}/${sub}_${ses}_desc-preproc_T1w_padscale.nii.gz
SSTLabels=${OutDir}/${sub}_malfLabels.nii.gz
SST_to_Native_warp=`find ${OutDir}/${ses} -name "*padscale*InverseWarp.nii.gz"`
Native_to_SST_affine=`find ${OutDir}/${ses} -name "*Affine.txt"`

# Transform labels from group template to t1w space
# QUESTION: How do you pick -n interpolation type?
# Multilabel for labeled image to maintain integer labels!!
antsApplyTransforms \
  -d 3 -e 0 -n Multilabel \
  -i ${SSTLabels} \
  -o [${OutDir}/${ses}/${sub}_${ses}_DKT.nii.gz, 0] \
  -r ${RefImg} \
  -t [${Native_to_SST_affine}, 1] \
  -t ${SST_to_Native_warp} 

# To finish DKT labeling, in antslongct use cortical thickness mask to generate
# DKTIntersection image.

###############################################################################
#######################  5. Rename files and cleanup.  ########################
###############################################################################

# Move session-level output into individual session output dirs.
for ses in ${sessions} ; do
  mv ${OutDir}/*_${ses}_* ${OutDir}/${ses};
done

# Move jobscripts into jobs sub dir
mkdir ${OutDir}/jobs
mv ${OutDir}/job*.sh ${OutDir}/jobs

# Rename SST and transform files to include subject label.
mv ${OutDir}/template0.nii.gz ${OutDir}/${sub}_template0.nii.gz
mv ${OutDir}/templatewarplog.txt ${OutDir}/${sub}_templatewarplog.txt
mv ${OutDir}/template0Affine.txt ${OutDir}/${sub}_template0Affine.txt
mv ${OutDir}/template0warp.nii.gz ${OutDir}/${sub}_template0warp.nii.gz

# Make subdir for joint label fusion output
mkdir ${OutDir}/malf
mv ${OutDir}/malfPost* ${OutDir}/malf
mv ${OutDir}/*malf*.txt ${OutDir}/malf

# Remove tmp files.
rm ${OutDir}/tmp_subjlist.csv
