#!/bin/ash
# shellcheck shell=dash
# Ash scripts will be checked as Dash.

set -o pipefail
FINAL_RELEASE_REPO="outdated-check"
git config --global user.email "$GIT_USER_EMAIL"
git config --global user.name "$GIT_USER_NAME"

if [ "$SKIP_SSL_VERIFICATION" = "true" ]; then
  export GIT_SSL_NO_VERIFY=true
  echo "Skipping ssl verification"
fi
OUTDATED_BRANCHES_FILE=$(echo $PWD/result/outdated-branches.log)

cd reference-resource || exit 1
URI=$(git remote get-url origin)
reference_head=$(git log -1 --oneline --format=%H)
cd ..

git clone "${URI}" "${FINAL_RELEASE_REPO}" --mirror
cd ${FINAL_RELEASE_REPO}
echo "Reference head selected: $reference_head"

# shellcheck disable=SC2086
# we need GIT_BRANCH_FILTER to be expanded with spaces
remote_branche_references=$(git ls-remote -h "$URI" ${GIT_BRANCH_FILTER} | sed 's/refs\/heads\///' | awk '{print $2"/"$1}' | sort)
rebase_count=0
branches_total=0
for remote_ref in $(echo ${remote_branche_references});do
  name=$(echo ${remote_ref}|cut -d'/' -f1)
  branch_head=$(echo ${remote_ref}|cut -d'/' -f2)
  echo "Processing $name(commit $branch_head)"
  ref_search=$(git log $branch_head  --pretty=tformat:%H|grep ${reference_head}|wc -l)
  if [ ${ref_search} -ne 1 ];then
    echo ${name} >> ${OUTDATED_BRANCHES_FILE}
    echo "   >> outdated branche detected ($name/$branch_head)"
    rebase_count=$((rebase_count+1))
  fi
  branches_total=$((branches_total+1))
done

if [ -f ${OUTDATED_BRANCHES_FILE} ];then
  echo "Outdated branches:"
  echo "========================"
  cat ${OUTDATED_BRANCHES_FILE}
  echo "========================"
  echo "Please rebase outdated branches: $rebase_count on $branches_total"
  exit 1
fi
