### This script takes in longitudinal T1w images organized according
### to the BIDS specification and uses ANTsR to output a single subject
### N4 bias-field corrected images, a single subject template (SST), and warps
### to the SST from each individual image
###
### Ellyn Butler
### April 9, 2020

library('ANTsR')
library('RNifti')


##### Read command line arguments to this script #####

args = commandArgs(trailingOnly=TRUE)

if (length(args) != 2) {
  stop("You must specify 1. the BIDS directory and 2. a subject (sub-####)", call.=FALSE)
} else {
  bidsdir = args[1] # ~/Documents/antssstbids/bids_directory/
  matches = regexpr("/$", bidsdir)
  if (length(regmatches(bidsdir, matches)) == 0) {
    bidsdir = paste0(bidsdir, "/")
  }
  subj = args[2] # sub-100088
}

raw_t1w_images <- system(paste0("find ", bidsdir, subj, " ", "-name ", "sub-*_ses-*_T1w.nii.gz"), intern=TRUE)
if (length(raw_t1w_images < 2) { stop("You must have at least two T1w images", call.=FALSE) }


##### Load the images into R, naming images by session label #####

seslabels <- rep(NA, length(raw_t1w_images))
i=1
for (t1w_nifti in raw_t1w_images) {
  seslabel <- strsplit(t1w_nifti, "/")[[1]][length(strsplit(t1w_nifti, "/")[[1]])]
  seslabel <- strsplit(strsplit(seslabel, "_")[[1]][2], "-")[[1]][2]
  seslabels[i] <- seslabel
  assign(seslabel, readNifti(raw_t1w_images[1]))
  i=i+1
}

if (anyNA(seslabels)) { stop("One or more of your images failed to load") }


##### Process data #####

sst_pipeline <- function(t1w_image) {
  # 1.) N4 bias field correction

  # 2.) Multivariate template construction (call to system)

  # #.) Write out processed images
  #(Need to figure out nature of output directory on Flywheel)
}



apply























#
