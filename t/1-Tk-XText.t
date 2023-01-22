
use strict;
use warnings;
use Test::More tests => 15;
use Test::Tk;
use Tk;

BEGIN { use_ok('Tk::XText') };

createapp;

my $text = $app->XText(
)->pack(
	-expand => 1,
	-fill => 'both',
) if defined $app;

my $original = "one\ntwo\n";
my $indented = "\tone\n\ttwo\n";

my $commentline1 = "#one\ntwo\n";
my $commentsel1 = "#one\n#two\n";

my $commentline2 = "<<-one->>\ntwo\n";
my $commentsel2 = "<<-one\ntwo\n->>";

@tests = (
	[ sub { return defined $text }, 1, 'XText widget created' ],

	[ sub {
		$text->insert('end', $original);
		return $text->get('0.0', 'end - 1c'); 
	}, $original, 'Inserted text' ],

	[ sub {
		$text->selectAll;
		$text->selectionIndent;
		return $text->get('0.0', 'end - 1c'); 
	}, $indented, 'Indented text' ],
	[ sub {
		$text->selectAll;
		$text->selectionUnIndent;
		return $text->get('0.0', 'end - 1c'); 
	}, $original, 'Unindented text' ],
	[ sub {
		$text->unselectAll;
		$text->SetCursor('0.0 lineend');
		$text->Comment;
		return $text->get('0.0', 'end - 1c'); 
	}, $commentline1, 'Comment line 1' ],
	[ sub {
		$text->unselectAll;
		$text->SetCursor('0.0 lineend');
		$text->UnComment;
		return $text->get('0.0', 'end - 1c'); 
	}, $original, 'UnComment line 1' ],
	[ sub {
		$text->selectAll;
		$text->Comment;
		return $text->get('0.0', 'end - 1c'); 
	}, $commentsel1, 'Comment selection 1' ],
	[ sub {
		$text->selectAll;
		$text->UnComment;
		return $text->get('0.0', 'end - 1c'); 
	}, $original, 'UnComment selection 1' ],
	[ sub {
		$text->configure(-commentstart => '<<-');
		$text->configure(-commentend => '->>');
		$text->unselectAll;
		$text->SetCursor('0.0 lineend');
		$text->Comment;
		return $text->get('0.0', 'end - 1c'); 
	}, $commentline2, 'Comment line 2' ],
	[ sub {
		$text->unselectAll;
		$text->SetCursor('0.0 lineend');
		$text->UnComment;
		return $text->get('0.0', 'end - 1c'); 
	}, $original, 'UnComment line 2' ],
	[ sub {
		$text->selectAll;
		$text->Comment;
		return $text->get('0.0', 'end - 1c'); 
	}, $commentsel2, 'Comment selection 2' ],
	[ sub {
		$text->selectAll;
		$text->UnComment;
		return $text->get('0.0', 'end - 1c'); 
	}, $original, 'UnComment selection 2' ],
);

starttesting;
