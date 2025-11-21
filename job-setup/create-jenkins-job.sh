#!/bin/bash

# Create a jenkins job
#
# # Copyright 2024 Sam Darwin
#
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at http://boost.org/LICENSE_1_0.txt)

set -e
set -x

scriptname="create-jenkins-job.sh"
scriptlocation=$(pwd)

# set defaults:

# The job will be created in _another_ github organization, not the specified one.
# That is so it can be tested before going live, since testing is almost always necessary.
# After running the script first without the -d flag, and confirming that everything works,
# run it again with -d.

# shellcheck disable=SC2034
github_test_org="sdarwin"
timestamper=$(date "+%Y-%m-%d-%H-%M-%S")

# READ IN COMMAND-LINE OPTIONS

TEMP=$(getopt -o h::,d::,s: --long help::,deploy::,suffix: -- "$@")
eval set -- "$TEMP"

# extract options and their arguments into variables.
while true ; do
    case "$1" in
        -h|--help)
            helpmessage="""
usage: $scriptname [-h] [library_repo]

Builds library documentation.

optional arguments:
  -h, --help            Show this help message and exit
  -s, --suffix SUFFIX   Add a suffix to the job name. json_benchmarks instead of json.
  -d, --deploy          Convert an initial test job to production
standard arguments:
  library_repo	Example: boostorg/asio
"""

            echo ""
	    echo "$helpmessage" ;
	    echo ""
            exit 0
            ;;
        -s|--suffix)
            case "$2" in
                "") suffix_option="" ; shift 2 ;;
                 *) suffix_option=$2 ; shift 2 ;;
            esac ;;
	-d|--deploy)
	    deployoption="yes" ; shift 2 ;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done

if [ -z "${GH_TOKEN}" ]; then
    # shellcheck source=/dev/null
    . ~/.config/github_credentials
fi

if [ -z "${GH_TOKEN}" ]; then
    echo "Please set the environment variable export GH_TOKEN="
    echo "If included in ~/.config/github_credentials the script will source that file."
    echo "Exiting."
    exit 1
fi

if [ -n "$1" ]; then
    repo_stub=$1
    if [[ ! "$repo_stub" =~ / ]]; then
        echo "The repository value you provide to this script should match the format 'org/repo'."
        echo "Exiting."
        exit 1
    fi
    repo_url=https://github.com/$1
    repo_name=$(basename -s .git "${repo_url}")
    # shellcheck disable=SC2034,SC2046
    repo_org=$(basename $(dirname "${repo_url}"))
    if [ -n "$suffix_option" ]; then
        job_name="${repo_name}_${suffix_option}"
    else
        job_name="${repo_name}"
    fi
else
    echo "Repo not set."
    echo "The repository variable should match the format 'org/repo'."
    echo "Exiting."
    exit 1
fi

# Pre-flight checks

if gh auth status ; then
    echo "Already logged into the gh cli. Continuing."
else
    echo "Not logged into the gh cli. Please run 'gh auth login'"
    exit 1
fi

