#!/bin/bash

source_folder=$1
target_folder=./collect.sql

echo "# 数据库初始化sql" > $target_folder

for element in `ls $source_folder`
do  
    dir_or_file=$1"/"$element
    if [ -d $dir_or_file ]
    then 
        getdir $dir_or_file
    else
        echo $dir_or_file" >> $target_folder"
        cat $dir_or_file >> $target_folder
    fi  
done
