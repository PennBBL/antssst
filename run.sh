#!/bin/bash

# ANTsSST:    Single-Subject Template Creation
# Maintainer: Katja Zoner
# Updated:    09/10/2021

VERSION=0.1.0

###############################################################################
##########################      Usage Function      ###########################
###############################################################################
usage() {
	cat <<-HELP_MESSAGE
		      usage:  $0 [--help] [--version] 
		                [--jlf] [--all-labels] 
		                [--manual-step <STEP NUM>]
		                [--seed <RANDOM SEED>] 
		                SES [SES2 ...]
		      
		      positional arguments:
		      SES |                   Session label

		      optional arguments:
		      -h  | --help            Print this message and exit.
		      -j  | --jlf             Run JLF on the SST. (Default: False)
		      -m  | --manual-step     Manually identify which steps to run. 
		                                1: preproccessing, 
		                                2: SST creation,
		                                3: brain extraction, 
		                                4: joint label fusion
		                              Use multiple times to select multiple steps. (e.g. -m 2 -m 3)
		      -l  | --all-labels      Use non-cortical/whitematter labels for JLF. (Default: False.)
		      -s  | --seed            Random seed for ANTs registration. 
		      -v  | --version         Print version and exit.

	HELP_MESSAGE
}

###############################################################################
###############      Error Handling and Cleanup Functions      ################
###############################################################################

exit() {
	err=$?
	if [ $err -eq 0 ]; then
		cleanup
		echo "$0: Program finished successfully!"
	else
		echo "$0: ${PROGNAME:-}: ${1:-"Exiting with error code $err"}" 1>&2
		cleanup
	fi
}

cleanup() {
	echo -e "\nRunning cleanup ..."
	rm -rf $tmpdir
	echo "Done."
}

control_c() {
	echo -en "\n\n*** User pressed CTRL + C ***\n\n"
}

# Write progress message ($1) to both stdout and stderrs
log_progress() {
	echo -e "\n************************************************************" | tee -a /dev/stderr
	echo -e "***************     $1" | tee -a /dev/stderr
	echo -e "************************************************************\n" | tee -a /dev/stderr
}

###############################################################################
########  1. Preprocessing. N4 bias correction, padding, and scaling.  ########
###############################################################################
run_preprocessing() {

	log_progress "BEGIN: Preprocessing the T1w images."
	PROGNAME="preprocessing"

	# For each session, preprocess the T1w image and brain mask.
	for ses in ${sessions}; do

		# Make output sub-directory per session.
		SesDir=${SubDir}/sessions/${ses}
		mkdir -p ${SesDir}

		# Copy T1w image to session output dir.
		t1w="${SesDir}/${sub}_${ses}_T1w.nii.gz"
		find ${InDir}/fmriprep/${ses}/anat -name "${sub}_${ses}_desc-preproc_T1w.nii.gz" \
			-exec cp {} "${t1w}" \;

		# TODO: try with ANTsBrainExtraction??
		# Copy T1w brain mask to session output dir.
		mask="${SesDir}/${sub}_${ses}_brain-mask.nii.gz"
		find ${InDir}/fmriprep/${ses}/anat -name "${sub}_${ses}_desc-brain_mask.nii.gz" \
			-exec cp {} "${mask}" \;

		# Dialate and smooth brain mask from fMRIPrep to use as weight image in N4
		n4weight="${tmpdir}/${sub}_${ses}_brain-mask-DS.nii.gz"
		ImageMath 3 ${n4weight} MD ${mask} 5 879 # Dialate x5
		SmoothImage 3 ${n4weight} 3 ${n4weight}  # Smooth x3

		# Threshold T1w image to get mask of non-zero intensities for N4.
		n4mask="${tmpdir}/${sub}_${ses}_N4Mask.nii.gz"
		ThresholdImage 3 ${t1w} ${n4mask} 0.01 Inf

		# N4 Bias correction with weighted with mask.
		PROGNAME="N4BiasFieldCorrection"
		# TODO: parameter tuning??
		N4BiasFieldCorrection -d 3 \
			-b [ 200 ] \
			-c [ 100x100x100x100 ] \
			--input-image ${t1w} \
			--mask-image ${n4mask} \
			--weight-image ${n4weight} \
			--output ${t1w}

		# Pad and scale the N4-corrected T1w image.
		ImageMath 3 ${t1w} PadImage ${t1w} 25 # Pad x 25 voxels
		ImageMath 3 ${t1w} Normalize ${t1w} 1 # Normalize to [0, 1]
		
		# Also pad the T1w mask to stay in same space as T1w.
		ImageMath 3 ${mask} PadImage ${mask} 25 # Pad x 25 voxels

	done

	log_progress "END: Finished preprocessing the T1w images."
}

