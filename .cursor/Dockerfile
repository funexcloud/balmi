# Cloud Agent base image for the balmi Flutter app.
# Installs a pinned Flutter SDK and the minimal tools needed to run
# `flutter pub get`, `flutter analyze`, `flutter test`, and Drift code
# generation (`dart run build_runner build`).
#
# Repo source is checked out separately by Cursor after the image is built,
# so this file only provides stable system dependencies and the toolchain.
FROM ubuntu:24.04

# Pinned to match .metadata (Flutter revision 6655482ec0 / Dart 3.13.1),
# which is the version the project was created with and what pubspec.lock
# resolves against (flutter >= 3.44.0, dart >= 3.13.1).
ARG FLUTTER_VERSION=3.47.1
ARG FLUTTER_HOME=/opt/flutter

ENV DEBIAN_FRONTEND=noninteractive

# git + curl are required in fully custom images. unzip/xz-utils/ca-certificates
# are needed to fetch and extract the Flutter SDK and pub packages.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        unzip \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Install the pinned Flutter SDK into a system location owned by the agent user.
RUN curl -fsSL -o /tmp/flutter.tar.xz \
        "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    && mkdir -p "$(dirname "${FLUTTER_HOME}")" \
    && tar -xf /tmp/flutter.tar.xz -C "$(dirname "${FLUTTER_HOME}")" \
    && rm /tmp/flutter.tar.xz \
    && ln -s "${FLUTTER_HOME}/bin/flutter" /usr/local/bin/flutter \
    && ln -s "${FLUTTER_HOME}/bin/dart" /usr/local/bin/dart

ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

# The default Cloud Agent user. Give it ownership of the SDK so `flutter`
# (which shells out to git and writes to its own cache) works without root,
# then warm the engine artifacts needed to run tests headlessly.
RUN useradd -m -s /bin/bash ubuntu 2>/dev/null || true \
    && chown -R ubuntu:ubuntu "${FLUTTER_HOME}"

USER ubuntu

RUN git config --global --add safe.directory "${FLUTTER_HOME}" \
    && flutter config --no-analytics >/dev/null 2>&1 || true \
    && flutter precache --universal \
    && flutter --version
