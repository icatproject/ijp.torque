#!/usr/bin/env python
# TEST: trying to use IDS getLink as an alternative to downloading datasets.
# This version is non-interactive for now

import sys
from optparse import OptionParser
import os
import shutil
import subprocess
import traceback
# tempfile required - originally imported in lsf_utils
import tempfile

# Use local cat_utils
# from ijp import cat_utils
import cat_utils
from cat_utils import terminate, Session, IjpOptionParser
from ijp_lsf.constants import *
from ijp_lsf import lsf_utils

# May move this function into cat_utils
# Construct 'inner' command line from parsed options, omitting IJP options
def build_inner_options(options):
  cmd = []
  for option in vars(options):
    # skip IJP options
    if option not in ['sessionId','icatUrl','idsUrl','datasetIds','datafileIds']:
      value = getattr(options, option)
      if value == True:
        cmd += ['--' + option]
      elif type(value) is list:
        for elem in value:
          cmd += ['--' + option + '=' + str(elem)]
      elif value:
        cmd += ['--' + option + '=' + str(value)]
  return cmd

# TEST getLink usage; may move following functions to to cat_utils or lsf_utils

def getUpperBranches(session, datasetId, dest):
    if not os.path.exists(dest): os.mkdir(dest)
    fdir = tempfile.mkdtemp()
    linkDataset(session, datasetId, fdir)
    dirName = subprocess.check_output(['find', fdir, '-mindepth', '5', '-maxdepth', '5', '-type', 'd']).strip()
    for adir in os.listdir(dirName):
        shutil.move(os.path.join(dirName,adir), dest)
    shutil.rmtree(fdir)

def linkDataset(session, datasetId, path):
        """
        Retrieve the dataset as datafile links and move them to path
        """
        for datafile in getDatafiles(session, datasetId):
            fLink = session.idsClient.getLink(session.sessionId, datafile.id)
            shutil.move(fLink, os.path.join(path,datafile.name))

def getDatafiles(session, datasetId):
    # TODO limit the results size?
    query = "Datafile [dataset.id = " + str(datasetId) + "]"
    return session.search(query)

exc = None
try:

    usage = "usage: %prog dataset_id options"
    parser = IjpOptionParser(usage)
    
    # Options specific to this script:
    parser.add_option('--option', action="append", type="string")
    parser.add_option('--flats',action="store_true", default=False)

    (options, args) = parser.parse_args()
    
    jobName = os.path.basename(sys.argv[0])
    
    if not options.sessionId:
        terminate(jobName + " must specify an ICAT session ID", 1)
    
    # Report icat/ids URLs if present
    
    if not options.icatUrl:
        terminate(jobName + " must specify an ICAT url", 1)
    
    if not options.idsUrl:
        terminate(jobName + " must specify an IDS url", 1)
    
    sessionId = options.sessionId
    
    if not options.datasetIds:
        terminate(jobName + " must supply a dataset ID", 1)

    # Check that it's only a single ID, not a list
    
    if len(options.datasetIds.split(',')) > 1:
        terminate(jobName + ': expects a single datasetId, not a list: ' + options.datasetIds)
    
    datasetId = int(options.datasetIds)
    
    session = Session("LSF", options.icatUrl, options.idsUrl, sessionId)

    rest = args

    # UNCHANGED YET BELOW HERE
    
    os.mkdir("tmp")

    print "Downloading dataset with id", datasetId
    getUpperBranches(session, datasetId, "tmp")

    with open("msmm_dataset_root_marker.nodelete", "w") as dummy:
        pass
    
    cfg_file = None
    for name in ["run", "dataset"]:
        qfile = os.path.join("tmp", name + ".cfg")
        if os.path.exists(qfile):
            cfg_file = qfile
            break
    if not cfg_file: terminate("No dataset configuration file found", 1)

    cfg = {}
    with open(cfg_file, "r") as runcfg:
        for line in runcfg:
            line = line.partition(" ")
            cfg[line[0].strip()] = line[2].replace("\\", "/").strip()

    try:
        path = cfg["RunDir"].partition("/")[2]
    except Exception:
        terminate(cfg_file + " does not have a RunDir entry with the expected format", 1)

    shutil.move("tmp", path)

    for deptype in ["Bead", "Bias", "Dark", "Flatfield", "Check"]:
        dep = session.search("DatasetParameter.numericValue <-> ParameterType[name = '" + deptype.lower() + "_dataset'] <-> Dataset [id = " + str(datasetId) + "]")
        if len(dep) > 1: terminate("More than one " + deptype + " dataset found for dataset id " + str(datasetId), 1)
        if dep:
            dep = int(dep[0])
            try:
                dep_path = os.path.dirname(cfg[deptype + "Image"].partition("/")[2])
            except Exception:
                terminate("run.cfg does not have a " + deptype + "Image entry with the expected format", 1)
            if not os.path.exists(dep_path): os.makedirs(dep_path)
            print "Downloading", deptype, "dataset with id", dep
            # TEST: use local function, that uses ids.getLink
            getUpperBranches(session, dep, dep_path)

    path = os.path.join(os.getcwd(), path)
    
    # TEST: report what we would run, but do not run it
    cmd = [MSMM_VIEWER_DATASET, path] + build_inner_options(options) + rest
    print "About to run", cmd
    print "Non-interactive version, will not try to run viewer"
    # proc = subprocess.call(cmd)

    # print "All done - hit return"
    # sys.stdin.readline()

except Exception as e:

    exc = e
    traceback.print_exc()
    print "An error has occured - press return to continue."
    sys.stdin.readline()

except SystemExit as e:

    exc = e
    print "A fatal error has occured - press return to continue."
    sys.stdin.readline()

if exc: raise exc
