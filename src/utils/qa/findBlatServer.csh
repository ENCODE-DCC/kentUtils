#!/usr/bin/env tcsh
source `which qaConfig.csh`

################################
#
#  06-16-08
#  Ann Zweig
#
#  gets information about which blatServer hosts which genome(s)
#
################################

set db=''
set host=''
set machine="-h $sqlrr hgcentral"
set order='db'

if ( $#argv < 1 || $#argv > 3 ) then
  echo
  echo " gets info about which blat server hosts which genome(s)"
  echo
  echo " usage:  db|host|all  [db|host]  [machine]"
  echo "   first parameter required: one specific db or host or all dbs"
  echo "   second parameter optional: order by db or by host (blatServer)"
  echo "     defaults to order by db"
  echo "   third parameter optional: specify machine"
  echo "     defaults to RR"
  echo
  exit
else
  set db={$argv[1]}%   # support wildcard
  set host=$argv[1]
endif

if ( "$HOST" != "hgwdev" ) then
 echo "\n ERROR: you must run this script on dev!\n"
 exit 1
endif

if ( $#argv > 1 ) then
  set order=$argv[2]
  if ( $order != "host" && $order != "db" ) then
    set machine=$argv[2]
    set order='db'
  endif
endif

# set host for non-RR machines
if ( $#argv == 3 ) then
  set machine=$argv[3]
endif

echo $machine | grep hgwbeta > /dev/null
if ( ! $status ) then
  set machine="-h $sqlbeta hgcentralbeta"
endif
  
echo $machine | grep hgwdev > /dev/null
if ( ! $status ) then
    set machine='hgcentraltest'
endif

echo $machine | egrep -i "hgw[1-8]|rr" > /dev/null
if ( ! $status ) then
  set machine="-h $sqlrr hgcentral"
endif

if ( all% == "$db" ) then
  set db='%'
endif

# echo "order   $order"
# echo "machine $machine"
# echo "host    $host   "
# echo "db      $db     "

# find out if user has specified host or db
echo $host | grep blat > /dev/null
if ( $status ) then
  hgsql $machine -e "SELECT DISTINCT db, host \
    FROM blatServers WHERE db LIKE '$db' ORDER BY '$order'"
else
  hgsql $machine -e "SELECT DISTINCT db, host \
    FROM blatServers WHERE host = '$host' ORDER BY '$order'"
endif
