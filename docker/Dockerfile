FROM erlang:26-alpine

WORKDIR /app
COPY . .

RUN apk add --no-cache bash git build-base wget \
  && adduser -D -u 1000 aaa-user \
  && wget -qO- https://github.com/erlang/rebar3/releases/download/3.23.0/rebar3 \
       | install -m 0755 /dev/stdin /usr/local/bin/rebar3 \
  && rebar3 clean \
  && rebar3 as prod release

# Diameter identity
ENV AAA_ORIGIN_REALM="mnc001.mcc001.3gppnetwork.org"

# SWm server (ePDG connects here)
ENV AAA_SWM_PORT="3868"
ENV AAA_SWM_TRANSPORT="tcp"

# SWx client (toward HSS via DRA)
ENV DRA_HOST="dra-diameter"
ENV DRA_PORT="3868"
ENV DRA_TRANSPORT="tcp"

# S6b server (PGW connects here)
ENV AAA_S6B_PORT="3869"
ENV AAA_S6B_TRANSPORT="tcp"

# PLMN
ENV MCC="001"
ENV MNC="01"

# HTTP API
ENV AAA_API_PORT="8080"

RUN mkdir -p /data && chown aaa-user:aaa-user /data

EXPOSE 3868 3869 8080

USER aaa-user
CMD ["/app/_build/prod/rel/aaa_server/bin/aaa_server", "foreground"]
