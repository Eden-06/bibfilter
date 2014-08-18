#!/bin/ruby
# encoding : utf-8

Version="1.0"
Documentation=<<EOS
NAME
 bibfilter - allows to filter the entries of a given bibtex file

SYNOPSIS
 ruby bibfilter.rb -cN FILES
 ruby bibfilter.rb [-aT|-rT]+ [-eREG|-iREG] FILES
 ruby bibfilter.rb -n FILES
 ruby bibfilter.rb -h
 ruby bibfilter.rb -V

DESCRIPTION
 bibfilter is a simple commandline tool which enables the user to
 either interactively or automatically filter a given bibtex file.
 Each bibtex entry passing the filter will be printed to STDOUT,
 whereas the interactive part of the programm uses STDERR for its output.
 Please note that all the automatic filters are executed in a strict 
 order first retaining all bibitems (with -a and -i) and afterwards 
 removing the rest according to (-r and -e)


OPTIONS
 -cN   Filter the bibitems by citations and remove all entries with less
       then N citations.
       (This method assumes a citations field in each bibtex entry.)
 -d    remove duplicates from the bibtex entries based on their key.
       This option is combinable with every other option.
 -aT   Filter the bibitems and retain all items belonging to a certain
       class (i.e.: article, book, incollections).
       This option can be used multiple times but not in combination 
       with other options! 
 -rT   Filter the bibitems and remove all items belonging to a certain 
       class (i.e.: article, book, incollections).
       This option can be used multiple times but not in combination 
       with other options!
 -e"/REGEX/"
       excludes all bibitems to which this ruby regular expression applies
       The expression will be evaluated for each line of a bibfile, so 
       it is impossible evaluate a howl bibitem.
       This option can be used once, but combined with other automated 
       options like -a, -r, or -i.
 -i"/REGEX/"
       includes all bibitems to which this ruby regular expression applies
       The expression will be evaluated for each line of a bibfile, so 
       it is impossible evaluate a howl bibitem.
       This option can be used once, but combined with other automated 
       options like -a, -r, or -e.
 -n    Perform an Interactive decission process showing the title, the
       link and the number of citations (default).
 -h    Show this document.
 -m    measure the entries in the bibtex file to compute the citations
       min, max, and median as well as the total number of entries.
       This works also in combination with automatic filters but not with
       interactive filter.
 -l    add the total number of files referenced in the bibtex file to the
       measured entries. This option implies -m.
 -t    creates output of measures in the CSV format with count;
       citations median, min, max. This option implies -m.
 -v    produces verbose output.
 -V    Shows the version number.

USAGE
 ruby bibfilter.rb -c100 paper2002.bib > filteredpapers2002.bib
       remove all bibtex entries from the paper2002.bib file with a
       citation count below 100 and store the remaining entries into the
       file filteredpapers2002.bib
 ruby bibfilter.rb -n paper2002.bib > filteredpapers2002.bib
       go through all the papers interactivelly and

AUTHOR
 Thomas "Eden_06" Kuehn

VERSION
 %s
EOS

#method definitions

def achievements(index,size,removed,l)
 return "[Double Kill]" if l==2
 return "\e[33m[Multi Kill]\e[0m" if l==3
 return "\e[4;31m[Mega Kill]\e[0m" if l==6
 return "\e[5;31m[Ultra Kill]\e[0m" if l==9
 return "\e[31m[M-m-m Monster Kill]\e[0m" if l==12
 return "\e[7;31m[LUDACRIS KILL!]\e[0m" if l==15
 return "\e[1;37;31m[H O L Y S H I T!]\e[0m" if l==18

 return "[removed]"
end

# begin of execution
key="-n" 
files=[]
verbose=false
mincount=0
retain=[]
remove=[]
rinclude=nil
rexclude=nil
summary=false
countfiles=false
table=false
removeduplicates=false

ARGV.each do|x| 
 case x
  when /^-c([0-9]+)$/
   key,mincount="-c",$1.to_i
  when /^-d$/
   removeduplicates=true
  when /^-a([a-zA-Z]+)$/
   key="-a"
   retain << $1.to_s.downcase
  when /^-r([a-zA-Z]+)$/
   key="-a"
   remove << $1.to_s.downcase
  when /^-i\/(.*)\//
   key="-a"
   rinclude=Regexp.new($1)
  when /^-e\/(.*)\//
   key="-a"
   rexclude=Regexp.new($1)
  when /^-[nhV]$/
   key=$~.to_s
  when /^-m$/
   summary=true
   key="-a"
  when /^-l$/
   summary=true
   countfiles=true
   key="-a"
  when /^-t$/
   summary=true
   table=true
   key="-a"
  when /^-v$/
   verbose=true
  else
   files << x
  end
end

if files.empty? or key=="-h"
 puts Documentation % Version
 exit(1)
