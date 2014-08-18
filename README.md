bibfilter
=========

Is a lightweight commandline tool to filter bibtex files. It was tailored to work together with gsresearch. 
It simply allows to filter the entries of a given bibtex file.

Systemrequirements
==================

* Ruby Version 1.9.3 (or higher) [\[get here\]](https://www.ruby-lang.org/de/downloads/)

Synopsis
========

```bash
ruby bibfilter.rb -cN FILES
ruby bibfilter.rb [-aT|-rT]+ [-eREG|-iREG] FILES
ruby bibfilter.rb -n FILES
ruby bibfilter.rb -h
ruby bibfilter.rb -V
```

Description
===========

 Bibfilter is a simple commandline tool which enables the user to
 either interactively or automatically filter a given bibtex file.
 Each bibtex entry passing the filter will be printed to STDOUT,
 whereas the interactive part of the programm uses STDERR for its output.
 Please note that all the automatic filters are executed in a strict 
 order first retaining all bibitems (with -a and -i) and afterwards 
 removing the rest according to (-r and -e)

Commandline Options
===================

 Argument     | Function
:------------:|-------------------------------------------------------------------
 -cN          | Filter the bibitems by citations and remove all entries with less then N citations. (This method assumes a citations field in each bibtex entry.)
 -d           | remove duplicates from the bibtex entries based on their key. This option is combinable with every other option.
 -aT          |Filter the bibitems and retain all items belonging to a certain class (i.e.: article, book, incollections). This option can be used multiple times but not in combination with other options! 
 -rT          |Filter the bibitems and remove all items belonging to a certain class (i.e.: article, book, incollections). This option can be used multiple times but not in combination with other options!
 -e"/REGEX/"  |excludes all bibitems to which this ruby regular expression applies. The expression will be evaluated for each line of a bibfile, so it is impossible evaluate a howl bibitem. This option can be used once, but combined with other automated options like -a, -r, or -i.
 -i"/REGEX/"  |includes all bibitems to which this ruby regular expression applies. The expression will be evaluated for each line of a bibfile, so it is impossible evaluate a howl bibitem. This option can be used once, but combined with other automated options like -a, -r, or -e.
 -n           |Perform an Interactive decission process showing the title, the link and the number of citations (default).
 -h           |Show this document.
 -m           |Measure the entries in the bibtex file to compute the citations min, max, and median as well as the total number of entries. This works also in combination with automatic filters but not with the interactive filter.
 -t           |creates output of measures in the CSV format with count; citations median, min, max. This option implies -m.
 -l           |add the total number of files referenced in the bibtex file to the measured entries. This option implies -m and can be combined with -t.
 -v           |produces verbose output.
 -V           |Shows the version number.

Usage
=====
The following command will remove all bibtex entries from the **paper2002.bib** file with a citation count below 100 and store the remaining entries into the file **filteredpapers2002.bib**

```bash
ruby bibfilter.rb -c100 paper2002.bib > filteredpapers2002.bib
```

The following invocation will go through all the papers interactivelly and stores the results into the **filteredpapers2002.bib**
```bash
 ruby bibfilter.rb -n paper2002.bib > filteredpapers2002.bib
```
