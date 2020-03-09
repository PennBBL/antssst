import json
import flywheel
import os
import sys
import logging


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger('fw-heudiconv-gear')

outputs = [f for f in os.listdir("/flywheel/v0/output/") if os.path.isfile(os.path.join("/flywheel/v0/output/", f))]
if outputs:
    # start up inputs
    invocation = json.loads(open('/flywheel/v0/config.json').read())
    config = invocation['config']
    inputs = invocation['inputs']
    destination = invocation['destination']

    fw = flywheel.Flywheel(inputs['api_key']['key'])
    user = fw.get_current_user()

    # start up logic:
    heuristic = None #inputs['heuristic']['location']['path']
    analysis_container = fw.get(destination['id'])
    project_container = fw.get(analysis_container.parents['project'])
    project_label = project_container.label
    dry_run = False #config['dry_run']
    action = "Export" #config['action']
    use_all_sessions = False #config['use_all_sessions']

    if use_all_sessions:

        # logging stuff
        logger.info("=======: fw-heudiconv starting up :=======")
        logger.info("Copying multi-session fMRIprep run to the project level...")

        inputs_list = []
        try:
            for key, val in inputs.items():

                if key != "api_key":
                    fname = val['location']['name']
                    obj = fw.get(val['hierarchy']['id'])
                    input_ref = obj.get_file(fname).ref()
                    inputs_list.append(input_ref)

            myanalysis = project_container.add_analysis(label = analysis_container.label, inputs = inputs_list)
            myanalysis.add_note(
                "Copied from a multi-session fMRIprep analysis gear, ID: {}".format(analysis_container.id)
            )

            myanalysis.upload_output(["/flywheel/v0/output/" + x for x in outputs])
            logger.info("You should find your analysis in Projects -> {} -> Analyses".format(project_label))
        except Exception as e:
            logger.warning("Failed to copy multi-session analysis to the project level!")
            logger.warning(e)
            sys.exit(0)
        logger.info("Done!")
