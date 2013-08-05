#  Makefile for kentUtils project
#  performs the operations of fetching selected directories from
#  the kent source tree using 'git' and then building the utilities
#  in the kent source tree.  All build results will be kept locally
#  in this directory.

export DESTDIR = ${CURDIR}
export BINDIR = /bin
export MACHTYPE = local
export CGI_BIN = ${DESTDIR}/cgi-bin
export DOCUMENTROOT = ${DESTDIR}/htdocs
export SCRIPTS = ${DESTDIR}/scripts
export SAMTABIXDIR = ${DESTDIR}/samtabix
export USE_SAMTABIX = 1
export USE_SSL = 1
export NOSQLTEST = 1

all:  utils

utils: libs
	cd src && ${MAKE} userApps
	cd src/parasol && ${MAKE}
	./src/utils/userApps/mkREADME.sh ${DESTDIR}/${BINDIR} ${CURDIR}/kentUtils.Documentation.txt

libs: fetchSamtabix installEnvironment
	cd samtabix && ${MAKE}
	cd src && ${MAKE} libs

clean:
	test ! -d src || (cd src && ${MAKE} -i -k clean)
	rm -fr samtabix

fetchSamtabix:
	test -d samtabix || /bin/echo "git clone fetch samtabix" 1>&2
	test -d samtabix || git clone http://genome-source.cse.ucsc.edu/samtabix.git samtabix

# this installEnvironment will add all the shell environment variables
# to the src/inc/localEnvironment.mk file which is included
# from the src/inc/userApps.mk to allow any 'make' to function
# properly when inside this extracted source tree.  The 'sed' operation
# removes the '-e' from the echo for systems where the echo command doesn't
# recognize the '-e' argument

installEnvironment:
	@echo -e "export DESTDIR = ${DESTDIR}\n\
export BINDIR = ${BINDIR}\n\
export MACHTYPE = ${MACHTYPE}\n\
export CGI_BIN = ${CGI_BIN}\n\
export DOCUMENTROOT = ${DOCUMENTROOT}\n\
export SCRIPTS = ${SCRIPTS}\n\
export SAMTABIXDIR = ${SAMTABIXDIR}\n\
export USE_SAMTABIX = 1\n\
export USE_SSL = 1\n\
export NOSQLTEST = 1" | sed -e 's/-e //' > src/inc/localEnvironment.mk

update: clean
	git pull
	${MAKE} utils
