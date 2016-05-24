#!/bin/bash

export REPO_SLUG="rakshazi/magecode.xyz"

echo -e "\e[32mRunning details: $TRAVIS_REPO_SLUG / $TRAVIS_BRANCH / $TRAVIS_BUILD_DIR \n\e[m"

if [ "$TRAVIS_REPO_SLUG" == $REPO_SLUG ]; then

  echo -e "\e[32mChecking out gh-pages branch...\n\e[m"

  cd $TRAVIS_BUILD_DIR
  git clone --quiet --depth=1 --branch=gh-pages https://${GH_TOKEN}@github.com/${REPO_SLUG} gh-pages > /dev/null
  if [ $? -ne 0 ]; then echo -e "\e[31mCould not clone the repository\e[m"; exit 1; fi

  echo -e "\e[32mGenerating site....\n\e[m"
  curl -sSO https://download.sculpin.io/sculpin.phar
  chmod +x ./sculpin.phar
  ./sculpin.phar generate --env=prod
  rm -f ./sculpin.phar

  echo -e "\e[32mSyncronizing content...\n\e[m"
  rsync -rtv --delete ./output_prod/* ./gh-pages
  if [ $? -ne 0 ]; then echo -e "\e[31mCould not sync directories\e[m"; exit 1; fi

  echo -e "\e[32mPreparing commit with changes...\n\e[m"

  cd gh-pages
  touch .nojekyll

  git config user.email "github.com@openaliasbox.org"
  git config user.name "TravisCI Builder Bot"

  git add --all .
  if [ $? -ne 0 ]; then echo -e "\e[31mFailed to add files to commit.\e[m"; exit 1; fi

  git commit -m "Publishing latest changes to blog from build $TRAVIS_COMMIT (Build #$TRAVIS_BUILD_NUMBER) to gh-pages"
  if [ $? -ne 0 ]; then echo -e "\e[31mFailed to create commit.\e[m"; exit 1; fi

  if [ "$TRAVIS_BRANCH" != "master" ]; then
    echo -e "\e[31mPR Build Detected. \n\e[m";
    echo -e "\e[31mAborting push to live repository.\e[m";
    exit 0;
  fi

  echo -e "\e[32mPushing Changes to Live Repository ... \n\e[m"

  git push -fq origin gh-pages > /dev/null;
  if [ $? -ne 0 ]; then echo -e "\e[31mFailed to push changes.\e[m"; exit 1; fi

  echo -e "\e[32mLatest blog update pushed to gh-pages.\n\e[m"

fi
