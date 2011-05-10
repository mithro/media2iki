#!/bin/python

"""
This script abuses the php script at
http://toolserver.org/~magnus/wiki2xml/w2x.php to convert mediawiki markup to
HTML.
"""

import sys
import urllib
import urllib2

url = "http://toolserver.org/~magnus/wiki2xml/w2x.php"
d = {
  "use_templates":"all",
  "templates":"",
  "whatsthis":"wikitext",
  "site":"en.wikipedia.org/w",
  "useapi":"1",
  "document_title":"",
  "doit":"Convert",
  "plaintext_markup":"1",
  "plaintext_prelink":"1",
  "translated_text_target_language":"en",
  "output_format":"xml",
  "xhtml_logical_markup":"1",
  "text": sys.stdin.read(),
  }

urldata = urllib.urlencode(d)
r = urllib2.urlopen(url, urldata).read()
sys.stdout.write(r)
