#!/bin/bash

#random_time=$(($RANDOM % 8))
#echo "等待 ${random_time} 分钟后开始执行"
#for((i=0; i<${random_time}; i++)); do
#    echo "倒计时 $[${random_time}-$i] 分钟"
#    sleep 1m
#done

. phone.inc.sh

sudo timedatectl set-timezone Asia/Shanghai

git config --global user.name "github-actions"
git config --global user.email "github-actions@github.com"
fz="fz_$(date '+%Y%m%d%H%M%S')"
git checkout -b $fz

bash github.phone.sh

git add .
git commit -m "update @ $(date '+%Y-%m-%d %H:%M:%S') | $(cat ./phone.txt)"
git checkout master
git merge --no-ff -m "merge @ $(date '+%Y-%m-%d %H:%M:%S') | $(cat ./phone.txt)" $fz
git push
git branch -d $fz
