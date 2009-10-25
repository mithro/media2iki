#!/usr/bin/env ruby

# This script turns a directory full of revision files back into
# a single XML file suitable for sorting and then fast-loading.
#
# It modifies the title in the XML to match the file name.
# Therefore, you can move or rename the files, and the resulting
# XML will me modified to reflect the changes in the filesystem.
# (this is kind of too bad...  otherwise we could just concatenate
# the revision files and ignore rexml completely).

require 'find'
require 'rexml/document'


def process(entry)
   entry =~ /^\.\/(.*)-(\d+-\d+)$/ or raise "Could not parse #{entry}"
   name,date = [$1,$2]
   # puts "name=#{name}   date=#{date}"

   doc = REXML::Document.new File.new(entry)
   title = doc.root.elements["title"].text

   if title != name
      $stderr.puts "Warn: #{title} has been renamed to #{name}"
      doc.root.elements["title"].text = name
   end

   bar = REXML::Formatters::Default.new
   bar.write(doc, $stdout)
end


puts '<?xml version="1.0" encoding="UTF-8"?>'
puts '<mediawiki xmlns="http://www.mediawiki.org/xml/export-0.3/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.mediawiki.org/xml/export-0.3/ http://www.mediawiki.org/xml/export-0.3.xsd" version="0.3" xml:lang="en">'

Find.find('.') do |entry|
    next if entry =~ /^\.\/\.git/
   if File.file?(entry)
      process(entry)
   end
end

puts '</mediawiki>'

