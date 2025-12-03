#!/bin/bash

function show_help {
    echo "Использование: $0 [опции]"
    echo "  -u, --users          Список пользователей"
    echo "  -p, --processes      Список процессов"
    echo "  -h, --help           Справка"
    echo "  -l PATH, --log PATH  Вывод в файл"
    echo "  -e PATH, --errors PATH Ошибки в файл"
    exit 0
}

function show_users {
    awk -F: '{print "User: " $1 ", Home: " $6}' /etc/passwd | sort
}

function show_processes {
    ps -e -o pid,comm --sort=pid
}

ACTION_USERS=false
ACTION_PROCESSES=false

TEMP=$(getopt -o upl:e:h --long users,processes,log:,errors:,help -n 'script.sh' -- "$@")
if [ $? != 0 ] ; then echo "Ошибка аргументов" >&2 ; exit 1 ; fi
eval set -- "$TEMP"

while true; do
  case "$1" in
    -u | --users ) ACTION_USERS=true; shift ;;
    -p | --processes ) ACTION_PROCESSES=true; shift ;;
    -h | --help ) show_help; shift ;;
    -l | --log )
        DIR=$(dirname "$2")
        if [ ! -d "$DIR" ] || [ ! -w "$DIR" ]; then
            echo "Ошибка доступа к логу: $DIR" >&2; exit 1
        fi
        exec 1>"$2"; shift 2 ;;
    -e | --errors )
        DIR=$(dirname "$2")
        if [ ! -d "$DIR" ] || [ ! -w "$DIR" ]; then
            echo "Ошибка доступа к логу ошибок: $DIR" >&2; exit 1
        fi
        exec 2>"$2"; shift 2 ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

if [ "$ACTION_USERS" = true ]; then show_users; fi
if [ "$ACTION_PROCESSES" = true ]; then show_processes; fi

if [ "$ACTION_USERS" = false ] && [ "$ACTION_PROCESSES" = false ]; then
     if [ -t 1 ]; then echo "Ничего не выбрано. См. -h" >&2; fi
fi
