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
  VERSION_INFO="{
                      'type': 'mrkdwn',
                      'text': '*Version:*\n*<https://bitbucket.org/$BITBUCKET_WORKSPACE/$BITBUCKET_REPO_SLUG/src/$VERSION|$VERSION>*'
                  },"
}

enable_changelog() {
  echo "CHANGELOG enabled..."
  echo "Link to CHANGELOG: https://bitbucket.org/$BITBUCKET_WORKSPACE/$BITBUCKET_REPO_SLUG/src/$BITBUCKET_BRANCH/CHANGELOG.md"
  CHANGELOG_PAYLOAD="{
                        'type': 'mrkdwn',
                        'text': '*Changelog:*\n*<https://bitbucket.org/$BITBUCKET_WORKSPACE/$BITBUCKET_REPO_SLUG/src/$BITBUCKET_BRANCH/CHANGELOG.md|CHANGELOG.md>*'
                    },"
}

notify_slack() {
  echo "Notifying slack to webhook $1"
  curl -X POST -H 'Content-type: application/json' --data "{
              'blocks': [
                    {
                      'type': 'section',
                      'fields': [
                          {
                              'type': 'mrkdwn',
                              'text': '*Project:*\n*<https://bitbucket.org/account/user/$BITBUCKET_WORKSPACE/projects/$BITBUCKET_PROJECT_KEY|$PROJECT_NAME>*'
                          },
                          {
                              'type': 'mrkdwn',
                              'text': '*Team:*\n$TEAM_NAME'
                          }
                      ]
                    },
                    {
                        'type': 'divider'
                    },
                    {
                        'type': 'section',
                        'fields': [
                            {
                                'type': 'mrkdwn',
                                'text': '*Service:*\n$BITBUCKET_REPO_SLUG'
                            },
                            {
                                'type': 'mrkdwn',
                                'text': '*Environment:*\n$ENVIRONMENT'
                            },
                            $VERSION_INFO
                            $CHANGELOG_PAYLOAD
                            {
                                'type': 'mrkdwn',
                                'text': '*Build Number:*\n*<https://bitbucket.org/$BITBUCKET_WORKSPACE/$BITBUCKET_REPO_SLUG/addon/pipelines/home#!/results/$BITBUCKET_BUILD_NUMBER|#$BITBUCKET_BUILD_NUMBER>*'
                            }
                       ]
                    },
                    {
                      'type': 'divider'
                    },
                    {
                      'type': 'section',
                      'fields': [
                        {
                          'type': 'mrkdwn',
                          'text': '><https://hub.docker.com/repository/docker/raphacps/smart-slack-notification-pipe|smart-slack-notification 1.0.0>'
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

notify_slack_list
###end program