#!/bin/bash

declare -a components

components=('base' 'api' 'engine' 'monitors')
tag='train'

docker login
for c in ${components[*]}; do
    echo $c
    docker push jijisa/centos-source-masakari-${c}:${tag}
done
