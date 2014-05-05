#!/bin/bash
#
# consul        Manage the consul agent
#       
# chkconfig:   2345 95 95
# description: Consul is a tool for service discovery and configuration
# processname: consul
# config: /etc/consul.conf
# pidfile: /var/run/consul.pid

### BEGIN INIT INFO
# Provides:       consul
# Required-Start: $local_fs $network
# Required-Stop:
# Should-Start:
# Should-Stop:
# Default-Start: 2 3 4 5
# Default-Stop:  0 1 6
# Short-Description: Manage the consul agent
# Description: Consul is a tool for service discovery and configuration
### END INIT INFO

# source function library
. /etc/rc.d/init.d/functions

prog="consul"
user="consul"
exec="/usr/bin/$prog"
pidfile="/var/run/$prog.pid"
lockfile="/var/lock/subsys/$prog"
logfile="/var/log/$prog"
conffile="/etc/consul.conf"
confdir="/etc/consul.d"
membersfile="/var/lib/consul/server_members"

# pull in sysconfig settings
[ -e /etc/sysconfig/$prog ] && . /etc/sysconfig/$prog

export GOMAXPROCS=${GOMAXPROCS:-2}

start() {
    [ -x $exec ] || exit 5
    
    [ -f $conffile ] || exit 6
    [ -d $confdir ] || exit 6

    umask 077

    touch $logfile $pidfile
    chown $user:$user $logfile $pidfile

    echo -n $"Starting $prog: "
    
    ## holy shell shenanigans, batman!
    ## daemon can't be backgrounded.  we need the pid of the spawned process,
    ## which is actually done via runuser thanks to --user.  you can't do "cmd
    ## &; action" but you can do "{cmd &}; action".
    daemon \
        --pidfile=$pidfile \
        --user=consul \
        " { $exec agent -config-file=$conffile -config-dir=$confdir &>> $logfile & } ; echo \$! >| $pidfile "
    
    RETVAL=$?
    echo
    
    [ $RETVAL -eq 0 ] && touch $lockfile
    
    if [ -s $membersfile ]; then
        echo -n $"Re-joining cluster: "
        
        ## allow time to launch
        sleep 5
        
        ## I think I want to iterate through every entry in $membersfile and
        ## return success if any are successfully joined…
        cat $membersfile | xargs $exec join &>> /dev/null
        
        RETVAL=$?
        
        if [ $RETVAL -eq 0 ]; then
            success

            rm -f $membersfile
        else
            failure
        fi
        
        echo
    fi
    
    return $RETVAL
}

stop() {
    echo -n $"Shutting down $prog: "
    
    ## store current server members so we can re-join later. exclude ourselves.
    our_ip=$( ip addr show dev eth0 | awk '/inet / { split($2, cidr, "/"); print cidr[1]; }' )
    consul members -status=alive -role=consul \
        | awk '{ split($2, addr, ":"); print addr[1] }' \
        | fgrep -v $our_ip \
        > $membersfile
        
    ## graceful shutdown with leave
    $exec leave &> /dev/null
    
    RETVAL=$?
    
    [ $RETVAL -eq 0 ] && success || failure

    echo
    [ $RETVAL -eq 0 ] && rm -f $lockfile $pidfile
    return $RETVAL
}

restart() {
    stop
    start
}

reload() {
    echo -n $"Reloading $prog: "
    killproc -p $pidfile $exec -HUP
    echo
}

force_reload() {
    restart
}

rh_status() {
    status -p "$pidfile" -l $prog $exec
    
    RETVAL=$?
    
    [ $RETVAL -eq 0 ] && $exec members
    
    return $RETVAL
}

rh_status_q() {
    rh_status >/dev/null 2>&1
}

case "$1" in
    start)
        rh_status_q && exit 0
        $1
        ;;
    stop)
        rh_status_q || exit 0
        $1
        ;;
    restart)
        $1
        ;;
    reload)
        rh_status_q || exit 7
        $1
        ;;
    force-reload)
        force_reload
        ;;
    status)
        rh_status
        ;;
    condrestart|try-restart)
        rh_status_q || exit 0
        restart
        ;;
    *)
        echo $"Usage: $0 {start|stop|status|restart|condrestart|try-restart|reload|force-reload}"
        exit 2
esac

exit $?
