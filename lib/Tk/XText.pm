package Tk::XText;

=head1 NAME

Tk::XText - Extended Text widget

=cut

use vars qw($VERSION);
$VERSION = '0.40';
use strict;
use warnings;
use Carp;

use Tk;
use Math::Round;

use base qw(Tk::Derived Tk::Text);
Construct Tk::Widget 'XText';

=head1 SYNOPSIS

 require Tk::XText;
 my $text= $window->XText(@options)->pack;

=head1 DESCRIPTION

B<Tk::XText> inherits L<Tk::Text>. It adds an advanced Undo/Redo stack, 
facilities for indenting and unindenting, commenting and uncommenting 
and autoindendation.

It's main purpose is to serve as the text widget in the L<Tk::CodeText> 
mega widget.

The options and methods below are only documented if they are not available
within the L<Tk::CodeText> context. Otherwise see there.

=head1 OPTIONS

=over 4

=item Name: B<autoIndent>

=item Class: B<AutoIndent>

=item Switch: B<-autoindent>

.

=item Name: B<disableMenu>

=item Class: B<DisableMenu>

=item Switch: B<-disablemenu>

.

=item Switch: B<-findandreplacecall>

.

=item Name: B<indentStyle>

=item Class: B<IndentStyle>

=item Switch: B<-indentstyle>

.

=item Switch: B<-logcall>

.

=item Name: B<match>

=item Class: B<Match>

=item Switch: B<-match>

.

=item Switch: B<-matchoptions>

.

=item Switch: B<-mlcommentend>

The end string of a multi line comment.

=item Switch: B<-mlcommentstart>

The start string of a multi line comment.

=item Switch: B<-modifycall>

This callback is called every time text is modified.
used in L<Tk::Codetext> for adjusting line numbers and
triggering syntax highlighting/code folding.

=item Switch: B<-slcomment>

The start string of a single line comment.

=back

=cut

=head1 EVENTS AND KEYBINDINGS

Besides the events of l<Tk::Text>, this module responds to
the following events and bindings:

 Event:         Key:
 <<Find>>       F8
 <<Replace>>    F9
 <<Indent>>     CONTROL+J
 <<UnIndent>>   CONTROL+SHIFT+J or CONTROL+TAB
 <<Comment>>    CONTROL+G
 <<UnComment>>  CONTROL+SHIFT+G
 <<Undo>>       CONTROL+Z
 <<Redo>>       CONTROL+SHIFT+Z

Further more, CONTROL+A selects all text.

=head1 METHODS

=over 4

=cut

sub Populate {
	my ($self, $args) = @_;
	$self->SUPER::Populate($args);

	$self->{BUFFER} = '';
	$self->{BUFFERMODE} = '';
	$self->{BUFFERMODIFIED} = 0;
	$self->{BUFFERSTART} = '1.0';
	$self->{BUFFERREPLACE} = '';
	$self->{REDOSTACK} = [];
	$self->{UNDOSTACK} = [];

	$self->ResetRedo;
	$self->ResetUndo;

	
	$self->ConfigSpecs(
		-autoindent => ['PASSIVE', 'autoIndent', 'AutoIndent', 0],
		-disablemenu => ['PASSIVE', 'disableMenu', 'Disablemenu', 0],
		-findandreplacecall => ['PASSIVE'],
		-indentstyle => ['PASSIVE', 'indentStyle', 'IndentStyle', "tab"],
		-logcall => ['CALLBACK', undef, undef, sub {}],
		-match => ['PASSIVE', 'match', 'Match', '[]{}()'],
		-matchoptions	=> ['METHOD', undef, undef, [-background => 'blue', -foreground => 'yellow']],
		-mlcommentend => ['PASSIVE'],
		-mlcommentstart => ['PASSIVE'],
		-modifycall => ['CALLBACK', undef, undef, sub {}],
		-slcomment => ['PASSIVE'],
		DEFAULT => [ 'SELF' ],
	);
	$self->eventAdd('<<Find>>', '<F8>');
	$self->eventAdd('<<Replace>>', '<F9>');
	$self->eventAdd('<<Indent>>', '<Control-j>');
	$self->eventAdd('<<UnIndent>>', '<Control-J>');
	$self->eventAdd('<<Comment>>', '<Control-g>');
	$self->eventAdd('<<UnComment>>', '<Control-G>');
	$self->eventAdd('<<Undo>>', '<Control-z>');
	$self->eventAdd('<<Redo>>', '<Control-Z>');
	$self->bind('<Control-Tab>', 'UnIndent' );
	$self->bind('<KeyRelease>', 'matchCheck');
	$self->bind('<Control-a>', 'selectAll');
	$self->markSet('match', '0.0');
}

