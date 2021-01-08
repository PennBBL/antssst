#!/bin/bash

InDir=/data/input
OutDir=/data/output

#############################################################
##################### PROCESSING STEPS #####################
#############################################################

######## Find relevant files/paths ########
sessions="$@"
ases=`echo ${sessions} | cut -d ' ' -f 1`
subj=`find ${InDir}/${ases}/ -name "*${ases}.html" | cut -d '/' -f 5 | cut -d '_' -f 1`

t1wimages=""
for ses in $sessions; do
  t1wimage=`find ${InDir}/${ses}/anat -name "${subj}_${ses}_desc-preproc_T1w.nii.gz"`;
  t1wimages="${t1wimages} ${t1wimage}";
done

######## Make output directory ########
for ses in ${sessions}; do
  mkdir ${OutDir}/${ses};
done

######## Mask, pad, scale the T1w images ########
for image in ${t1wimages}; do
  ses=`echo $image | cut -d "/" -f 4`;
  imagename=`echo $image | cut -d "/" -f 6`;
  imagename=$(echo "$imagename" | sed "s/T1w/T1w_padscale/");
  mask=${InDir}/${ses}/anat/${subj}_${ses}_desc-brain_mask.nii.gz;
  # Mask
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

######## Run Template Construction ########
# On bias-field corrected, but not skull-stripped, image
for image in ${t1wpsm}; do echo "${image}" >> ${OutDir}/tmp_subjlist.csv ; done

/scripts/antsMultivariateTemplateConstruction.sh -d 3 -o "${OutDir}/" -n 0 -m 40x60x30 -i 5 -c 0 -z ${image} ${OutDir}/tmp_subjlist.csv

######## Rename files as appropriate ########
for ses in ${sessions} ; do
  mv ${OutDir}/*_${ses}_* ${OutDir}/${ses};
done

mv ${OutDir}/template0.nii.gz ${OutDir}/${subj}_template0.nii.gz
mv ${OutDir}/templatewarplog.txt ${OutDir}/${subj}_templatewarplog.txt
mv ${OutDir}/template0Affine.txt ${OutDir}/${subj}_template0Affine.txt
mv ${OutDir}/template0warp.nii.gz ${OutDir}/${subj}_template0warp.nii.gz


######## Remove unnecessary files ########
rm ${OutDir}/tmp_subjlist.csv
