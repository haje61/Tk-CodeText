use strict;
use warnings;
use Test::More tests => 5;
use Test::Tk;
use Tk;
require Tk::XText;

BEGIN { use_ok('Tk::CodeText::StatusBar') };

createapp;

my $text;
my $bar;
if (defined $app) {
	$text = $app->XText(
	)->pack(
		-expand => 1,
		-fill => 'both',
	);
	$bar = $app->StatusBar(
		-widget => $text,
	)->pack(
		-fill => 'x',
	);
}

push @tests, (
	[ sub { return defined $text }, 1, 'XText widget created' ],
	[ sub { return defined $bar }, 1, 'StatusBar widget created' ],
);

starttesting;