sub Backspace {
	my $self = shift;
	if ($self->compare('insert','!=','1.0')) { #We are not at the start of the text
		$self->RecordUndo('backspace', $self->editModified);
		if ($self->selectionExists) {
			$self->SUPER::delete('sel.first','sel.last');
		} else {
			$self->SUPER::delete('insert-1c')
		}
		$self->Callback('-modifycall', 'insert');
	}
}

sub Buffer {
	my $self = shift;
	$self->{BUFFER} = shift if @_;
	return $self->{BUFFER}
}

sub BufferMode {
	my $self = shift;
	$self->{BUFFERMODE} = shift if @_;
	return $self->{BUFFERMODE}
}

sub BufferModified {
	my $self = shift;
	$self->{BUFFERMODIFIED} = shift if @_;
	return $self->{BUFFERMODIFIED}
}

sub BufferReplace {
	my $self = shift;
	$self->{BUFFERREPLACE} = shift if @_;
	return $self->{BUFFERREPLACE}
}

sub BufferStart {
	my $self = shift;
	$self->{BUFFERSTART} = shift if @_;
	return $self->{BUFFERSTART}
}

=item B<canUndo>

=cut

sub canUndo {
	my $self = shift;
	my $stack = $self->UndoStack;
	return ((@$stack > 0) or ($self->Buffer ne ''));
}

=item B<canRedo>

=cut

sub canRedo {
	my $stack = $_[0]->RedoStack;
	return (@$stack > 0)
}

sub ClassInit {
	my ($class,$mw) = @_;
	$mw->bind($class, '<<Find>>','FindPopUp');
	$mw->bind($class, '<<Replace>>','FindAndReplacePopUp');
	$mw->bind($class, '<<Comment>>','comment');
	$mw->bind($class, '<<Comment>>','comment');
	$mw->bind($class,'<<UnComment>>','uncomment');
	$mw->bind($class, '<<Indent>>','indent');
	$mw->bind($class,'<<UnIndent>>','unindent');
	$mw->bind($class, '<<Undo>>','undo');
	$mw->bind($class,'<<Redo>>','redo');
	$mw->bind($class, '<Return>', 'doAutoIndent', );
	return $class->SUPER::ClassInit($mw);
}

=item B<clear>

=cut

sub clear {
	my $self = shift;
	$self->delete('1.0', 'end');

	$self->ResetRedo;
	$self->ResetUndo;

	$self->Buffer('');
	$self->BufferMode('');
	$self->BufferModified(0);
	$self->BufferReplace('');
	$self->BufferStart('1.0');
	$self->editModified(0);
	$self->OverstrikeMode(0);

	$self->Callback('-modifycall', '1.0');
}

sub clearModified {
	my $self = shift;
	$self->Flush;
	$self->editModified(0);
	$self->BufferModified(0);
	my $r = $self->RedoStack;
	my $u = $self->UndoStack;
	for (@$r, @$u) { $_->{'modified'} = 1 }
}

=item B<comment>

=cut

