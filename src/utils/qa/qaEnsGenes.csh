#!/usr/bin/env tcsh
source `which qaConfig.csh`

###############################################
# 
#  03-18-08
#  Ann Zweig
#
#  Runs through the usual checks for Ensembl
#  Gene updates.
# 
###############################################

set runOn=''
set ver=0
set dbs=''
set db=''
set betaList=''

if ($#argv != 2 ) then
  echo
  echo "  runs test suite for ensGene track update"
  echo "  run this script before you push the new tables to beta"
  echo "  (makes lots of files: run in junk directory)"
  echo "  (it's best to direct output and errors to a file: '>&')"
  echo
  echo "    usage: ensGeneVersionNumber (db | all)"
  echo "      ensGeneVersionNumber  = Ensembl's version, e.g. 49"
  echo "      choose one database (db) or all dbs with ensGenes tracks (all)"
  echo
  exit 1
else
  set ver=$argv[1]
  set runOn=$argv[2]
endif

# run only from hgwdev
if ( "$HOST" != "hgwdev" ) then
  echo "\nERROR: you must run this script on hgwdev!\n"
  exit 1
endif

# check input
if ( $ver <= 45 || $ver >= 100 ) then
  echo "\nERROR: you must enter a valid version number!\n"
  exit 1
endif

# get rid of files, if they are around
rm -f xxDbList$$ xxNotActive$$ xxNotOnBeta$$

# figure out which assemblies already have an ensGene track on beta
set betaList=`getAssemblies.csh ensGene | egrep -v 'get' | egrep -v 'ensGene'` 

# figure out which databases we're running it on
if ( 'all' == $runOn ) then
 set dbs=`hgsql -Ne "SELECT db FROM trackVersion WHERE version = '$ver' \
 and name='ensGene' ORDER BY db" hgFixed | sort -u`
 echo "\nThe following databases were updated on hgwdev to ensGenes v$ver :"
 echo "$dbs\n"

 if ( "" == "$dbs" ) then
  echo "\nERROR: there is no update available for version number $ver\n"
  exit 1
 else # updates for this ensGene version exist
  foreach db ($dbs)
   set onBeta=`hgsql -h $sqlbeta -Ne "SELECT name FROM dbDb \
   WHERE name = '$db' AND active = 1" hgcentralbeta`

   if ( "" == "$onBeta" ) then
    echo $db >> xxNotActive$$
   else
    set hasTrack=''
    set hasTrack=`echo $betaList | egrep -wo $db`
    if ( "$db" != "$hasTrack" ) then
     echo $db >> xxNotOnBeta$$
     echo $db >> xxDbList$$
    else
     echo $db >> xxDbList$$
    endif
   endif
  end

  # print out all results
  if ( -e xxNotActive$$ ) then
   echo "\nOf that list, the following databases are not active on beta"
   echo "so the tests in this script will not be run on them:"
   cat xxNotActive$$
  endif

  if ( -e xxNotOnBeta$$ ) then
   echo "\nOf that list, the following databases do not have an ensGenes track"
   echo "on hgwbeta (however, the tests in this script will still be run on them)."
   echo "You might consider releasing an ensGenes track for these databases:"
   cat xxNotOnBeta$$
  endif

  set dbs=`cat xxDbList$$`
 endif
else # running on one database only (don't check, just run)
 echo "\nRunning script for Ensebml Genes v$ver on this assembly:\n"
 set dbs=$runOn
 echo $dbs
endif

# a huge loop through all databases
foreach db ($dbs)
 echo "\n\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
 echo "~~~~~~~~~ $db ~~~~~~~~~~~~"
 echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

 # find out if this is a new Ensembl Genes track (or an update)
 set ensTrack=`echo $betaList | egrep -wo $db`

 echo "\n\n----------------------"
 echo "compare new (dev) and old (beta) ens* tables"
 echo "this shows the counts of rows unique to dev, unique to beta, and"
 echo "present on both.  you should be suspicious if there are big differences"
 compareWholeColumn.csh $db ensGene name
 compareWholeColumn.csh $db ensPep name
 compareWholeColumn.csh $db ensGtp transcript
 echo

 echo "\n\n----------------------"
 echo "check a few of the new additions to the ensGene table"
 echo "(be sure to click all the way out to Ensembl website)"
 echo "\ncheck these in $db browser on hgwdev:"
 head -2 $db.ensGene.name.devOnly
 tail -2 $db.ensGene.name.devOnly

 # only do this test if the ensGene track already exists on beta
 if ( $db == $ensTrack ) then
  echo "\n\n----------------------"
  echo "check a few of the deleted items from the ensGene table"
  echo "(make sure they have also been dropped from Ensembl website)"
  echo "\ncheck these in $db browser on hgwbeta:"
  head -2 $db.ensGene.name.betaOnly
  tail -2 $db.ensGene.name.betaOnly
 endif

 echo "\n\n----------------------"
 echo "these are full sets of corresponding rows from the three tables:"
 echo "ensGene <-> ensPep <-> ensGtp on hgwdev"
 echo "\ncheck these two genes (and their peptides) on hgwdev for '$db':"
 hgsql -e "SELECT * FROM ensGene, ensPep, ensGtp WHERE \
 ensGene.name = ensPep.name AND ensGene.name = ensGtp.transcript LIMIT 2\G" $db

 echo "\n\n----------------------"
 echo "run genePredCheck on the ensGene table. if there a failure here,"
 echo "then something is seriously wrong with the ensGene table."  
 echo "MarkD can help you figure out exactly what's wrong."
 echo "\ngenePredCheck results for $db.ensGene on hgwdev:" 
 genePredCheck -db=$db ensGene

 echo "\n\n----------------------"
 echo "find out which chroms the genes are on (for both dev and beta)."  
 echo "look for unusually small or large numbers here (or big differences)."
 # don't run this on scaffold assemblies
 set numChroms=`hgsql -Ne "SELECT COUNT(*) FROM chromInfo" $db`
 if ( $numChroms < 100 ) then
  if ( $db == $ensTrack ) then
   countPerChrom.csh $db ensGene $db hgwbeta
  else
   countPerChrom.csh $db ensGene $db
  endif
 else
  echo "$db is a scaffold assembly: skipping countPerChrom"
 endif
 echo

 echo "\n\n----------------------"
 echo "featureBits for new (dev) and old (beta) tables"
 echo "\nfeatureBits $db ensGene (on hgwdev):"
 featureBits $db ensGene
 echo "featureBits $db -countGaps ensGene (on hgwdev):"
 featureBits $db -countGaps ensGene
 echo "featureBits $db -countGaps ensGene gap (on hgwdev):"
 featureBits $db -countGaps ensGene gap

 if ( $db == $ensTrack ) then
  echo "\nfeatureBits $db ensGene (on hgwbeta):"
  (setenv HGDB_CONF $HOME/.hg.conf.beta; featureBits $db ensGene)
  echo "featureBits $db -countGaps ensGene (on hgwbeta):"
  (setenv HGDB_CONF $HOME/.hg.conf.beta; featureBits $db -countGaps ensGene)
  echo "featureBits $db -countGaps ensGene gap (on hgwbeta):"
  (setenv HGDB_CONF $HOME/.hg.conf.beta; featureBits $db -countGaps ensGene gap)
 endif
 echo

 echo "\n\n----------------------"
 echo "check that the ensGene track is sorted by chrom:"
 echo "positionalTblCheck -verbose=2 $db ensGene\n"
 positionalTblCheck -verbose=2 $db ensGene
 echo

 echo "\n\n----------------------"
 echo "run Joiner Check. look for errors in the following two lines only:"
 echo "ensPep.name and ensGtp.transcript"
 echo "\nrunning joinerCheck for $db on ensemblTranscriptId:"
 joinerCheck -keys -database=$db -identifier=ensemblTranscriptId ~/kent/src/hg/makeDb/schema/all.joiner

 echo "\n\n----------------------"
 echo "ensGene names typically begin with 'ENS'. if there is a number other"
 echo "than 0, then there are ensGenes that do not begin with 'ENS'."
 echo "check them out on the Ensembl website."
 echo "\nnumber of ensGenes that do not begin with 'ENS' in '$db':"
 set num=`hgsql -Ne "SELECT COUNT(*) FROM ensGene WHERE name \
 NOT LIKE 'ENS%'" $db`
 echo $num
 if ( 0 != $num ) then
  echo "instead of 'ENS', the ensGenes in this table look like this:"
  hgsql -Ne "SELECT name FROM ensGene WHERE name NOT LIKE 'ENS%' LIMIT 3" $db
 endif

 echo "\n\n----------------------"
 echo "A few tracks have another table or two associated with them.  For"
 echo "example, when Ensembl uses different scaffold names than we do, there"
 echo "should be a translation table called: ensembleGeneScaffold.  This"
 echo "table supports a separate track called: Ensembl Assembly."
 echo "Assemblies with a UCSC Gene track should also have a table called:"
 echo "knownToEnsembl. Here's what this assembly has:"
 echo
 hgsql -Ne "SHOW TABLES LIKE 'ensemblGeneScaffold'" $db
 hgsql -Ne "SHOW TABLES LIKE 'knownToEnsembl'" $db

end # huge loop through each database

# remember the hgFixed.trackVersion table
echo "\n\n----------------------"
echo "Don't forget to also push (to beta and then to the RR)"
echo "the trackVersion table in the hgFixed database."
echo "There are rows to allow the correct version number to be displayed in hgTrackUi."
echo "Before you push the table, check the differences with compareWholeTable.csh hgFixed trackVersion"
echo "See Wiki for more details: http://genomewiki.cse.ucsc.edu/genecats/index.php/Ensembl_QA"

# make sure the date column has been updated
echo "\n\n----------------------"
echo "the dateReference column in the hgFixed.trackVersion table"
echo "should say 'current' for your database (or all):"
hgsql -Ne "SELECT db, dateReference FROM trackVersion WHERE version = $ver AND name = 'ensGene' ORDER BY db" hgFixed

# check that the corresponding upstream MAF files have been updated
echo "\n\n----------------------"
echo "In conjunction with an Ensembl Gene update, some upstream MAF files need"
echo "to be rebuilt. Specifically those for: ornAna1, fr2, gasAcu1, oryLat2"
echo "Check for them here (look for new dates) there should be 3 for each db:"
echo "hgwdev:/data/apache/htdocs-hgdownload/goldenPath/<db>/multiz*way/maf/ensGene.upstream?000.maf.gz"
echo

# clean up
rm -f xxDbList$$ xxNotActive$$ xxNotOnBeta$$

echo "\nthe end.\n"

exit 0
