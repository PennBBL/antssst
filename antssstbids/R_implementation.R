### This script takes in longitudinal T1w images organized according
### to the BIDS specification and uses ANTsR to output a single subject
### N4 bias-field corrected images, a single subject template (SST), and warps
### to the SST from each individual image
###
### Ellyn Butler
### April 9, 2020 - April 15, 2020

library('ANTsR')
library('parallel')


########## Read command line arguments to this script ##########

args = commandArgs(trailingOnly=TRUE)

if (length(args) != 2) {
  stop("You must specify 1. the BIDS directory and 2. a subject (sub-####)", call.=FALSE)
} else {
  bidsdir = args[1]
  matches = regexpr("/$", bidsdir)
  if (length(regmatches(bidsdir, matches)) == 0) {
    bidsdir = paste0(bidsdir, "/")
  }
  subj = args[2]
}

#################### FOR TESTING ####################

bidsdir="~/Documents/antssstbids/bids_directory/"
subj="sub-100088"

#####################################################

# Create output directory in same directory as BIDS input directory
parentdir=paste(strsplit(bidsdir, "/")[[1]][1:(length(strsplit(bidsdir, "/")[[1]])-1)], collapse="/")
system(paste0("mkdir ", parentdir, "/bids_out_directory/"))

# Identify paths to T1w images and check that at least two are present
raw_t1w_images <- system(paste0("find ", bidsdir, subj, " ", "-name ", "sub-*_ses-*_T1w.nii.gz"), intern=TRUE)
if (length(raw_t1w_images) < 2) { stop("You must have at least two T1w images", call.=FALSE) }


##### Load the images into R, naming images by session label #####

seslabels <- rep(NA, length(raw_t1w_images))
i=1
for (t1w_nifti in raw_t1w_images) {
  seslabel <- strsplit(t1w_nifti, "/")[[1]][length(strsplit(t1w_nifti, "/")[[1]])]
  seslabel <- strsplit(strsplit(seslabel, "_")[[1]][2], "-")[[1]][2]
  seslabels[i] <- seslabel
  assign(seslabel, antsImageRead(raw_t1w_images[1]))
  i=i+1
}

if (anyNA(seslabels)) { stop("One or more of your images failed to load") }


########## ---------- Process data ---------- ##########

#### 1.) N4 bias field correction
N4_newname <- function(seslabel) {
  assign(paste0("N4corrected_", seslabel), abpN4(get(seslabel)))
}

mclapply(seslabels, N4_newname)

#### 2.) Write N4-corrected images to session directories and create
####     temporary csv of paths to these images

for (n4corrected_image in paste0("N4corrected_", seslabels)) {
  antsImageWrite(get(n4corrected_image),
    file=paste0(bidsoutdir, )
}

#### 3.) Multivariate template construction (call to system)
antsMultivariateTemplateConstruction_newname <- function(N4corrected_paths) [
  system(paste0("antsMultivariateTemplateConstruction.sh
    -d 3 -n 0 -o ", bids_out_directory, subj, "/", subj, "_SST_T1w.nii.gz ",
    ))

  # Move single subject templates to subject directories
}

N4corrected_paths <- paste0("N4corrected_", seslabels)

antsMultivariateTemplateConstruction_newname(N4corrected_images)

#### 4.)

















#(Need to figure out nature of output directory on Flywheel)






















#
