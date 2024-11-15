#!/bin/ash
# shellcheck shell=dash
# Ash scripts will be checked as Dash.

set -o pipefail
set -e

git config --global user.email "$GIT_USER_EMAIL"
git config --global user.name "$GIT_USER_NAME"
git config --global merge.renamelimit "$GIT_MERGE_RENAMELIMIT"
git config --global safe.directory '*'

FINAL_RELEASE_REPO=updated-git-resource

if [ "$SKIP_SSL_VERIFICATION" = "true" ]; then
  export GIT_SSL_NO_VERIFY=true
  echo "Skipping ssl verification"
fi

cd reference-resource || exit 1
URI=$(git remote get-url origin)

# shellcheck disable=SC2086
# we need GIT_BRANCH_FILTER to be expanded with spaces
current_heads=$(git ls-remote -h "$URI" ${GIT_BRANCH_FILTER} | sed 's/refs\/heads\///' | awk '{print $2, $1}' | sort)
cd ..

echo "selected branches list with associated commit id:"
DISPLAY_SEPARATOR="=================="
echo ${DISPLAY_SEPARATOR}
echo "${current_heads}"
echo ${DISPLAY_SEPARATOR}
git clone "${URI}" "${FINAL_RELEASE_REPO}"
cd ${FINAL_RELEASE_REPO} || exit 1
git checkout -B "${GIT_CHECKOUT_BRANCH}" -t "origin/${GIT_CHECKOUT_BRANCH}"

git_br=$(echo "${current_heads}" |awk '{ for (i=2;i<=NF;i+=2) $i=""; print}' )
echo "WIP Reset Complete" > .git/reset_branches
{
    echo ""
    echo "Restored branches:"
    echo "${current_heads}"
} >> .git/reset_branches

for branch_name in ${git_br}; do
  echo ${DISPLAY_SEPARATOR}
  echo "Processing $branch_name"
  git merge -m "Merge branch '$branch_name' after WIP reset [skip ci]" "origin/${branch_name}"
done

find . -maxdepth 5 -not \( -path "*.git" -prune \) -type d > .git/all_changed_dirs
echo "Changed dirs:"
cat .git/all_changed_dirs


# add timestamp to force triggering
cat .git/all_changed_dirs|sort |uniq > .git/changed_dirs
echo "Changed detected in the following dirs:"
cat .git/changed_dirs
echo ${DISPLAY_SEPARATOR}

date +'%Y-%m-%d-%H-%M-%S'|tee .git/.last-reset
while IFS= read -r aDir
do
  if [ -d "${aDir}" ]; then
    cp .git/.last-reset "${aDir}"
  fi
done < .git/changed_dirs

echo "Adding changes to git"
git add .
git commit --file .git/reset_branches