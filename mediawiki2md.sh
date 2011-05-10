#!/bin/bash

# This script do the following:
#  1. uses the mediawiki2html script to convert the mediawiki to HTML.
#  2. uses pandoc to convert HTML to markdown (leaving any unknown HTML as raw)
#  3. htmltable2pandoc to convert HTML tables into markdown syntax.

find -type f -name AI_Clients.mediawiki | while read i; do
  NAME=`echo $i | sed -e's/.mediawiki$//'`
  echo "Converting $NAME.mediawiki -> $NAME.md"
  if [ -x "$NAME.mediaxml" ]; then
    python mediawiki2mediaxml.py < "$NAME.mediawiki" > "$NAME.mediaxml"
  fi
  xsltproc mediaxml2xhtml.xslt "$NAME.mediaxml" > "$NAME.xhtml"
  pandoc -r html -R -w markdown --no-wrap < "$NAME.xhtml" | \
    perl htmltable2pandoc.pl > "$NAME.md"
  echo "Done!"
  echo
  sleep 1
done