function initial_main_setup {

    echo "Setting up a test version of the job"

    ####################
    #
    # The first series of steps creates a pull request in the ${github_test_org} organization
    # which will be used to test jenkins jobs with pull requests
    #
    ####################

    mkdir -p ~/github/jenkins_scripts
    cd ~/github/jenkins_scripts
    if [ ! -d "${repo_name}" ]; then
        git clone "${repo_url}"
    fi
    
    cd "${repo_name}"
    # shellcheck disable=SC2034
    localrepodir=$(pwd)
    
    if git remote -v | grep upstream ; then
        echo "upstream remote found. The fork has likely already been done. Continuing."
    else
        # 2025, at the very beginning, this was needed?
        gh repo set-default "${repo_org}/${repo_name}"
        echo "Running gh repo fork --remote"
        gh repo fork --remote
        gh repo set-default "${github_test_org}/${repo_name}"
    fi
    
    if git remote -v | grep origin | grep ${github_test_org} ; then
        echo "validation step: the git origin repo matches this script's github_test_org. Ok."
    else
        echo "validation step: the git origin repo does not matches this script's github_test_org. Exiting."
        exit 1
    fi
    
    if git branch -avv | grep prtest | grep "testing pull request" ; then
        echo "The prtest branch already exists. Switching to that."
        echo "git checkout prtest"
        git checkout prtest
    else
        echo "git checkout -b prtest"
        git checkout -b prtest
    fi
    
    if gh pr list | grep prtest | grep "testing pull request" ; then
        echo "Test PR already exists. Continuing."
    else
        echo "Generating a test PR."
        echo " " >> README.md || true
        echo " " >> README.adoc || true
        
        git config user.name testbot
        git config user.email testbot@example.com

        git remote set-url origin "https://testbot:${GH_TOKEN}@github.com/${github_test_org}/${repo_name}"

        git add .
        git commit -m "testing pull request doc previews"
        git push --set-upstream origin prtest --force

        # For security, let's put the URL back to normal
        git remote set-url origin "https://github.com/${github_test_org}/${repo_name}"

        gh pr create --base develop -R "${github_test_org}/${repo_name}" --title "testing pull request doc previews" --body "Don't merge this PR"
    fi
    
    #####################
    #
    # Determine the type of repo
    #
    #####################
    
    if [ -f doc/build_antora.sh ] ; then
        job_type="antora_libraries_1"
    else
        job_type="standard_libraries_1"
    fi
    
    tmpdir=$(mktemp -d)
    
    cp "$scriptlocation/job-templates/${job_type}/config.xml" "${tmpdir}/config.xml"
    cd "${tmpdir}"
    
    echo "Running sed to customize config.xml in ${tmpdir}"
    sed -i "s/template_job_name/${job_name}/g" config.xml
    sed -i "s/template_repository/${repo_name}/g" config.xml
    sed -i "s/template_organization/${github_test_org}/g" config.xml
    # Still in testing mode for a new repo:
    echo "second to last"
    sed -i "s|cppalliance/jenkins-ci|${github_test_org}/jenkins-ci|" config.xml
    echo "last sed"
    sed -i "s|<name>\*/master</name>|<name>\*/testing</name>|" config.xml
    
    mkdir -p "/var/lib/jenkins/jobs/${job_name}"
    chown jenkins:jenkins "/var/lib/jenkins/jobs/${job_name}"
    chown jenkins:jenkins config.xml
    destfile="/var/lib/jenkins/jobs/${job_name}/config.xml"
    if [ ! -f "${destfile}" ]; then
        cp -p config.xml "/var/lib/jenkins/jobs/${job_name}/config.xml"
        # shellcheck source=/dev/null
        . ~/.config/jenkins_credentials
        java -jar /usr/bin/jenkins-cli.jar -s http://localhost:8080 -auth "$JENKINS_USER:$JENKINS_PASSWORD" reload-configuration
    else
        echo "The job, and config.xml, already exist, at ${destfile}. Not copying in a new file."
    fi

    # Completion messages
    if [ "${testing_branch_success}" = "yes" ]; then
        echo ""
        echo "Testing environment set up. Go to ~/github/${github_test_org}/jenkins-ci in the 'testing' branch, and verify the job is correct."
        echo "After that has been confirmed, run this script again with the --deploy option, to 'go live'."
        echo ""
    else
        echo ""
        echo "Testing environment in ~/github/${github_test_org}/jenkins-ci was not completed."
        echo "There may be multiple reasons for that problem. The feature is currently in development."
        echo "Please go to that directory and manually configure the 'testing' branch, based on the latest copy of 'master'"
        echo "Proceed to test the jobs."
        echo "Then run this script again with the --deploy option, to 'go live'."
        echo ""
    fi
}

function deploy_job {
 
    echo "Deploy the test job to production"

    configfile="/var/lib/jenkins/jobs/${job_name}/config.xml"
    sed -i "s|<repoOwner>$github_test_org|<repoOwner>$repo_org|g" "${configfile}"
    sed -i "s|<repositoryUrl>https://github.com/$github_test_org|<repositoryUrl>https://github.com/$repo_org|g" "${configfile}"
    sed -i "s|<url>https://github.com/$github_test_org/jenkins-ci|<url>https://github.com/cppalliance/jenkins-ci|g" "${configfile}"
    sed -i "s|<name>\*/testing</name>|<name>\*/master</name>|" "${configfile}"
    # shellcheck source=/dev/null
    . ~/.config/jenkins_credentials
    java -jar /usr/bin/jenkins-cli.jar -s http://localhost:8080 -auth "$JENKINS_USER:$JENKINS_PASSWORD" reload-configuration
}

