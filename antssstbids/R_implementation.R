### This script takes in longitudinal T1w images organized according
### to the BIDS specification and uses ANTsR to output a single subject
### N4 bias-field corrected images, a single subject template (SST), and warps
### to the SST from each individual image
###
### Ellyn Butler
### April 9, 2020

library('ANTsR')


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


##### Load the images into R #####






















#
