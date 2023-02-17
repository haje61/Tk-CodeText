use strict;
use warnings;
use Test::More tests => 13;
use Test::Tk;
use Tk;

BEGIN { use_ok('Tk::CodeText') };

createapp;

my $text = $app->CodeText(
	-tabs => '7m',
	-font => 'Hack 12',
	-syntax => 'XML',
)->pack(
	-expand => 1,
	-fill => 'both',
) if defined $app;

$text->Subwidget('Statusbar')->Button(
	-text=> 'Reset',
	-relief => 'flat',
	-command => ['clear', $text], 
)->pack(-side => 'left');

$text->Subwidget('Statusbar')->Button(
	-text=> 'Load Ref file',
	-relief => 'flat',
	-command => ['load', $text, 'lib/Tk/CodeTextOld.pm'], 
)->pack(-side => 'left');

$app->configure(-menu => $app->Menu(
	-menuitems => [
		[ cascade => '~File',
			-menuitems => [
				[ command => '~Load', -command => sub {
					my $file = $app->getOpenFile;
					$text->load($file) if defined $file;
				}],
				[ command => '~Save', -command => sub {
					my $file = $app->getSaveFile;
					$text->save($file) if defined $file;
				}],
			]
		],
		[ cascade => '~Edit',
			-menuitems => $text->EditMenuItems,
		],
		[ cascade => '~View',
			-menuitems => $text->ViewMenuItems,
		],
	],
));

#testing accessors
my @accessors = qw(Colored ColorInf FoldButtons FoldInf highlightinterval LoopActive NoHighlighting);
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
