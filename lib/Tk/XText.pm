package Tk::XText;

=head1 NAME

Tk:XText - Extended Text widget

=cut

use vars qw($VERSION);
$VERSION = '0.40';
use strict;
use warnings;
use Carp;

use Tk;

use base qw(Tk::Derived Tk::Text);
Construct Tk::Widget 'XText';

=head1 SYNOPSIS

 require Tk::XText;
 my $text= $window->XText(@options)->pack;

=head1 DESCRIPTION

=head1 OPTIONS

=over 4

=item Switch: B<-autoindent>

=item Switch: B<-commentend>

=item Switch: B<-commentstart>

=item Switch: B<-disablemenu>

=item Switch: B<-indentchar>

=item Switch: B<-match>

=item Switch: B<-matchoptions>

=item Switch: B<-modifycall>

=item Switch: B<-updatecall>

=back

=cut

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
# 	$self->{UNDOREDOSIZES} = [0, 0];

	$self->ResetRedo;
	$self->ResetUndo;

	
	$self->ConfigSpecs(
		-autoindent => ['PASSIVE', 'autoIndent', 'AutoIndent', 0],
		-commentend => ['PASSIVE'],
		-commentstart => ['PASSIVE', undef, undef, "#"],
		-disablemenu => ['PASSIVE', 'disableMenu', 'Disablemenu', 0],
		-indentchar => ['PASSIVE', undef, undef, "\t"],
		-match => ['PASSIVE', undef, undef, '[]{}()'],
		-matchoptions	=> ['METHOD', undef, undef, [-background => 'red', -foreground => 'yellow']],
		-modifycall => ['CALLBACK', undef, undef, sub {}],
		-updatecall => ['CALLBACK', undef, undef, sub {}],
		DEFAULT => [ 'SELF' ],
	);
	$self->eventAdd('<<Indent>>', '<Control-j>');
	$self->eventAdd('<<UnIndent>>', '<Control-J>');
	$self->eventAdd('<<Comment>>', '<Control-g>');
	$self->eventAdd('<<UnComment>>', '<Control-G>');
	$self->eventAdd('<<Undo>>', '<Control-z>');
	$self->eventAdd('<<Redo>>', '<Control-Z>');
	$self->bind('<Return>', 'doAutoIndent' );
	$self->bind('<Control-Tab>', 'UnIndent' );
	$self->bind('<KeyRelease>', 'matchCheck');
	$self->bind('<Control-a>', 'selectAll');
	$self->markSet('match', '0.0');
}