sub comment {
	my $self = shift;
	my $slstart = $self->cget('-slcomment');
	my $mlend = $self->cget('-mlcommentend');
	my $mlstart = $self->cget('-mlcommentstart');
	my $modified = $self->editModified;
	if ($self->CommentType eq 'multi') {
		#multi line operation
		if ((defined $mlend) and (defined $mlstart)) {
			my ($rb, $re) = $self->tagRanges('sel');
			my $old = $self->get($rb, $re);
			$self->SUPER::insert($rb, $mlstart);
			$self->SUPER::insert($re, $mlend);
			my $len = length $mlend;
			$re = $self->index("$re + $len chars");
			my $new = $self->get($rb, $re);
			$self->unselectAll;
			$self->tagAdd('sel',$rb, $re);
			$self->RecordUndo('replace', $modified, $rb, $old, $new);
			$self->Callback('-modifycall', $rb);
			my $lines = $self->linenumber($re) - $self->linenumber($rb);
			$self->log("Commented $lines lines");
		} elsif (defined $slstart) { 
			$self->selectionModify($slstart, 0, 'Commented');
		}
	} else { 
		#single line operation
		my $begin = $self->index('insert linestart');
		my $end = $self->index("$begin lineend");
		my $old = $self->get($begin, $end);
		if (defined $slstart) {
			$self->SUPER::insert($begin, $slstart);
		} elsif ((defined $mlend) and (defined $mlstart)) {
			$self->SUPER::insert($end, $mlend);
			$self->SUPER::insert($begin, $mlstart);
		}
		my $new = $self->get($begin, "$begin lineend");
		$self->RecordUndo('replace', $modified, $begin, $old, $new);
		$self->Callback('-modifycall', $begin);
	}
}

sub CommentType {
	my $self = shift;
	if ($self->selectionExists) {
		my $mode = 'single'; #does the selection span over multiple lines?
		my ($rb, $re) = $self->tagRanges('sel');
		$mode = 'multi' if ($self->linenumber($rb) < $self->linenumber($re));
		return $mode
	}
	return 'single'	
}

sub delete {
	my $self = shift;
	my $begin = $_[0];
	$begin = 'insert' unless defined $begin;
	my $string = $self->get(@_);
	$self->RecordUndo('delete', $self->editModified, $begin, $string);
	$self->SUPER::delete(@_);
	$self->Callback('-modifycall', $begin);
}

sub DoAutoIndent {
	my $self = shift;
	if ($self->cget('-autoindent')) {
		my $i = $self->index('insert linestart');
		if ($self->compare($i, ">", '1.0')) {
			my $s = $self->get("$i - 1 lines", "$i - 1 lines lineend");
			$s =~ /^(\s+)/;
			if ($1) {
				$self->insert('insert', $1);
			}
		}
	}
}

sub EditMenuItems {
	my $self = shift;
	return (
		["command"=>'~Copy',
			-accelerator => 'CTRL+C',
			-command => [$self => 'clipboardCopy']
		],
		["command"=>'C~ut', 
			-accelerator => 'CTRL+X',
			-command => [$self => 'clipboardCut']
		],
		["command"=>'~Paste', 
			-accelerator => 'CTRL+V',
			-command => [$self => 'clipboardPaste']
		],
		"-",
		["command"=>'~Undo', 
			-accelerator => 'CTRL+Z',
			-command => [$self => 'undo']
		],
		["command"=>'~Redo', 
			-accelerator => 'CTRL+SHIFT+Z',
			-command => [$self => 'redo']
		],
		"-",
		["command"=>'C~omment', 
			-accelerator => 'CTRL+G',
			-command => [$self => 'comment']
		],
		["command"=>'U~ncomment', 
			-accelerator => 'CTRL+SHIFT+G',
			-command => [$self => 'uncomment']
		],
		"-",
		["command"=>'~Indent', 
			-accelerator => 'CTRL+J',
			-command => [$self => 'indent']
		],
		["command"=>'Unin~dent', 
			-accelerator => 'CTRL+SHIFT+J',
			-command => [$self => 'unindent']
		],
	);
}

sub EmptyDocument { $_[0]->clear }

sub findandreplacepopup {
	my $self = shift;
	my $call = $self->cget('-findandreplacecall');
	if (defined $call) {
		&$call(@_);
	} else {
		$self->SUPER::findandreplacepopup(@_)
	}
}


sub FindandReplaceAll {
	my $self = shift;
	return $self->SUPER::FindandReplaceAll(@_);
}

sub Flush {
	my $self = shift;
	my $buf = $self->Buffer;
	my $rbuf = $self->BufferReplace;
	if ($buf ne '') {
		my $mode = $self->BufferMode;
		my $start = $self->BufferStart;
		my $bmod = $self->BufferModified;
		if ($mode eq 'backspace') {
			$self->PushUndoRaw('delete', $bmod, $start, $buf);
		} elsif ($mode eq 'replace') {
			$self->PushUndoRaw($mode, $bmod, $start, $buf, $rbuf);
		} else {
			$self->PushUndoRaw($mode, $bmod, $start, $buf);
		}
		$self->Buffer('');
		$self->BufferReplace('');
		$self->BufferMode('');
		$self->BufferModified($self->editModified);
		$self->BufferStart($self->index('insert'));
	}
}

