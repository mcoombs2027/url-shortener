ARG node_version=18
ARG node_image=node:${node_version}-alpine

FROM $node_image as builder

RUN mkdir /app

WORKDIR /app

RUN yarn install --frozen-lockfile --no-progress --ignore-scripts

RUN yarn build

# ---------------

FROM $node_image

RUN apk update && apk upgrade
RUN npm uninstall npm -g

WORKDIR /app/

CMD yarn start