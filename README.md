# meter-chel_infra
meter-chel Infra repository


# Домашняя работа к лекции №5
# Знакомство с облачной инфраструктурой и облачными сервисами

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
xxxxxxxxxxxxxxxxxxxxxxxx - полученный ключ в строку ввода

адрес: `mongodb://localhost:27017/pritunl`

### Сгенерирован пароль на страницу ввода

```
username: "pritunl"
password: "------------"
```
После появилась форма смены имени и пароля, оставил старые

Добавил организацию `meter-otus`
Добавил пользователя `test` с PIN yyyyyyyyyyyyyyyyyyyyyyy
Добавил сервер `meterVPN` порт `14608 udp Virtual Network 192.168.235.0/24` и привязал его к организации meter-otus

Скачал конфигурационный файл meter-otus_test_meterVPN.ovpn
ЗАПУСТИТЬ СЕРВЕР ТОЖЕ НУЖНО!!!!

### НА РАБОЧЕМ ХОСТЕ установить openvpn:
установка openvpn
```
apt install openvpn

openvpn --config meter-otus_test_meterVPN.ovpn
```
логин test пароль yyyyyyyyyyyyyyyyyyyyyy```

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

# Домашняя работа к лекции №6
# Деплой тестового приложения

testapp_IP = 130.193.45.104
testapp_port = 9292

### Установка curl
```
apt install curl
```
### Интерактивная установка CLI
https://cloud.yandex.ru/docs/cli/operations/install-cli#interactive
```
curl https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
```
Скрипт установит CLI и добавит путь до исполняемого файла в переменную окружения PATH.

После завершения установки перезапустить командную оболочку.
```
exec -l $SHELL
```
## Создание профиля
https://cloud.yandex.ru/docs/cli/operations/profile/profile-create

токен
zzzzzzz-zzzzzzzzzzzzzzzzzz

настройка профиля
```
yc init
```
посмотреть что получилось
```
yc config list
```
Убедитесь, что ваш профиль в состоянии ACTIVE
```
yc config profilelist
```

## Создаем новый инстанс
Используем CLI для создания инстанса, для проверки корректности
работы CLI после настройки
```
yc compute instance create \
  --name reddit-app \
  --hostname reddit-app \
  --memory=4 \
  --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB \
  --network-interface subnet-name=default-ru-central1-c,nat-ip-version=ipv4 \
  --metadata serial-port-enable=1 \
  --ssh-key ~/.ssh/id_rsa.pub
```
в профиль ssh доступ на новую машину, только пользователь yc-user

## Обновляем APT и устанавливаем Ruby и Bundler:
```
apt update
apt install -y ruby-full ruby-bundler build-essential
```

Проверяем Ruby и Bundler
`ruby -v`
ruby 2.3.1p112 (2016-04-26) [x86_64-linux-gnu]
`bundler -v`
Bundler version 1.11.2

## Устанавливаем MongoDB
Добавляем ключи и репозиторий MongoDB.
```
wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.2.list
```
Обновим индекс доступных пакетов и установим нужный пакет:
```
apt-get update
apt-get install -y mongodb-org
```

### Запускаем MongoDB:
`systemctl start mongod`

Добавляем в автозапуск:
`systemctl enable mongod`

Проверяем работу MongoDB
`systemctl status mongod`

## Деплой приложения
Копируем код
`git clone -b monolith https://github.com/express42/reddit.git`

Переходим в директорию проекта и устанавливаем зависимости приложения:
`cd reddit && bundle install`

Запускаем сервер приложения в папке проекта:
`puma -d`

Проверьте что сервер запустился и на каком порту он слушает:
`ps aux | grep puma`

## Проверка работы
http://130.193.45.104:9292/


# Домашняя работа к лекции №7
# Сборка образов VM при помощи Packer

## создать и перейти в ветку packer-base
`git checkout -b packer-base`

