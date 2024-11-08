FROM python:3.10

# OpenJDK 설치 (예시로 OpenJDK 17을 설치)
RUN apt-get update && \
    apt-get install -y openjdk-17-jdk fonts-nanum build-essential libhdf5-dev && \
    apt-get install -y wget unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# JAVA_HOME 환경 변수 설정
ENV JAVA_HOME /usr/lib/jvm/java-17-openjdk-amd64

# Google Chrome 설치
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list' && \
    apt-get update && \
    apt-get install -y google-chrome-stable && \
    rm -rf /var/lib/apt/lists/*

# ChromeDriver 설치
RUN CHROMEDRIVER_VERSION=$(curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE) && \
    wget -q "https://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VERSION}/chromedriver_linux64.zip" && \
    unzip chromedriver_linux64.zip && \
    mv chromedriver /usr/local/bin/ && \
    rm chromedriver_linux64.zip

# 작업 디렉토리 설정
WORKDIR /app

ARG BRANCH_NAME=bepet_scraping
ARG DIR_NAME=bepet_scraping # 변경대상

# Git repository clone
RUN git clone https://github.com/nohjuhyeon/bepet_scraping ${DIR_NAME} # 변경대상
WORKDIR /app/${DIR_NAME}

# Requirements 설치
COPY requirements.txt /app/requirements.txt
WORKDIR /app
RUN pip install -r requirements.txt

# RUN rm -rf .git # 도커 만들어지고나면 주석처리하기
