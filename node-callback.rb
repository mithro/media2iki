#!/usr/bin/env ruby

#require 'xml'
require 'rexml/document'


def parse_node(infile, xpath, callback, extra)
    doc = REXML::Document.new File.new(infile)

	nodes = doc.elements.each(xpath) do |node|
		callback.call(node)
	end
end
