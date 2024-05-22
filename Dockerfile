ARG node_version=18
ARG node_image=node:${node_version}-alpine

FROM $node_image as builder

RUN mkdir /app

WORKDIR /app

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile --no-progress --ignore-scripts

COPY next.config.mjs .
COPY tsconfig.json .
COPY postcss.config.js .
COPY tailwind.config.ts .
COPY public/ ./public/
COPY src/ ./src/

RUN yarn build

# ---------------

FROM $node_image

RUN apk update && apk upgrade
RUN npm uninstall npm -g

ENV NODE_ENV=production

WORKDIR /app/

COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/next.config.mjs ./
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./

CMD yarn start