my %flushkeys = (
	"\t" => 1, 
	"\n" => 1,
	" "  => 1
);

sub FlushConditional {
	my ($self, $pos, $key) = @_;
	$pos = $self->index($pos);
	my $mode = $self->BufferMode;
	my $start = $self->BufferStart;
	my $len = length($self->Buffer);
	my $icmoved = 0;
	if ($mode eq 'backspace') {
		$icmoved = ($start ne $pos);
	} elsif ($mode eq 'delete') {
		$icmoved = ($start ne $pos)
	} elsif ($mode eq 'insert') {
		$icmoved = ($self->index("$start + $len chars") ne $pos)
	} elsif ($mode eq 'replace') {
		$len = length($self->BufferReplace);
		$icmoved = ($self->index("$start + $len chars") ne $pos)
	} else {
		carp "illegal buffermode '$mode'\n";
	}
	if ((exists $flushkeys{$key}) or ($icmoved)) {
		$self->Flush;
		$self->BufferMode($mode);
		return 1
	}
	return 0
}

=item B<getFontInfo>

=cut

sub getFontInfo {
	my $self = shift;
	my $f = $self->cget('-font');
	my %inf = ();
	my @opt = qw(-family -size -weight -slant -underline -overstrike);
	for (@opt) {
		$inf{$_} = $self->fontActual($f, $_)
	}
	return \%inf
}

=item B<goTo>

=cut

sub goTo {
	my ($self, $pos) = @_;
	$self->markSet('insert', $pos);
	$self->see($pos);
}

=item B<indent>

=cut

sub indent {
	my $self = shift;
	my $ichar = $self->indentString;
	if ($self->selectionExists) {
		$self->selectionModify($ichar, 0, 'Indented');
	} else {
		my $begin = $self->index('insert linestart');
		my $old = $self->get($begin, "$begin lineend");
		my $new = $ichar . $old;
		$self->RecordUndo('replace', $self->editModified, $begin, $old, $new);
		$self->SUPER::insert($begin, $ichar);
		$self->Callback('-modifycall', $begin);
	}
}

sub indentString {
	my $self = shift;
	my $style = $self->cget('-indentstyle');
	my $ichar = '';
	if ($style eq 'tab') {
		$ichar = "\t";
	} else {
		my $str = '';
		for (0 .. $style) {
			$ichar = $ichar . ' '
		}
	}
	return $ichar;
}

sub insert {
	my ($self, $pos, $string) = @_;
	$pos = $self->index($pos);
	$self->RecordUndo('insert', $self->editModified,$pos, $string);
	$self->SUPER::insert($pos, $string);
	$self->Callback('-modifycall', $pos);
}

sub Insert {
	my ($self, $string) = @_;
	$self->SUPER::Insert($string);
	$self->DoAutoIndent if $string eq "\n" ;
}

sub InsertKeypress {
	my ($self, $char) = @_;
	return unless length($char);
	my $index = $self->index('insert');
	if ($self->OverstrikeMode) {
		my $current = $self->get('insert');
		$current = '' if $current eq "\n";
		$self->RecordUndo('replace', $self->editModified, $index, $current, $char);
		$self->SUPER::delete($index) unless $current eq '';
		$self->SUPER::insert($index, $char);
		$self->Callback('-modifycall', $index);
	} else {
		$self->Insert($char);
	}
}

sub insertTab {
	my $self = shift;
	if ($self->selectionExists) {
		$self->indent;
	} else {
		$self->SUPER::insertTab;
	}
}

=item B<linenumber>

=cut

sub linenumber {
	my ($self, $index) = @_;
	$index = 'insert' unless defined $index;
	my $id = $self->index($index);
	my ($line, $pos ) = split(/\./, $id);
	return $line;
}

=item B<load>

=cut

