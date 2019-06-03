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
TARGET_REPOSITORY="git@github.com:SooluThomas/testTranslation.git"
TARGET_DOC_DIR="."
SOURCE_DOC_DIR="docs/_build/html"
SOURCE_DIR=`pwd`
TRANSLATION_LANG='ja'

SOURCE_REPOSITORY="git@github.com:SooluThomas/qiskit.git"
SOURCH_BRANCH="translationDocs"
DOC_DIR_1="docs/_build/gettext"
DOC_DIR_2="docs/locale"

# Build the documentation.
echo "make doc"
make doc
echo "end of make doc"

echo "show current dir: "
pwd

echo "cd docs"
cd docs
# Extract document's translatable messages into pot files
# https://sphinx-intl.readthedocs.io/en/master/quickstart.html
echo "Extract document's translatable messages into pot files: "
sphinx-build -b gettext -D language=$TRANSLATION_LANG . _build/gettext/$TRANSLATION_LANG

# Setup / Update po files
echo "Setup / Update po files"
sphinx-intl update -p _build/gettext -l $TRANSLATION_LANG

# Make translated document
# make -e SPHINXOPTS="-Dlanguage='ja'" html
echo "Make translated document"
sphinx-build -b html -D language=$TRANSLATION_LANG . _build/html/locale/$TRANSLATION_LANG

# Setup the deploy key.
# https://gist.github.com/qoomon/c57b0dc866221d91704ffef25d41adcf
echo "set ssh"
pwd
set -e
openssl aes-256-cbc -K $encrypted_a301093015c6_key -iv $encrypted_a301093015c6_iv -in ../tools/github_deploy_key.enc -out github_deploy_key -d
chmod 600 github_deploy_key
eval $(ssh-agent -s)
ssh-add github_deploy_key
echo "end of configuring ssh"

# Clone to the working repository for .po and pot files
cd ..
pwd
echo "git clone for working repo"
git clone --depth 1 $SOURCE_REPOSITORY temp --single-branch --branch $SOURCH_BRANCH
cd temp
git branch
git config user.name "SooluThomas"
git config user.email "soolu.elto@gmail.com"

# Copy the new rendered files and add them to the commit.
echo "copy directory"
mkdir $DOC_DIR_1
cp -r $SOURCE_DIR/$DOC_DIR_1/* $DOC_DIR_1/
mkdir $DOC_DIR_2
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
echo "********** End of pushing po and pot files to working repo! *************"

# Clone the landing page repository.
cd ..
pwd
echo "git clone for landing page repo"
git clone --depth 1 $TARGET_REPOSITORY tmp
cd tmp
git config user.name "SooluThomas"
git config user.email "soolu.elto@gmail.com"

# Selectively delete files from the dir, for preserving versions and languages.
echo "git rm -rf"
git rm -rf --ignore-unmatch $TARGET_DOC_DIR/*.html \
    $TARGET_DOC_DIR/_* \
    $TARGET_DOC_DIR/aer \
    $TARGET_DOC_DIR/autodoc \
    $TARGET_DOC_DIR/aqua \
    $TARGET_DOC_DIR/terra \
    $TARGET_DOC_DIR/ignis

# Copy the new rendered files and add them to the commit.
# mkdir -p $TARGET_DOC_DIR
echo "copy directory"
cp -r $SOURCE_DIR/$SOURCE_DOC_DIR/* $TARGET_DOC_DIR/

# git checkout translationDocs
echo "add to target dir"
git add $TARGET_DOC_DIR

# Commit and push the changes.
echo "git commit"
git commit -m "Automated documentation update from meta-qiskit" -m "Commit: $TRAVIS_COMMIT" -m "Travis build: https://travis-ci.com/$TRAVIS_REPO_SLUG/builds/$TRAVIS_BUILD_ID"
echo "git push"
git push --quiet
