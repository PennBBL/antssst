import ants 
import antspynet
import argparse
import sys
import os

parser = argparse.ArgumentParser()
parser.add_argument("-i", "--anatomical-image", help="Input anatomical image (T1w)", type=str, required=True)
parser.add_argument("-o", "--brain-output-file", help="Output file", type=str,required = True)
parser.add_argument("-m", "--mask-output-file", help="Output file for mask", type=str)
args = parser.parse_args()

t1_file = args.anatomical_image
t1 = ants.image_read(t1_file)

probability_mask = antspynet.brain_extraction(t1, modality = 't1',antsxnet_cache_directory = "/opt/dataCache/ANTsXNet")
mask = ants.threshold_image(probability_mask, 0.5, 1, 1, 0)
mask = ants.morphology(mask,"close",6).iMath_fill_holes()
brain = mask * t1
ants.image_write(mask,args.mask_output_file)
ants.image_write(brain,args.brain_output_file)
