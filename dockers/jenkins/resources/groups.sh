#!/bin/bash

cd $(dirname $(readlink -f $0))

if [ "$U" == "admin" ]; then
  echo "admin,superuser"
else
  if [[ -e userProjects/${U}.projects ]]; then
    cat userProjects/${U}.projects
  else
    echo nogroup
  fi
fi

