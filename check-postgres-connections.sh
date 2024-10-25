#! /bin/bash

HELP="
    usage: $0 [ -W value -C value -u username -p password -h localhost]

        -W --> Warning value (number of available connections)
        -C --> Critical value (number of available connections)
        -u --> Postgres Username (default username: postgres)
        -p --> Postgres password (default password: postgres)
	-h --> Postgres localhost (default localhost: 127.0.0.1)
"
if [ "$#" -lt 2 ]; then 
    echo "${HELP}"   
else 
    default_username="postgres"
    default_password="postgres"
    default_localhost="127.0.0.1"
    default_warning_value="200"
    default_critical_value="400"

    while [ -n "${1}" ]; do
        case "${1}" in
            -W | --warning-count)
                w_count="${2}"
                shift
                shift
                ;;
            -C | --critical-count)
                c_count="${2}"
                shift
                shift
                ;;
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

    if [ -z "${w_count}" ]; then
        w_count="${default_warning_value}"
    fi

    if [ -z "${c_count}" ]; then
        c_count="${default_critical_value}"
    fi

    if [ -z "${c_count}" -o -z "${w_count}" ]; then
        status="${HELP}"
        message_string="Both critical and warning thresholds must be defined"
        status_code=1
    else
        connection_check="$(PGPASSWORD="$password" psql -U "$username" -h "$localhost" -c '\x' -c 'SELECT version();')"
        if [ $? -ge 1 ]; then
            status="Connection ERROR"
            message_string="$connection_check"
            status_code=1
        else
            max_connections="$(PGPASSWORD="$password" psql -U "$username" -h "$localhost" -c '\x' -c 'SHOW max_connections' | awk '/max_connections/ {print $3}')"
            superuser_connections="$(PGPASSWORD="$password" psql -U "$username" -h "$localhost" -c '\x' -c 'SHOW superuser_reserved_connections' | awk '/superuser_reserved_connections/ {print $3}')"
            available_connections="$(echo "$max_connections-$superuser_connections" | bc -l | tr -d '\r')"

            if [ "$available_connections" -le "$c_count" ]; then
                status="CRITICAL"
                message_string="Only $available_connections connections left available on Postgres"
                status_code=1
            elif [ "$available_connections" -le "$w_count" ]; then
                status="WARNING"
                message_string="Only $available_connections connections left available on Postgres"
                status_code=2
            else
                status="OK"
                message_string="There are $available_connections connections available on Postgres"
                status_code=0
            fi
        fi
    fi
    status_message="${status}: ${message_string}"
    echo "$status_message"
    exit "${status_code}"
fi    
