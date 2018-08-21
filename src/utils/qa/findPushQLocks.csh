#!/usr/bin/env tcsh
source `which qaConfig.csh`

######################################
#
# Ann Zweig -- 3-20-2008
#
# find locks in the pushQ on hgwbeta
# run with 'real' to unlock them all
#
######################################

set unlock=''

if ($#argv != 1 ) then
  echo
  echo "  find all locks in the pushQ on hgwbeta"
  echo
  echo "    usage: go|real"
  echo "     run with 'go' to see a list of locks"
  echo "     run with 'real' to unlock all the locks"
  echo
  exit
else
  set run=$argv[1]
endif

set unlock=`hgsql -h $sqlbeta -Ne "SELECT qid FROM pushQ \
  WHERE lockDateTime != '' or lockUser != ''" qapushq`
if ( '' == "$unlock" ) then
  echo "\n no locks to unlock\n"  
  exit 0
endif

if ( 'go' == $run ) then
  hgsql -h $sqlbeta -e "SELECT qid, lockUser, lockDateTime FROM pushQ \
  WHERE lockDateTime != '' or lockUser != ''" qapushq
  exit 0
else 
  if ( 'real' == $run && '' != "$unlock" ) then
    foreach lock ( $unlock )
      hgsql -h $sqlbeta -e "UPDATE pushQ SET lockUser = '', lockDateTime = '' \
      WHERE qid = '$lock'" qapushq
      echo "\nunlocking qid: $lock"
    end
  else
    echo "\n  not a valid argument\n"
    echo "${0}:"
    $0
    exit 1
  endif
endif

exit 0
