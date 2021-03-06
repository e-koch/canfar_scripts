#!/bin/bash
echo 'Making dirs'
mkdir -p ${TMPDIR}/{vos, proc}
echo 'Mount VOS in readonly mode'

# Source bash profile
shopt -s expand_aliases
source /home/ekoch/.bash_profile

# Set username. Otherwise CASA crashes.
export USER='ekoch'

# Clone CANFAR repo
rm -rf /home/ekoch/canfar_scripts
git clone https://github.com/e-koch/canfar_scripts.git /home/ekoch/canfar_scripts

# First argument is the name of the concatenated MS file.
conc_name = ${1}

# Arguments provide the paths to the MS's. Concatenate them together to pass to python script
echo "$#-1 paths provided."
conc_args = ${2}
for arg in {3..$#}
do
    conc_args+=' '${arg}
done

echo "Mounting data"
mount_data
echo 'Run casapy'
cd ${TMPDIR}/proc
casapy --nogui -c /home/ekoch/canfar_scripts/concat/casanfar_concat.py conc_name conc_args
echo 'Unmount'
sudo fusermount -u ${TMPDIR}/vos
echo 'Mount writable area'
mount_data_write
echo 'Copy files'
cp -a ${TMPDIR}/proc/* ${TMPDIR}/vos/
echo 'Unmount'
sudo fusermount -u ${TMPDIR}/vos
