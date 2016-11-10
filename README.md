Convert the Datalab ASC format to R style ASCII text files.
===========================================================

Used the definiton of Datalab's ASC format from here: [ASC File Format](http://datalab.epina.at/helpeng/asc_format.htm).

This definition seems to be not complete, at least in my files there is a `nominal variables` flag which is set to `FALSE`

Usage
-----

Convert files like this:

    asc2txt.awk file_to_convert.asc > converted.txt

The files can then be read by R by using

    X <- read.table("converted.txt")

Disclaimer
----------

I never had DataLab installed anywhere, so I only developed this tool to convert
some existing files, to work with them in R.

If you want to extend this script, please feel free to do so! Send in pull requests if you like.
