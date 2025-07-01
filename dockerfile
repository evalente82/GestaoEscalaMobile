# --- ESTÁGIO 1: Build ---
FROM debian:12-slim AS build

RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

ARG FLUTTER_VERSION=3.22.2
RUN curl -fSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" -o flutter.tar.xz \
    && tar -xJf flutter.tar.xz -C /opt/ \
    && rm flutter.tar.xz

ENV PATH="/opt/flutter/bin:${PATH}"
RUN git config --global --add safe.directory /opt/flutter
RUN flutter doctor

WORKDIR /app

# Ignora o pubspec.lock local para resolver as dependências no ambiente de build
COPY pubspec.yaml ./
RUN flutter pub get

COPY . .
RUN flutter build web

# --- ESTÁGIO 2: Produção ---
FROM nginx:alpine

RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 3000