sub load {
	my ($self, $file) = @_;

	unless (open INFILE, '<', $file) { 
		warn "cannot open $file";
		return 0
	};
	$self->clear;
	while (my $line = <INFILE>) {
		$self->SUPER::insert('end', $line);
	}
	close INFILE;
	$self->goTo('1.0');
	$self->editModified(0);
	$self->Callback('-modifycall', '1.0');
	$self->log("Loaded $file");
	return 1
}

=item B<log>

=cut

sub log {
	my ($self, $message) = @_;
	$self->Callback('-logcall', $message);
}

sub matchCheck {
	my $self = shift;
	my $c = $self->get('insert - 1 chars', 'insert');
	my $p = $self->index('match');
	if ($p ne '0.0') {
		$self->tagRemove('Match', $p, "$p + 1 chars");
		$self->markSet('match', '0.0');
	}
	if ($c) {
		my $v = $self->cget('-match');
		my $p = index($v, $c);
		if ($p ne -1) { #a character in '-match' has been detected.
			my $count = 0;
			my $found = 0;
			if ($p % 2) {
				my $m = substr($v, $p - 1, 1);
				$self->matchFind('-backwards', $c, $m, 
					$self->index('insert - 1 chars'),
					$self->index('@0,0'),
				);
			} else {
				my $m = substr($v, $p + 1, 1);
				$self->matchFind('-forwards', $c, $m,
					$self->index('insert'),
					$self->index($self->visualEnd . '.0 lineend'),
				);
			}
		}
	}
}

sub matchFind {
	my ($self, $dir, $char, $ochar, $start, $stop) = @_;
	#first of all remove a previous match highlight;
	my $pattern = "\\$char|\\$ochar";
	my $found = 0;
	my $count = 0;
	while ((not $found) and (my $i = $self->search(
		$dir, '-regexp', '-nocase', '--', $pattern, $start, $stop
	))) {
		my $k = $self->get($i, "$i + 1 chars");
#		print "found $k at $i and count is $count\n";
		if ($k eq $ochar) {
			if ($count > 0) {
#				print "decrementing count\n";
				$count--;
				if ($dir eq '-forwards') {
					$start = $self->index("$i + 1 chars");
				} else {
					$start = $i;
				}
			} else {
#				print "Found !!!\n";
				$self->markSet('match', $i);
				$self->tagAdd('Match', $i, "$i + 1 chars");
				$self->tagRaise('Match');
				$found = 1;
			}
		} elsif ($k eq $char) {
#			print "incrementing count\n";
			$count++;
			if ($dir eq '-forwards') {
				$start = $self->index("$i + 1 chars");
			} else {
				$start = $i;
			}
		} elsif ($i eq $start) {
			$found = 1;
		}
	}
}

sub matchoptions {
	my $self = shift;
	if (my $o = shift) {
		my @op = ();
		if (ref($o)) {
			@op = @$o;
		} else {
			@op = split(/\s+/, $o);
		}
		$self->tagConfigure('Match', @op);
	}
}


sub PostPopupMenu {
	my $self = shift;
	$self->SUPER::PostPopupMenu(@_) unless $self->cget('-disablemenu');
}

sub PullUndo {
	my $self = shift;
	my $stack = $self->UndoStack;
	return shift(@$stack);
}

sub PullRedo {
	my $self = shift;
	my $stack = $self->RedoStack;
	return shift(@$stack);
}

sub PushUndo {
	my $self = shift;
	my $stack = $self->UndoStack;
	unshift(@$stack, @_);
}

sub PushUndoRaw {
	my ($self, $mode, $modified, @content) = @_;
	my %undo = (
		content => \@content,
		mode => $mode,
		modified => $modified,
	);

	my @ranges = $self->tagRanges('sel');
	$undo{'selection'} = \@ranges if (@ranges eq 2);

	$self->PushUndo(\%undo);
}

sub PushRedo {
	my $self = shift;
	my $stack = $self->RedoStack;
	unshift(@$stack, @_);
}

