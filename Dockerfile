FROM alpine:3.11.3

RUN apk add --update --no-cache bash

COPY pipe /
COPY LICENSE.txt pipe.yml README.md /
RUN wget -P / https://bitbucket.org/bitbucketpipelines/bitbucket-pipes-toolkit-bash/raw/0.4.0/common.sh

RUN chmod a+x /*.sh

RUN apk add --no-cache curl

ENTRYPOINT ["/pipe.sh"]
