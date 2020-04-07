#!/usr/local/miniconda/bin/python
import sys
import logging
import shutil
from zipfile import ZipFile
from unittest import mock
import argparse
from pathlib import PosixPath
from fw_heudiconv.cli import export
import flywheel
from qsiprep.cli import run as qsiprep_run
from glob import glob

# logging stuff
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger('qsiprep-gear')
logger.info("=======: antssstbids :=======")


# Gather variables that will be shared across functions
with flywheel.GearContext() as context:
    # Setup basic logging
    context.init_logging()
    # Log the configuration for this job
    # context.log_config()
    config = context.config
    builtin_recon = config.get('recon_builtin')
    recon_spec = builtin_recon if builtin_recon else \
        context.get_input_path('recon_spec')
    ignore = config.get('ignore', '').split()
    output_space = config.get('output_space', '').split()
    analysis_id = context.destination['id']
    gear_output_dir = PosixPath(context.output_dir)
    antssstbids_script = gear_output_dir / "antssstbids_run.sh"
    output_root = gear_output_dir / analysis_id
    working_dir = PosixPath(str(output_root.resolve()) + "_work")
    bids_dir = output_root
    bids_root = bids_dir / 'bids_dataset'
    # Get relevant container objects
    fw = flywheel.Client(context.get_input('api_key')['key'])
    analysis_container = fw.get(analysis_id)
    project_container = fw.get(analysis_container.parents['project'])
    session_container = fw.get(analysis_container.parent['id'])
    subject_container = fw.get(session_container.parents['subject'])

    project_label = project_container.label
    extra_t1 = context.get_input('t1_anatomy')
    extra_t1_path = None if extra_t1 is None else \
        PosixPath(context.get_input_path('t1_anatomy'))
    extra_t2 = context.get_input('t2_anatomy')
    extra_t2_path = None if extra_t2 is None else \
        PosixPath(context.get_input_path('t2_anatomy'))
    use_all_sessions = config.get('use_all_sessions', False)

    # output zips
    #html_zipfile = gear_output_dir / (analysis_id + "_antssstbids_html.zip")
    derivatives_zipfile = gear_output_dir / (analysis_id + "_antssstbids_derivatives.zip")
    #debug_derivatives_zipfile = gear_output_dir / (
    #    analysis_id + "_debug_antssstbids_derivatives.zip") # Probably won't exist
    working_dir_zipfile = gear_output_dir / (analysis_id + "_antssstbids_workdir.zip")
    errorlog_zipfile = gear_output_dir / (analysis_id + "_antssstbids_errorlog.zip")


