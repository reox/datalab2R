Convert the Datalab ASC format to R style ASCII text files.

Used the definiton of Datalab's ASC format from here: [ASC File Format](http://datalab.epina.at/helpeng/asc_format.htm)

The files can then be read by R by using

    table.read("converted.txt")