end

if key=="-V"
 puts Version
 exit(1)
end

files.each do|file|
  unless File.exists?(file)
   $stderr.puts "The selected file %s did not exist." % file
   exit(2)
  end
end

if key=="-e" and regexp.nil?
  $stderr.puts "Option -e and -i require a legal regular expression i.e. \"/patents/\""
  exit(3)
end

bibitems=[]
files.each do|file|
  open(file,"r") do|f|
   f.each_line do|line|
    bibitems << []  if /^@.*/ =~ line
    bibitems.last << line.strip unless bibitems.last.nil?
   end
  end
end

$stderr.puts "found %d bibitems"%bibitems.size if verbose

## remove Duplicates
if removeduplicates
 h=bibitems.inject(Hash.new){|h,bib| h[$1]=bib if /^@.*{(.+),/ =~ bib.first; h }
 bibitems=h.values.clone
 $stderr.puts "found %d unique bibitems"%bibitems.size if verbose
end

## select an appropriate filter predicate
predicate=case key
            when "-c"
             lambda {|bib|
                     a=bib.find{|l| /citations.*=.*\{([0-9]+)\}/ =~ l }
                     if a.nil?
                       false
                     else
                       n=$1.to_i                       
                       if n >= mincount
                         true
                       else
                         false
                       end
                     end
             };
            when "-a"
             lambda {|bib|
                     keep=false 
                     #first include all items
                     unless retain.empty? or (bib.find{|l| /^\@([a-zA-Z]+)\{/ =~ l }).nil?
                       keep|=! retain.index($1.to_s.downcase).nil?
                     else unless rinclude.nil?
		                     keep|=! (bib.find{|l| rinclude =~ l }).nil?
		                   else
		                     keep=true
		                   end
                     end
                     if keep
                       unless remove.empty? or (bib.find{|l| /^\@([a-zA-Z]+)\{/ =~ l }).nil?
												 keep&=remove.index($1.to_s.downcase).nil? 
                         # keep will be false if the term is within remove					
											 end
											 unless rexclude.nil?
                         keep&=(bib.find{|l| rexclude =~ l }).nil?
                       end
                     end
                     keep                    
             };              
            when "-n"
             lambda {|bib,i,s,r|
                     $stderr.puts "entry: %d of %d (%.2f %%) removed: %d (%.2f %%)" % [i+1,s,(i*100.0)/s,r,(r*100.0)/(i+1)]
                     $stderr.puts " class: %s"% $1.to_s unless (bib.find{|l| /^\@([a-zA-Z]+)\{/ =~ l }).nil?
                     $stderr.puts " title: %s"% $1.to_s unless (bib.find{|l| /title.*=.*\{(.+)\}/ =~ l }).nil?
                     $stderr.puts " url  : %s"% $1.to_s unless (bib.find{|l| /howpublished.*=.*\{\\url\{(.+)\}\}/ =~ l }).nil?
                     $stderr.puts " cites: %s"% $1.to_s unless (bib.find{|l| /citations=\{([0-9]+)\}/ =~ l }).nil?
                     $stderr.print("Remove this entry (y/n) [default no]? ")
                     key=$stdin.gets.strip
                     !(/^[yY].*/ =~ key)
                    }
            else nil
          end

filtered=bibitems
## the power of ruby
if key=="-n" and (not predicate.nil?)
 s=bibitems.size
 r=0
 l=0
 bibitems.each_with_index do|x,i|
  if predicate.call(x,i,s,r)
   puts x
   #$stdout.flush #include to immediatly flush the buffer once written
   l=0
  else
   r+=1
   l+=1
   $stderr.puts achievements(i,s,r,l)
  end
 end
else
 unless predicate.nil?
  filtered=bibitems.select(&predicate)
  filtered.each{|x| puts x} unless summary
 end
end



if summary
  citations=filtered.map do|bib|
    if bib.find{|l| /citations.*=.*\{([0-9]+)\}/ =~ l }.nil?
      0
    else 
      $1.to_i # abused side effect
    end
  end.sort
  filecount=filtered.inject(0) do|sum,bib|
    if bib.find{|l| /file.*=.*\{.+\}/ =~ l }.nil? then sum else sum+1 end
  end
  if table
    a=[citations.size,
       citations[(citations.size/2)+1],
       citations.first,
       citations.last]
    a << filecount if countfiles
    puts (a.map{|x| if x.nil? then 0 else x end}).join(", ")
  else
    puts "size:       %d" % citations.size
    puts "median:     %d" % citations[citations.size/2+1] if citations.size > 2
    puts "min:        %d" % citations.first               if citations.size > 1
    puts "max:        %d" % citations.last                if citations.size > 1
    puts "file links: %d" % filecount                     if countfiles
  end
end



