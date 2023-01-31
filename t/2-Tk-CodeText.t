use strict;
use warnings;
use Test::More tests => 4;
use Test::Tk;
use Tk;

BEGIN { use_ok('Tk::CodeText') };

createapp;

my $text = $app->CodeText->pack(
		-expand => 1,
		-fill => 'both',
	) if defined $app;

@tests = (
	[ sub { return defined $text }, 1, 'CodeText widget created' ],
);


starttesting;
