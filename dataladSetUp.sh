#!/usr/bin/env bash

root_dir=${PWD}
raw_dir=${root_dir}/inputs/raw
derivatives_dir=${root_dir}/outputs/derivatives
preproc_dir=${derivatives_dir}/bidspm-preproc
stats_dir=${derivatives_dir}/bidspm-stats
roi_dir=${derivatives_dir}/bidspm-roi
decoding_dir=${derivatives_dir}/cosmomvpa-decoding
rsa_dir=${derivatives_dir}/cosmomvpa-rsa

GIN_BASENAME='deafCat_pilots'

# get url of the gin repos from config
source dataladConfig.sh

# install raw dataset
datalad install -d . -s "${URL_RAW}" "${raw_dir}"

# create the derivatives universe of classic sub-subdatasets ()
# . outputs
# └── derivatives
#     ├── bidspm-preproc
#     └── bidspm-stats

datalad create -d . "${derivatives_dir}"

if [ ! -z "${GIN_BASENAME}" ]; then
    cd "${derivatives_dir}"
    datalad create-sibling-gin -d . -s origin --access-protocol ssh --private  cpp_brewery/"${GIN_BASENAME}"-derivatives
    cd "${root_dir}"
    datalad subdatasets --set-property url git@gin.g-node.org:/cpp_brewery/"${GIN_BASENAME}"-derivatives.git "${derivatives_dir}"
fi

cd "${derivatives_dir}"

#preproc
datalad create -d . "${preproc_dir}"

if [ ! -z "${GIN_BASENAME}" ]; then
    cd "${preproc_dir}"
    datalad create-sibling-gin -d . -s origin --access-protocol ssh --private  cpp_brewery/"${GIN_BASENAME}"-derivatives-bidspm-preproc
    cd "${derivatives_dir}"
    datalad subdatasets --set-property url git@gin.g-node.org:/cpp_brewery/"${GIN_BASENAME}"-derivatives-bidspm-preproc.git bidspm-preproc
fi

cd "${derivatives_dir}"

#stats
datalad create -d . "${stats_dir}"

if [ ! -z "${GIN_BASENAME}" ]; then
    cd "${stats_dir}"
    datalad create-sibling-gin -d . -s origin --access-protocol ssh --private  cpp_brewery/"${GIN_BASENAME}"-derivatives-bidspm-stats
    cd "${derivatives_dir}"
    datalad subdatasets --set-property url git@gin.g-node.org:/cpp_brewery/"${GIN_BASENAME}"-derivatives-bidspm-stats.git bidspm-stats
fi

cd "${derivatives_dir}"

#roi
datalad create -d . "${roi_dir}"

if [ ! -z "${GIN_BASENAME}" ]; then
    cd "${roi_dir}"
    datalad create-sibling-gin -d . -s origin --access-protocol ssh --private  cpp_brewery/"${GIN_BASENAME}"-derivatives-bidspm-roi
    cd "${derivatives_dir}"
    datalad subdatasets --set-property url git@gin.g-node.org:/cpp_brewery/"${GIN_BASENAME}"-derivatives-bidspm-roi.git bidspm-roi
fi

cd "${derivatives_dir}"

#decoding
datalad create -d . "${decoding_dir}"

if [ ! -z "${GIN_BASENAME}" ]; then
    cd "${decoding_dir}"
    datalad create-sibling-gin -d . -s origin --access-protocol ssh --private  cpp_brewery/"${GIN_BASENAME}"-derivatives-cosmomvpa-decoding
    cd "${derivatives_dir}"
    datalad subdatasets --set-property url git@gin.g-node.org:/cpp_brewery/"${GIN_BASENAME}"-derivatives-cosmovmpa-decoding.git cosmomvpa-decoding
fi

cd "${derivatives_dir}"

#rsa    
datalad create -d . "${rsa_dir}"

if [ ! -z "${GIN_BASENAME}" ]; then
    cd "${rsa_dir}"
    datalad create-sibling-gin -d . -s origin --access-protocol ssh --private  cpp_brewery/"${GIN_BASENAME}"-derivatives-cosmomvpa-rsa
    cd "${derivatives_dir}"
    datalad subdatasets --set-property url git@gin.g-node.org:/cpp_brewery/"${GIN_BASENAME}"-derivatives-cosmovmpa-rsa.git cosmomvpa-rsa
fi

cd "${derivatives_dir}"

datalad push --to origin -r

cd "${root_dir}"

datalad save -m "add code and folders to set subdatasets"

datalad push --to origin

echo "############################"
echo "# DATALAD IS READY TO WORK #"
echo "############################"
