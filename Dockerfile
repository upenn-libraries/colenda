FROM pennlib/passenger-ruby23:0.9.23-ruby-build

# Expose Nginx HTTP service
EXPOSE 80

# Expose ssh port for git commands
EXPOSE 22

# For SMTP
EXPOSE 25

RUN add-apt-repository ppa:jtgeibel/ppa

RUN apt-get update && apt-get install -qq -y --no-install-recommends \
        build-essential \
        default-jdk \
        git-annex \
        git-core \
        imagemagick \
        libmysqlclient-dev \
        netbase \
        nodejs \
        openssh-server \
        sudo \
        vim \
        xsltproc

# Remove default generated SSH keys to prevent use in production
RUN rm /etc/ssh/ssh_host_*

RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"

# The base phusion passenger-ruby image keeps the nginx logs within the container
# and then forwards them to stdout/stderr which causes bloat. Instead
# we want to redirect logs to stdout and stderr and defer to Docker for log handling.

# Solution from: https://github.com/phusion/passenger-docker/issues/72#issuecomment-493270957
# Disable nginx-log-forwarder because we just use stderr/stdout, but
# need to remove the "sv restart" line in the nginx run command too.
RUN touch /etc/service/nginx-log-forwarder/down && \
    sed -i '/nginx-log-forwarder/d' /etc/service/nginx/run

# Forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

RUN echo "export VISIBLE=now" >> /etc/profile

RUN mkdir -p /home/app/webapp

RUN mkdir -p /home/app/webapp/log

RUN mkdir -p /home/app/webapp/tmp

RUN mkdir -p /fs

RUN mkdir -p /fs/pub

RUN mkdir -p /fs/pub/data

RUN mkdir -p /fs/priv

RUN mkdir -p /fs/priv/workspace

RUN mkdir -p /fs/automate

RUN mkdir -p /fs/automate_kaplan

RUN mkdir -p /fs/automate_pap

RUN mkdir -p /home/app/webapp/string_exts

RUN mkdir -p /home/app/webapp/rails_admin_colenda

RUN mkdir -p /etc/my_init.d

ADD docker/gitannex.sh /etc/my_init.d/gitannex.sh

ADD docker/imaging.sh /etc/my_init.d/imaging.sh

ADD docker/ssh_service.sh /etc/my_init.d/ssh_service.sh

RUN chmod 0700 \
  /etc/my_init.d/gitannex.sh \
  /etc/my_init.d/imaging.sh \
  /etc/my_init.d/ssh_service.sh

RUN chown -R app:app /fs

WORKDIR /home/app/webapp

COPY Gemfile Gemfile.lock /home/app/webapp/

ADD rails_admin_colenda /home/app/webapp/rails_admin_colenda

ADD string_exts /home/app/webapp/string_exts

RUN bundle install

COPY . /home/app/webapp/

CMD bundle update --source hydra && bundle update --source rails_admin

RUN RAILS_ENV=production SECRET_KEY_BASE=x bundle exec rake assets:precompile --trace

RUN rm -f /etc/service/nginx/down

RUN rm /etc/nginx/sites-enabled/default

USER app

RUN git config --global user.email 'docker-user@example.com'

RUN git config --global user.name 'Docker User'

USER root

ADD webapp.conf /etc/nginx/sites-enabled/webapp.conf

ADD rails-env.conf /etc/nginx/main.d/rails-env.conf

RUN wget https://www.incommon.org/custom/certificates/repository/sha384%20Intermediate%20cert.txt --output-document=/etc/ssl/certs/InCommon.pem --no-check-certificate

# Clean up APT and bundler when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

CMD ["/usr/sbin/sshd", "-D"]

CMD ["/sbin/my_init"]
