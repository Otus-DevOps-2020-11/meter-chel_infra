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
AgAAAABKx-eaAATuwd9nKf9Wy0clsNmFjQQWXJM

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

token: AgAAAABKx-eaAATuwd9nKf9Wy0clsNmFjQQWXJM
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
	    "folder_id": "b1g09rkrom55eupsmgpm",
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


# Домашняя работа к лекции №8
# Знакомство с Terraform
# (Terraform-1)

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
      image_id = "fd8fg4r8mrvoq6q2ve76"
    }
  }

  network_interface {
    # Указан id подсети default-ru-central1-a
    subnet_id = "e9bem33uhju28r5i7pnu"
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

connection {
  type = "ssh"
  host = yandex_compute_instance.app.network_interface.0.nat_ip_address
  user = "ubuntu"
  agent = false
  # путь до приватного ключа
  private_key = file("~/.ssh/id_rsa")
  }

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
~ folder_id = "b1g4871feed9nkfl3dnu" -> (known after apply)
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
cloud_id = "b1g7mh55020i2hpup3cj"
folder_id = "b1g4871feed9nkfl3dnu"
zone = "ru-central1-a"
image_id = "fd8mmtvlncqsvkhto5s6"
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


# Домашняя работа к лекции №9
# Принципы организации инфраструктурного кода и работа над инфраструктурой в команде на примере Terraform
# (Terraform-2)

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
Модули будут загружены в директорию `.terraform`, в которой уже содержится провайдер

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


# Задания со *
