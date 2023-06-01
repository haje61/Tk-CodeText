# Tk-CodeText
Tk::Text widget with syntax highlighting and code folding

**Tk::CodeText** aims to be a Scintilla like text widget for Perl/Tk.

This is a rewrite, almost from scratch and not backwards compatible
with version 0.3.4 and earlier.

It uses **Syntax::Kamelon** for syntax highlighting, code folding
and syntax sensitive commenting and unmommenting, both single line
and multiple line.

Features:

  * line numbers
  * code folding
  * status bar with document info and tools for setting tab size, indent style and syntax
  * advanced word based undo/redo stack that keeps track of the last saving point and selections
  * syntax highlighting in many languages and formats.
  * commenting and uncommenting blocks and lines
  * indenting and unindenting blocks and lines
  * automatic indentation
  * matching of {}, () and [] pairs

# Requirements

Following Perl modules should be installed:

  * File::Path
  * Math::Round
  * Syntax::Kamelon
  * Test::Tk
  * Tk
  * Tk::ColorEntry
  * Tk::PopList

# Installation

  perl Makefile.PL
  make
  make test
  make install

# Sample program codetext

This package comes with a sample script **codetext**. You can invoke
it from the command line after install.

Before install you can do:

  * perl -Mblib bin/codetext

For command line options type:

  * codetext -help

We recommend you install **Tk::GtkSettings** for the prettiest picture.


