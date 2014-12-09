#!/bin/bash

# Output to standard error
function stderr() { 
    echo "$@" >&2; 
}

# Output debug message to standard error
function debug() { 
    stderr "--- $@"; 
}

# Output to standard error
function stderr-n() { 
   echo -n "$@" >&2; 
}

# Output debug message to standard error
function debug-n() { 
   stderr-n "$@"; 
}

function get_dir() {
   local FILE=$1
   local DIRNAME=$( dirname "$FILE" )
   echo "$( cd $DIRNAME && pwd )"
}

