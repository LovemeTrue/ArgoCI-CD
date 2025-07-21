# Требования

kubernetes, helm v3, установленный чарт elma365-dbs или собственные базы данных PostgreSQL, MongoDB, Redis, RabbitMQ, хранилище S3, указав строки подключения к ним values

# Установка

- заполнить переменные в файле `values-elma365.yaml`
- выполнить `helm install elma365 ./elma365 -f values-elma365.yaml --timeout=30m --wait [-n namespace]`
- сохранить файл `values-elma365.yaml` для последующих обновлений

# Обновление
- заменить файл `values-elma365.yaml` сохранённым файлом с момента установки
- выполнить `helm upgrade elma365 ./elma365 -f values-elma365.yaml --timeout=30m --wait [-n namespace]`