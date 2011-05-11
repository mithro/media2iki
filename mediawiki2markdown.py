#!/usr/bin/python
#

from mwlib.uparser import simpleparse
from mwlib.parser import nodes

import cStringIO as StringIO

import sys

DEBUG = True
def debugger():
  if DEBUG:
    import traceback, pdb
    type, value, tb = sys.exc_info()
    pdb.post_mortem(tb)
  else:
    raise

class BaseConverter(object):

  def __init__(self):
    self.out = ""
    self.listmode = []

  def append(self, s):
    if isinstance(s, unicode):
      s = s.encode('utf-8')
    self.out += s

  def getvalue(self):
    out = self.out
    self.out = ""
    return out

  def parse_node(self, node):
    try:
      getattr(self, 'on_'+(node.tagname or node.__class__.__name__.lower()).replace('@',''))(node)
    except AttributeError, e:
      sys.stderr.write('Unknown node: '+(node.tagname or node.__class__.__name__.lower()))
      debugger()
    except:
      debugger()

  def parse_children(self, node):
    for child in node.children:
      self.parse_node(child)

  on_node = parse_children
  on_article = parse_children

  def on_ol(self, node):
    self.listmode.append('order')
    self.parse_children(node)
    self.listmode.pop(-1)

  def on_ul(self, node):
    self.listmode.append('unorder')
    self.parse_children(node)
    self.listmode.pop(-1)

  def on_text(self, node):
    self.append(node.asText())

  def on_style(self, node):
    # Definition list?
    if node.caption == ';':
      if not hasattr(self, 'dls'):
        self.dls = []

      self.dls.append(node)

    elif node.caption == ':':
      # If not part of an definition list, it's an indent...
      if not hasattr(self, 'dls'):
        self.append(" "*4*len(node.caption))
        self.parse_children(node)
      else:
        self.dls.append(node)

    # italics
    elif node.caption == "'''":
      self.on_bold(node)

    # bold
    elif node.caption == "''":
      self.on_italics(node)

    else:
      assert False, "Unknown style: %s" % node.caption

  # Ignore category links as we don't have anything similar
  def on_categorylink(self, node):
    return

  def on_table(self, node):
    table_cell_parser = self.__class__()

    table = []
    table_width = 0
    table_column_widths = []
    for row in node.children:
      if len(row.children) > table_width:
        table_width = len(row.children)
        while len(table_column_widths) < table_width:
          table_column_widths.append(0)

      cells = []
      for i, cell in enumerate(row.children):
        table_cell_parser.parse_children(cell)
        cell_data = table_cell_parser.getvalue()

        if table_column_widths[i] < len(cell_data):
          table_column_widths[i] = len(cell_data)

        cells.append({'node': cell, 'rendered': cell_data})

      while len(cells) < table_width:
        cells.append('')

      table.append({'rowtype': row,
                    'celltype': row.children[-1],
                    'cells': cells})

    self.on_process_table(table_column_widths, table)


class HTMLConverter(BaseConverter):
  """During HTML output (such as dl lists and tables) Markdown doesn't work."""

  def on_p(self, node):
    self.append("<p>")
    self.parse_children(node)
    self.append("</p>")

  def on_italics(self, node):
    self.append("<em>")
    self.parse_children(node)
    self.append("</em>")

  def on_bold(self, node):
    self.append("<strong>")
    self.parse_children(node)
    self.append("</strong>")

  def on_p(self, node):
    self.append("<p>")
    self.parse_children(node)
    self.append("</p>")

    # We need to specially handle defintion lists
    if hasattr(self, "dls"):
      self.append("<dl>\n")

      dls = self.dls
      del self.dls

      for dl in dls:
        if dl.caption == ';':
          self.append('<dt>')
          self.parse_children(dl)
          self.append('</dt>\n')
        elif dl.caption == ':':
          self.append('<dd>')
          self.parse_children(dl)
          self.append('</dd>\n')

      self.append("</dl>\n")
    self.append('\n')

  def on_namedurl(self, node):
    self.append("<a href='%s'>" % node.caption)
    self.append(node.children[0].asText().strip())
    self.append("</a>")

  def on_imagelink(self, node):
    self.append("<img src='%s' alt='%s' />'" % (
        node.asText(), node.target.replace('Image:', '')))

  def on_articlelink(self, node):
    self.append("<a href='/%s'>%s</a>" % (node.target, node.target))

  def on_section(self, node):
    self.append("\n")
    self.append("<h%i>" % node.level)
    self.parse_node(node.children[0])
    self.append("</h%i>" %node.level)
    self.append("\n")
    for child in node.children[1:]:
      self.parse_node(child)


