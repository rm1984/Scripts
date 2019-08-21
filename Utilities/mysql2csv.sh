#!/usr/bin/env bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        mysql2csv.sh
#
# Description:  A script that reads all the "INSERT" queries from a MySQL dump
#               file and saves the records in a CSV file ("dump_sql.csv").
#               The result may be a bit messy but is easy to grep and parse.
#
# Usage:        ./mysql2csv.sh <sql_dump>
#
#
# --TODO--
# - ???
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

SQL=$1


# FUNCTIONS --------------------------------------------------------------------

command_exists() {
    command -v "$1" >/dev/null 2>&1 || { echo "ERROR! Command not found: $1" 1>&2 ; exit 1 ; }
}


# CHECKS -----------------------------------------------------------------------

declare -a CMDS=(
"dos2unix"
"gawk"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done

if [[ "$#" -ne 1 ]] ; then
    echo "Usage: ./mysql2csv.sh <sql_dump>"

    exit 1
fi


# MAIN -------------------------------------------------------------------------

cat $SQL | dos2unix | gawk '
BEGIN {
  table = "dump_sql";
  sql = 1
}

{
  if ($0 ~ "^INSERT INTO ") {
    sql = 0
  }
  else if ($0 ~ "^DROP TABLE IF EXISTS") {
    table = gensub(/DROP TABLE IF EXISTS `(.+)`;/, "\\1", "g" $0);
    sql = 1
  }
  else {
    sql = 1
  }

  if (sql == 1) {
    print > table".sql";
  }
  else {
    n = split($0, a, /(^INSERT INTO `[^`]*` VALUES \()|(\),\()|(\);$)/)

    for(i=1;i<=n;i++) {
      len = length(a[i])
      if (len > 0) {
        data = a[i]
        print data > table".csv";
      }
    }
  }
}

END {}
'
