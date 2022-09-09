#!/bin/bash

if ! which shellcheck &> /dev/null
then
  echo "ShellCheck not installed"
  exit 1
fi
