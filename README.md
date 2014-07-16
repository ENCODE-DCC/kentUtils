kentUtils
====================

Jim Kent command line bioinformatic utilities

These are only the command line bioinformatic utilities
from the kent source tree.  This is not the genome browser install.
For the genome browser install, use the instructions from the source tree:

[src/product/](http://genome-source.cse.ucsc.edu/gitweb/?p=kent.git;a=tree;f=src/product)

System Requirements
-------------------

* Linux/Ubuntu/CentOS/Unix/MacOSX operating system
* gnu gcc - C code development system - http://www.gnu.org/software/gcc/
* gnu make - http://www.gnu.org/software/make/
* MySQL development system and libraries - http://dev.mysql.com/
* libpng runtime and development packages - http://www.libpng.org/
* libssl runtime and development packages - http://www.openssl.org/
* 'git' source code management: http://git-scm.com/downloads

These procedures expect the 'git' command to be available.

It is best to install these packages with your standard operating
system package management tools.
See also: [notes below](https://github.com/ENCODE-DCC/kentUtils#installing-required-packages) about installing packages.


Download source
---------------

Obtain a read-only copy of the source:

    git clone git://github.com/ENCODE-DCC/kentUtils.git

Creates the directory: ./kentUtils/

Build utilities
---------------

In the directory kentUtils/ run a 'make' command:

    cd kentUtils
    make

The resulting binaries are placed in the directory: ./bin/

    Note: there are no required shell environment settings as discussed
        in the genome browser build instructions.  In fact, this build
        system will ignore and override any shell environment settings
        you may have for the genome browser build environment.

Install utilities
-----------------

The binaries are built into ./bin/

To install them in a global bin/ directory, copy them
to a desired location, for example:

    sudo rsync -a -P ./bin/ /usr/local/bin/kentUtils/

The destination bin/kentUtils/ should be its own unique directory
to avoid overwriting same-named binaries in a standard bin/ directory.

Users add '/usr/local/bin/kentUtils' to their shell PATH
to access the commands.

Update utilities
----------------

This procedure expects the 'git' command to be available.

With the 'git' command available, the 'make update' will refresh
the source tree and rebuild.  In this directory:

    make update

This runs a 'make clean' in the source tree, runs a 'git pull' update
for the source, then runs a 'make utils' to rebuild everything.

Parasol
-------

There are 'parasol' binaries built into ./src/parasol/bin/
Use these binaries to set up a job control system on a compute cluster
or large machine with many CPU cores.
See also: [parasol README](http://genecats.cse.ucsc.edu/eng/parasol.htm)
for more information.  The usage messages from each command will help
with the setup.

Documentation
-------------

Each 'kent' command contains its own documentation.  Simply run the
commands without any arguments to see the usage message for operating
instructions.

When the utilities are built here, their usage messages have
been collected together in one file:

    kentUtils.Documentation.txt

MySQL database access
---------------------

Many of the commands can use the UCSC public MySQL server, or
your own local MySQL server with UCSC data formats.  Add these three
lines to a file in your HOME directory called '.hg.conf' and set
its permissions to: 'chmod 600 .hg.conf'

    db.host=genome-mysql.cse.ucsc.edu
    db.user=genomep
    db.password=password

This '.hg.conf' file is used by the kent commands to determine the
MySQL host and user/password to the database.  For your local MySQL
installation, use your host name and your read-only user/password names.

Installing required packages
----------------------------

On a MacOS system, you will need the [XCode](https://developer.apple.com/xcode/)
system installed.

And the [Mac Ports](http://www.macports.org/) install system.

With the Mac ports and XCode systems installed, you can install
the additional packages required (and helpful):

    sudo port install git-core gnutls rsync libpng mysql55 openssl curl wget

On a typical Linux system, for example Ubuntu, use the apt-get command
to install additional packages:

    sudo apt-get install git libssl-dev openssl mysql-client-5.1 mysql-client-core-5.1

Depending upon the version of your Linux/Ubuntu/CentOS operating system,
the specific version of packages you need may be different than this example.

Please use your standard operating system package management
install system (e.g. 'yum' on CentOS) to obtain correct versions of
these packages for your specific operating system version.

See also:

* [apt-get](https://help.ubuntu.com/8.04/serverguide/apt-get.html)
* [yum](http://www.centos.org/docs/5/html/yum/)

Known Problems
--------------

Please advise UCSC if you have the recommended installed libraries
and development system and this build will not function.
email to: <A HREF="mailto:&#103;&#101;n&#111;&#109;&#101;&#45;&#119;&#119;w&#64;&#115;&#111;&#101;.ucs&#99;.&#101;&#100;&#117;">
&#103;&#101;n&#111;&#109;&#101;&#45;&#119;&#119;w&#64;&#115;&#111;&#101;.ucs&#99;.
&#101;&#100;&#117;</A>

1. These procedures will not work as-is on sparc or alpha machines or
   with the Sun Solaris operating system.

Update history
--------------

* 16 Jul 2014 - brought up to date to version 302 source
* 17 Dec 2013 - brought up to date from version version 286 to version 293 source

============================================================================