class MarkdownConverter(BaseConverter):

  def __init__(self):
    BaseConverter.__init__(self)
    self.html = HTMLConverter()

  def parse(self, text):
    sys_stdout = sys.stdout
    ast_str = StringIO.StringIO()
    sys.stdout = ast_str
    ast = simpleparse(text)
    sys.stdout = sys_stdout
    #print ast_str.getvalue()
    self.parse_node(ast)

  def on_preformatted(self, node):
    self.append('\n<pre>')
    self.append(node.asText())
    self.append('</pre>\n')

  def on_pre(self, node):
    self.append('\n<pre>')
    for child in node.children:
      self.append(child.asText())
    self.append('</pre>\n')

  def on_p(self, node):
    self.parse_children(node)

    if hasattr(self, "dls"):
      self.append("<dl>\n")

      dls = self.dls
      del self.dls

      for dl in dls:
        if dl.caption == ';':
          self.append('<dt>')
          self.html.parse_children(dl)
          self.append(self.html.getvalue())
          self.append('</dt>\n')
        elif dl.caption == ':':
          self.append('<dd>')
          self.html.parse_children(dl)
          self.append(self.html.getvalue())
          self.append('</dd>\n')

      self.append("</dl>\n")
    self.append('\n')

  def on_italics(self, node):
    self.append("_")
    self.parse_children(node)
    self.append("_")

  def on_bold(self, node):
    self.append("**")
    self.parse_children(node)
    self.append("**")

  def on_gallery(self, node):
    """Gallery widgets are converted to lists."""
    for child in node:
      self.append('*   ')
      self.parse_node(child)
      self.append('\n')

  def on_namedurl(self, node):
    self.append("[")
    #self.parse_children(node)
    self.append(node.children[0].asText().strip())
    self.append("](%s)" % node.caption)

  def on_imagelink(self, node):
    self.append('![%s](%s)' % (
        node.asText(), node.target.replace('Image:', '')))

  def on_articlelink(self, node):
    self.append("[%s](/%s)" % (node.target, node.target))

  def on_namespacelink(self, node):
    self.append("[")
    self.parse_children(node)
    self.append("](%s)" % node.target.replace(' ', '_'))

  def on_section(self, node):
    self.append("\n")
    self.append("#" * node.level + " ")
    self.parse_node(node.children[0])
    self.append(" "+"#" * node.level)
    self.append("\n")
    for child in node.children[1:]:
      self.parse_node(child)

  def on_li(self, node):
    listmode = {'order': '1.', 'unorder': '+'}
    self.append(' '*(len(self.listmode)-1) + listmode[self.listmode[-1]])
    self.parse_children(node)

  def on_tagnode(self, node):
    if node.caption == 'hr':
      self.append('-'*75)
    else:
      assert False, "Unknown tag %s %s" % (node, node.caption)

  def on_process_table(self, widths, rows):
    # Insert a dummy header if one doesn't exist
    if rows[0]['celltype'].tagname != 'th':
      fakenode = nodes.Node()
      fakenode.tagname = 'th'
      fakenode.vlist = {}
      rows.insert(0, {'rowtype': rows[0]['rowtype'],
                      'celltype': fakenode,
                      'cells': [{'node': fakenode, 'rendered': ''}]*len(widths)})

    for row in rows:
      line = '| '
      for i, cell in enumerate(row['cells']):
        line += cell['rendered'].strip().ljust(widths[i])
        line += ' | '
      self.append(line[:-2])
      self.append('\n')

      if row['celltype'].tagname == 'th':
        divider = '| '
        for i, width in enumerate(widths):
          alignment = row['cells'][i]['node'].vlist.get('align', 'left')
          if alignment == 'left':
            divider += '-'*width
          elif alignment == 'center' or alignment == 'centre':
            divider += ':' + '-'*(width-2) + ':'
          elif alignment == 'right':
            divider += '-'*(width-1) + ':'
          else:
            assert False, 'Unknown alignment %s (%s)' % (
                alignment, rows['cells'][i])
          divider += ' | '
        self.append(divider[:-2])
        self.append('\n')


def main(infile=None):
  if infile is None:
    infile = sys.stdin
  else:
    infile = file(infile)

  mediawiki = infile.read()

  c = MarkdownConverter()
  c.parse(mediawiki)
  print c.out


if __name__ == "__main__":
  main(*sys.argv[1:])
