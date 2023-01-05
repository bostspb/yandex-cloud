# Синхронизация данных из MySQL

## Настройка рабочего окружения
https://cloud.yandex.ru/docs/cli/quickstart

Установливаем CLI
```bash
# PowerShell
iex (New-Object System.Net.WebClient).DownloadString('https://storage.yandexcloud.net/yandexcloud-yc/install.ps1')
```

Создаем профиль CLI, предварительно получив OAuth-токен в сервисе Яндекс.OAuth
```bash
yc init

yc config list
token: *****************************
cloud-id: b1ge0rv3msqdmrki2otu
folder-id: b1g7uigodj2tqaohibio

```

## Настройка синхронизации

Создаем виртуальный диск из образа с предварительно настроенной платформой интернет-магазина `magento`
(указываем свой `folder-id`).
```bash
yc compute disk create \
    --zone ru-central1-a \
    --name web-store-lab-dataplatform \
    --source-image-id fd86cb7ugap89m9ja920 \
    --folder-id b1g7uigodj2tqaohibio
```

Генерируем SSH-ключи по адресу `C:\Users\Zakhar/.ssh/yandex-cloud`
```bash
ssh-keygen -t ed25519
```

Создаем виртуальную машину
```bash
yc compute instance create \
    --name magento \
    --zone ru-central1-a \
    --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
    --hostname ya-sample-store \
    --use-boot-disk disk-name=web-store-lab-dataplatform \
    --folder-id b1g7uigodj2tqaohibio \
    --ssh-key ~/.ssh/yandex-cloud.pub 
```

Настраиваем параметры группы безопасности сети - открываем порты 22, 80 и 443 
(на момент прохождения курса данная функциональность не активна)

Проверяем подключение к виртуальной машине
```bash
ssh yc-user@51.250.86.232
```

Правим файл `C:\Windows\System32\drivers\etc\hosts` - добавляем строку 
`51.250.86.232 ya-sample-store.local`. 
Затем проверяем доступность сайта интернет-магазина - http://ya-sample-store.local

Подключаемся к БД интернет-магазина:
```
Host: 51.250.86.232:3306
DB Name: ya_sample_store
User: magento-svc
Password: m@gent0
```

Для реплицирования таблиц создаем кластер Managed Service for MySQL через веб-консоль Yandex Cloud:
- заходим в раздел Managed Service for MySQL внутри нашего каталога
- создаем кластер `ya-sample-cloud-mysql`, класс хоста `s2.small` (4 cores vCPU, 16 ГБ)
- указываем хранилище `network-ssd` 32 ГБ
- БД `magento-cloud`, пользователь `yc-user`, пароль `12345678`
- В сетевых настройках выбераем облачную сеть:
    - Зона доступности: `ru-central1-a`
    - Подсеть: `default-ru-central1-a`

Настраиваем Data Transfer:
- заходим в сервис  Yandex Data Transfer и создаем трансфер `sales-order-sync` и указываем эндпоинты:
    - Источник: `magento-source` с параметрами подключения от БД интернет-магазина `magento-svc`
    - Приемник: `magento-report-dest` с параметрами подключения к БД `magento-cloud` (отключаем проверку ограничений)
- указываем тип трансфера `Копировать и реплицировать` с копированием один раз
- активируем трансфер

Через веб-консоль в разделе Managed Service for MySQL заходим в консоль SQL и подключаемся к БД `magento-cloud`.
Убеждаемся, что схемы и данные перенеслись.

Проверяем работу репликации - создаем заказ на сайте интернет-магазина и смотрим его наличие в обоих БД:
```mysql-sql
SELECT so.*, soi.* 
FROM sales_order_grid so
INNER JOIN sales_order_item soi ON so.entity_id = soi.order_id
ORDER BY entity_id DESC
LIMIT 5 
```

Результат - заказ присутствует в обоих базах.
