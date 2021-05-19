# ANTsSST

ANTsSST uses [antsMultivariateTemplateConstruction.sh](https://github.com/ANTsX/ANTs/blob/master/Scripts/antsMultivariateTemplateConstruction.sh)
to create single subject
templates (SSTs) for longitudinal data organized according to the BIDS specification.
ANTsSST requires that fMRIPrep has been run on the T1w images (Note: Only tested on v20.0.5).

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
`docker pull pennbbl/antssst:0.0.7`.

Typically, Docker is used on local machines and not clusters because it requires
root access. If you want to run the container on a cluster, follow the Singularity
instructions.

### Running ANTsSST
Here is an example from one of Ellyn's runs:
```
docker run --rm -ti --entrypoint="/bin/sh" \
  -v /Users/butellyn/Documents/ExtraLong/data/freesurferCrossSectional/fmriprep/sub-10410:/data/input \
  -v /Users/butellyn/Documents/ExtraLong/data/singleSubjectTemplates/antssst5/sub-10410:/data/output \
  pennbbl/antssst:0.0.7 /scripts/run.sh ses-FNDM11 ses-FNDM21
```

- Line 1: Specify the entry point.
- Line 2: Bind fMRIPrep output directory (`/Users/butellyn/Documents/ExtraLong/data/freesurferCrossSectional/fmriprep/sub-10410`)
to the input directory in the container (`/data/input`).
- Line 3: Bind the directory where you want your ANTsSST output to end up
(`/Users/butellyn/Documents/ExtraLong/data/singleSubjectTemplates/antssst5/sub-10410`)
to the output directory in the container (`/data/output`).
- Line 4: Specify the Docker image and version. Run `docker images` to see if you
have the correct version pulled.

Substitute your own values for the files/directories to bind.

## Singularity
### Setting up
You must [install Singularity](https://singularity.lbl.gov/docs-installation) to
use the ANTsSST Singularity image.

After Singularity is installed, pull the ANTsSST image by running the following command:
`singularity pull docker://pennbbl/antssst:0.0.7`.

Note that Singularity does not work on Macs, and will almost surely have to be
installed by a system administrator on your institution's computing cluster.

### Running ANTsSST
Here is an example from one of Ellyn's runs:
```
singularity exec --writable-tmpfs --cleanenv \
  -B /project/ExtraLong/data/freesurferCrossSectional/fmriprep/sub-10410:/data/input \
  -B /project/ExtraLong/data/singleSubjectTemplates/antssst5/sub-10410:/data/output \
  /project/ExtraLong/images/antssst_0.0.7.sif /scripts/run.sh ses-FNDM11 ses-FNDM21
```

- Line 1: Specify that you want to execute a script in the image, and that you
do not want environment variables to leak into the container.
- Line 2: Bind fMRIPrep output directory (`/project/ExtraLong/data/freesurferCrossSectional/fmriprep/sub-10410`)
to the input directory in the container (`/data/input`).
- Line 3: Bind the directory where you want your ANTsSST output to end up
(`/project/ExtraLong/data/singleSubjectTemplates/antssst5/sub-10410`)
to the output directory in the container (`/data/output`).
- Line 4: Specify the Singularity image file.

Substitute your own values for the files/directories to bind.

## Example Scripts
See [this script](https://github.com/PennBBL/ExtraLong/blob/master/scripts/process/ANTsLong/submitANTsSST_v0.0.7.py)
for an example of building individual launch scripts for each subject with fMRIPrep output.
Note that `/project/ExtraLong/data/qualityAssessment/antssstExclude.csv` has a column
for the subject ID (`bblid`), a column for the session ID (`seslabel`), and a
column for whether or not to exclude that particular subject/session combination
from the construction of the single subject template (`antssstExclude`).

## Notes
1. For details on how ANTsSST was utilized for the ExtraLong project (all
longitudinal T1w data in the BBL), see [this wiki](https://github.com/PennBBL/ExtraLong/wiki).

## Future Directions
1. Since the ENTRYPOINT variable is defined
as `/scripts/run.sh` in the Dockerfile, there is almost surely a way to avoid
`--entrypoint="/bin/sh"` in the Docker call and `exec` in the Singularity call,
but the parsing of the sessions may need to change.
2. Set home directory in Dockerfile.
3. Perform a second round of N4 on the t1-weighted images (first round currently
  being performed by fMRIPrep, but does not appear to fully work).
4. Fix ANTs seed.