sub RecordUndo {
	my ($self, $mode, $modified, @content) = @_;
	
	$self->ResetRedo;

	if ($mode eq 'backspace') {
		if ($self->selectionExists) {
			$self->Flush;
			my @ranges = $self->tagRanges('sel');
			my $text = $self->get(@ranges);
			$self->PushUndoRaw('delete', $modified, $ranges[0], $text);
		} else {
			my $bufmode = $self->BufferMode;
			$self->Flush if $mode ne $bufmode;
			$self->BufferMode($mode);


			my $end = $self->index('insert');
			my $begin = $self->index("$end - 1c");
			my $char = $self->get($begin, $end);
			if ($char ne '') {
				$self->FlushConditional($end, $char);
				my $buf = $self->Buffer;
				$buf = "$char$buf";
				$self->Buffer($buf);
				$self->BufferStart($begin);
			}
		}
	} elsif (($mode eq 'delete') or ($mode eq 'insert')) {
		my ($pos, $text) = @content;
		$pos = $self->index($pos);

		if (length($text) > 1) {
			$self->Flush;
			$self->PushUndoRaw($mode, $modified, $pos, $text);
		} else {
			my $bufmode = $self->BufferMode;
			$self->Flush if $mode ne $bufmode;
			$self->BufferMode($mode);


			$self->BufferStart($pos) if $self->FlushConditional($pos, $text);
			my $buf = $self->Buffer;
			$buf = "$buf$text";
			$self->Buffer($buf);
		}
	} elsif ($mode eq 'replace') {
		my ($pos, $old, $new) = @content;
		$pos = $self->index($pos);

		if ((length($new) > 1) or ($self->selectionExists)) {
			$self->Flush;
			$self->PushUndoRaw($mode, $modified, $pos, $old, $new);
		} else {
			my $bufmode = $self->BufferMode;
			$self->Flush if $mode ne $bufmode;
			$self->BufferMode($mode);

			$self->BufferStart($pos) if $self->FlushConditional($pos, $new);
			my $buf = $self->Buffer;
			my $rbuf = $self->BufferReplace;
			$buf = "$buf$old";
			$rbuf = "$rbuf$new";
			$self->Buffer($buf);
			$self->BufferReplace($rbuf);
		}
	}
}

=item B<redo>

=cut

sub redo {
	my $self = shift;
	if ($self->canRedo) {
		my $o = $self->PullRedo;
		$self->PushUndo($o);

		my $mode = $o->{'mode'};
		if ($mode eq 'insert') {
			my $content = $o->{'content'};
			my ($pos, $text) = @$content;
			my $len = length($text);
			$self->SUPER::insert($pos, $text);
			$self->markSet('insert', $self->index("$pos + $len chars"));
			$self->see('insert');
		} elsif ($mode eq 'delete') {
			my $content = $o->{'content'};
			my ($pos, $text) = @$content;
			my $len = length($text);
			$self->SUPER::delete($pos, "$pos + $len chars");
			$self->markSet('insert', $pos);
			$self->see('insert');
		} elsif ($mode eq 'replace') {
			my $content = $o->{'content'};
			my ($pos, $old, $new) = @$content;
			my $len = length($old);
			$self->SUPER::delete($pos, "$pos + $len chars");
			$self->SUPER::insert($pos, $new);
			my $lnew = length($new);
			$self->markSet('insert', "$pos + $lnew chars");
			$self->see('insert');
		} else {
			carp "invalid redo mode $mode, should be 'delete', 'insert', or 'replace'\n";
		}
# 		if ($self->UndoStackEmpty) {
# 			$self->editModified($self->UndoEmptyModified);
# 		} else {
		$self->editModified($o->{'redo_modified'});
# 		}
		if (my $sel = $o->{'selection'}) {
			$self->unselectAll;
			$self->tagAdd('sel',@$sel);
		}
		my $pos = $o->{'content'}->[0];
		$self->Callback('-modifycall', $pos);
	}
}

sub RedoStack {
	return $_[0]->{REDOSTACK}
}

