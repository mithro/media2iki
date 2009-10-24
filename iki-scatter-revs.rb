#!/usr/bin/env ruby

# This script turns an XML file of revisions into a directory full
# of files, one revision per file.
#
# It doesn't currently check for duplicates -- if another revision
# is made on the exact date and time as a previous revision (down to
# the last second), it's just appended to the file.  This creates an
# invalid XML file that we can detect and correct when reading them
# back.
#
# Once you have the directory full of revision files, you can use
# mv, rm, grep etc.  See iki-gather-revs.rb for more.
# We set the modification date of each file to the date of each edit.
# That way you can use commands like "find -newer" to work with dates.


require 'rubygems'
require 'node-callback'
require 'time'

require 'fileutils' # for mkdir_p


def parse_revision(dir, node)
   elements = node.root.elements

   title = elements["title"].text
   timestamp = Time.parse(elements["timestamp"].text)

   filename = File.join(dir, title + '-' + timestamp.strftime("%Y%m%d-%H%M%S"))
   FileUtils.mkdir_p File.dirname(filename)
   File.open(filename, "a") { |f|
      # node.write is supposed to re-indent the document.
      # Too bad it doesn't.  I should have used libxml.
      node.write(f, 2)
      f << "\n"
   }
   # Make each file have the same modification date as its edit time.
   File.utime(timestamp, timestamp, filename)
   puts "Wrote #{filename}"
end


throw "You must supply the name of the file to parse!" unless infile = ARGV[0]
throw "You must supply the name of the directory to fill!" unless outdir = ARGV[1]

parse_node(infile, 'revision', 
   proc { |rev| parse_revision(outdir, rev)},
   {:compress_whitespace => %w{revision contributor}}
   )
puts "done."
