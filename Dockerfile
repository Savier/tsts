FROM python:3.9-slim-buster as base

ENV PYTHONFAULTHANDLER=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
        apt-transport-https \
        build-essential \
        ca-certificates \
        curl \
        git \
        gnupg \
        jq \
        less \
        libpcre3 \
        libpcre3-dev \
        openssh-client \
        telnet \
        unzip \
        vim \
        wait-for-it \
        wget \
        python3-wheel \
        python3-cffi \
        libcairo2 \
        libpango-1.0-0 \
        libpangocairo-1.0-0 \
        libgdk-pixbuf2.0-0 \
        libffi-dev \
        shared-mime-info \
    && apt-get clean \
    && rm -rf /var/cache/apt/archives/* \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && truncate -s 0 /var/log/*log

RUN  \
  echo "deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main" > /etc/apt/sources.list.d/nodesource.list \
  && wget -qO- https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

RUN apt-get update -qq \
    &&  DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
         postgresql-client-12 \
    && apt-get clean \
    && rm -rf /var/cache/apt/archives/* \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && truncate -s 0 /var/log/*log

RUN curl -sSL https://install.python-poetry.org | python3 - --version 1.1.12

ENV PATH $PATH:/root/.local/bin

RUN poetry config virtualenvs.create false
ENV PATH $PATH:/root/.poetry/bin

WORKDIR /app

COPY pyproject.toml poetry.lock ./
RUN poetry install  --no-interaction --no-ansi

ADD . /app
ENV DJANGO_SETTINGS_MODULE="tsts.settings"

EXPOSE 8000

CMD uwsgi --http :8000 --module tsts.wsgi --enable-threads

FROM base as deliverable

ARG DJANGO_ENV
ARG DJANGO_SECRET_KEY

RUN DATABASE_NAME= \
    DATABASE_USER= \
    DATABASE_PASSWORD= \
    DATABASE_HOST= \
    DATABASE_PORT= \
    ./manage.py collectstatic --noinput

VOLUME ["/app/staticfiles"]

CMD uwsgi --http :8000 --module tsts.wsgi  --log-filter '^((?!/health_check).)*$' --enable-threads
