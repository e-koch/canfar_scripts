#!/bin/bash

# Source bash profile
shopt -s expand_aliases
source /home/ekoch/.bash_profile

# Input
channel=${1}

mask_model_channel=$(($channel - 9))

ms_name=M33_b_c_channel_${channel}.ms.tgz
mask_name=M33_newmask_channel_${mask_model_channel}.image.tgz
model_name=M33_model_channel_${mask_model_channel}.image.tgz

# Set username. Otherwise CASA crashes.
export USER='ekoch'

# Get certificate
getCert

mkdir -p ${TMPDIR}/{vos,vos_cache,proc,vos_link}

rm -rf /home/ekoch/canfar_scripts
git clone https://github.com/e-koch/canfar_scripts.git /home/ekoch/canfar_scripts

echo "Mounting data"
mountvofs --vospace vos:MWSynthesis/ --mountpoint ${TMPDIR}/vos --cache_dir ${TMPDIR}/vos_cache

echo "Copying files onto VM"

cp ${TMPDIR}/vos/Arecibo/newmask_channels/${mask_name} ${TMPDIR}/proc
echo "Done M33_mask"

cp ${TMPDIR}/vos/Arecibo/model_channels/${model_name} ${TMPDIR}/proc
echo "Done M33_model"

cp -R ${TMPDIR}/vos/VLA/archival/single_channels/${ms_name} ${TMPDIR}/proc
echo "Done MS Set"

# Unmount
fusermount -u ${TMPDIR}/vos

cd ${TMPDIR}/proc

# Unzip the model and mask
tar -zxf ${mask_name}
tar -zxf ${model_name}
tar -zxf ${ms_name}

# Delete zip files
rm ${mask_name}
rm ${model_name}
rm ${ms_name}

# Rename the files w/o the zipped ends
ms_name=${ms_name: -4}
mask_name=${mask_name: -4}
model_name=${model_name: -4}

echo "Running CASA"

echo "Show contents"
ls -al ${TMPDIR}/proc

casapy --nogui -c /home/ekoch/canfar_scripts/img_pipe/archival_data/single_channel_clean.py ${ms_name} ${model_name} ${mask_name}

# Compress the clean output to upload to VOS
tar -zcf ${ms_name: -3}.clean.image.tar.gz ${ms_name: -3}.clean.image
tar -zcf ${ms_name: -3}.clean.mask.tar.gz ${ms_name: -3}.clean.mask
tar -zcf ${ms_name: -3}.clean.model.tar.gz ${ms_name: -3}.clean.model
tar -zcf ${ms_name: -3}.clean.psf.tar.gz ${ms_name: -3}.clean.psf
tar -zcf ${ms_name: -3}.clean.residual.tar.gz ${ms_name: -3}.clean.residual

# Now remount VOS, and copy over the relevant infos
echo "Remount"
# mount_data_write
mountvofs --vospace vos:MWSynthesis/VLA/archival/clean_channels/ --mountpoint ${TMPDIR}/vos --cache_dir ${TMPDIR}/vos_cache

cp -a ${TMPDIR}/proc/casa*.log ${TMPDIR}/vos/

cp -a ${TMPDIR}/proc/${ms_name: -3}.clean*.tar.gz ${TMPDIR}/vos/

echo "Unmount"
fusermount -u ${TMPDIR}/vos