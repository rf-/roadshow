FROM bash
RUN mkdir -p /scenario
WORKDIR /scenario
ENV LANG=C.UTF-8
CMD echo 'overridden command' && echo $ENV_VAR
