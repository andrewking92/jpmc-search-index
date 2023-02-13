#!/bin/bash

echo $1
mongosh $1 --username $2 --password $3 --eval "db.getSiblingDB('$4').runCommand({create: '$5'})"