function prepare_testing_branch {

    echo ""
    echo "Now in the function prepare_testing_branch"
    echo "When working on Jenkins, the idea is to test your changes first, in the testing branch of the github_test_org github organization."
    echo "Currently github_test_org==${github_test_org}, and so the testing repo is https://github.com/${github_test_org}/jenkins-ci, branch: testing"
    echo "This function will checkout the branch in ~/github/${github_test_org}/jenkins-ci"
    echo "From there, 'git push' your changes to github. Run tests."
    echo "The jobs themselves are configured to reference that branch, and will need to be modified right before going live, to again point to production."
    echo ""

    set -x

    testing_branch_success="yes"
    previousdir=$(pwd)
    mkdir -p "$HOME/github/${github_test_org}"
    cd "$HOME/github/${github_test_org}"
    if [ ! -d jenkins-ci ]; then
        git clone -b testing "https://github.com/${github_test_org}/jenkins-ci"
    fi
    cd jenkins-ci
    git fetch origin
    git remote add upstream https://github.com/cppalliance/jenkins-ci > /dev/null || true
    git fetch origin
    git fetch upstream
    if git branch -vv | grep "origin/testing" ; then
        echo "on the correct branch"
    else
        git checkout testing > /dev/null || git checkout --track origin/testing
    fi
    if git diff --cached --exit-code > /dev/null ; then
        echo "git diff --cached ok"
    else
        echo "git diff has a diff. Please resolve this manually. Not preparing the testing branch. Exiting from this function."
        testing_branch_success="no"
        set +x
        cd "${previousdir}"
        return "0"
    fi

    if git diff --exit-code > /dev/null ; then
        echo "git diff ok"
    else
        echo "git diff has a diff. Please resolve this manually. Not preparing the testing branch. Exiting from this function."
        testing_branch_success="no"
        set +x
        cd "${previousdir}"
        return "0"
    fi
    # Perhaps these checks can be allowed to fail
    # if git diff origin/testing --cached --exit-code > /dev/null ; then
    #     echo "git diff --cached ok"
    # else
    #     echo "git diff origin/testing has a diff. Please resolve this manually. Not preparing the testing branch. Exiting from this function."
    #     testing_branch_success="no"
    #     set +x
    #     cd "${previousdir}"
    #     return "0"
    # fi

    # if git diff origin/testing --exit-code > /dev/null ; then
    #     echo "git diff ok"
    # else
    #     echo "git diff origin/testing has a diff. Please resolve this manually. Not preparing the testing branch. Exiting from this function."
    #     testing_branch_success="no"
    #     set +x
    #     cd "${previousdir}"
    #     return "0"
    # fi

    git checkout master || git checkout --track origin/master
    git pull
    git merge upstream/master
    git branch -d testing
    git checkout -b testing
    echo "Testing branch configured successfully"
    cd "${previousdir}"
    set +x
}

function check_in_testing_branch {

    newtargetbranch="${repo_name}-${timestamper}"
    previousdir=$(pwd)
    cd "$HOME/github/${github_test_org}/jenkins-ci/scripts"
    if [ -f "${github_test_org}_${job_name}_prebuild.sh" ]; then
        mv "${github_test_org}_${job_name}_prebuild.sh" "${repo_org}_${job_name}_prebuild.sh"
    fi
    if [ -f "${github_test_org}_${job_name}_build.sh" ]; then
        mv "${github_test_org}_${job_name}_build.sh" "${repo_org}_${job_name}_build.sh"
    fi
    if [ -f "${github_test_org}_${job_name}_postbuild.sh" ]; then
        mv "${github_test_org}_${job_name}_postbuild.sh" "${repo_org}_${job_name}_postbuild.sh"
    fi
    git add .
    if ! git diff-index --quiet HEAD; then
        git commit -m "${repo_stub}"
        git remote set-url origin "https://testbot:${GH_TOKEN}@github.com/${github_test_org}/jenkins-ci"
        git push
    fi
    git checkout -b "test-backup-${timestamper}"
    git checkout master
    git pull
    git checkout -b "${newtargetbranch}"
    git merge --squash testing
    git add .
    if ! git diff-index --quiet HEAD; then
        git commit -m "${repo_stub}"
    fi

    git remote set-url origin "https://testbot:${GH_TOKEN}@github.com/${github_test_org}/jenkins-ci"
    git push --set-upstream origin "${newtargetbranch}"
    # For security, let's put the URL back to normal
    git remote set-url origin "https://github.com/${github_test_org}/jenkins-ci"

    gh pr create --base master -R "cppalliance/jenkins-ci" --title "${repo_stub}" --body "Update jenkins-ci: ${repo_stub}"
    read -r -p "Created a PR on jenkins-ci. Please review and merge it. Do you want to continue? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        echo "continuing"
    else
        echo "did not receive a Yy. Exiting."
        exit 1
    fi

    cd "${previousdir}"
}

if [ "$deployoption" == "yes" ]; then
    # After the job has been tested:
    check_in_testing_branch
    deploy_job
else
    # The most common steps:
    prepare_testing_branch
    initial_main_setup
fi

