# Python 3.10 이미지를 기반으로 생성
FROM python:3.10

# 필수 패키지 설치
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    ca-certificates \
    software-properties-common \
    firefox-esr \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# GeckoDriver 설치
RUN GECKODRIVER_VERSION=$(curl -sS https://api.github.com/repos/mozilla/geckodriver/releases/latest | grep "tag_name" | cut -d '"' -f 4) && \
    wget -q "https://github.com/mozilla/geckodriver/releases/download/${GECKODRIVER_VERSION}/geckodriver-${GECKODRIVER_VERSION}-linux64.tar.gz" -O /tmp/geckodriver.tar.gz && \
    tar -xvzf /tmp/geckodriver.tar.gz -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/geckodriver && \
    rm /tmp/geckodriver.tar.gz

# cron 및 tzdata 설치
RUN apt-get update && \
    apt-get install -y cron tzdata && \
    rm -rf /var/lib/apt/lists/*

# 시간대 설정
ENV TZ=Asia/Seoul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

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