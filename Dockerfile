#
# Build image
#
FROM python:3.12 AS image-build

RUN apt update
RUN apt install -y --no-install-recommends \
    build-essential \
    gcc
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt



#
# Phorcys build image 
#
FROM python:3.12 AS image-phorcys

RUN apt update
RUN apt install -y --no-install-recommends \
    build-essential \
    python3-dev \
    protobuf-compiler \
    git \
    setuptools \
    wheel
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN git clone https://github.com/PiRanhaLysis/Phorcys.git
RUN cd Phorcys && \
    pip install --no-cache-dir -r requirements.txt && \
    python setup.py sdist bdist_wheel


#
# Production image
#
FROM python:3.12-slim

# Container settings
ENV APP_USER 'detector'
ENV APP_DIR '/home/detector'

# Add user
RUN useradd $APP_USER

# Install dependencies
RUN apt update && \
    apt install -y --no-install-recommends \
    protobuf-compiler \
    gcc \
    git && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# App settings
ENV DEBUG False
WORKDIR $APP_DIR
USER $APP_USER

# Python security
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV PIP_NO_CACHE_DIR 1

# Install venv from the build image
COPY --from=image-build /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install the app
COPY --chown=$APP_USER:$APP_USER ./detector.py $APP_DIR/detector.py

# Run the app
CMD ["python", "detector.py"]