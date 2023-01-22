package Tk::XText;

=head1 NAME

Tk:XText - Extended Text widget

=cut

use vars qw($VERSION);
$VERSION = '0.40';
use strict;
use warnings;

use Tk;

use base qw(Tk::Derived Tk::TextUndo);
Construct Tk::Widget 'XText';

=head1 SYNOPSIS

 require Tk::XText;
 my $text= $window->XText(@options)->pack;

=head1 DESCRIPTION

=head1 OPTIONS

=over 4

=item Switch: B<-autoindent>

=item Switch: B<-commentchar>

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
	my $match = "[]{}()";
	$self->ConfigSpecs(
		-autoindent => ['PASSIVE', 'autoIndent', 'AutoIndent', 0],
		-commentend => ['PASSIVE'],
		-commentstart => ['PASSIVE', undef, undef, "#"],
		-disablemenu => ['PASSIVE', 'disableMenu', 'Disablemenu', 0],
		-indentchar => ['PASSIVE', 'indentchar', 'Indentchar', "\t"],
		-match => ['PASSIVE', undef, undef, $match],
		-matchoptions	=> ['METHOD', undef, undef, [-background => 'red', -foreground => 'yellow']],
		-modifycall => ['CALLBACK', undef, undef, sub {}],
		-updatecall => ['CALLBACK', undef, undef, sub {}],
		DEFAULT => [ 'SELF' ],
	);
	$self->eventAdd('<<Comment>>', '<Control-g>');
	$self->eventAdd('<<UnComment>>', '<Control-G>');
	$self->bind('<Return>', 'doAutoIndent' );
	$self->bind('<Control-Tab>', 'UnIndent' );
	$self->bind('<Key>', 'matchCheck');
	$self->markSet('match', '0.0');
}

sub Button1 {
	my $self = shift;
	$self->SUPER::Button1(@_);
	$self->matchCheck;
}

sub ClassInit {
	my ($class,$mw) = @_;
	$mw->bind($class, '<<Comment>>','Comment');
	$mw->bind($class,'<<UnComment>>','UnComment');

	return $class->SUPER::ClassInit($mw);
}

sub Comment {
	my $self = shift;
	my $start = $self->cget('-commentstart');
	my $end = $self->cget('-commentend');
	if ($self->selectionExists) {
		my ($rb, $re) = $self->tagRanges('sel');
		if (defined $end) {
			$self->insert($rb, $start);
			$self->insert($re, $end);
		} else {
			$self->selectionModify($start, 0)		
		}
	} else {
		$self->insert('insert linestart', $start);
		$self->insert('insert lineend', $end) if defined $end;
	}
}

# sub delete {
# 	my $self = shift;
# 	my $begin = $_[0];
# 	$begin = 'insert' unless defined $begin;
# 	my $b = $self->linenumber('insert');
# 	my $end = $_[1];
# 	$end = $begin unless defined $end;
# 	my $e = $self->linenumber($end);
# 	$self->SUPER::delete(@_);
# 	$self->Callback('-modifycall', $b, $e);
# }

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
		["command"=>'Comment', -command => [$self => 'Comment']],
		["command"=>'Uncomment', -command => [$self => 'UnComment']],
		"-",
		["command"=>'Indent', -command => [$self => 'selectionIndent']],
		["command"=>'Unindent', -command => [$self => 'selectionUnIndent']],
	];
}

# sub EmptyDocument {
# 	my $self = shift;
# 	my @r = $self->SUPER::EmptyDocument(@_);
# 	$self->Callback('-modifycall', '0.0', 'end');
# 	return @r
# }
# 
# sub insert {
# 	my $self = shift;
# 	my $pos = shift;
# 	$pos = $self->index($pos);
# 	my $begin = $self->linenumber("$pos - 1 chars");
# 	$self->SUPER::insert($pos, @_);
# 	$self->Callback('-modifycall', $begin, $self->linenumber("insert lineend"));
# }
# 
# sub Insert {
# 	my $self = shift;
# 	$self->SUPER::Insert(@_);
# 	$self->see('insert');
# }

sub InsertKeypress {
	my ($self,$char) = @_;
	if (($char ne '') and (ord($char) >= 32)) {
		my $index = $self->index('insert');
		my $line = $self->linenumber($index);
		if ($char =~ /^\S$/ and !$self->OverstrikeMode and !$self->tagRanges('sel')) {
			$self->SUPER::insert($index,$char);
			$self->Callback('-modifycall', $line, $line);
			return;
		}
# 		$self->addGlobStart;
		$self->SUPER::InsertKeypress($char);
# 		$self->addGlobEnd;
	}
}

sub insertTab {
	my $self = shift;
	my @ranges = $self->tagRanges('sel');
	if (@ranges eq 2) {
		$self->selectionIndent;
	} else {
		$self->SUPER::insertTab;
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
	my $start = $self->index($ranges[0]);
	my $end = $self->index($ranges[1]);
	my $len = length($char);
	while ($self->compare($start, "<", $end)) {
		if ($mode) {
			if ($self->get("$start linestart", "$start linestart + $len chars") eq $char) {
				$self->delete("$start linestart", "$start linestart + $len chars");
			}
		} else {
			$self->insert("$start linestart", $char)
		}
		$start = $self->index("$start + 1 lines");
	}
	$self->tagAdd('sel', @ranges);
}

sub selectAll {
	my $self = shift;
	$self->tagAdd('sel','1.0','end - 1c');
}

sub selectionExists {
	my $self = shift;
	my @ranges = $self->tagRanges('sel');
	return @ranges eq 2
}

sub selectionIndent {
	my $self = shift;
	$self->selectionModify($self->cget('-indentchar'), 0);
}

sub selectionUnIndent {
	my $self = shift;
	$self->selectionModify($self->cget('-indentchar'), 1);
}

sub UnComment {
	my $self = shift;
	my $start = $self->cget('-commentstart');
	my $end = $self->cget('-commentend');
	my $lstart = length($start);
	my $lend = length($end) if defined $end;
	if ($self->selectionExists) {
		my ($rb, $re) = $self->tagRanges('sel');
		$rb = $self->index("$rb linestart");
		$re = $self->index("$re lineend");
		my $text = $self->get($rb, $re);
		if ((defined $end) and ($text =~ /^$start/) and ($text =~ /$end$/)){
			$self->delete($rb, "$rb + $lstart chars");
			$self->delete("$re - $lend chars", $re);
		} else {
			$self->selectionModify($start, 1)		
		}
	} else {
		my $rb = $self->index('insert linestart');
		my $re =  $self->index('insert lineend');
		my $text = $self->get($rb, $re);
		if ((defined $end) and ($text =~ /^$start/) and ($text =~ /$end$/)){
			$self->delete('insert linestart', "insert linestart + $lstart chars");
			$self->delete( "insert lineend - $lend chars", 'insert lineend');
		} elsif ($text =~ /^$start/) {
			$self->delete('insert linestart', "insert linestart + $lstart chars");
		}
	}
}

sub UnIndent {
	my $self = shift;
	my @ranges = $self->tagRanges('sel');
	if (@ranges eq 2) {
		$self->selectionUnIndent;
	} else {
		my $index = $self->index('insert');
		my $start = $self->index('insert linestart');
		my $indentchar = $self->cget('-indentchar');
		my $len = length($indentchar);
		my $string = $self->get($start, $index);
		if ($string =~ /^$indentchar+/) {
			$self->delete($start, "$start + $len" . "c");
		}
	}
}

sub updateCall {
	my $self = shift;
	$self->Callback('-updatecall');
}

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
