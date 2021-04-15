FROM rust:buster AS boringtun

RUN cargo install boringtun

FROM ubuntu

WORKDIR /root

COPY config/aliases .bash_aliases

RUN apt update && apt install -y ca-certificates wireguard git curl jq iproute2 net-tools iptables

COPY --from=boringtun /usr/local/cargo/bin/boringtun /usr/local/bin

COPY config/transmission.json transmission.json

RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime

RUN DEBIAN_FRONTEND=noninteractive apt install -y tzdata

RUN dpkg-reconfigure --frontend noninteractive tzdata

RUN apt install -y software-properties-common && add-apt-repository -y ppa:transmissionbt/ppa && apt update

RUN apt install -y transmission-cli transmission-common transmission-daemon

RUN service transmission-daemon reload

RUN echo "$(jq -s 'add' /var/lib/transmission-daemon/info/settings.json transmission.json)" > /var/lib/transmission-daemon/info/settings.json

RUN mkdir /transmission

VOLUME /transmission

RUN mkdir /transmission/complete /transmission/incomplete

RUN chown -R debian-transmission:debian-transmission /transmission/*

COPY scripts scripts

WORKDIR scripts

ENV WG_QUICK_USERSPACE_IMPLEMENTATION=boringtun

ENV WG_SUDO=1

ENV DISABLE_IPV6=yes

ENV VPN_PROTOCOL=wireguard

ENV PIA_PF=true

CMD ["./run_setup.sh"]
