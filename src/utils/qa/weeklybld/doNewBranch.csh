#!/usr/bin/env tcsh
#
# WARNING: this does not like to be run with final & to detach from terminal.
#  Heather says perhaps running with "nohup" in front of the command might
#  make it work better.
#

cd $WEEKLYBLD

echo "BRANCHNN=$BRANCHNN"
echo "TODAY=$TODAY       (last build day)"
echo "LASTWEEK=$LASTWEEK   (previous build day)"
echo "REVIEW2DAY=$REVIEW2DAY   (review2 day, day9)"
echo "LASTREVIEW2DAY=$LASTREVIEW2DAY   (previous review2 day, day9)"
echo "REVIEWDAY=$REVIEWDAY   (review day, day2)"
echo "LASTREVIEWDAY=$LASTREVIEWDAY   (previous review day, day2)"


if ( "$TODAY" == "" ) then
 echo "TODAY undefined."
 exit 1
endif
if ( "$BRANCHNN" == "" ) then
 echo "BRANCHNN undefined."
 exit 1
endif
if ( "$LASTWEEK" == "" ) then
 echo "LASTWEEK undefined."
 exit 1
endif
if ( "$REVIEWDAY" == "" ) then
 echo "REVIEWDAY undefined."
 exit 1
endif
if ( "$LASTREVIEWDAY" == "" ) then
 echo "LASTREVIEWDAY undefined."
 exit 1
endif

set currentBranch=`git branch | grep master`
if ("$currentBranch" != "* master") then
    echo "Error: must be on master branch"
endif


if ( "$1" != "real" ) then
	echo
	echo "Not real.   To make real changes, put real as cmdline parm."
	echo
	exit 0
endif 

echo
echo "Now beginning to build new branch $BRANCHNN [${0}: `date`]"

echo

#echo debug: disabled ok cleanup
if ( -e GitReports.ok ) then
    rm GitReports.ok
endif

#echo debug: disabled cgiVersion
./updateCgiVersion.csh real

if ( $status ) then
 echo "git-cgi-version-update failed on $HOST [${0}: `date`]"
 exit 1
endif
echo "git-cgi-version-update done on $HOST [${0}: `date`]"


echo
#echo debug: disabled tagging
./tagNewBranch.csh real
if ( $status ) then
 echo "tagNewBranch.csh failed on $HOST [${0}: `date`]"
 exit 1
endif
echo "tagNewBranch.csh done on $HOST [${0}: `date`]"
echo "new branch v$BRANCHNN created."

echo
echo
echo  "NOW STARTING Git-Reports ON HGWDEV IN PARALLEL [${0}: `date`]"
echo
rm -f doNewGit.log
#echo debug: disabled buildGitReports
ssh -n hgwdev $WEEKLYBLD/buildGitReports.csh branch real >& doNewGit.log &
# note - we are now running it in the background on hgwdev

#echo
#echo  "SKIP 32-BIT BUILD ON $BOX32 [${0}: `date`]"
#echo


#---------------------

echo "Unpack the new branch on BUILDDIR for beta [${0}: `date`]"
#unpack the new branch on BUILDDIR for beta
#echo debug: disabled coBranch.csh
./coBranch.csh
if ( $status ) then
    echo "Unpack the new branch on BUILDDIR for beta FAILED [${0}: `date`]"
    echo "Waiting for any other processes to finish"
    wait
    exit 1
endif

# make the utils earlier in case it affects the other make steps
echo "Build utils on beta [${0}: `date`]"
echo
#echo debug: disabled build utils on beta
./buildUtils.csh
if ( $status ) then
    echo "Build utils on beta FAILED [${0}: `date`]"
    echo "Waiting for any other processes to finish"
    wait
    exit 1
endif

