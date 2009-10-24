#!/usr/bin/env ruby

# This script turns a directory full of revision files back into
# a single XML file suitable for sorting and then fast-loading.
#
# It modifies the title in the XML to match the file name.
# Therefore, you can move or rename the files, and the resulting
# XML will me modified to reflect the changes in the filesystem.
# (this is kind of too bad...  otherwise we could just concatenate
# the revision files and ignore rexml completely).
#
# Run it like this:
#   ruby ../iki-find-empty-edits.rb nodes

require 'find'
require 'rexml/document'


# Given a filename, returns the node name
def parse_name(entry)
   entry =~ /^\.\/(.*)-(\d+-\d+)$/ or raise "Could not parse #{entry}"
   return [$1,$2]
end

# Given a filename, returns the content of the text node.
def find_text(entry)
   doc = REXML::Document.new File.new(entry)
   return doc.root.elements["text"].text
end


def process(pv,nx)
   pvname,pvdate = parse_name(pv)
   nxname,nxdate = parse_name(nx)

   # If these are edits to the same node
   if pvname == nxname
      pvtext = find_text(pv)
      nxtext = find_text(nx)

      # And if the text nodes are the same
      if pvtext == nxtext
         puts "Empty Edit: #{nx}"
      end
   end
end

throw "You must specify the directory to search" unless ARGV[0]
Dir.chdir(ARGV[0]) or throw "Could not chdir to #{ARGV[0]}: #{$!}"

# Find all files in the given directory
files = []
Find.find('.') do |entry|
   next if entry =~ /^\.\/\.git/
    files << entry if File.file?(entry)
end

# And run over the sorted list of files
pv = nil
files.sort.each do |nx|
   process(pv,nx) if pv
   pv = nx
end
