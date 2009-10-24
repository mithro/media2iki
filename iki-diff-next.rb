#!/usr/bin/env ruby

# This will show the incremental changes made by a bunch of edits.
# The edits need to be scattered into files (see iki-scatter-revs.rb)
#
# Run it like this:
#    ruby iki-diff-next.rb nodes/Video-20070*
#

require 'rexml/document'


def show_comment(node)
   # return ""         # enable this line to turn off printing comments
   return "" unless node
   return ": " + node.text
end


# Read the text element from infile and write it to outfile
# Returns the comment for this node.
def write_text(infile, outfile)
   doc = REXML::Document.new File.new(infile)
   File.open(outfile, "w") { |f|
      f.write doc.root.elements["text"].text
      f.write "\n"
   }
   return show_comment(doc.root.elements["comment"])
end


# Read the text from from and to and diff it.
def diff(from, to)
   write_text(from, "/tmp/prev")
   comment = write_text(to, "/tmp/next")
   puts "\n\n\n\n########## changes made by #{to}#{comment}"
   # system('diff', '-u', '/tmp/prev', '/tmp/next')
   # skip the leading junk in the diff file
   system "diff -u /tmp/prev /tmp/next | tail -n +3"
end


pv = ARGV.shift
doc = REXML::Document.new File.new(pv)
comment = show_comment(doc.root.elements["comment"])
puts "############ original document by #{pv}#{comment}\n"
puts doc.root.elements["text"].text

while nx = ARGV.shift
   diff(pv, nx)
   pv = nx
end
