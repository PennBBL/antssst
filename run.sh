#!/bin/bash

InDir=/data/input
OutDir=/data/output

###############################################################################
########  1. Get session list, find relevant files, make output dir.   ########
###############################################################################

# List of session is passed in through container creation call.
sessions="$@"

# Get subject label.
ses=`echo ${sessions} | cut -d ' ' -f 1`
subj=`find ${InDir}/${ases}/ -name "*${ses}.html" | cut -d '/' -f 5 | cut -d '_' -f 1`

# Get T1w image per session from input dir.
t1wimages=""
for ses in $sessions; do
  t1wimage=`find ${InDir}/${ses}/anat -name "${subj}_${ses}_desc-preproc_T1w.nii.gz"`;
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
  #mask=${InDir}/${ses}/anat/${subj}_${ses}_desc-brain_mask.nii.gz;
  #ImageMath 3 ${OutDir}/${ses}/${imagename} m ${image} ${mask};

  # Pad
  ImageMath 3 ${OutDir}/${ses}/${imagename} PadImage ${image} 25;

  # Scale
  ImageMath 3 ${OutDir}/${ses}/${imagename} Normalize ${OutDir}/${ses}/${imagename} 1;

done

t1wpsm=""
for ses in $sessions; do
  t1wimage=`find ${OutDir}/${ses} -name "${subj}_${ses}_desc-preproc_T1w_padscale.nii.gz"`;
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


###############################################################################
#######################  4. Rename files and cleanup.  ########################
###############################################################################

# Move session-level output into individual session output dirs.
for ses in ${sessions} ; do
  mv ${OutDir}/*_${ses}_* ${OutDir}/${ses};
done

# Rename SST and transform files to include subject label.
mv ${OutDir}/template0.nii.gz ${OutDir}/${subj}_template0.nii.gz
mv ${OutDir}/templatewarplog.txt ${OutDir}/${subj}_templatewarplog.txt
mv ${OutDir}/template0Affine.txt ${OutDir}/${subj}_template0Affine.txt
mv ${OutDir}/template0warp.nii.gz ${OutDir}/${subj}_template0warp.nii.gz

# Remove tmp files.
rm ${OutDir}/tmp_subjlist.csv
