#!/bin/bash

# Функция подсказки. Вызывается, если запустить с флагом -h
function show_help {
    echo "Использование: $0 [опции]"
    echo "  -u, --users          Список пользователей"
    echo "  -p, --processes      Список процессов"
    echo "  -h, --help           Справка"
    echo "  -l PATH, --log PATH  Вывод в файл (лог)"
    echo "  -e PATH, --errors PATH Ошибки в файл"
    exit 0
}

# Функция для вывода пользователей
function show_users {
    # Берем файл /etc/passwd, разделитель двоеточие (-F:), выводим 1 и 6 колонку
    awk -F: '{print "User: " $1 ", Home: " $6}' /etc/passwd | sort
}

# Функция для просмотра процессов
function show_processes {
    # Сортируем процессы по PID для удобства
    ps -e -o pid,comm --sort=pid
}

# Флаги, чтобы запомнить, что именно выбрал пользователь
ACTION_USERS=false
ACTION_PROCESSES=false

# Использую getopt для разбора аргументов, так как getopts не умеет в длинные флаги (--users)
TEMP=$(getopt -o upl:e:h --long users,processes,log:,errors:,help -n 'script.sh' -- "$@")

# Проверяем, не ошибся ли пользователь при вводе флагов
if [ $? != 0 ] ; then 
    echo "Ошибка в аргументах, проверьте ввод" >&2 
    exit 1 
fi

# Это надо, чтобы правильно обработать аргументы с пробелами и кавычками
eval set -- "$TEMP"

# Бежим циклом по всем аргументам, которые ввел юзер
while true; do
  case "$1" in
    -u | --users ) 
        ACTION_USERS=true
        shift ;;
    -p | --processes ) 
        ACTION_PROCESSES=true
        shift ;;
    -h | --help ) 
        show_help
        shift ;;
    -l | --log )
        # Проверяем, существует ли папка для лога
        DIR=$(dirname "$2")
        if [ ! -d "$DIR" ] || [ ! -w "$DIR" ]; then
            echo "Нет доступа к папке или ее не существует: $DIR" >&2
            exit 1
        fi
        # Перенаправляем весь стандартный вывод (1) в файл
        exec 1>"$2"
        shift 2 ;;
    -e | --errors )
        # То же самое для ошибок
        DIR=$(dirname "$2")
        if [ ! -d "$DIR" ] || [ ! -w "$DIR" ]; then
            echo "Нет доступа для записи ошибок: $DIR" >&2
            exit 1
        fi
        # Перенаправляем поток ошибок (2) в файл
        exec 2>"$2"
        shift 2 ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

# Выполняем действия, если флаги были установлены
if [ "$ACTION_USERS" = true ]; then 
    show_users
fi

if [ "$ACTION_PROCESSES" = true ]; then 
    show_processes
fi

# Если ничего не выбрали, то подсказка, как пользоваться
if [ "$ACTION_USERS" = false ] && [ "$ACTION_PROCESSES" = false ]; then
     # -t 1 проверяет, что мы в терминале, а не пишем в файл
     if [ -t 1 ]; then 
        echo "Вы ничего не выбрали. Используйте -h для справки." >&2
     fi
fi
