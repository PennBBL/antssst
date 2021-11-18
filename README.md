# ANTsSST

ANTsSST uses [antsMultivariateTemplateConstruction.sh](https://github.com/ANTsX/ANTs/blob/master/Scripts/antsMultivariateTemplateConstruction.sh) to create single subject templates (SSTs) for longitudinal data organized according to the BIDS specification.
ANTsSST requires that fMRIPrep has been run on the T1w images (Note: Only tested on fMRIPrep v20.0.5).

WARNING: Make sure to only include high quality T1w images! Otherwise, your
SSTs will be poor quality. Utilize [FreeQC](https://github.com/PennBBL/freeqc)
to get quality values from Freesurfer output. See the ExtraLong project
[quality assessment wiki](https://github.com/PennBBL/ExtraLong/wiki/1.-Quality-Assessment)
for an example of how to utilize this output to filter out low-quality sessions.

## Docker
### Setting up
You must [install Docker](https://docs.docker.com/get-docker/) to use the ANTsSST
Docker image.

After Docker is installed, pull the ANTsSST image by running the following command:
`docker pull pennbbl/antssst:0.1.0`.

Typically, Docker is used on local machines and not clusters because it requires
root access. If you want to run the container on a cluster, follow the Singularity instructions.

### Running ANTsSST via Docker Image
Here is an example:
```
docker run -it --rm \
  -v /Users/kzoner/BBL/projects/ANTS/data/fmriprep/sub-93811/:/data/input/fmriprep \
  -v /Users/kzoner/BBL/projects/ANTS/data/ANTsLongitudinal/0.1.0/subjects/sub-93811:/data/output \
  -v /Users/kzoner/BBL/projects/ANTS/data/mindboggleVsBrainCOLOR_Atlases:/data/input/atlases \
  pennbbl/antssst:0.1.0 ses-PNC1 ses-PNC2 --seed 1
```

To the container, you must:
1. Bind the subject's fMRIPrep output directory (`/Users/kzoner/BBL/projects/ANTS/data/fmriprep/sub-93811/`) to the input directory in the container (`/data/input/fmriprep`).

2. Bind the subject's sub-directory within the overarching ANTsLongitudinal output directory (`/Users/kzoner/BBL/projects/ANTS/data/ANTsLongitudinal/subjects/sub-93811`) to the output directory in the container (`/data/output`).

3. Specify the Docker image and version. Run `docker images` to see if you have the correct version pulled.

4. Pass in command line arguments to the container run script. A list of sessions to process is required (`ses-PNC1 ses-PNC2`). Use the `--help` flag to print a usage message to see other available arugments.

## Singularity
### Setting up
You must [install Singularity](https://singularity.lbl.gov/docs-installation) to
use the ANTsSST Singularity image.

After Singularity is installed, pull the ANTsSST image by running the following command:
`singularity pull docker://pennbbl/antssst:0.1.0`.

Note that Singularity does not work on Macs, and will almost surely have to be
installed by a system administrator on your institution's computing cluster.

### Running ANTsSST via Singularity Image
Here is an example:
```
singularity run --cleanenv --writable-tmpfs --containall \
  -B ~/ants_pipelines/data/fmriprep/sub-93811:/data/input/fmriprep \
  -B ~/ants_pipelines/data/ANTsLongitudinal/subjects/sub-93811:/data/output \
  -B ~/ants_pipelines/data/mindboggleVsBrainCOLOR_Atlases:/data/input/atlases \
  ~/ants_pipelines/images/antssst_0.1.0.sif ses-PNC1 ses-PNC2 --seed 1 

```
In your call to Singularity you should:
1. Use `--cleanenv` and `--containall` flags to specify that you do not want environment variables to leak into the container.

2. Bind the subject's fMRIPrep output directory (`~/ants_pipelines/data/fmriprep/sub-93811`) to the input directory in the container (`/data/input/fmriprep`).

3. Bind the subject's sub-directory within the overarching NTsLongitudinal output directory (`~/ants_pipelines/data/ANTsLongitudinal/subjects/sub-93811`) to the output directory in the container (`/data/output`).

4. Specify the Singularity image file.

5. Pass in command line arguments to the container run script. A list of sessions to process is required (`ses-PNC1 ses-PNC2`). Use the `--help` flag to print a usage message to see other available arugments.

<!-- ## Example Scripts
See [this script](https://github.com/PennBBL/ExtraLong/blob/master/scripts/process/ANTsLong/submitANTsSST_v0.0.7.py)
for an example of building individual launch scripts for each subject with fMRIPrep output.
Note that `/project/ExtraLong/data/qualityAssessment/antssstExclude.csv` has a column
for the subject ID (`bblid`), a column for the session ID (`seslabel`), and a
column for whether or not to exclude that particular subject/session combination
from the construction of the single subject template (`antssstExclude`). -->

## Notes
1. For details on how ANTsSST was utilized for the ExtraLong project (all
longitudinal T1w data in the BBL), see [this wiki](https://github.com/PennBBL/ExtraLong/wiki).