echo
echo "Build branch sandbox on beta [${0}: `date`]"
# build branch sandbox on beta
#echo debug: disabled build branch sandbox on beta
./buildBeta.csh
if ( $status ) then
     echo "build on beta failed for v$BRANCHNN [${0}: `date`]"
    # echo "v$BRANCHNN build on beta failed." | mail -s "'v$BRANCHNN Build failed on beta'" $USER ${BUILDMEISTER} galt browser-qa
    echo "v$BRANCHNN build on beta failed [${0}: `date`]." | mail -s "v$BRANCHNN Build failed on beta" $USER ${BUILDMEISTER}
    echo "Waiting for any other processes to finish"
    wait
    exit 1
endif

## copy binaries to beta machine:
rsync -a -P --exclude=hg.conf --exclude=hg.conf.private \
  /usr/local/apache/cgi-bin-beta/ qateam@hgwbeta:/data/apache/cgi-bin/
rsync -a -P --exclude=hg.conf --exclude=hg.conf.private \
  /usr/local/apache/htdocs-beta/ qateam@hgwbeta:/data/apache/htdocs/
rsync -a -P --exclude=hg.conf --exclude=hg.conf.private --delete \
  /usr/local/apache/htdocs-beta/js/ qateam@hgwbeta:/data/apache/htdocs/js/
rsync -a -P --exclude=hg.conf --exclude=hg.conf.private --delete \
  /usr/local/apache/htdocs-beta/style/ qateam@hgwbeta:/data/apache/htdocs/style/

echo "build on beta done for v$BRANCHNN [${0}: `date`]"
echo "v$BRANCHNN built successfully on beta (day 16)." | mail -s "v$BRANCHNN Build complete on beta (day 16)." $USER ${BUILDMEISTER} galt kent browser-qa

echo
echo "Waiting for the background beta:git-reports to finish [${0}: `date`]"
wait
echo "Wait complete, checking results. [${0}: `date`]"
if ( -e GitReports.ok ) then
    echo "Git Reports finished ok. [${0}: `date`]"
    echo "buildGitReports.csh done on hgwdev, sending email... [${0}: `date`]"
    echo "Ready for pairings, day 16, Git reports completed for v${BRANCHNN} branch http://genecats.cse.ucsc.edu/git-reports/ (history at http://genecats.cse.ucsc.edu/git-reports-history/)." | mail -s "Ready for pairings (day 16, v${BRANCHNN} review)." $USER ${BUILDMEISTER} donnak kuhn ann kate luvina steve

	# email all who have checked in that code summaries are due
    @ LASTNN=$BRANCHNN - 1
    #foreach victim (braney larrym angie hiram tdreszer kate chinhli)
    set victims=( `git log v${LASTNN}_base..v${BRANCHNN}_base --name-status | grep Author | sort | uniq | awk '{ end=index($0,"@"); beg=index($0,"<"); addr=substr( $0,beg+1,end-beg-1); print addr; }'` )
    echo "Expected victims:\n${victims}" | mail -s "Code summaries for v$BRANCHNN are expected from...." $USER ${BUILDMEISTER}
    foreach victim ( $victims )
		git log --author=${victim} v${LASTNN}_base..v${BRANCHNN}_base --pretty=oneline > /dev/null
		if ($? == 0) then
		       rm -f /dev/shm/build.email.${victim}.txt
                       echo "To: ${victim}" > /dev/shm/build.email.${victim}.txt
                       echo "From: ann@soe.ucsc.edu" >> /dev/shm/build.email.${victim}.txt
                       echo "Subject: Code summaries are due for ${victim}" >> /dev/shm/build.email.${victim}.txt
                       echo "Cc: ann@soe.ucsc.edu" >> /dev/shm/build.email.${victim}.txt
                       echo "" >> /dev/shm/build.email.${victim}.txt
		       ./summaryEmail.sh ${victim} >> /dev/shm/build.email.${victim}.txt
		       cat /dev/shm/build.email.${victim}.txt | /usr/sbin/sendmail -t -oi
		       rm -f /dev/shm/build.email.${victim}.txt
		endif
    end
else
    echo "Git Reports had some error, no ok file found. [${0}: `date`]"
endif
echo

exit 0
