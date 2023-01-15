package Tk::XText;

use vars qw($VERSION);
$VERSION = '0.40';
use strict;
use warnings

use Storable;
use File::Basename;

use base qw(Tk::Derived Tk::Text);
Construct Tk::Widget 'CodeText';

sub Populate {
	my ($self,$args) = @_;
	$self->SUPER::Populate($args);
	$self->ConfigSpecs(
		-autoindent => ['PASSIVE', 'autoIndent', 'AutoIndent', 0],
		-match => ['PASSIVE'. 'match', 'Match', '[]{}()'],
		-matchoptions	=> ['METHOD', undef, undef, [-background => 'red', -foreground => 'yellow']],
		-indentchar => ['PASSIVE', 'indentchar', 'Indentchar', "\t"],
		-disablemenu => ['PASSIVE', 'disableMenu', 'Disablemenu', 0],
		-commentchar => ['PASSIVE', 'commentChar', 'Commentchar', "#"],
		-modifycall => ['CALLBACK', undef, undef, sub {}]
		-updatecall => ['CALLBACK', undef, undef, sub {}]
		DEFAULT => [ 'SELF' ],
	);
	$self->bind('<Return>', sub { $self->doAutoIndent });
}

sub clipboardCopy {
	my $self = shift;
	my @ranges = $self->tagRanges('sel');
	if (@ranges) {
		$self->SUPER::clipboardCopy(@_);
	}
}

sub clipboardCut {
	my $self = shift;
	my @ranges = $self->tagRanges('sel');
	if (@ranges) {
		$self->SUPER::clipboardCut(@_);
	}
}

sub clipboardPaste {
	my $self = shift;
	my @ranges = $self->tagRanges('sel');
	if (@ranges) {
		$self->tagRemove('sel', '1.0', 'end');
		return;
	}
	$self->SUPER::clipboardPaste(@_);
}

sub delete {
	my $self = shift;
	my $begin = $_[0];
	$begin = 'insert' unless defined $begin;
	my $b = $self->linenumber('insert');
	my $end = $_[1];
	$end = $begin unless defined $end;
	my $e = $self->linenumber($end);
	$self->SUPER::delete(@_);
	$self->Callback('-modifycall', $b, $e);
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
		["command"=>'Comment', -command => [$self => 'selectionComment']],
		["command"=>'Uncomment', -command => [$self => 'selectionUnComment']],
		"-",
		["command"=>'Indent', -command => [$self => 'selectionIndent']],
		["command"=>'Unindent', -command => [$self => 'selectionUnIndent']],
	];
}

sub EmptyDocument {
	my $self = shift;
	my @r = $self->SUPER::EmptyDocument(@_);
	$self->Callback('-modifycall', ('0.0', 'end');
	return @r
}

sub insert {
	my $self = shift;
	my $pos = shift;
	$pos = $self->index($pos);
	my $begin = $self->linenumber("$pos - 1 chars");
	$self->SUPER::insert($pos, @_);
	$self->Callback('-modifycall', ($begin, $self->linenumber("insert lineend");
}

sub Insert {
	my $self = shift;
	$self->SUPER::Insert(@_);
	$self->see('insert');
}

sub InsertKeypress {
	my ($self,$char) = @_;
#	print "calling InsertKeypress\n";
	if ($char ne '') {
		my $index = $self->index('insert');
		my $line = $self->linenumber($index);
		if ($char =~ /^\S$/ and !$self->OverstrikeMode and !$self->tagRanges('sel')) {
			$self->SUPER::insert($index,$char);
			$self->Callback('-modifycall', ($line, $line);
			return;
		}
		$self->addGlobStart;
		$self->SUPER::InsertKeypress($char);
		$self->addGlobEnd;
	}
}

sub linenumber {
	my ($self, $index) = @_;
	$index = 'insert' unless defined $index;
	my $id = $self->index($index);
	my ($line, $pos ) = split(/\./, $id);
	return $line;
}

sub Load {
	my $self = shift;
	my @r = $self->SUPER::Load(@_);
	return @r;
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
#		print "character $c number $p\n";
		if ($p ne -1) { #a character in '-match' has been detected.
			my $count = 0;
			my $found = 0;
			if ($p % 2) {
				my $m = substr($v, $p - 1, 1);
#				print "searching -backwards $c $m\n";
				$self->matchFind('-backwards', $c, $m, 
					$self->index('insert - 1 chars'),
					$self->index('@0,0'),
				);
			} else {
				my $m = substr($v, $p + 1, 1);
#				print "searching -forwards, $c, $m\n";
				$self->matchFind('-forwards', $c, $m,
					$self->index('insert'),
					$self->index($self->visualend . '.0 lineend'),
				);
			}
		}
	}
	$self->updateCall;
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

sub selectionModify {
	my ($self, $char, $mode) = @_;
	my @ranges = $self->tagRanges('sel');
	if (@ranges eq 2) {
		my $start = $self->index($ranges[0]);
		my $end = $self->index($ranges[1]);
#		print "doing from $start to $end\n";
		while ($self->compare($start, "<", $end)) {
#			print "going to do something\n";
			if ($mode) {
				if ($self->get("$start linestart", "$start linestart + 1 chars") eq $char) {
					$self->delete("$start linestart", "$start linestart + 1 chars");
				}
			} else {
				$self->insert("$start linestart", $char)
			}
			$start = $self->index("$start + 1 lines");
		}
		$self->tagAdd('sel', @ranges);
	}
}

sub selectionComment {
	my $self = shift;
	$self->selectionModify($self->cget('-commentchar'), 0);
}

sub selectionIndent {
	my $self = shift;
	$self->selectionModify($self->cget('-indentchar'), 0);
}

sub selectionUnComment {
	my $self = shift;
	$self->selectionModify($self->cget('-commentchar'), 1);
}

sub selectionUnIndent {
	my $self = shift;
	$self->selectionModify($self->cget('-indentchar'), 1);
}

sub updateCall {
	my $self = shift;
	my $call = $self->cget('-updatecall');
	&$call;
}

sub visualend {
	my $self = shift;
	my $end = $self->linenumber('end - 1 chars');
	my ($first, $last) = $self->Tk::Text::yview;
	my $vend = int($last * $end) + 2;
	if ($vend > $end) {
		$vend = $end;
	}
	return $vend;
}

=cut

1;

__END__
