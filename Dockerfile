ARG IMAGE=containers.intersystems.com/intersystems/iris-community:latest-em-linux-arm64
ARG IMAGE=containers.intersystems.com/intersystems/iris-community:latest-cd-linux-arm64
FROM $IMAGE
USER root
WORKDIR /app
RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /app
USER ${ISC_PACKAGE_MGRUSER}

COPY Installer.cls .
COPY src src
COPY iris.script /tmp/iris.script
COPY pdf /tmp/.
COPY requirements.txt .

USER ${ISC_PACKAGE_MGRUSER}

RUN pip3 install -r requirements.txt
RUN iris start IRIS \
	&& iris session IRIS < /tmp/iris.script \
    && iris stop IRIS quietly