FROM centos:7
MAINTAINER hfm.garden@gmail.com

RUN yum -y -q install bison gcc git make rake rpmdevtools wget which
ADD mysql-community-common-5.7.13-1.el7.x86_64.rpm /tmp/mysql-community-common-5.7.13-1.el7.x86_64.rpm
ADD mysql-community-libs-5.7.13-1.el7.x86_64.rpm /tmp/mysql-community-libs-5.7.13-1.el7.x86_64.rpm
ADD mysql-community-devel-5.7.13-1.el7.x86_64.rpm /tmp/mysql-community-devel-5.7.13-1.el7.x86_64.rpm
RUN rpm -U /tmp/mysql-community-common-5.7.13-1.el7.x86_64.rpm && rm /tmp/mysql-community-common-5.7.13-1.el7.x86_64.rpm
RUN rpm -U /tmp/mysql-community-libs-5.7.13-1.el7.x86_64.rpm && rm /tmp/mysql-community-libs-5.7.13-1.el7.x86_64.rpm
RUN rpm -U /tmp/mysql-community-devel-5.7.13-1.el7.x86_64.rpm && rm /tmp/mysql-community-devel-5.7.13-1.el7.x86_64.rpm

RUN rpmdev-setuptree

# Get nginx
ENV NGINX_VERSION 1.11.2
RUN wget -q http://nginx.org/packages/mainline/centos/7/SRPMS/nginx-$NGINX_VERSION-1.el7.ngx.src.rpm -P /tmp
RUN rpm -U /tmp/nginx-$NGINX_VERSION-1.el7.ngx.src.rpm
RUN yum-builddep -y -q /tmp/nginx-$NGINX_VERSION-1.el7.ngx.src.rpm

# Get OpenSSL
ENV OPENSSL_VERSION 1.0.2
RUN mkdir /usr/local/src/openssl && \
    wget -qO- https://www.openssl.org/source/openssl-$OPENSSL_VERSION-latest.tar.gz | \
    tar -xz -C /usr/local/src/openssl --strip=1

# Get ngx_mruby
ENV NGX_MRUBY_VERSION 1.18.2
RUN mkdir /usr/local/src/ngx_mruby && \
    wget -qO- https://github.com/matsumoto-r/ngx_mruby/archive/v$NGX_MRUBY_VERSION.tar.gz | \
    tar -xz -C /usr/local/src/ngx_mruby --strip=1

# build ngx_mruby with static-linked openssl
WORKDIR /usr/local/src/ngx_mruby
RUN ./configure -q --with-ngx-src-root=/root/rpmbuild/BUILD/nginx-$NGINX_VERSION --with-openssl-src=/usr/local/src/openssl
ADD build_config.rb /usr/local/src/ngx_mruby/build_config.rb
RUN make -s build_mruby
RUN make -s generate_gems_config

# rpmbuild
WORKDIR /root/rpmbuild/SPECS
ADD nginx.spec.patch /root/rpmbuild/SPECS/nginx.spec.patch
RUN patch -p0 < nginx.spec.patch
RUN rpmbuild -ba nginx.spec