def write_antssstbids_command():
    """Create a command script."""
    with flywheel.GearContext() as context:
        cmd = [
            '/usr/local/miniconda/bin/antssstbids',
            str(bids_root),
            str(output_root),
            'participant',
            '--stop_on_first_crash', '-v', '-v',
            # anat_only=False,
            '--b0-motion-corr-to', config.get('b0_motion_corr_to', 'iterative'),
            '--b0_threshold', str(int(config.get('b0_threshold', 100))),
            '--b0_to_t1w_transform', 'Rigid',
            '--dwi-denoise-window', str(config.get('dwi_denoise_window', 5)),
            '--fs-license-file', context.get_input_path('freesurfer_license'),
            '--hmc-model', config.get('hmc_model', 'eddy'),
            '--hmc-transform', config.get('hmc_transform', 'Affine'),
            '-w', str(working_dir),
            '--output-resolution', str(config.get('output_resolution')),
            '--output-space', config.get('output_space'),
            '--run-uuid', analysis_id,
            '--template', config.get('template', 'MNI152NLin2009cAsym')]
        # if acquisition_type is not None:
        #     cmd += ['--acquisition_type', acquisition_type]
        # If on HPC, get the cores/memory limits
        if config.get('sge-cpu'):
            # Parse SGE cpu syntax, such as "4-8" or just "4"
            cpuMin = int(config.get('sge-cpu').split('-')[0])
            cmd += ['--n_cpus', str(max(1, cpuMin - 1))]
        if config.get('combine_all_dwis', False):
            cmd.append('--combine_all_dwis')
        if config.get('denoise_before_combining', False):
            cmd.append('--denoise-before-combining')
        if config.get('do_reconall', False):
            cmd.append('--do-reconall')
        if context.get_input_path('eddy_config'):
            cmd += ['--eddy-config', context.get_input_path('eddy_config')]
        if config.get('fmap_bspline', False):
            cmd.append('--fmap-bspline')
        if config.get('fmap_no_demean', False):
            cmd.append('--fmap-no-demean')
        if config.get('force_spatial_normalization', False):
            cmd.append('--force-spatial-normalization')
        if config.get('force_syn', False):
            cmd.append('--force-syn')
        if config.get("ignore"):
            cmd += ['--ignore', config.get("ignore")]
        if config.get('impute_slice_threshold'):
            cmd += ['--impute-slice-threshold', str(config.get('impute_slice_threshold'))]
        if config.get('intramodal_template_iters'):
            cmd += ['--intramodal-template-iters',
                    str(config.get('intramodal_template_iters'))]
        if config.get('intramodal_template_transform'):
            cmd += ['--intramodal-template-transform',
                    config.get('intramodal_template_transform')]
        if config.get('longitudinal', False):
            cmd.append('--longitudinal')
        if config.get('notrack'):
            cmd.append('--notrack')
        if config.get('prefer_dedicated_fmaps'):
            cmd.append('--prefer-dedicated-fmaps')
        if recon_spec:
            cmd += ['--recon-spec', recon_spec]
        if config.get('shoreline_iters'):
            cmd += ['--shoreline-iters',
                    str(config.get('shoreline_iters'))]
        if config.get('skip_bids_validation'):
            cmd.append('--skip-bids-validation')
        if config.get('skull_strip_fixed_seed'):
            cmd.append('--skull-strip-fixed-seed')
        if config.get('skull_strip_template'):
            cmd += ['--skull_strip_template', config.get('skull_strip_template')]
        if config.get('sloppy', False):
            cmd.append('--sloppy')
        if config.get('use_syn_sdc', False):
            cmd.append('--use-syn-sdc')
        if config.get('write_local_bvecs'):
            cmd.append('--write-local-bvecs')
        if config.get('unringing_method'):
            cmd += ['--unringing-method', config.get('unringing_method')]
        if config.get('no_b0_harmonization'):
            cmd += ['--no-b0-harmonization']
        if config.get('dwi_no_biascorr'):
            cmd += ['dwi_no_biascorr']
    logger.info(' '.join(cmd))
    with qsiprep_script.open('w') as f:
        f.write(' '.join(cmd))

    return qsiprep_script.exists()


def fw_heudiconv_download():
    """Use fw-heudiconv to download BIDS data.

    Returns True if success or False if there are no dwi files."""
    subjects = [subject_container.label]
    if not use_all_sessions:
        # find session object origin
        sessions = [session_container.label]
    else:
        sessions = None

    # Do the download!
    bids_root.parent.mkdir(parents=True, exist_ok=True)
    downloads = export.gather_bids(fw, project_label, subjects, sessions)
    export.download_bids(fw, downloads, str(bids_dir.resolve()), dry_run=False)

    dwi_files = [fname for fname in bids_root.glob("**/*") if "dwi/" in str(fname)]
    if not len(dwi_files):
        logger.warning("No DWI files found in %s", bids_root)
        return False
    return True



def main():

    download_ok = fw_heudiconv_download()
    sys.stdout.flush()
    sys.stderr.flush()
    if not download_ok:
        logger.warning("Critical error while trying to download BIDS data.")
        return 1

    command_ok = write_antssstbids_command()
    sys.stdout.flush()
    sys.stderr.flush()
    if not command_ok:
        logger.warning("Critical error while trying to write antssstbids command.")
        return 1

    return 0



if __name__ == '__main__':
    sys.exit(main())
