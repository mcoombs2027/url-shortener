FROM node:20-alpine AS base

# Setup env variabless for yarn and nextjs
# https://nextjs.org/telemetry
ENV NEXT_TELEMETRY_DISABLED=1 NODE_ENV=production YARN_VERSION=4.2.1

RUN apk update && apk upgrade && apk add --no-cache libc6-compat

# install and use yarn 4.x
RUN corepack enable && corepack prepare yarn@${YARN_VERSION}



# Installing all the dependencies
# We clean up dependency size via Next's standalone build mode
# https://nextjs.org/docs/app/api-reference/next-config-js/output
RUN yarn install --immutable



RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001


USER nextjs

