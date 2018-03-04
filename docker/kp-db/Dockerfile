# СУБД kopnik.org
#
# собрать образ
# docker image build -t alexey2baranov/kp-db .
#
# выгрузить образ
# docker login
# docker push alexey2baranov/kp-db .

FROM postgres

#mc на всякий случай
RUN apt-get update && apt-get install -y mc

# Этот скрипт вызывается контейнером автоматически и создает три БД:
# боевую kopnik, разработки dev и тестов test
COPY ./init-user-db.sql /docker-entrypoint-initdb.d