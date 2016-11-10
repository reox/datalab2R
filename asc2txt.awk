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
# * We assume all files have CRLF, but you can change that per file
# * We do not know what the FLAG_NOMINAL does, we only have test data with FALSE

BEGIN {
    # Debugging flag for more output
    DEBUG = 0;

    # Input files are probably all CRLF, so set it and forget it...
    RS = "\r\n"
    ORS = "\n"

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
    NA = "###"

    # Some more flags for our state machine
    col_cols = 0;
    col_rows = 0;
    col_cur = 0;
    col_extra = 0;
    printheader = 1;

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

    # Calculate extra columns
    if (flags[FLAG_CLASSINFO]) {
        col_extra++;
    }
    if (flags[FLAG_FEATNAMES]) {
        col_extra++;
    }
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

(col_cols == ncols && printheader == 1) {
    # The header has been parsed, print it

    # The headers in R have always quotes (?)
    for (i in headers){
        if (headers[i]~/"/){
            printf "%s", headers[i];
        }
        else {
            printf "\"%s\"", headers[i];
        }
        if (i < length(headers)) {
            printf " "
        }
    }
    printf "\n"

    printheader = 0;
}


(col_cols == ncols && printheader == 0){
    # See http://web.archive.org/web/20120531065332/http://backreference.org/2010/04/17/csv-parsing-with-awk/
    # for the Idea how to parse CSV
    c=0
    while($0) {
        match($0,/[ \t]*"[^"]*"[ \t]*|[^ \t]*/)
        if (RLENGTH == 0){
            # Nothing matched, move on one char:
            $0 = substr($0, 2);
        }
        else{
            f=substr($0,RSTART,RLENGTH)
            # TODO trailing spaces and tabs are not removed
            gsub(/^ *"?|"? *,$/,"",f)
            # Save current field
            cur_row[col_cur] = f;
            col_cur++;
            # Move over
            $0=substr($0,RLENGTH+1)
        }
    }
}

(col_cur == col_cols + col_extra){
    # We collected a full row
    col_rows++;
    col_cur = 0;

    c_idx = 0;

    # Assuming that row attribute is first,
    # then the row name
    if (flags[FLAG_CLASSINFO]) {
        # We delete the first entry in the array
        delete cur_row[0];
        c_idx++;
    }
    if (flags[FLAG_OBJNAMES]) {
        # The first item is the rowname
        if (cur_row[c_idx]~/"/) {
            printf "%s ", cur_row[c_idx];
        }
        else {
            printf "\"%s\" ", cur_row[c_idx];
        }
        delete cur_row[c_idx];
    }

    c_idx = 0;
    for (i in cur_row) {
        # Check for NA value
        if (cur_row[i] == NA){
            printf "NA";
        }
        else {
            printf "%s", cur_row[i];
        }
        if (c_idx < nrows) {
            printf " ";
        }
        delete cur_row[i];
        c_idx++;
    }
    printf "\n";
}

END {
    if (col_rows != nrows) {
        print FILENAME " (line " FNR "): ERROR: Expected "nrows" rows of data, got "col_rows > "/dev/stderr";
    }


    # Debugging only...
    if (DEBUG) {
        print "DESCRIPTION " description > "/dev/stderr";
        print "NCOLS " ncols > "/dev/stderr";
        print "NROWS " nrows > "/dev/stderr";
        print "FLAG_CLASSINFO " flags[0] > "/dev/stderr";
        print "FLAG_FEATNAMES " flags[1] > "/dev/stderr";
        print "FLAG_OBJNAMES " flags[2] > "/dev/stderr";
        print "FLAG_NOMINAL " flags[3] > "/dev/stderr";

        for (x in headers){
            print headers[x] > "/dev/stderr";
        }
    }
}
