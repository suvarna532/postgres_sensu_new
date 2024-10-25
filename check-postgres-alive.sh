#! /bin/bash

HELP="
    usage: $0 [ -u username -p password -h localhost]

        -u --> Username 
        -p --> password
	-h --> localhost
"
if [ "$#" -lt 2 ]; then 
    echo "${HELP}"    
else 
    default_username="postgres"
    default_password="postgres"
    default_localhost="127.0.0.1"

    while [ -n "${1}" ]; do
        case "${1}" in
            -u | --username)
                username="${2}"
                shift
                shift
                ;;
            -p | --password)
                password="${2}"
                shift
                shift
                ;;
            -h | --localhost)
                localhost="${2}"
                shift
                shift
                ;;
        esac
    done

    if [ -z "${username}" ]; then
        username="${default_username}"
    fi

    if [ -z "${password}" ]; then
        password="${default_password}"
    fi

    if [ -z "${localhost}" ]; then
        localhost="${default_localhost}"
    fi
    
    connection_check="$(PGPASSWORD="$password" psql -U "$username" -h "$localhost" -c '\x' -c 'SELECT version();')"
    if [ "$?" -eq 0 ]; then
        status="OK"
        message_string="Postgres is alive"
        status_code=0
    else
        status="CRITICAL"
        message_string="$connection_check"
        status_code=1

    fi

    status_message="${status}: ${message_string}"
    echo "$status_message"
    exit "${status_code}"
fi
