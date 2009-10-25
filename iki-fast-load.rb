#!/usr/bin/env ruby

# This script is called on the final sorted, de-spammed revision
# XML file.
#
# It doesn't currently check for no-op revisions...  I believe
# that git-fast-load will dutifully load them even though nothing
# happened.  I don't care to solve this by adding a file cache
# to this script.  You can run iki-diff-next.rb to highlight any
# empty revisions that need to be removed.
#
# This turns each node into an equivalent file.
#    It does not convert spaces to underscores in file names.
#       This would break wikilinks.
#       I suppose you could fix this with mod_speling or mod_rewrite.
#
# It replaces nodes in the Image: namespace with the files themselves.


require 'rubygems'
require 'node-callback'
require 'time'
require 'ostruct'


# pipe is the stream to receive the git-fast-import commands
# putfrom is true if this branch has existing commits on it, false if not.
def format_git_commit(pipe, f)
   # Need to escape backslashes and double-quotes for git?
   # No, git breaks when I do this. 
   # For the filename "path with \\", git sez: bad default revision 'HEAD'
   # filename = '"' + filename.gsub('\\', '\\\\\\\\').gsub('"', '\\"') + '"'

   # In the calls below, length must be the size in bytes!!
   # TODO: I haven't figured out how this works in the land of UTF8 and Ruby 1.9.
   pipe.puts "commit #{f.branch}"
   pipe.puts "committer #{f.username} <#{f.email}> #{f.timestamp.rfc2822}"
   pipe.puts "data #{f.message.length}\n#{f.message}\n"
   pipe.puts "from #{f.branch}^0" if f.putfrom
   pipe.puts "M 644 inline #{f.filename}"
   pipe.puts "data #{f.content.length}\n#{f.content}\n"
   pipe.puts
end


# This just prints the revisions in a human-readable format.
def add_git_commit_dump(pipe, f)
   pipe.puts "filename: #{fields.filename}"
   pipe.puts "timestamp: #{fields.timestamp.rfc2822}"
   pipe.puts "message: #{fields.message}"
   pipe.puts "content size: #{fields.content.length}"
   pipe.puts
end


def read_file(title)
   puts "Reading file #{title}"
   mystring = ''
   File.open(title, "r") { |f|
       mystring = f.read
   }
   return mystring
end


def imgurl(file)
   # If you want to store all files in another dir, uncomment this line:
   #return "images/" + file
   # By default we store all files in the root directory.
   return file
end


# Reads a Mediawiki commit, converts it into an Ikiwiki commit.
#
# An example of what we're parsing:
#
# <revision><title>Main Page</title>
#       <id>1</id>
#       <timestamp>2006-06-15T16:37:31Z</timestamp>
#       <contributor>
#         <ip>Mediawiki default</ip>
#       </contributor>
#       <minor/>
#       <text xml:space="preserve">'''Mediawiki has been successfully installed.'''
# 
# Consult the [http://www.mediawiki.org/wiki/Help:Configuration_settings configuration settings list] and the [http://meta.wikipedia.org/wiki/MediaWiki_User%27s_Guide User's Guide] for information on customising and using the wiki software.</text>
#     </revision>
#
#  Here are the fields that can appear in contributors:
#    <ip>Mediawiki default</ip>
#    <ip>127.0.0.1</ip>
#    <username>Bronson</username><id>2</id>

def parse_revision(node, basedir)
   elements = node.elements

   title = elements["title"].text
   text = elements["text"].text

   if not text
      text = ""
   end

   timestamp = Time.parse(elements["timestamp"].text)
   # we'll ignore Mediawiki's minor flag; it seems to be useless.

   if true
      # Enable this to show the node we're processing
      puts "\n\n############"
	  puts title
	  puts timestamp
   end


   # ikiwiki uses two commit message formats:
   #   Known username?  "web commit by USERNAME: COMMENT"    (we drop user id)
   #   Unknown username?  "web commit from IPADDR: COMMENT"
   #   Mediawiki Engine?  "web commit from Mediawiki default: COMMENT"
   # Of course, it also uses the free-form commit of anybody who
   # whacked stuff into the git repo directly.
   contributor = elements["contributor"]
   message = "web commit "
   if contributor.elements["ip"]
      message += "by " + contributor.elements["ip"].text
   elsif contributor.elements["username"]
      message += "from " + contributor.elements["username"].text
   else
      raise "Could not discover author from " + contributor
   end

   # This appears to be a limitation of the ikiwiki commit message format
   # (it uses a colon to denote the start of the commit message).
   throw "User can't contain a colon: #{message}" if message =~ /:/

   message += (elements["comment"] ? ": " + elements["comment"].text : "")

   # Fix up the Image namespace.
   if title =~ /^Image:(.*)$/
      # Load the file directly into this commit rather than just referring to it.
      title = imgurl($1)
      text = read_file("#{basedir}/images/#{title.gsub(' ', '_')}")
   else
      # Fix the Image namespace
      text.gsub!('[[Image:', '[['+imgurl(""))
      text.gsub!('[[Media:', '[['+imgurl(""))
      # And warn if we see any other weird namespaces in here.
      text.scan(/\[\[([^:\]]*:[^\]]*)\]\]/) do |link|
         $stderr.puts "Warning: unknown namespace in link \"#{link}\" on page \"#{title}\""
      end
      # And add the ".mediawiki" extension to all mediawiki-formatted files.
      title = title + ".mediawiki"
   end

   # ikiwiki doesn't handle files with spaces in the names.  :(
   title.gsub!(" ", "_")

   return OpenStruct.new({
      :filename => title,
      :message => message,
      :content => text,
      :timestamp => timestamp
      })
end


throw "You must supply the name of the file to read!" unless infile = ARGV[0]
throw "You must supply the name of the repo to fill!" unless repo = ARGV[1]
# stupid libxml sax parser can't parse from a filehandle
# so we need to make all our paths absolute before chdiring.
infile = File.expand_path(infile)
basedir = File.expand_path('.')

Dir.chdir(repo) or throw "Could not chdir to #{repo}: #{$!}"

# Create a new git repo if one doesn't already exist
unless File.exists?('.git')
   system("git init") or raise "Could not run git init"
end

#branch = "refs/head/master"
branch = `git symbolic-ref HEAD`.chomp
raise "Could not run git-symbolic-ref HEAD??" if branch.strip == ""
# git-fast-import requires us to use the from command if we're importing
# into a pre-existing branch.  git-rev-parse will tell us if the branch exists.
putfrom = system("git rev-parse #{branch} >/dev/null 2>&1")
username = `git config user.name`.chomp
raise "You must set your user name.  See git config." if username.strip == ""
email = `git config user.email`.chomp
raise "You must set your email address.  See git config." if email.strip == ""

IO.popen("git fast-import --date-format=rfc2822 --quiet", "w") do |pipe|
   nodeproc = proc { |node|
      fields = parse_revision(node, basedir)
      puts "importing #{fields.filename} at #{fields.timestamp}"
      fields.putfrom = putfrom
      # We only want putfrom to be true for the first commit we pass to gfi.
      # If we leave it true then only the last commit will be stored in git.
      putfrom = false
      fields.branch = branch
      fields.username = username
      fields.email = email
      format_git_commit(pipe, fields)
   }
   parse_node(infile, 'mediawiki/revision', nodeproc,
      {:compress_whitespace => %w{revision contributor}})
end

# git-fast-import doesn't update the working directory.
# This is good but we must manually update it when we're done.
system("git checkout")
