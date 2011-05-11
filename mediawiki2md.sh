#!/bin/bash

# This script do the following:
#  1. uses the mediawiki2html script to convert the mediawiki to HTML.
#  2. uses pandoc to convert HTML to markdown (leaving any unknown HTML as raw)
#  3. htmltable2pandoc to convert HTML tables into markdown syntax.

find -type f -name \*.mediawiki | while read i; do
  NAME=`echo $i | sed -e's/.mediawiki$//'`
  echo "Converting $NAME.mediawiki -> $NAME.md"

  echo " -> $NAME.mediawiki.munged"
  sed -e's/^    \* /\* /' -e's/^   \([0-9]*\)\./#/' -e"s/\*\([^\*]*\)\*/'''\1'''/g" $NAME.mediawiki > $NAME.mediawiki.munged

  echo " -> $NAME.mediaxml"
  php ./wiki2xml/php/wiki2xml_command.php "$NAME.mediawiki.munged" "$NAME.mediaxml" > /dev/null

  echo " -> $NAME.mediaxml.munged"
  cat \
    $NAME.mediaxml > $NAME.mediaxml.munged

  echo " -> $NAME.mediaxml.munged"
  tidy -i -xml "$NAME.mediaxml.munged" > "$NAME.mediaxml.tidy"

  echo " -> $NAME.xhtml.messy"
  xsltproc --novalid mediaxml2xhtml.xslt "$NAME.mediaxml.tidy" > "$NAME.xhtml.messy"

  echo " -> $NAME.xhtml.tidy"
  tidy -i -asxhtml "$NAME.xhtml.messy" > "$NAME.xhtml.tidy"

  echo " -> $NAME.md-no-table"
  pandoc -r html -R -w markdown --no-wrap < "$NAME.xhtml.tidy" > "$NAME.md-no-table"

  echo " -> $NAME.md"
  perl htmltable2pandoc.pl < "$NAME.md-no-table" > "$NAME.md"

  echo "Done!"
  echo
  sleep 1
done
