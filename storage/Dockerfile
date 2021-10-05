# based on https://github.com/BretFisher/node-docker-good-defaults/blob/main/Dockerfile
FROM node:16.10.0-alpine

ARG SOURCE_DIR=./storage

ARG NODE_ENV=production
ENV NODE_ENV $NODE_ENV
ENV TZ=Europe/Amsterdam

RUN apk update && apk upgrade && \
    apk add --no-cache bash openssh tzdata curl

RUN npm i npm@latest -g

RUN mkdir /opt/node_app && chown node:node /opt/node_app
WORKDIR /opt/node_app

USER node

COPY --chown=node:node $SOURCE_DIR/package.json $SOURCE_DIR/package-lock.json* ./
RUN npm install --no-optional && npm cache clean --force
ENV PATH /opt/node_app/node_modules/.bin:$PATH

HEALTHCHECK --start-period=2s --interval=5s --retries=5 CMD node healthcheck.js

WORKDIR /opt/node_app/app
COPY --chown=node:node $SOURCE_DIR .

COPY $SOURCE_DIR/docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD [ "node", "./bin/app" ]