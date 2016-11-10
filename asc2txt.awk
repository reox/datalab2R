#!/usr/bin/awk
# Reading DataLab's ASC files and convert them to R files.
#
# Sebastian Bachmann, 2016
#
# The documentation of the ASC file format was taken from:
#   http://datalab.epina.at/helpeng/asc_format.htm
#
# This parser has probably some faults and limitations
#
# Known Limitations are:
# * Header information with escaped quotes are not parsed correctly
# * We do not know what the FLAG_NOMINAL does, we only have test data with FALSE

BEGIN {
    description = "";
    ncols = 0;
    nrows = 0;

    # Define the flags as array
    # So we can manipulate them easier from functions
    flags[0] = 0;
    flags[1] = 0;
    flags[2] = 0;
    flags[3] = 0;

    # Controls if there is a classinfo preceeding the row
    FLAG_CLASSINFO = 0;
    # Controls if there are Feature names, aka row names
    FLAG_FEATNAMES = 1;
    # Controls if there are names for each object, e.g. row
    FLAG_OBJNAMES = 2;
    # This Flag is not part of the online documentation but present in files
    FLAG_NOMINAL = 3;
}

function parseBoolean(param, flag) {
    # Row 4 contains the Flags
    if (param == "TRUE"){
        flags[flag] = 1;
    }
    else if (param == "FALSE"){
        flags[flag] = 0;
    }
    else {
        print FILENAME " (line " FNR "): ERROR: Expected TRUE or FALSE" > "/dev/stderr";
        exit 1;
    }
}


(FNR == 1){
    # Store the description which is in line 1.
    # We probably do not need it...
    description = $0;
    next;
}

(FNR == 2){
    # Row 2 contains the number of features = number of columns
    ncols = $1;
    next;
}

(FNR == 3){
    # Row 3 contains the number of rows = number of objects
    nrows = $1;
    next;
}

(FNR == 4){
    parseBoolean($1, FLAG_CLASSINFO);
    parseBoolean($2, FLAG_FEATNAMES);
    parseBoolean($3, FLAG_OBJNAMES);
    parseBoolean($4, FLAG_NOMINAL);

    next;
}

# Debugging only...
END {
    print "DESCRIPTION " description;
    print "NCOLS " ncols;
    print "NROWS " nrows;
    print "FLAG_CLASSINFO " flags[0];
    print "FLAG_FEATNAMES " flags[1];
    print "FLAG_OBJNAMES " flags[2];
    print "FLAG_NOMINAL " flags[3];
}
