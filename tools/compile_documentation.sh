#!/bin/bash

# This code is part of Qiskit.
#
# (C) Copyright IBM 2018, 2019.
#
# This code is licensed under the Apache License, Version 2.0. You may
# obtain a copy of this license in the LICENSE.txt file in the root directory
# of this source tree or at http://www.apache.org/licenses/LICENSE-2.0.
#
# Any modifications or derivative works of this code must retain this
# copyright notice, and modified files need to carry a notice indicating
# that they have been altered from the originals.

# Script for pushing the documentation to the qiskit.org repository.

# Non-travis variables used by this script.
TARGET_REPOSITORY="git@github.com:SooluThomas/qiskit.git"
TARGET_BRANCH="translationDocs"
DOC_DIR_1="docs/_build/gettext"
DOC_DIR_2="docs/locale"
SOURCE_DIR=`pwd`
TRANSLATION_LANG='ja'

echo "cd docs"
cd docs
# Extract document's translatable messages into pot files
echo "Extract document's translatable messages into pot files: "
sphinx-build -b gettext -D language=$TRANSLATION_LANG . _build/gettext/$TRANSLATION_LANG

# Setup / Update po files
echo "Setup / Update po files"
sphinx-intl update -p _build/gettext -l $TRANSLATION_LANG

# Setup the deploy key.
# https://gist.github.com/qoomon/c57b0dc866221d91704ffef25d41adcf
echo "set ssh"
set -e
openssl aes-256-cbc -K $encrypted_a301093015c6_key -iv $encrypted_a301093015c6_iv -in ../tools/github_deploy_key.enc -out github_deploy_key -d
chmod 600 github_deploy_key
eval $(ssh-agent -s)
ssh-add github_deploy_key
echo "end of configuring ssh"

# Clone the landing page repository.
cd ..
echo "git checkout and git clone"
git checkout $TARGET_BRANCH
git clone --depth 1 $TARGET_REPOSITORY tmp
cd tmp
git config user.name "SooluThomas"
git config user.email "soolu.elto@gmail.com"

# Copy the new rendered files and add them to the commit.
# mkdir -p $TARGET_DOC_DIR
echo "copy directory"
cp -r $SOURCE_DIR/$DOC_DIR_1/* $DOC_DIR_1/
cp -r $SOURCE_DIR/$DOC_DIR_2/* $DOC_DIR_2/

# git checkout translationDocs
echo "add to pot files to target dir"
git add $DOC_DIR_1
git add $DOC_DIR_2

# Commit and push the changes.
echo "git commit"
git commit -m "Automated documentation update to add .po and .pot files from meta-qiskit" -m "Commit: $TRAVIS_COMMIT" -m "Travis build: https://travis-ci.com/$TRAVIS_REPO_SLUG/builds/$TRAVIS_BUILD_ID"
echo "git push"
git push --quiet origin $TARGET_BRANCH