## Установка Packer
Скачал (https://www.packer.io/downloads.html)

echo $PATH
распаковал Packer в папку /usr/local/bin

Проверьте установку командой `packer -v`
версия 1.1.6

## Создание сервисного аккаунта для Packer в Yandex.Cloud

Получите ваш folder-id - ID каталога в Yandex.Cloud:
`yc config list`

token: XXXXXXX-xxxxxxxxxxxxxxxxxxxx
cloud-id: 111111111111111111111
folder-id: 222222222222222222
compute-default-zone: ru-central1-c

Создать сервисный аккаунт:
```
SVC_ACCT="meter-packer-base"
FOLDER_ID="22222222222222222"
yc iam service-account create --name $SVC_ACCT --folder-id $FOLDER_ID
```
Выдайте права аккаунту:
```
ACCT_ID=$(yc iam service-account get $SVC_ACCT | \
grep ^id | awk '{print $2}')

yc resource-manager folder add-access-binding --id $FOLDER_ID \
--role editor \
--service-account-id $ACCT_ID
```

Создание service account key fifile
Создайте IAM key и экспортируйте его в файл. Помните, что
файлы, содержащие секреты, необходимо хранить за пределами
вашего репозитория.
`yc iam key create --service-account-id $ACCT_ID --output ~/key.json`

## Создание файла-шаблона Packer

Создайте в infra-репозитории директорию packer
`mkdir ~/meter-chel_infra/packer`

Внутри директории packer создайте файл ubuntu16.json. Это и
будет наш Packer шаблон, содержащий описание образа VM,
который мы хотим создать. Для нашего тестового приложения мы
соберем образ VM с предустановленными Ruby и MongoDB,так
называемый baked-образ.
```
cd ~/meter-chel_infra/packer
touch ubuntu16.json
```

В файле ubuntu16.json сконфигурируйте билдер (gist)
Builders - секция, отвечающая за то, на какой платформе и с
какими параметрами мы будем делать ВМ, которую впоследствии
сохраним как образ.

Provisioners - секция, которая позволяет устанавливать нужное
ПО, производить настройки системы и конфигурацию приложений
на созданной ВМ. Используя скрипты для установки Ruby и
MongoDB из предыдущего ДЗ, определим два провижинера

```
{
    "builders": [
	{
	    "type": "yandex",
	    "service_account_key_file": "/root/key.json",
	    "folder_id": "--------------------",
	    "source_image_family": "ubuntu-1604-lts",
	    "image_name": "reddit-base-{{timestamp}}",
	    "image_family": "reddit-base",
	    "ssh_username": "ubuntu",
	    "platform_id": "standard-v1",
	    "use_ipv4_nat": "true",
	    "disk_name": "hw7-hdd",
	    "disk_type": "network-hdd",
	    "disk_size_gb": "15"
	}
    ],
    "provisioners": [
	{
	    "type": "shell",
	    "script": "scripts/install_ruby.sh",
	    "execute_command": "sudo {{.Path}}"
	},
	{
	    "type": "shell",
	    "script": "scripts/install_mongodb.sh",
	    "execute_command": "sudo {{.Path}}"
	}
    ]
}
```

Создание скриптов для provisioners
Внутри директории packer создайте директорию scripts для
скриптов, которые будут использованы в provisioners
Скопируйте в эту директорию скрипты install_ruby.sh и
install_mongodb.sh из предыдущего ДЗ

## Packer позволяет выполнить синтаксическую проверку
шаблона. Сделайте её:

`packer validate ./ubuntu16.json`

Система попросила обновиться, сделал
`yc components update`

## Процесс сборки образа:
`packer build ./ubuntu16.json`

## После сборки образа создал тестовую VM, получил доступ по SSH и установил reddit и проверил работоспособность
```
ssh -i ~/.ssh/appuser appuser@<публичный IP машины>
sudo apt-get update
sudo apt-get install -y git
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install
puma -d
```
Откройте в браузере http://<внешний IP машины>:9292:

## Параметризирование шаблона
Создал файл variables.json с переменными и добавил в .gitignore. Добавил следующие параметры:
```
  "folder_id"
  "source_image_family"
  "service_account_key_file"
  "disk_name"
  "disk_type"
  "disk_size_gb"
```
чтобы использовать шаблон нужно перейти в директорию packer
Для сборки образа с использованием файла variables.json необходимо выполнить

```
packer build -var-file=variables.json ubuntu16.json
```

## Задания со *

### Построение bake-образа

Создан шаблон immutable.json
фактически в ubuntu16.json добавлено два провижинера
```
        {
          "type": "file",
          "source": "files/puma.service",
          "destination": "/tmp/puma.service"
        },
        {
          "type": "shell",
          "script": "scripts/deploy.sh",
          "execute_command": "sudo {{.Path}}"
        }
```
которые автоматизируют установку и запуск ранее делаемые вручную,
в папку скриптов добавлен deploy.sh"
в папку files файл puma.service


# Домашняя работа к лекции №8 (Terraform-1)
# Знакомство с Terraform

создать и перейти в ветку terraform-1
'git checkout -b terraform-1'

Установка Terraform (используем версию 0.12.)
Скачал (https://releases.hashicorp.com/terraform/0.12.0/terraform_0.12.0_linux_amd64.zip)

'echo $PATH'
распаковал Terraform в папку /usr/local/bin

Проверьте установку командой 'terraform -v'
Terraform v0.12.0
Your version of Terraform is out of date! The latest version
is 0.14.3. You can update by downloading from www.terraform.io/downloads.html


Создайте директорию terraform внутри вашего проекта
'mkdir terraform'

Внутри директории terraform создайте пустой файл: main.tf
```
cd terraform/
:~/meter-chel_infra/terraform# touch main.tf
```

В корне репозитория создайте файл .gitignore с содержимым
```
*.tfstate
*.tfstate.*.backup
*.tfstate.backup
*.tfvars
.terraform/
```
## определим секцию Provider в файле main.tf,
которая позволит Terraform управлять ресурсами YC через API
вызовы
```
provider "yandex" {
token = "<Auth или статический ключ сервисного аккаунта>"
cloud_id = "<идентификатор облака>"
folder_id = "<идентификатор каталога>"
zone = "ru-central1-a"
}
```
Узнать их можно с помощью команды:
`yc config list`


Провайдеры Terraform являются загружаемыми модулями, начиная с версии 0.10.
Для того чтобы загрузить провайдер и начать его использовать выполните
следующую команду в директории terraform:
`terraform init`

В файле main.tf после определения провайдера, добавьте ресурс для создания
инстанса VM в YC.
Определим SSH ключ пользователя ubuntu в метаданных нашего инстанса.
Помним, что публичные ключи доступны инстансам VM именно через метаданные.
Здесь мы используем встроенную функцию file, которая позволяет считывать
содержимое файла и вставлять его в наш конфигурационный файл.
```
resource "yandex_compute_instance" "app" {
  name = "reddit-app"
}

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      # Указать id образа созданного в предыдущем домашем задании
      image_id = "xxxxxxxxxxxxxxxxxxxx"
    }
  }

  network_interface {
    # Указан id подсети default-ru-central1-a
    subnet_id = "zzzzzzzzzzzzzzzzzz"
    nat       = true
  }

metadata = {
ssh-keys = "ubuntu:${file("~/.ssh/yc.pub")}"

}
```
Посмотреть информацию о имени, семействе и id пользовательских образов своего
каталога можно с помощью команды `yc compute image list`

Перед тем как дать команду terraform'у применить изменения,
хорошей практикой является предварительно посмотреть, какие
изменения terraform собирается произвести
`terraform plan`

Для того чтобы запустить инстанс VM, описание характеристик которого мы описали
в конфигурационном файле main.tf, используем команду:
`terraform apply`

Начиная с версии 0.11 terraform apply запрашивает дополнительное подтверждение
при выполнении. Необходимо добавить '-auto-approve' для отключения этого.
Результатом выполнения команды также будет создание файла `terraform.tfstate`
 в директории terraform. Terraform хранит в этом файле состояние управляемых им
ресурсов.
Искать нужные атрибуты ресурсов по state файлу не очень удобно, поэтому
terraform предоставляет команду show для чтения стейт файла.
Найдите внешний IP адрес созданного инстанса, но уже используя команду show:
`terraform show | grep nat_ip_address`

Зная внешний IP адрес, попробуем подключиться к инстансу по SSH

При необходимости пересоздать инстанс, нужно вначале его уничтожить:
`terraform destroy`

# Использование переменных и Provisioners

## Output vars
Согласитесь, что каждый раз использовать grep для поиска внешнего IP адреса по
результатам команды terraform show довольно неудобно. К тому же, если у нас
будет запущено несколько VM, то понять к какой машине относится какой адрес
становится еще сложнее.
Поэтому вынесем интересующую нас информацию - внешний адрес VM - в выходную
переменную (output variable), чтобы облегчить себе поиск. Чтобы не мешать
выходные переменные с основной конфигурацией наших ресурсов, создадим их в
отдельном файле, который назовем outputs.tf. Помним, что название файла может
быть любым, т.к. terraform загружает все файлы в текущей директории, имеющие
расширение .tf.
Создайте файл outputs.tf в директории terraform со следующим содержимым.
```
output "external_ip_address_app" {
  value = yandex_compute_instance.app.network_interface.0.nat_ip_address
}
```
Формат
yandex_compute_instance.app - инициализируем ресурс, указывая его тип и имя
network_interface.0.nat_ip_address - указываем нужные атрибуты ресурса

Используем команду `terraform refresh`, чтобы выходная переменная приняла
значение.
Outputs:
external_ip_address_app = 130.193.37.129

Значение выходных переменным можно посмотреть, используя
команду `terraform output`:

`terraform output`
external_ip_address_app = 130.193.37.129
`terraform output external_ip_address_app`
130.193.37.129

## Provisioners
Provisioners в terraform вызываются в момент создания/удаления ресурса и
позволяют выполнять команды на удаленной или локальной машине. Их используют
для запуска инструментов управления конфигурацией или начальной настройки системы.
Используем провижинеры для деплоя последней версии приложения на созданную VM.
Внутрь ресурса, содержащего описание VM, вставьте секцию провижинера типа file,
 который позволяет копировать содержимое файла на удаленную машину.
```
provisioner "file" {
source = "files/puma.service"
destination = "/tmp/puma.service"
}
```
В нашем случае мы говорим, провижинеру скопировать локальный файл, располагающийся
по указанному относительному пути (files/puma.service), в указанное место на удаленном хосте.
В определении провижинера мы указали путь до systemd unit файла для Puma.
Systemd использует unit файлы для запуска, остановки сервиса или добавления его в
автозапуск. С его помощью мы можем запускать сервер приложения, используя
команду systemctl start puma.
Создадим директорию files внутри директории terraform и создадим внутри нее файл puma.service

Добавим еще один провиженер для запуска скрипта деплоя
приложения на создаваемом инстансе. Сразу же после
определения провижинера file (провижинеры выполняются по
порядку их определения), вставьте секцию провижинера remoteexec:
```
provisioner "remote-exec" {
script = "files/deploy.sh"
}
```
В определении данного провижинера мы указываем
относительный путь до скрипта, который следует запустить на
созданной VM.
Создайте файл deploy.sh в директории terraform/files

Определим параметры подключения провиженеров к VM.
Внутрь ресурса VM, перед определением провижинеров, добавьте
следующую секцию :
```
connection {
  type = "ssh"
  host = yandex_compute_instance.app.network_interface.0.nat_ip_address
  user = "ubuntu"
  agent = false
  # путь до приватного ключа
  private_key = file("~/.ssh/id_rsa")
  }
```
В данном примере мы указываем, что провижинеры, определенные в ресурсе VM,
должны подключаться к созданной VM по SSH, используя для подключения приватный
ключ пользователя


Так как провижинеры по умолчанию запускаются сразу после
создания ресурса (могут еще запускаться после его удаления),
чтобы проверить их работу нам нужно удалить ресурс VM и создать
его снова.
Terraform предлагает команду `taint`, которая позволяет пометить
ресурс, который terraform должен пересоздать, при следующем
`запуске terraform apply`.

пересоздать ресурс VM при следующем применении изменений:
`terraform taint yandex_compute_instance.app`

Планируем изменения: `terraform plan`
```
# yandex_compute_instance.app is tainted, so must be replaced
-/+ resource "yandex_compute_instance" "app" {
~ created_at = "2020-04-08T08:19:56Z" -> (known after apply)
~ folder_id = "------------------" -> (known after apply)
```
-/+ означает, что ресурс будет удален и создан вновь.

Применяем изменения `terraform apply`

Расшифровка вывода
yandex_compute_instance.app (remote-exec): Connected! -
провиженеру удалось подключиться к VM.

yandex_compute_instance.app (remote-exec): Cloning into
'/home/ubuntu/reddit'... - скрипт запустился и началось
клонирование репозитория.

## Input vars
Входные переменные позволяют нам параметризировать
конфигурационные файлы.
Для того чтобы использовать входную переменную ее нужно
сначала определить в одном из конфигурационных файлов.
Создадим для этих целей еще один конфигурационный файл
variables.tf в директории terraform

Определим переменные в файле variables.tf
```
variable cloud_id{
  description = "Cloud"
}
variable folder_id {
  description = "Folder"
}
variable zone {
  description = "Zone"
  # Значение по умолчанию
  default = "ru-central1-a"
}
variable public_key_path {
  # Описание переменной
  description = "Path to the public key used for ssh access"
}
variable image_id {
  description = "Disk image"
}
variable subnet_id{
  description = "Subnet"
}
variable service_account_key_file{
  description = "key.json"
}
```
Теперь можем использовать input переменные в определении
других ресурсов. Чтобы получить значение пользовательской
переменной внутри ресурса используется синтаксис `var.var_name`

Определим соответствующие параметры ресурсов с помощью переменных в `main.tf`:
```
provider "yandex" {
service_account_key_file = var.service_account_key_file
cloud_id = var.cloud_id
folder_id = var.folder_id
zone = var.zone
}
```
### Обратите внимание, что теперь для аутентификации используется ключ
### сервисного аккаунта, а не токен. Вы можете передать значение как токена,
### так и ключа сервисного аккаунта.
```
boot_disk {
    initialize_params {
      # Указать id образа созданного в предыдущем домашем задании
      image_id = var.image_id
    }
  }

  network_interface {
    # Указан id подсети default-ru-central1-a
    subnet_id = var.subnet_id
    nat       = true
  }

  metadata = {
  ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
```

Задать значения переменных можно (и нужно) используя специальный файл
`terraform.tfvars`, из которого тераформ загружает значения автоматически при
каждом запуске. В директории `terraform` создайте файл `terraform.tfvars`, в
котором определите ваши переменные. Это должно выглядеть примерно так:
```
cloud_id = "xxxxxxxxxxxxxxxxx"
folder_id = "yyyyyyyyyyyyyyyyyy"
zone = "ru-central1-a"
image_id = "zzzzzzzzzzzzzzzzzzzz"
```
Пересоздадим все ресурсы
```
terraform destroy
terraform plan
terraform apply
```

### Оформление
Отформатируйте все конфигурационные файлы используя команду
`terraform fmt`

## Описание файлов
main.tf - основной файл

`папка files` - файлы скриптов и приложений

`variables.tf` - объявление переменных, что есть такая переменная,
пояснение к переменной (необязательно) и можно задать значение по умолчанию.

`terraform.tfvars` - значения переменных

`outputs.tf` - чтобы не смешивать выходные переменные с основной
конфигурацией наших ресурсов (не писать их в файл `main.tf` файл),
созданы в отдельном файле

# Задания со *

##Автоматизация создания нескольких копий ВМ с помощью переменной count
```
resource "yandex_compute_instance" "app" {
   name                      = "reddit-app-${count.index}"
   count                     = var.count_app
```

## Балансировщик
создается с помощью `resource "yandex_lb_network_load_balancer" "app"`,
описываются входящие порты и порты назначения, и целевая группа `attached_target_group` - фактически список адресов на которые будет производится переназначение.
Формируется список адресов с помощью `resource "yandex_lb_target_group" "app_tg"` из указанной в `subnet_id` сети.


# Домашняя работа к лекции №9 (Terraform-2)
Принципы организации инфраструктурного кода и работа над инфраструктурой в команде на примере Terraform

создать и перейти в ветку terraform-2
`git checkout -b terraform-2`


# Возможность получать атрибуты другого ресурса

Зададим IP для инстанса с приложением в виде внешнего ресурса. Для этого определим ресурсы `yandex_vpc_network` и `yandex_vpc_subnet` в конфигурационном файле `main.tf`.
```
resource "yandex_vpc_network" "app-network" {
name = "reddit-app-network"
}
resource "yandex_vpc_subnet" "app-subnet" {
name = "reddit-app-subnet"
zone = "ru-central1-a"
network_id = "${yandex_vpc_network.app-network.id}"
v4_cidr_blocks = ["192.168.10.0/24"]
}
```
Для того чтобы использовать созданный IP адрес в нашем ресурсе VM нам необходимо сослаться на атрибуты ресурса,
который этот IP создает, внутри конфигурации ресурса VM. В конфигурации ресурса VM определите, IP адрес для создаваемого инстанса.
```
network_interface {
subnet_id = yandex_vpc_subnet.app-subnet.id
nat = true
}
```
### В обоих случаях забирается `id` созданных ранее ресурсов

Ссылку в одном ресурсе на атрибуты другого тераформ понимает как зависимость (не явную) одного ресурса от другого. Это влияет
на очередность создания и удаления ресурсов при применении изменений.

Terraform поддерживает также явную зависимость - используется параметр `depends_on`


# Структуризация ресурсов

## Несколько VM

### Вынесем БД на отдельный инстанс VM.
Для этого необходимо в директории packer, где содержатся ваши шаблоны для билда VM, создать два новых шаблона db.json и app.json.
При помощи шаблона db.json должен собираться образ VM, содержащий установленную MongoDB.
Шаблон app.json должен использоваться для сборки образа VM, с установленными Ruby.
В качестве базового образа для создания образа возьмите ubuntu16.04.
Для выполнения задания, нужно лишь скопировать и слегка подкорректировать уже имеющийся шаблон ubuntu16.json.

### Создадим две VM
Разобьем конфиг main.tf на несколько конфигов.
Создадим файл app.tf, куда вынесем конфигурацию для VM с приложением.
Пока пренебрежем провижинерами.
```
resource "yandex_compute_instance" "app" {
name = "reddit-app"
labels = {
tags = "reddit-app"
}
resources {
cores = 1
memory = 2
}
boot_disk {
initialize_params {
image_id = var.app_disk_image
}
}
network_interface {
subnet_id = yandex_vpc_subnet.app-subnet.id
nat = true
}
...
}
```

Обратите внимание, что мы вводим новую переменную для образа приложения. Не забудьте объявить ее в `variables.tf` и задать в `terraform.tfvars`:
```
variable app_disk_image {
description = "Disk image for reddit app"
default = "reddit-app-base"
}
```
### Аналогичные действия нужно сделать для файла `db`


Создадим файл vpc.tf, в который вынесем кофигурацию сети и подсети, которое применимо для всех инстансов нашей сети.
```
resource "yandex_vpc_network" "app-network" {
name = "app-network"
}
resource "yandex_vpc_subnet" "app-subnet" {
name = "app-subnet"
zone = "ru-central1-a"
network_id = "${yandex_vpc_network.app-network.id}"
v4_cidr_blocks = ["192.168.10.0/24"]
}
```
В итоге, в файле main.tf должно остаться только определение провайдера:
```
provider "yandex" {
service_account_key_file = var.service_account_key_file
cloud_id = var.cloud_id
folder_id = var.folder_id
zone = var.zone
}
```
Не забудьте добавить nat адреса инстансов в outputs переменные.
```
output "external_ip_address_app" {
value = yandex_compute_instance.app.network_interface.0.nat_ip_address
}
output "external_ip_address_db" {
value = yandex_compute_instance.db.network_interface.0.nat_ip_address
}
```
Планируем и применяем изменения одной командой: `terraform apply`
Если у вас все прошло успешно, можете проверить, что хосты доступны, и на них установлено необходимое ПО.
Затем удалите созданные ресурсы, используя `terraform destroy`.

# Модули
Разбивая нашу конфигурацию нашей инфраструктуры на отдельные конфиг файлы, мы готовили для себя почву для работы
с модулями. Внутри директории `terraform` создайте директорию `modules`, в которой мы будет определять модули.

### DB module
Внутри директории modules создайте директорию `db`, в которой создайте три привычных нам файла `main.tf`, `variables.tf`,
`outputs.tf`. Скопируем содержимое `db.tf`, который мы создали ранее, в `modules/db/main.tf`. Затем определим переменные,
которые у нас используются в `db.tf` и объявляются в `variables.tf` в файл переменных модуля `modules/db/variables.tf`

### modules/db/variables.tf
```
variable public_key_path {
description = "Path to the public key used for ssh access"
}
variable db_disk_image {
description = "Disk image for reddit db"
default = "reddit-db-base"
}
variable subnet_id {
description = "Subnets for modules"
}
```
### App module - аналогично DB module

### Не забудем про в выходные переменные
modules/app/outputs.tf
```
output "external_ip_address_app" {
value = yandex_compute_instance.app.network_interface.0.nat_ip_address
}
```

Прежде чем вызывать и проверять модули, для начала удалим `db.tf` и `app.tf`, а так же `vpc.tf` (Вместо него теперь используем переменные) в нашей директории, чтобы terraform перестал их использовать.
В файл `main.tf`, где у нас определен провайдер вставим секции вызова созданных нами модулей.

### main.tf
```
provider "yandex" {
service_account_key_file = var.service_account_key_file
cloud_id = var.cloud_id
folder_id = var.folder_id
zone = var.zone
}
module "app" {
source = "./modules/app"
public_key_path = var.public_key_path
app_disk_image = var.app_disk_image
subnet_id = var.subnet_id
}
module "db" {
source = "./modules/db"
public_key_path = var.public_key_path
db_disk_image = var.db_disk_image
subnet_id = var.subnet_id
}
```
Чтобы начать использовать модули, нам нужно сначала их загрузить из указанного источника . В нашем случае источником модулей будет просто локальная папка на диске.
Используем команду для загрузки модулей. В директории terraform: `terraform get`
Модули будут загружены в директорию `.terraform`, в которой уже содержится провайдер.
ЗАМЕЧАНИЕ: `terraform get`своеобразная регистрация модулей и в директории `.terraform` записывается только путь до них, если модуль изменяется то изменения учитываются, а вот если изменяется путь до модуля, то нужно снова его регистрировать командой `terraform get`.

### Получаем output переменные из модуля
В созданном нами модуле app мы определили выходную переменную для внешнего IP инстанса.
Чтобы получить значение этой переменной, переопределим ее:
```
output "external_ip_address_app" {
value = module.app.external_ip_address_app
}
output "external_ip_address_db" {
value = module.db.external_ip_address_db
}
```
После применения конфигурации с помощью terraform apply в соответствии с нашей конфигурацией у нас должен быть SSH-доступ ко обоим инстансам

# Переиспользование модулей
Основную задачу, которую решают модули - это увеличивают переиспользуемость кода и помогают нам следовать принципу DRY.
Инфраструктуру, которую мы описали в модулях, теперь можно использовать на разных стадиях нашего конвейера непрерывной поставки с необходимыми нам изменениями.
Создадим инфраструктуру для двух окружений (`stage` и `prod`), используя созданные модули.

В директории terrafrom создайте две директории: `stage` и `prod`.
Скопируйте файлы `main.tf`, `variables.tf`, `outputs.tf`, `terraform.tfvars`, `key.json` из директории `terraform` в каждую из созданных директорий.
Поменяйте пути к модулям в `main.tf` на `../modules/xxx` вместо `modules/xxx`.
Инфраструктура в обоих окружениях будет идентична.

### terraform/stage/main.tf
```
provider "yandex" {
service_account_key_file = var.service_account_key_file
cloud_id = var.cloud_id
folder_id = var.folder_id
zone = var.zone
}
module "app" {
source = "../modules/app"
public_key_path = var.public_key_path
app_disk_image = var.app_disk_image
subnet_id = var.subnet_id
}
module "db" {
source = "../modules/db"
public_key_path = var.public_key_path
db_disk_image = var.db_disk_image
subnet_id = var.subnet_id
}
```
Проверьте правильность настроек инфраструктуры каждого окружения. Для этого нужно запустить terraform apply в каждом из них.
Не забывайте удалять ресурсы после проверок.

## Реестр модулей
В сентябре 2017 компания HashiCorp запустила публичный реестр модулей для terraform .
До этого модули можно было либо хранить либо локально, как мы делаем в этом ДЗ, либо забирать из Git, Mercurial или HTTP.
На главной странице можно искать необходимые модули по названию и фильтровать по провайдеру.
Модули бывают Verified и обычные. Verified это модули от HashiCorp и ее партнеров.


# Домашняя работа к лекции №10 (ansible-1)
# Знакомство с Ansible

## Ansible, установка и настройка клиента на рабочую машину
Работа в Ansible гарантирована в Linux/Unix машинах и в подситеме WSL Windows 10.
Для работоспособности Ansible требуется установить Python

Добейтесь установки Python 2.7 и/или проверьте что
установлена нужная версия
`python --version`

Рекомендуется также поставить пакетный менеджер pip или easy_install

Любым из пакетных менеджеров установите ansible, примеры:
```
pip install -r requirements.txt
pip install ansible>=2.4
easy_install `cat requirements.txt`
```
Проверяем, что Ansible установлен:
```
ansible --version
ansible 2.4.x.x
```

### Ansible управляет инстансами виртуальных машин (c Linux ОС) используя SSH-соединение.
### Поэтому для управление инстансом при помощи Ansible нам нужно убедиться, что мы можем подключиться к нему по SSH.
### Для управления хостами при помощи Ansible на них также должен быть установлен Python

Для далнейшей работы потребуются две VM, ноапример из предыдущего задания

Хосты и группы хостов, которыми Ansible должен управлять, описываются в инвентори-файле.
имя инвентори-файла задается в ancible.cfg или в команде вызова после ключа -i

Создадим инвентори файл inventory, в котором укажем информацию о созданном инстансе приложения и параметры подключения к нему по SSH:
```
например
appserver ansible_host=35.195.186.154 ansible_user=appuser ansible_private_key_file=~/.ssh/appuser
```
где appserver - краткое имя, которое идентифицирует данный хост.
Обратите внимание, что это должна быть одна строка в файле inventory


### Убедимся, что Ansible может управлять нашим хостом.
Используем команду ansible для вызова модуля ping из командной строки.

`ansible appserver -i ./inventory -m ping`

Ping-модуль позволяет протестировать SSH-соединение, при этом ничего не изменяя на самом хосте.
```
-m ping - вызываемый модуль
-i ./inventory - путь до файла инвентори
appserver - Имя хоста, которое указали в инвентори, откуда Ansible yзнает, как подключаться к хосту
```
вывод команды:
```
appserver | SUCCESS => {
"changed": false,
"ping": "pong"
}
```
Повторите такую же процедуру для инстанса БД

Для того чтобы управлять инстансами нам приходится вписывать много данных в наш инвентори файл.
К тому же, чтобы использовать данный инвентори, нам приходится каждый раз указывать его явно, как опцию команды ansible.
Многое из этого мы можем определить в конфигурации Ansible.
Для того чтобы настроить Ansible под нашу работу, создадим конфигурационный файл для него `ansible.cfg`.

### ansible.cfg:
```
[defaults]
inventory = ./inventory
remote_user = appuser
private_key_file = ~/.ssh/appuser
host_key_checking = False
retry_files_enabled = False
```

Теперь можно удалить избыточную информацию из файла `inventory` и использовать значения по умолчанию:

### inventory:
```
appserver ansible_host=35.195.74.54
dbserver ansible_host=35.195.162.174
```

Используем модуль `command`, который позволяет запускать произвольные команды на удаленном хосте.
Выполним команду uptime для проверки времени работы инстанса.
Команду передадим как аргумент для данного модуля, использовав опцию -a:
`ansible dbserver -m command -a uptime`

## Работа с группами хостов
Управлять при помощи Ansible отдельными хостами становится неудобно, когда этих хостов становится более одного.
В инвентори файле мы можем определить группу хостов для управления конфигурацией сразу нескольких хостов.
Список хостов указывается под названием группы, каждый новый хост указывается в новой строке.
В нашем случае, каждая группа будет включать в себя всего один хост.
Сейчас мы определим группы хостов в инвентори файле

### inventory:
```
[app] #  Это название группы
appserver ansible_host=35.195.74.54 # Cписок хостов в данной группе

[db]
dbserver ansible_host=35.195.162.174
```

Теперь мы можем управлять не отдельными хостами, а целыми группами, ссылаясь на имя группы:
```
ansible app -m ping

appserver | SUCCESS => {
"changed": false,
"ping": "pong"
}
```
Параметры:
```
app - имя группы
-m ping - имя модуля Ansible
appserver - имя сервера в группе, для которого применился модуль
```

## Начиная с Ansible 2.4 появилась возможность использовать YAML для inventory.
Создадим файл `inventory.yml` и перенесем в него записи из имеющегося inventory.
### В файле `ancible.cfg` нужно исправить имя конфигурационного файла!

### inventory.yml
```
app:
  hosts:
    appserver:
      ansible_host: 35.190.196.109

db:
  hosts:
    dbserver:
      ansible_host: 104.155.9.218
```

`ansible all -m ping -i inventory.yml`

Ключ `-i` переопределяет путь к инвентори файлу
```
dbserver | SUCCESS => {
"changed": false,
"ping": "pong"
}
appserver | SUCCESS => {
"changed": false,
"ping": "pong"
}
```
## Выполнение команд

Из проедыдущего задания: на app-сервере у нас пакером при билде установлен ruby.
А на db-сервер установлена MongoDB.
Попробуем не заходя на хосты, проверить наличие необходимых компонентов в созданном окружении.

### Проверим, что на app сервере установлены компоненты для работы приложения (`ruby` и `bundler`):

`ansible app -m command -a 'ruby -v'`
```
appserver | SUCCESS | rc=0 >>
ruby 2.3.1p112 (2016-04-26) [x86_64-linux-gnu]
```
`ansible app -m command -a 'bundler -v'`
```
appserver | SUCCESS | rc=0 >>
Bundler version 1.11.2
```

А теперь попробуем указать две команды модулю command:
`ansible app -m command -a 'ruby -v; bundler -v'`
```
appserver | FAILED | rc=1 >>
ruby: invalid option -; (-h will show valid options) (RuntimeError)non-zero
return code
```
В то же время модуль shell успешно отработает:
`ansible app -m shell -a 'ruby -v; bundler -v'`
```
appserver | SUCCESS | rc=0 >>
ruby 2.3.1p112 (2016-04-26) [x86_64-linux-gnu]
Bundler version 1.11.2
```
### Модуль command выполняет команды, не используя оболочку (sh, bash), поэтому в нем не работают перенаправления потоков и нет доступа к некоторым переменным окружения.

Проверим на хосте с БД статус сервиса MongoDB с помощью модуля `command` и `shell`.
(Эта операция аналогична запуску на хосте команды `systemctl status mongod`):

`ansible db -m command -a 'systemctl status mongod'`
```
dbserver | SUCCESS | rc=0 >>
● mongod.service - High-performance, schema-free document-oriented database
```
`ansible db -m shell -a 'systemctl status mongod'`
```
dbserver | SUCCESS | rc=0 >>
● mongod.service - High-performance, schema-free document-oriented database
```

А можем выполнить ту же операцию используя модуль `systemd`, который предназначен для управления сервисами:
`ansible db -m systemd -a name=mongod`
```
dbserver | SUCCESS => {
"changed": false,
"name": "mongod",
"status": {
"ActiveState": "active", ...
```

Или с помощью модуля `service`, который более универсален и будет работать и в более старых ОС с `init.d`-инициализацией:
`ansible db -m service -a name=mongod`
```
dbserver | SUCCESS => {
"changed": false,
"name": "mongod",
"status": {
"ActiveState": "active", ...
```

На предыдущем примере с проверкой состояния сервиса можно увидеть преимущества использования модуля вместо запуска shell-команд.
Модуль возвращает в качестве ответа набор переменных, которые можно легко использовать для проверки в дальнейшем коде.
Например `status.ActiveState` содержит состояние сервиса.
А для shell-команд нужно будет реализовывать проверку с помощью регулярных выражений, кодов возврата и других сложных и ненадежных решений.

Используем модуль git для клонирования репозитория с
приложением на app сервер:

`ansible app -m git -a 'repo=https://github.com/express42/reddit.git dest=/home/appuser/reddit'`
```
appserver | SUCCESS => {
"after": "61a7f75b3d3e6f7a8f279896fb4e9f0556e1a70a",
"before": null,
"changed": true
}
```
`ansible app -m git -a 'repo=https://github.com/express42/reddit.git dest=/home/appuser/reddit'`
```
appserver | SUCCESS => {
"after": "61a7f75b3d3e6f7a8f279896fb4e9f0556e1a70a",
"before": "5c217c565c1122c5343dc0514c116ae816c17ca2",
"changed": false,
"remote_url_changed": false
}
```

Как мы видим, повторное выполнение этой команды проходит успешно, только переменная `changed` будет false (что значит, что изменения не произошли)

И попробуем сделать то же самое с модулем `command`:

`ansible app -m command -a 'git clone https://github.com/express42/reddit.git /home/appuser/reddit'`
```
appserver | SUCCESS | rc=0 >>
Cloning into '/home/appuser/reddit'...
```
`ansible app -m command -a \`
```
'git clone https://github.com/express42/reddit.git /home/appuser/reddit'
appserver | FAILED | rc=128 >>
fatal: destination path '/home/appuser/reddit' already exists and is not
an empty directory. non-zero return code
```
А в этом примере, повторное выполнение завершается ошибкой.

Реализуем простой плейбук, который выполняет аналогичные предыдущему слайду действия (клонирование репозитория).
Создайте файл `clone.yml`
```
- name: Clone
hosts: app
tasks:
- name: Clone repo
git:
repo: https://github.com/express42/reddit.git
dest: /home/appuser/reddit
```
И выполните: `ansible-playbook clone.yml`
Результат примерно такой:
```
PLAY RECAP
***************************************************************************
appserver : ok=2 changed=0 unreachable=0 failed=0
```
Теперь выполните `ansible app -m command -a 'rm -rf ~/reddit'` и проверьте еще раз выполнение плейбука.

### Команда `ansible app -m command -a 'rm -rf ~/reddit'` удалила папку  `~/reddit` и при выполнении плейбука `clone.yml` ansible внес изменения - создал папку заново

Результат был такой:
```
PLAY RECAP
***************************************************************************
appserver : ok=2 changed=1 unreachable=0 failed=0
```

## Задание со *

файл `inventory.json` создал скриптом inventory.sh,
в `inventory.sh` ip адреса инстансов ВМ получаются с помощью `yc compute instances list`

`inventory.json` должен выглядеть примерно так:
```
{
 "all": {
  "hosts": {
         "130.193.51.131",
"178.154.226.138"
           }
   },
 "app": {
  "hosts": {
         "130.193.51.131"
           }
   },
 "db": {
  "hosts": {
         "178.154.226.138"
           }
   },
}
```

в `ansible.cfg` внесены изменения
```
inventory = ./inventory.json

[inventory]
enable_plugins = yaml
```
команда  `ansible all -m ping` выдает ответ о доступности хостов


# Домашняя работа к лекции №11 (Ansible-2)
# Продолжение знакомства с Ansible: templates, handlers, dynamic inventory, vault, tags

## Создадим плейбук 'reddit_app_one_play.yml' таким образом, чтобы получился один play c множеством tasks с tags.
```
---
- name: Configure hosts & deploy application
  hosts: all
  vars:
    mongo_bind_ip: 0.0.0.0
    db_host: 192.168.100.24
  tasks:
    - name: Change mongo config file
      become : true
      template:
        src : templates/mongod.conf.j2
        dest: /etc/mongod.conf
        mode: 0644
      tags: db-tag
      notify: restart mongod

    - name: Install git
      become: true
      package:
        name:
          - git
          - ruby
          - bundler
        state: present
        update_cache: yes
      tags: deploy-tag

    - name: Add unit file for Puma
      become : true
      copy:
        src: files/puma.service
        dest: /etc/systemd/system/puma.service
      tags: app-tag
      notify: reload puma

    - name: Add config for DB connection
      become : true
      template:
        src : templates/db_config.j2
        dest: /home/ubuntu/db_config
        owner: ubuntu
        group: ubuntu
      tags: app-tag

    - name: enable puma
      become : true
      systemd: name=puma enabled=yes
      tags: app-tag

    - name: Fetch the latest version of application code
      git:
        repo: https://github.com/express42/reddit.git
        dest: /home/ubuntu/reddit
        version: monolith
      tags: deploy-tag
      notify: reload puma

    - name: Bundle install
      bundler:
        state: present
        chdir: /home/ubuntu/reddit
      tags: deploy-tag

  handlers:
  - name: restart mongod
    become : true
    service: name=mongod state=restarted
  - name: reload puma
    become : true
    service: name=puma state=restarted
```
чтобы работать с таким playbook'jv необходимы команды следующего вида:
```
ansible-playbook reddit_app_one_play.yml --limit db --tags db-tag
ansible-playbook reddit_app_one_play.yml --limit app --tags app-tag
ansible-playbook reddit_app_one_play.yml --limit app --tags deploy-tag
```
также можно использовать ключ `--check` для выполнения сценария без его применения.

## Один плейбук, несколько сценариев
Создадим плейбук 'reddit_app_multiple_plays.yml' таким образом, чтобы получился несколько play.
```
---
- name: Configure MongoDB
  hosts: db
  become : true
  tags:
   - db-tag
  vars:
    mongo_bind_ip: 0.0.0.0
  tasks:
    - name: Change mongo config file
      template:
        src : templates/mongod.conf.j2
        dest: /etc/mongod.conf
        mode: 0644
      notify: restart mongod
  handlers:
  - name: restart mongod
    service: name=mongod state=restarted

- name: Configure hosts & deploy application
  hosts: app
  tags:
   - app-tag
  vars:
    db_host: 192.168.100.7
  become : true
  tasks:
    - name: Add unit file for Puma
      copy:
        src: files/puma.service
        dest: /etc/systemd/system/puma.service
      tags: app-tag
      notify: reload puma

    - name: Add config for DB connection
      template:
        src : templates/db_config.j2
        dest: /home/ubuntu/db_config
        owner: ubuntu
        group: ubuntu

    - name: Install git
      become: true
      package:
        name:
          - git
          - ruby
          - bundler
        state: present
        update_cache: yes
      tags: deploy-tag

    - name: enable puma
      become : true
      systemd: name=puma enabled=yes
      tags: app-tag

    - name: Fetch the latest version of application code
      git:
        repo: https://github.com/express42/reddit.git
        dest: /home/ubuntu/reddit
        version: monolith
      tags: deploy-tag
      notify: reload puma

    - name: Bundle install
      bundler:
        state: present
        chdir: /home/ubuntu/reddit
      tags: deploy-tag

    - name: enable puma
      systemd: name=puma enabled=yes

  handlers:
  - name: reload puma
    become : true
    service: name=puma state=restarted
```
чтобы работать с таким playbook'ом необходимы команды следующего вида:
```
ansible-playbook reddit_app_multiple_plays.yml --tags db-tag
ansible-playbook reddit_app_multiple_plays.yml --tags app-tag
ansible-playbook reddit_app_multiple_plays.yml --tags deploy-tag
```
Таким playbook'ом проще управлять, так как не надо запоминать к какой группе серверов относится тег.

# Несколько плейбуков
Разделим предыдущий playbook на несколько плейбуков (app.yml, db.yml, deploy_app.yml)
В файле site.yml перечислим все файлы с playbook.
```
---
- import_playbook: db.yml
- import_playbook: app.yml
- import_playbook: deploy.yml
```
теперь можно одним файлом запустить все сценарии
Проверка и запуск
```
ansible-playbook site.yml --check
ansible-playbook site.yml
```

## Провижининг в Packer

Необходимо заменить провиженеры в Packer с shell на ansible.
```
    "provisioners": [
        {
            "type": "ansible",
            "user": "ubuntu",
            "playbook_file": "../ansible/packer_app.yml"
        }
    ]
```
без параметра user выдавал ошибку доступа

Создал файлы, вместо install_ruby.sh и install_mongodb.sh:
ansible/packer_app.yml - устанавливает Ruby и Bundler
ansible/packer_db.yml - добавляет репозиторий MongoDB, устанавливает ее и включает сервис.

## Проверка

### Создать образы packer

Перейти в каталог packer и выполнить команды в терминале
```
packer build -var-file=variables.json app.json
packer build -var-file=variables.json db.json
```
Будут созданы образы в YC, 'reddit-app-ansible' и 'reddit-db-ansible'
 (в файлах packer к имени образа можно добавить '-{{timestamp}}', чтобы каждый раз оно было разным и образ не нужно было удалять при повторном запуске сборки образа).

### Создать ВМ

Перейти в каталог terraform/stage и выполнить команду в терминале
```
terraform init
terraform plan
terraform apply
```
На основе созданных образов будут созданы 2 ВМ в YC.

## Деплой приложения

Заменить IP ВМ на актуальные в файлах inventory.yml и в app.yml заменить значение переменной *db_host* на актуальный внутренний адрес ВМ с базой данных
Перейти в директорию ansible и выполнить команду в терминале
```
ansible-playbook site.yml
```

В результате приложение будет доступно по адресу <Внешний IP>:9292


# Задания со *

1. Добавил в outputs.tf
```

resource "local_file" "AnsibleInventory" {
 content = templatefile("inventory.tmpl",
 {
  app-extip = module.app.external_ip_address_app,
  db-extip = module.db.external_ip_address_db,
 }
 )
 filename = "../../ansible/inventory.ini"
}
```
2. Добавил шаблон 'inventory.tmpl' для формирования файла inventory.ini
```
[db]
dbserver ansible_host=${db-extip}
[app]
appserver ansible_host=${app-extip} db_address=${db-extip}
```

3. Переменную db_host (app.yml) берем из inventory файла (inventory.ini) - создается динамически)
```
vars:
   db_host: "{{ db_address }}"
```
4. В 'ansible.cfg' нужно внести изменения
```
[defaults]
inventory = ./inventory.ini

[inventory]
enable_plugins = ini
```


# Домашняя работа к лекции №12 (Ansible-3)
# Ansible роли, управление настройками нескольких окружений

Создал init структуру с принятым на Galaxy форматом для ролей stage и prod
```
ansible-galaxy init app
ansible-galaxy init db
```
Распределил по директориям файлы шаблонов и файлов конфигураций.
Из playbook перенес раздел tasks в директорию tasks.
Поскольку структура стандартизована в модулях не нужно указывать полный путь к шаблонам и файлам, а достаточно имени.
Хендлеры и переменные также выносятся в отдельную директорию.
В playbook app и db указываются только необходимые роли.

Далее настраиваем файлы для разных окружений (prod и stage).
Для каждого окружения создадим свой инвентори файл.
В файл конфигурации запишем путь к stage инвентори.
В каждом окружении создал директорию group_vars. В нем создаём файлы с переменными.

Добавил роль из ansible-galaxy jdauphant.nginx. Добавил переменные в group_vars
```
nginx_sites:
default:
- listen 80
- server_name "reddit"
- location / {
proxy_pass http://127.0.0.1:9292;
}
```
Добавил роль jdauphant.nginx в playbook app.

## Работа с Ansible Vault

Создал в домашней директории файл с паролем vault.key:
```
openssl rand -base64 -out ~/vault.key 12
```
добавил в .gitignore
Добавил путь к нему ansible.cfg

Добавил плейбук для создания пользователей (и ссылку на него в site.yml) и создал файл с данными пользователей credentials.yml
Зашифровал файл с помощью ansible-vault.
```
ansible-vault encrypt environments/prod/credentials.yml
ansible-vault encrypt environments/stage/credentials.yml
```
Дешифровка
```
ansible-vault decrypt environments/prod/credentials.yml
ansible-vault decrypt environments/stage/credentials.yml
```


# Задание со * Работа с динамическим инвентори

В outputs.tf в параметре filename для stage и prod потребовалось исправить параметр filename
```
output "external_ip_address_app" {
   value = module.app.external_ip_address_app
}

output "external_ip_address_db" {
   value = module.db.external_ip_address_db
}

resource "local_file" "AnsibleInventory" {
 content = templatefile("inventory.tmpl",
 {
  app-extip = module.app.external_ip_address_app,
  db-extip = module.db.external_ip_address_db,
 }
 )
 filename = "../../ansible/environments/prod/inventory.ini"
}
```
Требуется вносить изменения в 'ansible.cfg' или запускать с ключем i
```
ansible-playbook -i environments/prod/inventory site.yml
```

# Домашняя работа к лекции №13 (ansible-4)
# Разработка и тестирование ролей и плейбуков


## Установка Vagrant
```
mkdir ~/vagrant
cd ~/vagrant
wget https://releases.hashicorp.com/vagrant/2.2.14/vagrant_2.2.14_x86_64.deb
dpkg -i vagrant_2.2.14_x86_64.deb
rm -f vagrant_2.2.14_x86_64.deb
cd ~
rmdir ~/vagrant
vagrant -v
```

Команды для работы с vagrant
```
vagrant up - создание ВМ
vagrant box list - список боксов
vagrant status - Статус ВМ
vagrant ssh appserver - подключение к ВМ appserver
vagrant provision dbserver - Запустить секцию procision на ВМ
vagrant destroy -f - Удалить ВМ без подтверждения
```

## Vagrantfile

```
Vagrant.configure("2") do |config|

  config.vm.provider :virtualbox do |v|
    v.memory = 512
  end

  config.vm.define "dbserver" do |db|
    db.vm.box = "ubuntu/xenial64"
    db.vm.hostname = "dbserver"
    db.vm.network :private_network, ip: "10.10.10.10"

    db.vm.provision "ansible" do |ansible|
      ansible.playbook = "playbooks/site.yml"
      ansible.groups = {
      "db" => ["dbserver"],
      "db:vars" => {"mongo_bind_ip" => "0.0.0.0"}
      }
    end
  end

  config.vm.define "appserver" do |app|
    app.vm.box = "ubuntu/xenial64"
    app.vm.hostname = "appserver"
    app.vm.network :private_network, ip: "10.10.10.20"

    app.vm.provision "ansible" do |ansible|
      ansible.playbook = "playbooks/site.yml"
      ansible.groups = {
      "app" => ["appserver"],
      "app:vars" => { "db_host" => "10.10.10.10"}
      }
       ansible.extra_vars = {
        "deploy_user" => "ubuntu",
        "nginx_sites": {
          "default": [
            "listen 80",
            "server_name \"reddit\"",
            "location / { proxy_pass http://127.0.0.1:9292; }"
          ]
        }
      }
    end
  end
end
```

в файле добавлен провиженер для DB:
```
db.vm.provision "ansible" do |ansible|
      ansible.playbook = "playbooks/site.yml"
      ansible.groups = {
      "db" => ["dbserver"],
      "db:vars" => {"mongo_bind_ip" => "0.0.0.0"}
      }
```
Запуcк провиженера
```
vagrant provision dbserver
```

Добавил плейбук base.yml, в котором описал установку python. Добавил его в site.yml.
```
---
- name: Check && install python
  hosts: all
  become: true
  gather_facts: False

  tasks:
    - name: Install python for Ansible
      raw: test -e /usr/bin/python || (apt -y update && apt install -y python-minimal)
      changed_when: False
```
Используется raw модуль, который позволяет запускать команды по SSH и не требует наличия python на управляемом хосте.
Отменен также сбор фактов ансиблом, т.к. данный процесс требует установленного python и выполняется перед началом применения конфигурации.

Добавил файл db/tasks/install_mongo.yml, перенес в него таски установки MongoDB из packer_db.yml. Добавил тег 'install'.
В файл db/tasks/config_mongo.yml добавил таск с настройкой конфига MongoDB. Добавил тег 'config'

Аналогичные действия выполнил и для роли app.
В app/tasks/ruby.yml перенес таски относящиеся к установке ruby.
В app/tasks/puma.yml относящиеся к установке puma server.
Добавил провиженер в Vagrantfile для APP.

Параметризировал конфигурацию, чтобы можно было использовать ее для другого пользователя.
То есть во всех файлах заменил 'ubuntu' на '{{ deploy_user }}'.


## Задание со *

Для передачи параметров nginx в роли jdauphant.nginx в провиженер в Vagrantfile для APP добавил:
```
        "nginx_sites": {
          "default": [
            "listen 80",
            "server_name \"reddit\"",
            "location / { proxy_pass http://127.0.0.1:9292; }"
          ]
        }
```

В итоге при выполнении 'vagrant up' будут созданы две ВМ (db и app).
Для доступа к тестовому приложению достаточно в браузере ввести 'http://10.10.10.20' без указания порта


## Тестирование роли

Для тестирования ролей ansible необходимо установить Molecule, Ansible, Testinfra.

requirements.txt (В методичке описана molecule v2, необходимо ограничить версию molecule не выше 2.xx)
```
ansible>=2.4
molecule<=2.99
testinfra>=1.10
python-vagrant>=0.5.15
```
'pip install -r ansible/requirements.txt'


Команда molecule init для создания заготовки тестов для роли db (ansible/roles/db/)
'molecule init scenario --scenario-name default -r db -d vagrant'

при выполнении появилась ошибка, потребовалось выполнить
```
pip2 uninstall backports.functools-lru-cache
apt install python-backports.functools-lru-cache
```

Команды molecule:
molecule create - создает инстанс для теста
molecule list - просмотреть созданный инстанс
molecule login -h instance - подключиться к инстансу
molecule converge - запустить роль в инстансе
molecule verify - запустить тесты
molecule destroy - удалить инстанс
molecule test - запустить последовательность create, converge, verify, destroy


## Самостоятельно

В файл db/molecule/default/tests/test_default.py добавил проверку доступности порта 27017.
```
def testing_mongo_port(host):
    host.socket("tcp://0.0.0.0:27017").is_listening
```
При выполнении 'molecule verify' счетчик тестов увеличился на 1

В провиженерах packer добавил путь к ролям ansible.

'app'
```
"extra_arguments": ["--tags","ruby"],
"ansible_env_vars": ["ANSIBLE_ROLES_PATH={{ pwd }}/ansible/roles"]
```

'db'
```
"ansible_env_vars": ["ANSIBLE_ROLES_PATH={{ pwd }}/ansible/roles"]
```

## Задание со *
Не удалось выполнить - драйвера для YC нет.
