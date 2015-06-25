
'''
Creates a list of all files within a directory, then copies each over to
VOS.

Run getCert before this script.
'''

import vos
import os
import sys
import logging
import datetime

# Input a directory to copy over
folder = sys.argv[1]
vos_root = sys.argv[2]
ntries = int(sys.argv[3])
overwrite = True if sys.argv[4] == "True" else False

# Start logging
logging.basicConfig(
        filename=folder.rstrip("/")+"_"+str(datetime.datetime.now())+".log",
        level=logging.WARNING,
        format='%(asctime)s %(levelname)s:%(message)s')

logging.info("Starting at %s", str(datetime.datetime.now()))

client = vos.Client()

failed_list = []

for (root, direc, files) in os.walk(folder):

    vos_direc = os.path.join(vos_root, root)

    # First check if the directory exists in VOS:
    if not client.isdir(vos_direc):
        ntry = 0
        logging.info("%s does not exist yet.", vos_direc)
        while ntry <= ntries:
            if client.mkdir(vos_direc):
                logging.info("%s created.", vos_direc)
                break
            ntry += 1
        else:
            logging.warning("Could not create %s", vos_direc)
            logging.warning("Not attempting to copy files in %s", vos_direc)
            failed_list.append([root, direc, files])
            continue

    ntry = 0

    # Now loop through and copy the files in that directory
    for f in files:
        file_path = os.path.join(root, f)
        vos_path = os.path.join(vos_direc, f)

        if client.isfile(file_path):
            if overwrite:
                logging.info("Overwriting %s", file_path)
                client.delete(file_path)
            else:
                logging.info("%s already exists. Skipping.", file_path)
                continue

        while ntry <= ntries:
            if client.copy(file_path, vos_path):
                logging.info("Successfully copied %s", vos_path)
                break
            ntry += 1
        else:
            logging.warning("Could not copy %s", vos_path)
            failed_list.append([root, None, f])
            continue
