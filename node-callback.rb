require 'xml'

def parse_node(infile, nodetype, callback, extra)

	parser, parser.string = XML::Parser.new, xml
	doc, posts = parser.parse, []
	doc.find('//'+nodetype).each do |node|
		callback(node)
  	end
end
