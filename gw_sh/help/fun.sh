#!/bin/bash
#set -x

## 提示信息 带颜色

function echoColor () {
    case "$1" in
        green)  fg="32m";;
        red)    fg="31m";;
        yellow) fg="33m";;
        blue)   fg="34m";;
    esac
    echo -e "\033[${fg}${2}........... \033[0m"
}

