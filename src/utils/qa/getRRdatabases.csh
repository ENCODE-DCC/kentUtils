#!/usr/bin/env tcsh
source `which qaConfig.csh`

################################
#  10-04-04
#  gets the names of all databases on an RR machine
#  using mark's genbank dumps.
#
################################

set databases=""
set rootpath="/cluster/data/genbank/var/tblstats"  # mark's TABLE STATUS dump
set mach1=""
set dirname1=""
set machpath1=""
set fullpath1=""
set betamachs=""
set betapath=""
set betaflag=0
set betacommand="" 
set badmach=0
set active=""

if ( $#argv < 1 || $#argv > 2 ) then
  echo
  echo "  gets the names of all databases on an RR machine"
  echo "  not real-time. uses daily TABLE STATUS dump."
  echo
  echo "    usage: machine [active]"
  echo "     use 'active' param to restrict list to only active DBs"
  echo "     will accept machine = rr"
  echo
  exit
else
  set mach1=$argv[1]
  if ( $#argv == 2 ) then
    set active=$argv[2]
  endif
endif

if ( `echo $mach1 | egrep "hgw1|hgw2|hgw3|hgw4|hgw5|hgw6|rr"` == $mach1 ) then
  set machpath1=$rootpath/$tblStatusDumps
else
  set machpath1=$rootpath/$mach1
endif

set betalist=""
if (! -e $rootpath ) then
  set betapath="/genbank/var/tblstats"
  set betamachs=`ssh hgwbeta ls /genbank/var/tblstats`
  if ( $status ) then
    echo
    echo "  can't find list of valid RR machines in $rootpath"
    echo "     or in hgwbeta:/genbank/var/tblstats"
    echo
    exit 1
  else
    set betaflag=1
    set betacommand="ssh hgwbeta"
    echo $betamachs | grep $mach1 > /dev/null
    if ( $status ) then
      set badmach=1
    endif
  endif
else
  if (! -e $machpath1 ) then
    set badmach=1
  endif
endif

if ($badmach == 1) then
  echo
  echo "  $mach1 is not a valid machine"
  echo
  exit 1
endif

set debug="true"
set debug="false"

if ($debug == "true") then
  echo
  echo "mach1     $mach1"
  echo
  echo "machpath1 $machpath1"
  echo "dirname1  $dirname1"
  echo "fullpath1 $fullpath1"
  echo
  exit
endif

# set paths for most recent table status dump
if ( $betaflag == 0 ) then
  set dirname1=`ls $machpath1 | sort -r | head -1`
  set fullpath1=$machpath1/$dirname1
else
  # use data on beta
  set dirname1=`$betacommand ls $betapath/$mach1 | sort -r | head -1`
  set fullpath1=$betapath/$mach1/$dirname1
endif

if ( active != $active ) then
  # get names of databases from files database.tbls in mark's directories
  $betacommand ls -1 $fullpath1 | grep "tbls" | sed -e "s/\.tbls//" | sort
  echo "last dump: $dirname1"
else
  ssh hgwdev "hgsql -h $sqlrr -Ne '"SELECT name FROM dbDb WHERE \
   active = 1 ORDER BY name"' hgcentral"
endif
