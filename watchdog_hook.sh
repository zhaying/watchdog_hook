#BGN VARS
BLOGFILE=/var/log/wdboot.log
LOGFILE=/var/log/wd.log
#END VARS

#BGN FUNCTIONS 
log_message() {
  logger -t wdping $1
  echo "$1..." | tee -a $BLOGFILE $LOGFILE;
  if [ $2 ]; then
    logger -t wdping $2
    echo "$2..." | tee -a $BLOGFILE $LOGFILE;
  fi
}
error_message() {
  NOTE="Gateway is non-existent..."
  logger -t wdping $NOTE
  echo $NOTE | tee -a $BLOGFILE $LOGFILE;
}
set_gateway_ip() {
  THE_GW=$(route -n | grep 'UG'  | awk '{print $2}')
  export THE_GW=$(route -n | grep 'UG'  | awk '{print $2}')
}
delete_ping_line() {
  sed -i '/ping/d' /etc/watchdog.conf
}
create_config_line() {
  CONFIG_LINE="ping=$THE_GW"
}
log_config_line() {
  NOTE="CONFIG_LINE is set to '$CONFIG_LINE'";
  logger -t wdping $NOTE
  echo $NOTE | tee -a $BLOGFILE $LOGFILE;
}
update_watchdog_config() {
  fgrep -qxF $CONFIG_LINE /etc/watchdog.conf || echo $CONFIG_LINE >> /etc/watchdog.conf
}
clear_log_file() {
  NOTE="Log file reset...";
  logger -t wdping $NOTE
  echo $NOTE > $BLOGFILE;
}
watchdog_setup_add() {
  clear_log_file
  #BGN MORE VARS
  COUNTER=0;
  GATEWAY_EXISTENCE=$(route -n | grep 'UG' | awk '{print $2}' | wc -c);
  #END MORE VARS

  log_message "Existence before until " $GATEWAY_EXISTENCE

  until [ $GATEWAY_EXISTENCE -gt 0 ]; do
    log_message "Waiting" $COUNTER
    log_message $GATEWAY_EXISTENCE
    sleep 1s
    log_message "Checking"
    if [ $COUNTER -gt 120 ]; then
      log_message "Aborting"
      break
    else
      COUNTER=$((COUNTER+1))
      log_message $COUNTER
    fi
  done

  log_message "Existence after until " $GATEWAY_EXISTENCE

  if [ $GATEWAY_EXISTENCE -ne 0 ]; then
    set_gateway_ip
    delete_ping_line
    create_config_line
    log_config_line
    update_watchdog_config
  else
    error_message
  fi
}


watchdog_setup() {
        case $reason in
                BOUND|RENEW|REBIND|REBOOT)
                        watchdog_setup_add
                        ;;
                EXPIRE|FAIL|RELEASE|STOP)
                        ;;
        esac
}

watchdog_setup
