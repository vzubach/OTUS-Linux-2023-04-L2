#!/usr/bin/bash
#Получаем права суперпользователя
sudo -i
# Создаём RAID массив из 5 дисков:
echo Создаём RAID 5
sleep 1
mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
mdadm --create --verbose /dev/md0 -l 5 -n 5 /dev/sd{b,c,d,e,f}
echo RAID 5 создан!
# Создаём GPT разметку на созданном массиве
echo Создаём GPT
sleep 1
parted -s /dev/md0 mklabel gpt
# Создаём два одинаковых раздела на новом массиве
echo Создаём два одинаковых раздела
sleep 1
parted -s /dev/md0 mkpart primary ext4 0% 50%
sleep 1
parted -s /dev/md0 mkpart primary ext4 50% 100%
sleep 1
# Создаём папку для файла конфигурации программы mdadm
mkdir /etc/mdadm
# Создаём сам конфигурационный файл
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
# Форматируем разделы в формате ext4
echo Форматируем и монтируем разделы
sleep 1
for i in $(seq 1 2); do sudo mkfs.ext4 /dev/md0p$i; done
sleep 1
# Создаём папки в которые будут монтироваться разделы
mkdir -p /raid/part{1,2}
# Монтируем в них разделы
for i in $(seq 1 2); do sudo mount /dev/md0p$i /raid/part$i; done
echo Вносим информацию в файл fstab
sleep 1
# Парсим UUID и точки монтирования наших новых разделов, собираем строки конфигурации и записываем их в файл fstab 
# для атоматического монтирования разделов при загрузке. Подразумевается что это первый массив в этой ОС
for i in $(seq 1 2); do echo -e $(ls -al /dev/disk/by-uuid/ | grep md0p$i | awk '{print "UUID="$9}')"\t""$(findmnt -m | grep md0p$i | awk '{print $1,"\t"$3}')""\tdefaults\t0\t$((i+1))" ; done >> /etc/fstab
echo Всё готово!

