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
# * Feature Names with escaped quotes are not parsed correctly
# * Feature names seperated by "any ASCII character below 32" is not parsed correctly
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

    # Constant for NaN
    nan = "###"

    # Some more flags for our state machine
    col_cols = 0;
    col_rows = 0;
    col_cur = 0;

    _ord_init();
}

# We need the ORD function, taken from
# https://www.gnu.org/software/gawk/manual/html_node/Ordinal-Functions.html
function _ord_init()
{
    for (i = 0; i <= 255; i++) {
        t = sprintf("%c", i)
        _ord_[t] = i
    }
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

(FNR > 4 && flags[FLAG_FEATNAMES] && ncols > col_cols) {
    # We need to parse the header fields
    # TODO we do not support the full range of seperators, not even SPACE!
    # This is quite fatal but all our test data has tabs...
    split($0, h, "\t", seps)
    for (x in h) {
        if (h[x] != "") {
            headers[col_cols] = h[x];
            col_cols++;
        }
    }
    next;
}


(col_cols == ncols){
    c=0
    while($0) {
        match($0,/[ \t]*"[^"]*"[ \t]*|[^ \t]*/)
        if (RLENGTH == 0){
            # Nothing matched, move on one char:
            $0 = substr($0, 2);
        }
        else{
            f=substr($0,RSTART,RLENGTH)             # save what matched in f
            gsub(/^ *"?|"? *,$/,"",f)               # remove extra stuff
            print "Field " ++c " is " f
            $0=substr($0,RLENGTH+1)                 # "consume" what matched
        }
    }
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

    for (x in headers){
        print headers[x];
    }
}