sub ReplaceSelectionsWith {
	my ($self,$new_text ) = @_;

	my @ranges = $self->tagRanges('sel');
	my $range_total = @ranges;

	# if nothing selected, then ignore
	if ($range_total == 0) {return};

	# insert marks where selections are located
	# marks will move with text even as text is inserted and deleted
	# in a previous selection.
	for (my $i=0; $i<$range_total; $i++) {
		$self->markSet('mark_sel_'.$i => $ranges[$i]);
	}

	# for every selected mark pair, insert new text and delete old text
	my ($first, $last);
	for (my $i=0; $i<$range_total; $i=$i+2) {
		$first = $self->index('mark_sel_'.$i);
		$last = $self->index('mark_sel_'.($i+1));

		my $old = $self->get($first, $last);
		$self->RecordUndo('replace', $self->editModified, $first, $old, $new_text);
		$self->SUPER::insert($last, $new_text);
		$self->SUPER::delete($first, $last);
		$self->Callback('-modifycall', $first);

	}
	############################################################
	# set the insert cursor to the end of the last insertion mark
	$self->markSet('insert',$self->index('mark_sel_'.($range_total-1)));

	# delete the marks
	for (my $i=0; $i<$range_total; $i++) { 
		$self->markUnset('mark_sel_'.$i); 
	}
}

sub ResetRedo {
	$_[0]->{REDOSTACK} = [];
}

sub ResetUndo {
	$_[0]->{UNDOSTACK} = [];
}

=item B<save>

=cut

sub save {
	my ($self, $file) = @_;

	unless (open OUTFILE, '>', $file) { 
		warn "cannot open $file";
		return 0
	};
	my $index = '1.0';
	while ($self->compare($index,'<','end')) {
		my $end = $self->index("$index lineend + 1c");
		my $line = $self->get($index,$end);
		print OUTFILE $line;
		$index = $end;
	}
	close OUTFILE;
	$self->clearModified;
	$self->log("Saved $file");
	return 1
}

#fix for selectAll of Tk::Text. 
sub selectAll {
	my $self = shift;
#	$self->tagAdd('sel','1.0','end');
	$self->tagAdd('sel','1.0','end - 1c');
}

=item B<selectionExists>

=cut

sub selectionExists {
	my $self = shift;
	my @ranges = $self->tagRanges('sel');
	return @ranges > 1
}

sub selectionModify {
	my ($self, $char, $mode, $operation) = @_;
	my @ranges = $self->tagRanges('sel');
	my $start = $ranges[0];
	my $end = $self->index($ranges[1]);
	my $len = length($char);
	my $old = $self->get(@ranges);
	my $modified = $self->editModified;
	while ($self->compare($start, "<", $end)) {
		if ($mode) {
			if ($self->get("$start linestart", "$start linestart + $len chars") eq $char) {
				$self->SUPER::delete("$start linestart", "$start linestart + $len chars");
			}
		} else {
			$self->SUPER::insert("$start linestart", $char)
		}
		$start = $self->index("$start + 1 lines");
	}
	$self->unselectAll;
	$self->tagAdd('sel', @ranges);
	my $new = $self->get(@ranges);
	$self->RecordUndo('replace', $modified, $ranges[0], $old, $new);
	$self->Callback('-modifycall', $ranges[0]);
	my $lines = $self->linenumber($ranges[1]) - $self->linenumber($ranges[0]);
	$self->log("$operation $lines lines");
}


=item B<uncomment>

=cut

sub uncomment {
	my $self = shift;
	my $slstart = $self->cget('-slcomment');
	my $mlstart = $self->cget('-mlcommentstart');
	my $mlend = $self->cget('-mlcommentend');
	my $lend = length($mlend) if defined $mlend;
	my $lstart = length($mlstart) if defined $mlstart;
	my $modified = $self->editModified;
	if ($self->CommentType eq 'multi') {
		my ($rb, $re) = $self->tagRanges('sel');
		$rb = $self->index("$rb linestart");
		$re = $self->index("$re lineend");
		my $old = $self->get($rb, $re);
		if ((defined $mlstart) and(defined $mlend)) {
			if (($old =~ /^$mlstart/) and ($old =~ /$mlend$/)){
				$self->SUPER::delete($rb, "$rb + $lstart chars");
				$self->SUPER::delete("$re - $lend chars", $re);
				my $new = $self->get($rb, $re);
				$self->unselectAll;
				$self->tagAdd('sel', $rb, $re);
				$self->RecordUndo('replace', $modified, $rb, $old, $new);
				$self->Callback('-modifycall', $rb);
				my $lines = $self->linenumber($re) - $self->linenumber($rb);
				$self->log("Uncommented $lines lines");
			}
		} elsif (defined $slstart) {
			$self->selectionModify($slstart, 1, 'Uncommented')		
		}
	} else {
		my $rb = $self->index('insert linestart');
		my $re =  $self->index('insert lineend');
		my $old = $self->get($rb, $re);
		if (defined($slstart)) {
			$lstart = length $slstart;
			$self->SUPER::delete('insert linestart', "insert linestart + $lstart chars");
		} elsif ((defined $mlstart) and(defined $mlend)) {
			if (($old =~ /^$mlstart/) and ($old =~ /$mlend$/)){
				$self->SUPER::delete('insert linestart', "insert linestart + $lstart chars");
				$self->SUPER::delete( "insert lineend - $lend chars", 'insert lineend');
			}
		}
		my $new = $self->get($rb, "$rb lineend");
		$self->RecordUndo('replace', $modified, $rb, $old, $new);
		$self->Callback('-modifycall', $rb);
	}
}