###############################################################################
###############  2. Single Subject Template (SST) Construction  ###############
###############################################################################
run_construct_sst() {

	log_progress "BEGIN: Running single subject template construction."
	PROGNAME="antsMultivariateTemplateConstruction"

	# Generate csv of t1w images to pass to template construction script.
	find $SubDir/ -name "*T1w.nii.gz" >>${tmpdir}/t1w_list.csv

	# TODO: How should we pick a ref template?
	t1w_ref="${SesDir}/${sub}_${ses}_T1w.nii.gz"

	# Construct the single subject template.
	# -d 3 --> 3 dimensions
	# -n 0 --> don't do N4 bias field correction
	# -m   --> max-iterations in each registration
	# -i 5 --> iteration limit
	# -c 0 --> use localhost
	# -z   --> initial template/target volume/starting point
	/scripts/antsMultivariateTemplateConstruction.sh -d 3 \
		-o "${SubDir}/" \
		-n 0 \
		-m 40x60x30 \
		-i 5 \
		-c 0 \
		-z ${t1w_ref} \
		${tmpdir}/t1w_list.csv
	# TODO: test without -z reference? or with MNI ref temp?

	# Clean-up:
	# Move session-level output into individual session output dirs.
	for ses in ${sessions}; do

		# Reset session output dir
		SesDir=${SubDir}/sessions/${ses}

		# Rename native-to-sst inverse warp and move to session dir
		mv ${SubDir}/*${ses}*InverseWarp.nii.gz "${SesDir}/${sub}_${ses}_toSST_InverseWarp.nii.gz"

		# Rename native-to-sst warp and move to session dir
		mv ${SubDir}/*${ses}_T1w*Warp.nii.gz "${SesDir}/${sub}_${ses}_toSST_Warp.nii.gz"

		# Rename native-to-sst affine and move to session dir
		mv ${SubDir}/*${ses}*Affine.txt "${SesDir}/${sub}_${ses}_toSST_Affine.txt"

		# Rename T1w images warped to SST and move to session dir
		mv ${SubDir}/*${ses}*WarpedToTemplate.nii.gz "${SesDir}/${sub}_${ses}_WarpedToSST.nii.gz"

	done

	# Rename SST and transform files to include subject label.
	mv ${SubDir}/template0.nii.gz ${SubDir}/${sub}_template0.nii.gz
	mv ${SubDir}/templatewarplog.txt ${SubDir}/${sub}_templatewarplog.txt
	mv ${SubDir}/template0Affine.txt ${SubDir}/${sub}_template0Affine.txt
	mv ${SubDir}/template0warp.nii.gz ${SubDir}/${sub}_template0warp.nii.gz

	# Move jobscripts into jobs sub dir
	mkdir -p ${SubDir}/jobs
	mv ${SubDir}/job_* ${SubDir}/jobs

	log_progress "END: Finished SST construction."
}

###############################################################################
#################     3. Run brain extraction on the SST.     #################
###############################################################################
run_brain_extraction() {

	log_progress "BEGIN: Running brain extraction on the SST."

	SST=${SubDir}/${sub}_template0.nii.gz
	BrainExtractionTemplate=${InDir}/OASIS_PAC/T_template0.nii.gz
	BrainExtractionProbMask=${InDir}/OASIS_PAC/T_template0_BrainCerebellumProbabilityMask.nii.gz

	# Skull-strip the SST to get brain mask.
	antsBrainExtraction.sh -d 3 -a ${SST} \
		-e ${BrainExtractionTemplate} \
		-m ${BrainExtractionProbMask} \
		-o ${SubDir}/${sub}_

	log_progress "END: Finished brain extraction on the SST."
}

###############################################################################
#############   4. (Optional) Run joint label fusion on SSTs.       ###########
###############################################################################
run_jlf() {
	log_progress "BEGIN: Running joint label fusion."
	PROGNAME="antsJointLabelFusion"

	SST=${SubDir}/${sub}_template0.nii.gz

	# Construct atlas arguments for call to antsJointLabelFusion.sh
	# by looping through each atlas dir in OASIS dir to get brain and labels.
	atlas_args=""

	# If using mindboggleVsBrainCOLOR atlases...
	if [[ -d "${InDir}/atlases/mindboggleHeads" ]]; then

		# Loop thru mindboggle brains to build arglist of atlas brains + labels
		while read brain; do
			labels=$(basename ${brain} | sed "s/.nii.gz/_DKT31.nii.gz/")
			labels=${InDir}/atlases/mindboggleLabels/${labels}

			# Append current atlas and label to argument string
			atlas_args=${atlas_args}"-g ${brain} -l ${labels} "
		done <<<$(find ${InDir}/atlases/mindboggleHeads -name "OASIS-TRT*")

	# Else if using OASIS-TRT-20_volumes...
	else

		# Loop thru OASIS atlas dirs to build arglist of atlas brains + labels
		while read atlas_dir; do

			# Get T1w brain
			brain="${atlas_dir}/t1weighted_brain.nii.gz"

			if [[ ${useAllLabels} ]]; then
				# Get corresponding labels if using all labels (cort, wm, non-cort).
				labels=${atlas_dir}/labels.DKT31.manual+aseg.nii.gz
			else
				# Get corresponding labels if using only cortical labels (default).
				labels=${atlas_dir}/labels.DKT31.manual.nii.gz
			fi

			# Append current atlas and label to argument string
			atlas_args=${atlas_args}"-g ${brain} -l ${labels} "
		done <<<$(find ${InDir}/atlases/OASIS-TRT* -type d)

	fi

	# Make output directory for malf
	mkdir ${SubDir}/malf

	# Run JLF to map DKT labels onto the single-subject templates.
	antsJointLabelFusion.sh \
		-d 3 -c 2 -j 8 -k 1 \
		-t ${SST} \
		-o ${SubDir}/malf/${sub}_malf \
		-x ${SubDir}/malf/${sub}_BrainExtractionMask.nii.gz \
		-p ${SubDir}/malf/malfPosteriors%04d.nii.gz \
		${atlas_args}

	# Move DKT-labeled SST to main output dir and rename to match other DKT-labeled images.
	SST_labels=${SubDir}/${sub}_DKT.nii.gz
	mv ${SubDir}/malf/${sub}_malfLabels.nii.gz ${SST_labels}

	log_progress "END: Finished JLF on the SST."
}

###############################################################################
##########################         MAIN: SETUP        #########################
###############################################################################

# Set default cmd line args
seed=1
runAll=1      # Default to running all if -m option not used.
runPreproc="" # -m 1
runSST=""     # -m 2
runBE=""      # -m 3
runJLF=""     # -m 4 or --jlf
useAllLabels=""

# Parse cmd line options
PARAMS=""
while (("$#")); do
	case "$1" in
	-h | --help)
		usage
		exit 0
		;;
	-j | --jlf)
		runJLF=1
		shift
		;;
	-l | --all-labels)
		useAllLabels=1
		shift
		;;
	-m | --manual-step)
		if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
			step=$2
			if [[ "$step" == "1" ]]; then
				runAll=""
				runPreproc=1
			elif [[ "$step" == "2" ]]; then
				runAll=""
				runSST=1
			elif [[ "$step" == "3" ]]; then
				runAll=""
				runBE=1
			elif [[ "$step" == "4" ]]; then
				runAll=""
				runJLF=1
			else
				echo "Error: $step is not a valid value for the --manual-step flag."
				exit 1
			fi
			shift 2
		else
			echo "$0: Error: Argument for $1 is missing" >&2
			exit 1
		fi
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
	-v | --version)
		echo $VERSION
		exit 0
		;;
	-* | --*=) # unsupported flags
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

# Set env vars for ANTs
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1
export ANTS_RANDOM_SEED=$seed

# Make tmp dir
tmpdir="/data/output/tmp"
mkdir -p ${tmpdir}

# Set up error handling
set -euo pipefail
trap 'exit' EXIT
trap 'control_c' SIGINT

###############################################################################
########################        MAIN: PROCESSING       ########################
###############################################################################
log_progress "ANTsSST v${VERSION}: STARTING UP"

InDir=/data/input
SubDir=/data/output

# List of session is passed in through container creation call.
sessions="$@"

# Get subject label.
ses=$(echo ${sessions} | cut -d ' ' -f 1)
sub=$(find ${InDir}/fmriprep/ -name "*${ses}.html" -exec basename {} \; | cut -d _ -f 1)

# Run preprocessing steps.
if [[ ${runPreproc} ]] || [[ ${runAll} ]]; then
	run_preprocessing
fi

# Run SST creation.
if [[ ${runSST} ]] || [[ ${runAll} ]]; then
	run_construct_sst
fi

# Run brain extraction.
if [[ ${runBE} ]] || [[ ${runAll} ]]; then
	run_brain_extraction
fi

# Optionally, run JLF on the SST.
if [[ ${runJLF} ]]; then
	run_jlf
fi

log_progress "ANTsSST v${VERSION}: FINISHED SUCCESSFULLY"
