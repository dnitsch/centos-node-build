FROM centos:7

RUN  cp /usr/share/zoneinfo/Europe/London /etc/localtime
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
RUN sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

RUN yum update -y
RUN yum install -y wget zip unzip

ENV NVM_PATH "creationix/nvm/v0.33.4/install.sh"
ENV NVM_DIR  "/root/.nvm"
ENV NODE_VERSION_NG 10.15.1
ENV NPM_VERSION_NG 6.7.0

WORKDIR /opt/scripts

# Install NPM, Grunt and Bower
RUN wget -qO- https://raw.githubusercontent.com/${NVM_PATH} | bash && \
    . $NVM_DIR/nvm.sh && \
    nvm install $NODE_VERSION_NG && \
    nvm alias default $NODE_VERSION_NG && \
    nvm use default && \
    npm -g install npm@$NPM_VERSION_NG && \
    npm -g install grunt bower

RUN yum install -y git
RUN cd /usr/local/src
RUN yum groupinstall -y 'Development Tools'

RUN git clone https://github.com/sass/sassc.git \
    && git clone https://github.com/sass/libsass.git

RUN . sassc/script/bootstrap
RUN SASS_LIBSASS_PATH=`pwd`/libsass make -C sassc -j4
RUN sassc/bin/sassc  --version \
    && cp sassc/bin/sassc /usr/local/bin/sassc

RUN yum groupremove -y 'Development Tools'