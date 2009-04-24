#!/bin/sh

# (C) Barry Byrne 2008
# barry.j.byrne@gmail.com
# 
# This script is used to download and print out the daily crosswords
# from the Irish Times. 
# It's intended for my personal use only, but you're welcome to 
# modify it to your own purposes

# Revision 1.0.0
# Initial Release

# Requires pyPdf
# See: http://pybrary.net/pyPdf/
# Something like the following should install assuming version is same.

# cd /tmp
# curl -OR http://pybrary.net/pyPdf/pyPdf-1.12.tar.gz
# tar zxvf pyPdf-1.12.tar.gz
# cd pyPdf-1.12
# sudo ./setup.py install

# Modify DIR to where crosswords should be stored
# ORDER is either normal (crosaire on top) or reverse

DIR="/Users/Shared/crosswords"
COPIES=2
ORDER="normal"

BASEURL="http://www.irishtimes.com/newspaper/pdf"

# Program locations
# Defaults are from Mac OS 10.5.5.

CURL="/usr/bin/curl -s"
PYTHON="/usr/bin/python"
LP="/usr/bin/lp"
RM="/bin/rm"

DATE=`/bin/date +%Y%m%d`

SIMPLEX="$DIR/simplex-${DATE}.pdf"
CROSAIRE="$DIR/crosaire-${DATE}.pdf"
COMBINED="$DIR/combined-${DATE}.pdf"
PRINTED="$DIR/.${DATE}.printed"

# If today's puzzles  don't exist, then attempt to download them
# Only download if timestamp is today (-z option to curl)

if [ ! -f $SIMPLEX  -a ! -f $COMBINED ]
then
       $CURL -z $DATE -R -o $SIMPLEX $BASEURL/simplex.pdf
fi

if [ ! -f $CROSAIRE  -a ! -f $COMBINED ]
then
       $CURL -z $DATE -R -o $CROSAIRE $BASEURL/crosaire.pdf
fi

# If both puzzles do exist AND a combined version doesn't exist
# then make a combined version

if [ ! -f $COMBINED -a -f $SIMPLEX -a -f $CROSAIRE ]
then
       echo "Got both puzzles"
       $PYTHON << EOP

# Here Be Python!
# Watch your indentation!

from pyPdf import PdfFileWriter, PdfFileReader

def CP(input, output):
 for pageNum in range(input.numPages):
   page = input.getPage(pageNum)
   output.addPage(page)

output = PdfFileWriter()
CP(PdfFileReader(file("$SIMPLEX", "rb")), output)
CP(PdfFileReader(file("$CROSAIRE", "rb")), output)
output.write(file("$COMBINED", "wb"))

# End of python
EOP

fi

# Delete unwanted source files and print if we have a result
# Default is 2-up, default printer.
# Set outputorder to reverse to switch ordering

if [ -f $COMBINED ]
then
  $RM -f $SIMPLEX $CROSAIRE
    if [ ! -f $PRINTED ]
    then  
      $LP -n $COPIES \
	-o job-sheets=none \
	-o number-up=2 \
	-o outputorder=$ORDER $COMBINED
      touch $PRINTED
    fi
else
  echo "Failed to merge PDFs"
  echo "Perhaps pyPDF is not installed?"
fi
