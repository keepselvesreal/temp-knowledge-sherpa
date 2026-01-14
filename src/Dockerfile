FROM wordpress:latest

# 빌드 인자: 호스트 사용자의 UID/GID
ARG UID
ARG GID

# www-data 사용자를 호스트 UID/GID와 동일하게 설정
RUN groupmod -g ${GID} www-data && \
    usermod -u ${UID} -g ${GID} www-data && \
    chown -R ${UID}:${GID} /var/www/html

# www-data 사용자로 실행
USER www-data

EXPOSE 80

CMD ["apache2-foreground"]
