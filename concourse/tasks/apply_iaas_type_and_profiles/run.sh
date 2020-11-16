#!/bin/bash

git clone paas-templates-resource paas-templates-resolved
echo "Copying git metadata"
pushd paas-templates-resource/.git/
if [[ ! (-e commit_message && -e commit_timestamp && -e committer && -e describe_ref && -e ref && -e short_ref) ]];then
  echo "Missing git info; commit_message, commit_timestamp, committer, describe_ref, ref or short_ref"
  exit 1
fi

popd

cp -p paas-templates-resource/.git/commit_message paas-templates-resolved/.git
cp -p paas-templates-resource/.git/commit_timestamp paas-templates-resolved/.git
cp -p paas-templates-resource/.git/committer paas-templates-resolved/.git
cp -p paas-templates-resource/.git/describe_ref paas-templates-resolved/.git
cp -p paas-templates-resource/.git/ref paas-templates-resolved/.git
cp -p paas-templates-resource/.git/short_ref paas-templates-resolved/.git


cd "paas-templates-resolved/$ROOT_DEPLOYMENT_NAME/$COA_DEPLOYMENT_NAME/$CONFIG_DIR" || exit 0

if [[ -n "${IAAS_TYPE}" && -d "${IAAS_TYPE}" ]]; then
  echo "Copying from ${PWD}/${IAAS_TYPE} to ${PWD}"
  cp -rv "${IAAS_TYPE}"/* .
else
  echo "ignoring IAAS_TYPE customization. Iaas type not defined / detected at ${PWD}/${IAAS_TYPE}. Iaas type: $IAAS_TYPE"
fi

if [ -z "${PROFILES}" ]; then
  echo "\$PROFILES is empty, skipping"
  exit 0
fi

echo "${PROFILES}"|sed -e 's/,/\n/g' > /tmp/profiles.txt
if [ "$PROFILES_AUTOSORT" = "true" ]; then
  NEWLINE_DELIMITED_PROFILES=$(sort </tmp/profiles.txt)
  echo -e "Auto sort profiles:\n${NEWLINE_DELIMITED_PROFILES}"
else
  NEWLINE_DELIMITED_PROFILES=$(cat /tmp/profiles.txt)
  echo "Auto sort profiles disabled: ${NEWLINE_DELIMITED_PROFILES}"
fi
for profile in ${NEWLINE_DELIMITED_PROFILES}; do
  echo "-------------------------"
  if [[ -n ${profile} && -d ${profile} ]]; then
    cp -rv "${profile}"/* .
  else
    echo "ignoring ${profile} customization. Profile not defined/detected at ${PWD}/${profile}"
  fi
done
