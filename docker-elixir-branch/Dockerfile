FROM erlang:latest

ENV HOME /root

WORKDIR $HOME

ADD entrypoint.sh .
RUN chmod +x entrypoint.sh \
 && cp entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT [ "entrypoint.sh" ]
