
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Dockerfile for installing the necessary dependencies for building Hadoop.
# See BUILDING.txt.

#
# start with ubuntu:xenial (aka 16.04 LTS) for OpenJDK 8
#
FROM ppc64le/ubuntu:xenial

WORKDIR /root

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_TERSE true

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

######
# Install common dependencies from packages
#
# WARNING: DO NOT PUT JAVA APPS HERE! Otherwise they will install default
# Ubuntu Java.  See Java section below!
######
RUN apt-get -q update && apt-get -q install --no-install-recommends -y \
    build-essential 

RUN apt-get -q install --no-install-recommends -y bzip2

RUN apt-get -q install --no-install-recommends -y cmake 
RUN apt-get -q install --no-install-recommends -y    curl 
RUN apt-get -q install --no-install-recommends -y doxygen 
RUN apt-get -q install --no-install-recommends -y fuse 
RUN apt-get -q install --no-install-recommends -y    g++ 
RUN apt-get -q install --no-install-recommends -y    gcc 
RUN apt-get -q install --no-install-recommends -y    git 
RUN apt-get -q install --no-install-recommends -y    gnupg-agent 
RUN apt-get -q install --no-install-recommends -y    make 
RUN apt-get -q install --no-install-recommends -y    libbz2-dev 
RUN apt-get -q install --no-install-recommends -y    libcurl4-openssl-dev 
RUN apt-get -q install --no-install-recommends -y    libfuse-dev 
RUN apt-get -q install --no-install-recommends -y    libsnappy-dev 
RUN apt-get -q install --no-install-recommends -y    libssl-dev 
RUN apt-get -q install --no-install-recommends -y    libtool 
RUN apt-get -q install --no-install-recommends -y    pinentry-curses 
RUN apt-get -q install --no-install-recommends -y    pkg-config
RUN apt-get -q install --no-install-recommends -y    python 
RUN apt-get -q install --no-install-recommends -y    python2.7 
RUN apt-get -q install --no-install-recommends -y    python-pip 
RUN apt-get -q install --no-install-recommends -y    rsync 
RUN apt-get -q install --no-install-recommends -y    snappy 
RUN apt-get -q install --no-install-recommends -y    zlib1g-dev

######
# protobuf 2.5.0 isn't available in Xenial, so grab the source from Trusty (14.04) and recompile
####

RUN curl -L -s -S -O https://launchpad.net/ubuntu/+source/protobuf/2.5.0-9ubuntu1/+build/5604345/+files/libprotobuf8_2.5.0-9ubuntu1_ppc64el.deb
RUN curl -L -s -S -O https://launchpad.net/ubuntu/+source/protobuf/2.5.0-9ubuntu1/+build/5604345/+files/libprotoc8_2.5.0-9ubuntu1_ppc64el.deb
RUN curl -L -s -S -O https://launchpad.net/ubuntu/+source/protobuf/2.5.0-9ubuntu1/+build/5604345/+files/protobuf-compiler_2.5.0-9ubuntu1_ppc64el.deb
RUN dpkg -i libprotobuf8_2.5.0-9ubuntu1_ppc64el.deb libprotoc8_2.5.0-9ubuntu1_ppc64el.deb protobuf-compiler_2.5.0-9ubuntu1_ppc64el.deb
RUN rm libprotobuf8_2.5.0-9ubuntu1_ppc64el.deb libprotoc8_2.5.0-9ubuntu1_ppc64el.deb protobuf-compiler_2.5.0-9ubuntu1_ppc64el.deb

#######
# OpenJDK Java
#######

RUN apt-get install -y software-properties-common
RUN apt-get -q install -y openjdk-8-jdk
RUN update-ca-certificates -f

####
# Apps that require Java
###
RUN apt-get -q update && apt-get -q install --no-install-recommends -y \
    ant \
    findbugs \
    maven

######
# Install findbugs
######
RUN mkdir -p /opt/findbugs && \
    curl -L -s -S \
         https://sourceforge.net/projects/findbugs/files/findbugs/3.0.1/findbugs-noUpdateChecks-3.0.1.tar.gz/download \
         -o /opt/findbugs.tar.gz && \
    tar xzf /opt/findbugs.tar.gz --strip-components 1 -C /opt/findbugs
ENV FINDBUGS_HOME /opt/findbugs

####
# Install shellcheck
####
RUN apt-get -q install -y cabal-install
RUN mkdir /root/.cabal
RUN echo "remote-repo: hackage.fpcomplete.com:http://hackage.fpcomplete.com/" >> /root/.cabal/config
#RUN echo "remote-repo: hackage.haskell.org:http://hackage.haskell.org/" > /root/.cabal/config
RUN echo "remote-repo-cache: /root/.cabal/packages" >> /root/.cabal/config
RUN cabal update
RUN cabal install shellcheck --global

####
# Install bats
####
RUN add-apt-repository -y ppa:duggan/bats
RUN apt-get -q update
RUN apt-get -q install --no-install-recommends -y bats

####
# Install pylint
####
RUN pip install setuptools
RUN pip install pylint

####
# Install dateutil.parser
####
RUN pip install python-dateutil

###
# Avoid out of memory errors in builds
###
ENV MAVEN_OPTS -Xms256m -Xmx512m

###
# Everything past this point is either not needed for testing or breaks Yetus.
# So tell Yetus not to read the rest of the file:
# YETUS CUT HERE
###

####
# Install Forrest (for Apache Hadoop website)
###
RUN mkdir -p /usr/local/apache-forrest ; \
    curl -s -S -O http://archive.apache.org/dist/forrest/0.8/apache-forrest-0.8.tar.gz ; \
    tar xzf *forrest* --strip-components 1 -C /usr/local/apache-forrest ; \
    echo 'forrest.home=/usr/local/apache-forrest' > build.properties

# Add a welcome message and environment checks.
ADD hadoop_env_checks.sh /root/hadoop_env_checks.sh
RUN chmod 755 /root/hadoop_env_checks.sh
RUN echo '~/hadoop_env_checks.sh' >> /root/.bashrc

