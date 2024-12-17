# Python 3.10 이미지를 기반으로 생성
FROM python:3.10


# 최신 ChromeDriver 설치
RUN CHROMEDRIVER_VERSION=$(curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE) && \
    wget -q "https://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VERSION}/chromedriver_linux64.zip" && \
    unzip chromedriver_linux64.zip && \
    mv chromedriver /usr/local/bin/ && \
    rm chromedriver_linux64.zip

# Google Chrome 설치
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list' && \
    apt-get update && \
    apt-get install -y google-chrome-stable && \
    rm -rf /var/lib/apt/lists/*

# cron 및 tzdata, jdk 설치
RUN apt-get update && \
    apt-get install -y cron tzdata && \
    rm -rf /var/lib/apt/lists/*


    
# 시간대 설정
ENV TZ=Asia/Seoul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone


# download
RUN wget https://bitbucket.org/eunjeon/mecab-ko/downloads/mecab-0.996-ko-0.9.2.tar.gz

# 압축해제
RUN tar xvfz mecab-0.996-ko-0.9.2.tar.gz

# install 
RUN cd mecab-0.996-ko-0.9.2 && \
    ./configure && \
    make && \
    make check && \
    make install

RUN apt-get install autoconf automake

    # download
RUN wget https://bitbucket.org/eunjeon/mecab-ko-dic/downloads/mecab-ko-dic-2.1.1-20180720.tar.gz
    
    # 압축해제
RUN tar xvfz mecab-ko-dic-2.1.1-20180720.tar.gz
    
    # install 
# mecab-ko-dic 설치
# 필요한 패키지 설치
RUN apt-get update && apt-get install -y \
    build-essential \
    mecab \
    libmecab-dev \
    curl \
    xz-utils \
    file \
    git \
    automake \
    autoconf \
    libtool \
    pkg-config

# mecab-ko-dic 설치
RUN tar xvfz mecab-ko-dic-2.1.1-20180720.tar.gz && \
    cd mecab-ko-dic-2.1.1-20180720 && \
    ./configure && \
    ./autogen.sh && \
    make && \
    make install

# 공유 라이브러리 경로 설정
RUN echo "/usr/local/lib" > /etc/ld.so.conf.d/mecab.conf && \
    ldconfig

# 환경 변수 설정 (추가 안전장치)
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH



RUN git clone https://bitbucket.org/eunjeon/mecab-python-0.996.git &&\
    cd mecab-python-0.996 &&\
    python setup.py build &&\
    python setup.py install

COPY user-nnp.csv /mecab-ko-dic-2.1.1-20180720/user-dic/user-nnp.csv

# MeCab 사용자 사전 업데이트
RUN cd mecab-ko-dic-2.1.1-20180720 && \
    tools/add-userdic.sh && \
    make install

# 작업 디렉토리 설정
WORKDIR /app

ARG BRANCH_NAME=belab_scraping
ARG DIR_NAME=belab_scraping # 변경대상

# Git repository clone
RUN git clone https://github.com/nohjuhyeon/belab_scraping ${DIR_NAME} # 변경대상
WORKDIR /app/${DIR_NAME}

# Git 사용자 정보 설정
RUN git config --global user.email "njh2720@gmail.com"
RUN git config --global user.name "nohjuhyeon"

# Requirements 설치
COPY requirements.txt /app/requirements.txt
WORKDIR /app
RUN pip install -r requirements.txt

# Git 작업 자동화 스크립트 추가
COPY git_workflow.sh /app/${DIR_NAME}/function_list/git_workflow.sh
RUN chmod +x /app/${DIR_NAME}/function_list/git_workflow.sh

# crontab 파일 추가
COPY my_crontab /etc/cron.d/my_crontab

# crontab 권한 설정
RUN chmod 0644 /etc/cron.d/my_crontab

# crontab 적용
RUN crontab /etc/cron.d/my_crontab

# 로그 파일 생성
RUN touch /var/log/cron.log




# 컨테이너 시작 시 cron 실행
CMD ["cron", "-f"]
# RUN rm -rf .git # 도커 만들어지고나면 주석처리하기
