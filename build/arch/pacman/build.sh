#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ID=$(docker build -t serialize/arch:pacman $DIR)
