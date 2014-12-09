#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
$("$DIR/filesystem/build.sh")
$("$DIR/glibc/build.sh")
$("$DIR/bash/build.sh")
$("$DIR/perl/build.sh")
$("$DIR/pacman/build.sh")

