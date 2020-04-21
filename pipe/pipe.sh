#!/usr/bin/env bash

source "$(dirname "$0")/common.sh"

echo "Executing the pipe..."

# Required parameters
PROJECT_NAME=${PROJECT_NAME:?'PROJECT_NAME variable missing.'}
TEAM_NAME=${TEAM_NAME:?'TEAM_NAME variable missing.'}
SLACK_HOOK_URL=${SLACK_HOOK_URL:?'SLACK_HOOK_URL variable missing.'}

# Default parameters
CHANGELOG=${CHANGELOG:="false"}

########init method declarations
discover_environment() {
  echo "discovering environment..."
  if [ "$BITBUCKET_BRANCH" == "master" ]; then
    ENVIRONMENT="production"
  elif [ "$BITBUCKET_BRANCH" == "staging" ] || [ "$BITBUCKET_BRANCH" == "stage" ]; then
    ENVIRONMENT='staging'
  else
    ENVIRONMENT="develop"
  fi
  echo "Environment: $ENVIRONMENT"
}

configure_version() {
  echo "Tag version: $VERSION"
  VERSION_INFO="Version: *<https://bitbucket.org/$BITBUCKET_WORKSPACE/$BITBUCKET_REPO_SLUG/src/$VERSION|$VERSION>*"
}

enable_changelog() {
  echo "CHANGELOG enabled=$CHANGELOG"
  echo "Link to CHANGELOG: https://bitbucket.org/$BITBUCKET_WORKSPACE/$BITBUCKET_REPO_SLUG/src/$BITBUCKET_BRANCH/CHANGELOG.md"
  CHANGELOG_PAYLOAD="Changelog: *<https://bitbucket.org/$BITBUCKET_WORKSPACE/$BITBUCKET_REPO_SLUG/src/$BITBUCKET_BRANCH/CHANGELOG.md|CHANGELOG.md>*"
}

configure_success_failure_deployment_variables() {
  echo "Pipeline exit code: $BITBUCKET_EXIT_CODE"
  if [ "$BITBUCKET_EXIT_CODE" == "0" ]; then
    DEPLOYMENT_FEEDBACK="completed *successfully!*"
    ICON_DEPLOYMENT_FEEDBACK="'accessory': {
                                'type': 'image',
                                'image_url': 'https://raw.githubusercontent.com/raphacps/smart-slack-notification/feature/alterar-layout/tick_ok_image.png',
                                'alt_text': 'Succeeded deployment'
                              }"
  else
    DEPLOYMENT_FEEDBACK="ended with *failure...*"
    ICON_DEPLOYMENT_FEEDBACK="'accessory': {
                                'type': 'image',
                                'image_url': 'https://raw.githubusercontent.com/raphacps/smart-slack-notification/feature/alterar-layout/failure_tick.png',
                                'alt_text': 'Failure deployment'
                              }"
  fi
  echo "Pipeline exit code: $BITBUCKET_EXIT_CODE"
}

notify_slack() {
  echo "Notifying slack to webhook $1"
  curl -X POST -H 'Content-type: application/json' --data "{
              'blocks': [
                    {
                      'type': 'section',
                      'text': {
                        'type': 'mrkdwn',
                        'text': '*Deploy Notification*\n*Team:* $TEAM_NAME\t\t\t *Project:* <https://bitbucket.org/account/user/$BITBUCKET_WORKSPACE/projects/$BITBUCKET_PROJECT_KEY|$PROJECT_NAME>'
                      }
                    },
                    {
                      'type': 'divider'
                    },
                    {
                      'type': 'section',
                      'text': {
                        'type': 'mrkdwn',
                        'text': 'Deployment of service *<https://bitbucket.org/$BITBUCKET_WORKSPACE/$BITBUCKET_REPO_SLUG/src/$BITBUCKET_BRANCH|$BITBUCKET_REPO_SLUG>* on *$BITBUCKET_DEPLOYMENT_ENVIRONMENT* $DEPLOYMENT_FEEDBACK\nBuild Number: *<https://bitbucket.org/$BITBUCKET_WORKSPACE/$BITBUCKET_REPO_SLUG/addon/pipelines/home#!/results/$BITBUCKET_BUILD_NUMBER|#$BITBUCKET_BUILD_NUMBER>*\n$VERSION_INFO\n$CHANGELOG_PAYLOAD'
                      },
                      $ICON_DEPLOYMENT_FEEDBACK
                    },
                    {
                      'type': 'divider'
                    },

                    {
                      'type': 'context',
                      'elements': [
                        {
                          'type': 'mrkdwn',
                          'text': '*><https://hub.docker.com/repository/docker/raphacps/smart-slack-notification-pipe|smart-slack-notification 1.1.0>*'
                        }
                      ]
                    }
                  ]
             }" $1
  echo "$webhook notifyed"
}

notify_slack_list() {
  set -f
  IFS=,
  WEBHOOKS=($SLACK_HOOK_URL)
  for webhook in "${WEBHOOKS[@]}"; do
    notify_slack $webhook
  done
}
########end method declarations

###init program
discover_environment
if [ ! -z $VERSION ]; then
  configure_version
fi

if [ "$CHANGELOG" == true ]; then
  enable_changelog
fi

configure_success_failure_deployment_variables

notify_slack_list
###end program