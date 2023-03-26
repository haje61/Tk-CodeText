package Tk::CodeText::Theme;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.40';

my %Attributes = (
	Alert => 1,
	Annotation => 1,
	Attribute => 1,
	BaseN => 1,
	BuiltIn => 1,
	Char => 1,
	Comment => 1,
	CommentVar => 1,
	Constant => 1,
	ControlFlow => 1,
	DataType => 1,
	DecVal => 1,
	Documentation => 1,
	Error => 1,
	Extension => 1,
	Float => 1,
	Function => 1,
	Import => 1,
	Information => 1,
	Keyword => 1,
	Normal => 1,
	Operator => 1,
	Others => 1,
	Preprocessor => 1,
	RegionMarker => 1,
	SpecialChar => 1,
	SpecialString => 1,
	String => 1,
	Variable => 1,
	VerbatimString => 1, 
	Warning => 1,
);

my $IdString = "Tk::CodeText theme file";

my %Options = (
	-background => 1,
	-foreground => 1,
	-slant => 1,
	-weight => 1,
);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {
		POOL => {}
	};
	bless ($self, $class);
	$self->clear;
	return $self;
}

sub clear {
	my $self = shift;
	my $pool = $self->Pool;
	for (keys %$pool) { delete $pool->{$_} };
	for ($self->tagList) {
		my $tag = $_;
		my %options = ();
		for ($self->optionList) {
			$options{$_} = ''
		}
		$pool->{$tag} = \%options
	}
}

sub getItem {
	my ($self, $tag, $option) = @_;
	my $pool = $self->Pool;
	if ($self->validTag($tag)) {
		if ($self->validOption($option)) {
			return $self->Pool->{$tag}->{$option}
		} else {
			warn "invalid option '$option' in getItem"
		}
	} else {
		warn "invalid tag name '$tag' in getItem"
	}
}

sub get {
	my $self = shift;
	my $pool = $self->Pool;
	my @result = ();
	for ($self->tagList) {
		my $tag = $_;
		push @result, $tag;
		my @options = ();
		for ($self->optionList) {
			my $val = $pool->{$tag}->{$_};
			push @options, $_, $val unless $val eq '';
		}
		push @result => \@options
	}
	return @result
}

sub load {
	my ($self, $file) = @_;
	if (open(OFILE, "<", $file)) {
		my $id = <OFILE>;
		chomp $id;
		unless ($id eq $IdString) {
			warn "$file is not a $IdString";
			close OFILE;
			return
		}
		my @values = ();
		my $section;
		my @inf = ();
		while (<OFILE>) {
			my $line = $_;
			chomp $line;
			if ($line =~ /^\[([^\]]+)\]/) { #new section
				push @values, $section, [ @inf ] if defined $section;
				$section = $1;
				@inf = ();
			} elsif ($line =~ s/^([^=]+)=//) {#new key
				push @inf, $1, $line;
			}
		}
		push @values, $section, [ @inf ] if defined $section;
		close OFILE;
		$self->put(@values);
	} else {
		warn "Cannot open '$file'"
	}
}

sub optionList {
	return sort keys %Options;
}

sub Pool {
	return $_[0]->{POOL};
}

sub put {
	my $self = shift;
	$self->clear;
	my $pool = $self->Pool;
	while (@_) {
		my $tag = shift;
		my $opt = shift;
		next unless $self->validTag($tag);
		my @options = @$opt;
		while (@options) {
			my $key = shift @options;
			my $value = shift @options;
			$pool->{$tag}->{$key} = $value if $self->validOption($key);
		}
	}
}

sub save {
	my ($self, $file) = @_;
	if (open(OFILE, ">", $file)) {
		print OFILE "$IdString\n";
		my @values = $self->get;
		while (@values) {
			my $tag = shift @values;
			print OFILE "[$tag]\n";
			my $options = shift @values;
			while (@$options) {
				my $key = shift @$options;
				my $value = shift @$options;
				print OFILE "$key=$value\n";
			}
		}
		close OFILE
	} else {
		warn "Cannot open '$file'"
	}
}

sub setItem {
	my ($self, $tag, $option, $value) = @_;
	my $pool = $self->Pool;
	if ($self->validTag($tag)) {
		if ($self->validOption($option)) {
			$self->Pool->{$tag}->{$option} = $value if defined $value
		} else {
			warn "invalid option '$option' in setItem"
		}
	} else {
		warn "invalid tag name '$tag' in setItem"
	}
}

sub tagList {
	return sort keys %Attributes;
}

sub validOption {
	my ($self, $option) = @_;
	return exists $Options{$option};
}

sub validTag {
	my ($self, $tag) = @_;
	return exists $Attributes{$tag};
}
