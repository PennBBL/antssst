### Pad image, construct template, and organize outputs
###
### Ellyn Butler
### April 16, 2020

bidsInDir=#argument to container... "~/Documents/antssstbids/bids_directory"
subj=#argument to container... sub-100088
t1wimages=`find ${bidsInDir}/${subj}/ses*/anat -name "*T1w.nii*"`
sessions=`find ${bidsInDir}/${subj} -maxdepth 1 -type d -name "ses-*"`
sessions=`basename ${sessions}`

######## Make output directory ########

currentDir=`dirname ${bidsInDir}`
bidsOutDir=${currentDir}/bids_out_directory/
mkdir ${bidsOutDir}
for ses in ${sessions}; do mkdir -p ${bidsOutDir}/${ses}/anat; done


######## Run Template Construction ########

for image in ${t1wimages}; do echo "${image}" >> ${bidsOutDir}/tmp_subjlist.csv ; done

antsMultivariateTemplateConstruction.sh \
    -d 3 -o "${bidsOutDir}/${subj}/${subj}_SST" \
    -c 2 -j 2 ${bidsOutDir}/tmp_subjlist.csv


######## Rename files as appropriate ########



######## Remove unnecessary files ########
