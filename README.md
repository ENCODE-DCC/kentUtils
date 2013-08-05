====================
kentUtils
====================

Jim Kent command line bioinformatic utilities

  These are only the command line bioinformatic utilities
  from the kent source tree.  This is not the genome browser install.
  For the genome browser install, use the instructions from the source tree:
    http://genome-source.cse.ucsc.edu/gitweb/?p=kent.git;a=tree;f=src/product

====================
System Requirements
====================

Linux/Ubuntu/CentOS/Unix/MacOSX operating system
gnu gcc - C code development system - http://www.gnu.org/software/gcc/
gnu make - http://www.gnu.org/software/make/
MySQL development system and libraries - http://dev.mysql.com/
libpng runtime and development packages - http://www.libpng.org/
libssl runtime and development packages - http://www.openssl.org/

Optional:
'git' source code management: http://git-scm.com/downloads

It is best to install these packages with your standard operating
system package management tools.
    (see notes below about installing packages)

====================
Download source
====================

Obtain a read-only copy of the source:
   git clone git://github.com/ENCODE-DCC/kentUtils.git

Creates the directory: ./kentUtils/

====================
Build utilities
====================

In the directory kentUtils/ run a 'make' command:
   cd kentUtils
   make

The resulting binaries are placed in ./kentUtils/bin/

   Note: there are no required shell environment settings as discussed
         in the genome browser build instructions.  In fact, this build
         system will ignore and override any shell environment settings
         you may have for the genome browser build environment.

====================
Install utilities
====================

   The binaries are built into ./userApps/bin/
   To install them in a global bin/ directory, copy them
   to a desired location, e.g.:

      sudo rsync -a -P ./userApps/bin/ /usr/local/bin/kentUtils/

   The destination bin/kentUtils/ should be its own unique directory
   to avoid overwriting same-named binaries in a standard bin/ directory.

   Users add '/usr/local/bin/kentUtils' to their shell PATH
   to access the commands.

