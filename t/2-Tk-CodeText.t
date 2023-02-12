use strict;
use warnings;
use Test::More tests => 11;
use Test::Tk;
use Tk;

BEGIN { use_ok('Tk::CodeText') };

createapp;

my $text = $app->CodeText(
	-font => 'Hack 12',
	-syntax => 'XML',
)->pack(
	-expand => 1,
	-fill => 'both',
) if defined $app;

#testing accessors
my @accessors = qw(Colored ColorInf highlightinterval LoopActive NoHighlighting);
for (@accessors) {
	my $method = $_;
	push @tests, [sub {
		my $default = $text->$method;
		$text->$method('blieb');
		my $res1 = $text->$method;
		$text->$method('quep');
		my $res2 = $text->$method;
		$text->$method($default);
		return (($res1 eq 'blieb') and ($res2 eq 'quep'));
	}, 1, "Accessor $method"];
}

push @tests, (
	[ sub { return defined $text }, 1, 'CodeText widget created' ],
	[ sub { return $text->syntax }, 'XML', 'Syntax set to XML' ],
	[ sub { 
		$text->configure(-syntax => 'Perl');
		return $text->syntax 
	}, 'Perl', 'Syntax set to Perl' ],
);


starttesting;
