# meter-chel_infra
meter-chel Infra repository

# HomeWork #5 Знакомство с облачной инфраструктурой и облачными сервисами

bastion_IP = 130.193.58.17
someinternalhost_IP = 10.128.0.24


## Cоздание учетной записи в Yandex
Привязка аккаунта к Yandex.Cloud
Создано новое облако cloud-otus-meter
Создан новый каталог infra
Генерация пары ключей ssh-keygen (было сделано ранее их и использую)

Создана VM bastion с ОС Ubuntu 16.04 lts
задан публичный адрес, логин meter и публичный ключ
доступ к консоли тоже разрешил

Создана VM someinternalhost с ОС Ubuntu 16.04 lts
с внутренним адресом, логин meter, публичный ключ
и доступ к консоли разрешен

зашел снаружи на bastion
```
ssh -i ~/.ssh/id_rsa meter@130.193.58.17
```
ок

как велит мануал на странице 11.1 сделал
```
ssh meter@10.128.0.24
```
ожидаемо был послан

### настройка SSH forwarding
на локальной машине
```
ssh-add -L
```
добавить приватный ключ в SSH агент
```
ssh-add ~/.ssh/id_rsa
```

Вход
```
ssh -i ~/.ssh/id_rsa -A meter@130.193.58.17
```
и
```
ssh meter@10.128.0.24
```
и ок т.к. `hostname` = `someinternalhost` и `ip a show eth0`
```
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether d0:0d:bd:7d:99:80 brd ff:ff:ff:ff:ff:ff
    inet 10.128.0.24/24 brd 10.128.0.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::d20d:bdff:fe7d:9980/64 scope link
       valid_lft forever preferred_lft forever
```
проверил на бастионе
```
ls -la ~/.ssh
```
ключей нет

https://130.193.58.17/setup

### На хосте bastion выполняем команды (стр 13.2)
```
su
cat <<EOF> setupvpn.sh
#!/bin/bash
echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.4.list
echo "deb http://repo.pritunl.com/stable/apt xenial main" > /etc/apt/sources.list.d/pritunl.list
apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv 0C49F3730359A14518585931BC711F9BA15703C6
apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv 7568D9BB55FF9E5287D586017AE645C0CF8E292A
apt-get --assume-yes update
apt-get --assume-yes upgrade
apt-get --assume-yes install pritunl mongodb-org
systemctl start pritunl mongod
systemctl enable pritunl mongod
EOF
```

Выполняется скрипт установки mongodb и VPN-cервера pritunl
`bash setupvpn.sh`

Открываем в браузере ссылку: https://130.193.58.17/setup

Ошибку SSL пропускаем и доверяем этому сайту. Cледуем инструкциям на экране
```
pritunl setup-key
```
1ffddabf025d4761921096c348b3f088 - полученный ключ в строку ввода

адрес: `mongodb://localhost:27017/pritunl`

### Сгенерирован пароль на страницу ввода

```
username: "pritunl"
password: "Y9RjnMR7TphT"
```
После появилась форма смены имени и пароля, оставил старые

Добавил организацию `meter-otus`
Добавил пользователя `test` с PIN 6214157507237678334670591556762
Добавил сервер `meterVPN` порт `14608 udp Virtual Network 192.168.235.0/24` и привязал его к организации meter-otus

Скачал конфигурационный файл meter-otus_test_meterVPN.ovpn
ЗАПУСТИТЬ СЕРВЕР ТОЖЕ НУЖНО!!!!

### НА РАБОЧЕМ ХОСТЕ установить openvpn:
установка openvpn
```
apt install openvpn

openvpn --config meter-otus_test_meterVPN.ovpn
```
логин test пароль 6214157507237678334670591556762```

`ssh -i ~/.ssh/id_rsa meter@10.128.0.24`

подтверждение: `hostname = someinternalhost`

## Доп задание
Предложить вариант решения для подключения из консоли при помощи команды вида ssh someinternalhost из локальной консоли рабочего устройства
```
~/.ssh файл config

host bastion
ForwardAgent yes
hostname 130.193.58.17
user meter

host someinternalhost
HostName 10.128.0.24
User meter
ProxyCommand ssh -W %h:%p meter@130.193.58.17

meter@someinternalhost:~$ hostname
someinternalhost
```
Выполнено

## Сертификат
В настройках pritunl Server в поле Lets Encrypt Domain добавить
```
130.193.58.17.sslip.io
130.193.58.17.xip.io
```
но не сработало
```
"detail": "Error creating new order :: too many certificates already issued for: xip.io: see https://letsencrypt.org/docs/rate-limits/"
```
50 сертификатов на домен в неделю...```

HomeWork 6 Деплой тестового приложения

testapp_IP = 130.193.46.147
testapp_port = 9292

Установка curl
apt install curl

Интерактивная установка CLI
https://cloud.yandex.ru/docs/cli/operations/install-cli#interactive

curl https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
Скрипт установит CLI и добавит путь до исполняемого файла в переменную окружения PATH.

После завершения установки перезапустить командную оболочку.
exec -l $SHELL

Создание профиля
https://cloud.yandex.ru/docs/cli/operations/profile/profile-create

токен
AgAAAABKx-eaAATuwd9nKf9Wy0clsNmFjQQWXJM

настройка профиля
yc init

посмотреть что получилось
yc config list

Убедитесь, что ваш профиль в состоянии ACTIVE
yc config profilelist


Создаем новый инстанс
Используем CLI для создания инстанса, для проверки корректности
работы CLI после настройки

yc compute instance create \
  --name reddit-app \
  --hostname reddit-app \
  --memory=4 \
  --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB \
  --network-interface subnet-name=default-ru-central1-c,nat-ip-version=ipv4 \
  --metadata serial-port-enable=1 \
  --ssh-key ~/.ssh/id_rsa.pub

в профиль ssh доступ на новую машину, только пользователь yc-user

Обновляем APT и устанавливаем Ruby и Bundler:
apt update
apt install -y ruby-full ruby-bundler build-essential


Проверяем Ruby и Bundler
ruby -v
ruby 2.3.1p112 (2016-04-26) [x86_64-linux-gnu]
bundler -v
Bundler version 1.11.2

Устанавливаем MongoDB
Добавляем ключи и репозиторий MongoDB.

wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.2.list

Обновим индекс доступных пакетов и установим нужный пакет:
apt-get update
apt-get install -y mongodb-org


Запускаем MongoDB:
systemctl start mongod

Добавляем в автозапуск:
systemctl enable mongod

Проверяем работу MongoDB
systemctl status mongod


Деплой приложения
Копируем код
git clone -b monolith https://github.com/express42/reddit.git

Переходим в директорию проекта и устанавливаем зависимости приложения:
cd reddit && bundle install

Запускаем сервер приложения в папке проекта:
puma -d

Проверьте что сервер запустился и на каком порту он слушает:
ps aux | grep puma

Проверка работы
http://130.193.46.147:9292/

Изменил в /etc/mongod.conf - теперь слушает все порты
net:
  port: 27017
  bindIp:0.0.0.0 (было 127.0.0.1)

перезапустил VM
