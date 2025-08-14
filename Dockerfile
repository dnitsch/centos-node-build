FROM centos:7

RUN  cp /usr/share/zoneinfo/Europe/London /etc/localtime
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
RUN sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

RUN yum update -y
RUN yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN yum -y install https://rpms.remirepo.net/enterprise/remi-release-7.rpm
RUN yum -y install yum-utils
RUN yum-config-manager --enable remi-php82
RUN yum update -y
RUN yum install -y php php-cli

RUN yum install -y wget mysql openssh-clients
RUN yum -y install yum-utils
RUN wget http://getcomposer.org/installer -P /tmp
RUN cat "/tmp/installer" | php -d allow_url_fopen=On
RUN php -v
RUN php -m
RUN mv composer.phar /usr/local/bin/composer && rm -rf /tmp/installer
RUN yum install zip unzip -y

ENV PHP_PACKAGES "php-gd \
                  php-intl php-mysqlnd  \
                  php-pear php-pecl-mongodb php-pecl-mysql \
                  php-pecl-wddx php-pecl-zip php-pecl-xdebug \
                  php-soap php-xml php-xmlrpc php-bcmath"

RUN yum install -y $PHP_PACKAGES

ENV NVM_PATH "creationix/nvm/v0.33.4/install.sh"
ENV NVM_DIR  "/root/.nvm"
ENV NODE_VERSION_NG 10.15.1
ENV NODE_VERSION_DASHBOARD 10.15.1
ENV NODE_VERSION_NGAS 6.9.5
ENV NPM_VERSION_NG 6.7.0
ENV NPM_VERSION_DASHBOARD 6.7.0
ENV NPM_VERSION_NGAS 6.7.0

# Install NPM, Grunt and Bower
RUN wget -qO- https://raw.githubusercontent.com/${NVM_PATH} | bash && \
    . $NVM_DIR/nvm.sh && \
    nvm install $NODE_VERSION_DASHBOARD && \
    nvm install $NODE_VERSION_NG && \
    nvm install $NODE_VERSION_NGAS && \
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

# Install drush for legacy and ng
RUN wget http://ftp.drupal.org/files/projects/drush-7.x-5.9.tar.gz && \
    mkdir /opt/drush && tar -zxf drush-7.x-5.9.tar.gz -C /opt/drush && \
    ln -sf /opt/drush/drush/drush /usr/bin/drush7 && \
    rm drush-7.x-5.9.tar.gz && \
    composer global require drush/drush:8.1.13 && \
    ln -s ~/.composer/vendor/drush/drush/drush /usr/bin/drush8

# For BitBucket clone
RUN mkdir /root/.ssh
RUN chmod 700 /root/.ssh
RUN ssh-keyscan -H bitbucket.org > /root/.ssh/known_hosts

COPY ./infra/etc /etc

# 'Install MongoDB client'
RUN yum install -y mongodb-org

WORKDIR /opt/scripts
# Create non-root user
RUN useradd -m -s /bin/bash appuser && \
    chown -R appuser:appuser /opt/scripts

# Set working directory for appuser
WORKDIR /home/appuser

# Switch to non-root user
USER appuser