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
    ## which is actually done via runuser thanks to --user.
    ## you can't do "cmd &; action" but you can do "{cmd &}; action".
    ## consul 0.2.1 added -pid-file; although the following creates $pidfile
    ## owned by consul:consul, using -pid-file results in a permission error.
    daemon \
        --pidfile=$pidfile \
        --user=consul \
        " { $exec agent -config-file=$conffile -config-dir=$confdir &>> $logfile & } ; echo \$! >| $pidfile "
    
    RETVAL=$?
    echo
    
    [ $RETVAL -eq 0 ] && touch $lockfile
    
    echo -n $"Waiting for Consul ready: "
    
    ## wait up to 60s for the rpc port to become listened-upon
    ## consul 0.2.1 got much slower to start!
    count=0
    ready=0
    pid=$( cat ${pidfile} )
    while checkpid ${pid} && [ $count -lt 60 ] && [ $ready -ne 1 ]; do
        count=$(( count + 1 ))
        
        if netstat -lptn | egrep -q ":8400.*LISTEN +${pid}/" ; then
            ready=1
        else
            sleep 1
        fi
    done
    
    if [ $ready -eq 1 ]; then
        RETVAL=0
        success
    else
        RETVAL=1
        failure
    fi
    
    echo    
    return $RETVAL
}

stop() {
    echo -n $"Shutting down $prog: "
    
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
