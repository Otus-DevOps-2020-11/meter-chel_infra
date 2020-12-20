yc compute instance create \
--name reddit-app \
--hostname reddit-app \
--memory=4 \
--create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=20GB \
--network-interface subnet-name=default-ru-central1-c,nat-ip-version=ipv4 \
--metadata serial-port-enable=1 \
--metadata-from-file user-data=./template
