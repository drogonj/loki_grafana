FROM grafana/grafana:latest

USER root

RUN apk add --no-cache jq

COPY ./dashboards/ /etc/grafana/provisioning/dashboards/
COPY ./datasources/ /etc/grafana/provisioning/datasources/
COPY ./scripts/users_setup.sh /tmp/users_setup.sh

RUN chmod +x /tmp/users_setup.sh

USER grafana
