#!/usr/bin/env bash

if [ -z "$1" ]
then
  echo "tag number parameter is missing...."
  exit 1
fi

docker build -t raphacps/smart-slack-notification-pipe:$1 .
docker push  raphacps/smart-slack-notification-pipe:$1