sub Backspace {
	my $self = shift;
	$self->RecordUndo('backspace');
	if ($self->compare('insert','!=','1.0')) { #We are not at the start of the text
		if ($self->selectionExists) {
			$self->SUPER::delete('sel.first','sel.last');
		} else {
			$self->SUPER::delete('insert-1c')
		}
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
	my $stack = $_[0]->{UNDOSTACK};
	return (@$stack > 0)
}

=item B<canRedo>

=cut

sub canRedo {
	my $stack = $_[0]->{REDOSTACK};
	return (@$stack > 0)
}

sub ClassInit {
	my ($class,$mw) = @_;
	$mw->bind($class, '<<Comment>>','comment');
	$mw->bind($class,'<<UnComment>>','uncomment');
	$mw->bind($class, '<<Indent>>','indent');
	$mw->bind($class,'<<UnIndent>>','unindent');
	$mw->bind($class, '<<Undo>>','undo');
	$mw->bind($class,'<<Redo>>','redo');
	return $class->SUPER::ClassInit($mw);
}

=item B<clear>

=cut

sub clear {
	my $self = shift;
	$self->SUPER::delete('1.0', 'end');

	$self->ResetRedo;
	$self->ResetUndo;

	$self->Buffer('');
	$self->BufferMode('');
	$self->BufferModified(0);
	$self->BufferReplace('');
	$self->BufferStart($self->index('insert'));
	$self->editModified(0);
	$self->OverstrikeMode(0);

	$self->Callback('-modifycall', '1.0');
}

sub clipboardCut {
	my $self = shift;
	if ($self->selectionExists) {
		my ($begin , $end) = $self->tagRanges('sel');
		my $text = $self->get($begin, $end);
		$self->RecordUndo('delete', $begin, $text);
		$self->SUPER::clipboardCut(@_);
	}
}

# TODO
sub clipboardColumnCut {
	my $self = shift;
	return $self->SUPER::clipboardColumnCut(@_);
}

sub clipboardPaste {
	my $self = shift;
	my $new = $self->clipboardGet;
	if ($self->selectionExists) {
		my ($begin , $end) = $self->tagRanges('sel');
		my $text = $self->get($begin, $end);
		$self->RecordUndo('replace', $begin, $text, $new);
	} else {
		$self->RecordUndo('insert', $self->index('insert'), $new);
	}
	$self->SUPER::clipboardPaste(@_);
}

# TODO
sub clipboardColumnPaste {
	my $self = shift;
	return $self->SUPER::clipboardColumnPaste(@_);
}

=item B<comment>

=cut

sub comment {
	my $self = shift;
	my $start = $self->cget('-commentstart');
	my $end = $self->cget('-commentend');
	if ($self->selectionExists) {
		if (defined $end) {
			my ($rb, $re) = $self->tagRanges('sel');
			my $old = $self->get($rb, $re);
			$self->SUPER::insert($rb, $start);
			$self->SUPER::insert($re, $end);
			my $len = length $end;
			$re = $self->index("$re + $len chars");
			my $new = $self->get($rb, $re);
			$self->RecordUndo('replace', $rb, $old, $new);
			$self->unselectAll;
			$self->tagAdd('sel',$rb, $re);
			$self->Callback('-modifycall', $rb);
		} else {
			$self->selectionModify($start, 0)		
		}
	} else {
		my $begin = $self->index('insert linestart');
		my $old = $self->get($begin, "$begin lineend");
		$self->SUPER::insert($begin, $start);
		$self->SUPER::insert("$begin lineend", $end) if defined $end;
		my $new = $self->get($begin, "$begin lineend");
		$self->RecordUndo('replace', $begin, $old, $new);
		$self->Callback('-modifycall', $begin);
	}
}

sub delete {
	my $self = shift;
	my $begin = $_[0];
	$begin = 'insert' unless defined $begin;
	my $string = $self->get(@_);
	$self->RecordUndo('delete', $begin, $string);
	$self->SUPER::delete(@_);
	$self->Callback('-modifycall', $begin);
}

sub doAutoIndent {
	my $self = shift;
	if ($self->cget('-autoindent')) {
		my $i = $self->index('insert linestart');
		if ($self->compare($i, ">", '0.0')) {
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
	return [
		@{$self->SUPER::EditMenuItems},
		"-",
		["command"=>'Comment', -command => [$self => 'comment']],
		["command"=>'Uncomment', -command => [$self => 'uncomment']],
		"-",
		["command"=>'Indent', -command => [$self => 'indent']],
		["command"=>'Unindent', -command => [$self => 'unindent']],
	];
}

sub EmptyDocument { $_[0]->clear }

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
			$self->PushUndoRaw('delete', $start, $buf, $bmod);
		} elsif ($mode eq 'replace') {
			$self->PushUndoRaw($mode, $start, $buf, $rbuf, $bmod);
		} else {
			$self->PushUndoRaw($mode, $start, $buf, $bmod);
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
}

=item B<indent>

=cut

sub indent {
	my $self = shift;
	my $ichar = $self->cget('-indentchar');
	if ($self->selectionExists) {
		$self->selectionModify($ichar, 0);
	} else {
		my $begin = $self->index('insert linestart');
		my $old = $self->get($begin, "$begin lineend");
		$self->SUPER::insert($begin, $ichar);
		my $new = $self->get($begin, "$begin lineend");
		$self->RecordUndo('replace', $begin, $old, $new);
		$self->Callback('-modifycall', $begin);
	}
}

sub insert {
	my ($self, $pos, $string) = @_;
	$pos = $self->index($pos);
	$self->RecordUndo('insert', $pos, $string);
	$self->SUPER::insert($pos, $string);
	$self->Callback('-modifycall', $pos);
}

sub InsertKeypress {
	my ($self, $char) = @_;
	return unless length($char);
	my $index = $self->index('insert');
	if ($self->OverstrikeMode) {
		my $current = $self->get('insert');
		$current = '' if $current eq "\n";
		$self->RecordUndo('replace', $index, $current, $char);
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
					$self->index($self->visualend . '.0 lineend'),
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
	my $stack = $self->{UNDOSTACK};
	return shift(@$stack);
}

sub PullRedo {
	my $self = shift;
	my $stack = $self->{REDOSTACK};
	return shift(@$stack);
}

sub PushUndo {
	my $self = shift;
	my $stack = $self->{UNDOSTACK};
	unshift(@$stack, @_);
}

sub PushUndoRaw {
	my ($self, $mode, @content, $modified) = @_;

	my %undo = (
		content => \@content,
		mode => $mode,
		modified => $modified,
	);

	my @ranges = $self->tagRanges('sel');
	$undo{'selection'} = \@ranges if (@ranges eq 2);
	
# 	$undo{'remod'} = 1 unless $modified;

	$self->PushUndo(\%undo);
}

sub PushRedo {
	my $self = shift;
	my $stack = $self->{REDOSTACK};
	unshift(@$stack, @_);
}

sub RecordUndo {
	my ($self, $mode, @content) = @_;

	$self->ResetRedo;

	if ($mode eq 'backspace') {
		if ($self->selectionExists) {
			$self->Flush;
			my @ranges = $self->tagRanges('sel');
			my $text = $self->get(@ranges);
			$self->PushUndoRaw('delete', $ranges[0], $text, $self->editModified);
		} else {
			my $bufmode = $self->BufferMode;
			$self->BufferMode($mode) if $bufmode eq '';
			$self->Flush if $mode ne $self->BufferMode;


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
			$self->PushUndoRaw($mode, $pos, $text, $self->editModified);
		} else {
			my $bufmode = $self->BufferMode;
			$self->BufferMode($mode) if $bufmode eq '';
			$self->Flush if $mode ne $self->BufferMode;


			$self->BufferStart($pos) if $self->FlushConditional($pos, $text);
			my $buf = $self->Buffer;
			$buf = "$buf$text";
			$self->Buffer($buf);
		}
	} elsif ($mode eq 'replace') {
		my ($pos, $old, $new) = @content;
		$pos = $self->index($pos);

		if (length($new) > 1) {
			$self->Flush;
			$self->PushUndoRaw($mode, $pos, $old, $new, $self->editModified);
		} else {
			my $bufmode = $self->BufferMode;
			$self->BufferMode($mode) if $bufmode eq '';
			$self->Flush if $mode ne $self->BufferMode;

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
		} elsif ($mode eq 'delete') {
			my $content = $o->{'content'};
			my ($pos, $text) = @$content;
			my $len = length($text);
			$self->SUPER::delete($pos, "$pos + $len chars");
			$self->markSet('insert', $pos);
		} elsif ($mode eq 'replace') {
			my $content = $o->{'content'};
			my ($pos, $old, $new) = @$content;
			my $len = length($old);
			$self->SUPER::delete($pos, "$pos + $len chars");
			$self->SUPER::insert($pos, $new);
			my $lnew = length($new);
			$self->markSet('insert', "$pos + $lnew chars");
		} else {
			carp "invalid redo mode $mode, should be 'delete', 'insert', or 'replace'\n";
		}
# 		$self->editModified($o->{'redomod'});
		if (my $sel = $o->{'selection'}) {
			$self->unselectAll;
			$self->tagAdd('sel',@$sel);
		}
		my $pos = $o->{'content'}->[0];
		$self->Callback('-modifycall', $pos);
	}
}

# sub RedoStackSize {
# 	my $stack = $_[0]->{REDOSTACK};
# 	my $size = @$stack;
# 	return $size;
# }

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
		$self->RecordUndo('replace', $first, $old, $new_text);
		$self->SUPER::insert($last, $new_text);
		$self->SUPER::delete($first, $last);

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

=item B<selectionModify>

=cut

sub selectionModify {
	my ($self, $char, $mode) = @_;
	my @ranges = $self->tagRanges('sel');
	my $start = $ranges[0];
	my $end = $self->index($ranges[1]);
	my $len = length($char);
	my $old = $self->get(@ranges);
	while ($self->compare($start, "<", $end)) {
		if ($mode) {
			if ($self->get("$start linestart", "$start linestart + $len chars") eq $char) {
				$self->SUPER::delete("$start linestart", "$start linestart + $len chars");
			}
		} else {
			$self->insert("$start linestart", $char)
		}
		$start = $self->index("$start + 1 lines");
	}
	my $new = $self->get(@ranges);
	$self->RecordUndo('replace', $ranges[0], $old, $new);
	$self->Callback('-modifycall', $ranges[0]);
# 	$self->tagAdd('sel', @ranges);
}

=item B<uncomment>

=cut

sub uncomment {
	my $self = shift;
	my $start = $self->cget('-commentstart');
	my $end = $self->cget('-commentend');
	my $lstart = length($start);
	my $lend = length($end) if defined $end;
	if ($self->selectionExists) {
		my ($rb, $re) = $self->tagRanges('sel');
		$rb = $self->index("$rb linestart");
		$re = $self->index("$re lineend");
		my $old = $self->get($rb, $re);
		if ((defined $end) and ($old =~ /^$start/) and ($old =~ /$end$/)){
			$self->SUPER::delete($rb, "$rb + $lstart chars");
			$self->SUPER::delete("$re - $lend chars", $re);
			my $new = $self->get($rb, $re);
			$self->RecordUndo('replace', $rb, $old, $new);
			$self->Callback('-modifycall', $rb);
		} else {
			$self->selectionModify($start, 1)		
		}
	} else {
		my $rb = $self->index('insert linestart');
		my $re =  $self->index('insert lineend');
		my $old = $self->get($rb, $re);
		if ((defined $end) and ($old =~ /^$start/) and ($old =~ /$end$/)){
			$self->SUPER::delete('insert linestart', "insert linestart + $lstart chars");
			$self->SUPER::delete( "insert lineend - $lend chars", 'insert lineend');
		} elsif ($old =~ /^$start/) {
			$self->SUPER::delete('insert linestart', "insert linestart + $lstart chars");
		}
		my $new = $self->get($rb, "$rb lineend");
		$self->RecordUndo('replace', $rb, $old, $new)
	}
}

=item B<undo>

=cut

sub undo {
	my $self = shift;
	$self->Flush;
	if ($self->canUndo) {

		my $o = $self->PullUndo;
		$self->PushRedo($o);

		my $mode = $o->{'mode'};
		if ($mode eq 'delete') {
			my $content = $o->{'content'};
			my ($pos, $text) = @$content;
			my $len = length($text);
			$self->SUPER::insert($pos, $text);
			$self->markSet('insert', $self->index("$pos + $len chars"));
		} elsif ($mode eq 'insert') {
			my $content = $o->{'content'};
			my ($pos, $text) = @$content;
			my $len = length($text);
			$self->SUPER::delete($pos, "$pos + $len chars");
			$self->markSet('insert', $pos);
		} elsif ($mode eq 'replace') {
			my $content = $o->{'content'};
			my ($pos, $old, $new) = @$content;
			my $len = length($new);
			$self->SUPER::delete($pos, "$pos + $len chars");
			$self->SUPER::insert($pos, $old);
			my $lold = length($old);
			$self->markSet('insert', $self->index("$pos + $lold chars"));
		} else {
			carp "invalid undo mode $mode, should be 'delete', 'insert', or 'replace'\n";
		}
		$self->editModified($o->{'modified'});
		if (my $sel = $o->{'selection'}) {
			$self->unselectAll;
			$self->tagAdd('sel',@$sel);
		}
		my $pos = $o->{'content'}->[0];
		$self->Callback('-modifycall', $pos);
	}
}

# sub UndoRedoSizes {
# 	my $self = shift;
# 	$self->{UNDOREDOSIZES} = shift if @_;
# 	return $self->{UNDOREDOSIZES}
# }
# 
# sub UndoStackSize {
# 	my $stack = $_[0]->{UNDOSTACK};
# 	my $size = @$stack;
# 	return $size;
# }

=item B<unindent>

=cut

sub unindent {
	my $self = shift;
	my $ichar = $self->cget('-indentchar');
	if ($self->selectionExists) {
		$self->selectionModify($ichar, 1);
	} else {
		my $index = $self->index('insert');
		my $start = $self->index('insert linestart');
		my $indentchar = $self->cget('-indentchar');
		my $len = length($indentchar);
		my $string = $self->get($start, $index);
		my $old = $self->get($start, "$start lineend");
		if ($string =~ /^$indentchar+/) {
			$self->SUPER::delete($start, "$start + $len" . "c");
		}
		my $new = $self->get($start, "$start lineend");
		$self->RecordUndo('replace', $start, $old, $new);
		$self->Callback('-modifycall', $start);
	}
}

=item B<visualend>

=cut

sub visualend {
	my $self = shift;
	my $end = $self->linenumber('end - 1 chars');
	my ($first, $last) = $self->yview;
	my $vend = int($last * $end) + 2;
	if ($vend > $end) {
		$vend = $end;
	}
	return $vend;
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