=item B<undo>

=cut

sub undo {
	my $self = shift;
	if ($self->canUndo) {
		$self->Flush;

		my $o = $self->PullUndo;
		my $mod = $self->editModified;
		$self->PushRedo($o);

		my $mode = $o->{'mode'};
		if ($mode eq 'delete') {
			my $content = $o->{'content'};
			my ($pos, $text) = @$content;
			my $len = length($text);
			$self->SUPER::insert($pos, $text);
			$self->markSet('insert', $self->index("$pos + $len chars"));
			$self->see('insert');
		} elsif ($mode eq 'insert') {
			my $content = $o->{'content'};
			my ($pos, $text) = @$content;
			my $len = length($text);
			$self->SUPER::delete($pos, "$pos + $len chars");
			$self->markSet('insert', $pos);
			$self->see('insert');
		} elsif ($mode eq 'replace') {
			my $content = $o->{'content'};
			my ($pos, $old, $new) = @$content;
			my $len = length($new);
			$self->SUPER::delete($pos, "$pos + $len chars");
			$self->SUPER::insert($pos, $old);
			my $lold = length($old);
			$self->markSet('insert', $self->index("$pos + $lold chars"));
			$self->see('insert');
		} else {
			carp "invalid undo mode '$mode"."', should be 'delete', 'insert', or 'replace'\n";
		}
# 		if ($self->RedoStackEmpty) {
# 			$self->editModified($self->RedoEmptyModified);
# 		} else {
		$self->editModified($o->{'modified'});
		$o->{'redo_modified'} = $mod;
# 		}
		if (my $sel = $o->{'selection'}) {
			$self->unselectAll;
			$self->tagAdd('sel',@$sel);
		}
		my $pos = $o->{'content'}->[0];
		$self->Callback('-modifycall', $pos);
	}
}

sub UndoStack {
	return $_[0]->{UNDOSTACK}
}

=item B<unindent>

=cut

sub unindent {
	my $self = shift;
	my $ichar = $self->indentString;
	if ($self->selectionExists) {
		$self->selectionModify($ichar, 1, 'Unindent');
	} else {
		my $modified = $self->editModified;
		my $index = $self->index('insert');
		my $start = $self->index('insert linestart');
		my $len = length($ichar);
		my $string = $self->get($start, $index);
		my $old = $self->get($start, "$start lineend");
		if ($string =~ /^$ichar/) {
			$self->SUPER::delete($start, "$start + $len" . "c");
		}
		my $new = $self->get($start, "$start lineend");
		$self->RecordUndo('replace', $modified, $start, $old, $new);
		$self->Callback('-modifycall', $start);
	}
}

=item B<visualBegin>

=cut

sub visualBegin {
	my $self = shift;
	return $self->linenumber('@0,0');
}

=item B<visualEnd>

=cut

sub visualEnd {
	my $self = shift;
	my $height = $self->height;
	return $self->linenumber('@0,' . $height);
}

=back

=head1 AUTHOR

=over 4

=item Hans Jeuken (hanje at cpan dot org)

=back

=cut

=head1 BUGS

Unknown. If you find any, please contact the author.

=cut

=head1 TODO

=over 4


=back

=cut

=head1 SEE ALSO

=over 4


=back

=cut

1;

__END__

