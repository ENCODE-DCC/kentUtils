#!/usr/bin/env tcsh
source `which qaConfig.csh`


################################
#
#  Pushes multiple tables from dev to beta
#  can't use "&" after output command because of "password prompt"
#  (if you do, each command gets put into background and 
#      requires "fg" to get to password prompt)
#  can't redirect output into file: 
#      use "script filename.out" to capture ?
#  also records total size of the push
#
################################

set db=""
set tablelist=""

set warningMessage="\n usage:  `basename $0` database tableList\n\
\n\
Pushes tables in list to mysqlbeta and records size. \n\
Requires sudo access to mypush to run.\n\
\n\
If prompted to re-type password, sudo timeout length\n\
may not be set to a long enough interval. Check with\n\
admins if this is the case.\n\
\n\
Will report total size of push and write two files:\n\
db.tables.push -> output for all tables from mypush\n\
db.tables.pushSize -> size of push\n"

if ($2 == "") then
  echo $warningMessage
  exit
else
  set db=$1
  set tablelist=$2
endif

set trackName=`echo $2 | sed -e "s/Tables//"`

rm -f $db.$trackName.push
foreach table (`cat $tablelist`)
  echo pushing "$table"
  sudo -v # validate sudo timestamp and extend timeout
  sudo mypush $db "$table" $sqlbeta >> $db.$trackName.push
  echo "$table" >> $db.$trackName.push
end
echo


# --------------------------------------------
# "check that all tables were pushed:"

echo
updateTimes.csh $db $tablelist
echo


# --------------------------------------------
# "find the sizes of the pushes:"

echo
echo "find the sizes of the pushes:"
echo
grep 'total size' $db.$trackName.push | gawk '{total+=$4} END {print total}' \
   > $db.$trackName.pushSize
set size=`cat $db.$trackName.pushSize`
echo "$size\n    bytes"
echo
echo $size | gawk '{print $1/1000;print "    kilobytes"}'
echo
echo $size | gawk '{print $1/1000000;print "    megabytes"}'
echo
echo

echo end.
exit 0
