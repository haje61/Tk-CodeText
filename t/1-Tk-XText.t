
use strict;
use warnings;
use Test::More tests => 44;
use Test::Tk;
use Tk;

BEGIN { use_ok('Tk::XText') };

my $original = "one\ntwo\n";
my $indentedline = "\tone\ntwo\n";
my $indentedsel = "\tone\n\ttwo\n";

my $commentline1 = "#one\ntwo\n";
my $commentsel1 = "#one\n#two\n";

my $commentline2 = "<<-one->>\ntwo\n";
my $commentsel2 = "<<-one\ntwo\n->>";

createapp;

my $text;
if (defined $app) {
	$text = $app->XText(
	)->pack(
		-expand => 1,
		-fill => 'both',
	) if defined $app;

	my $pos = '';
	my $lines = '';
	my $size = '';
	my $ovr = '';
	my $mod = '';

	my $call;
	$call = sub {
		$pos = $text->index('insert');
		$lines = $text->linenumber('end - 1c');
		$size = length($text->get('1.0', 'end - 1c'));
		if ($text->OverstrikeMode) {
			$ovr = 'OVERWRITE',
		} else {
			$ovr = 'INSERT',
		}
		if ($text->editModified) {
			$mod = 'MODIFIED'
		} else {
			$mod = 'SAVED'
		}
		$app->after(200, $call);
	};
	
	my $sb = $app->Frame->pack(-fill => 'x');

	$sb->Label(
		-text => " Pos:"
	)->pack(-side => 'left', -pady => 2);
	$sb->Label(
		-textvariable => \$pos, 
		-width => 8, 
		-relief => 'groove'
	)->pack(-side => 'left', -pady => 2);

	$sb->Label(
		-text => " Lines:"
	)->pack(-side => 'left', -pady => 2);
	$sb->Label(
		-textvariable => \$lines, 
		-width => 5, 
		-relief => 'groove'
	)->pack(-side => 'left', -pady => 2);

	$sb->Label(
		-text => " Size:"
	)->pack(-side => 'left', -pady => 2);
	$sb->Label(
		-textvariable => \$size, 
		-width => 8, -relief => 'groove')->pack(-side => 'left', -pady => 2);
	$sb->Label(
		-textvariable => \$ovr,
		-width => 11, 
		-relief => 'groove'
	)->pack(-side => 'left', -pady => 2);
	$sb->Label(
		-textvariable => \$mod, 
		-width => 9, 
		-relief => 'groove'
	)->pack(-side => 'left', -pady => 2);
	$sb->Button(
		-text=> 'Reset', 
		-command => ['EmptyDocument', $text], 
	)->pack(-side => 'left', -pady => 2);
	&$call;
}

@tests = (
	[ sub { return defined $text }, 1, 'XText widget created' ],


	#testing inserting and undo redo
	[ sub {
		$text->insert('end -1c', $original);
		return $text->get('1.0', 'end - 1c'); 
	}, $original, 'Inserted text' ],

	[ sub {
		$text->undo;
		my $t = $text->get('1.0', 'end - 1c');
		print "result '$t'\n";
		return $text->get('1.0', 'end - 1c'); 
	}, '', 'Undo Inserted text' ],

	[ sub {
		$text->redo;
		return $text->get('1.0', 'end - 1c'); 
	}, $original, 'Redo Inserted text' ],


	#testing indent line and undo redo
	[ sub {
		$text->markSet('insert', '1.0 lineend');
		$text->indent;
		return $text->get('1.0', 'end - 1c'); 
	}, $indentedline, 'Indented line' ],

	[ sub {
		$text->undo;
		return $text->get('1.0', 'end - 1c'); 
	}, $original, 'Undo Iindented line' ],

	[ sub {
		$text->redo;
		return $text->get('1.0', 'end - 1c'); 
	}, $indentedline, 'Redo Idented line' ],


	#testing unindent line and undo redo
	[ sub {
		$text->unindent;
		return $text->get('1.0', 'end - 1c'); 
	}, $original, 'Unindented line' ],

	[ sub {
		$text->undo;
		return $text->get('1.0', 'end - 1c'); 
	}, $indentedline, 'Undo Unindented line' ],

	[ sub {
		$text->redo;
		return $text->get('1.0', 'end - 1c'); 
	}, $original, 'Redo Unidented line' ],

	#testing indent selection and undo redo
	[ sub {
		$text->selectAll;
		$text->indent;
		return $text->get('1.0', 'end - 1c'); 
	}, $indentedsel, 'Indented selection' ],

	[ sub {
		$text->undo;
		return $text->get('1.0', 'end - 1c'); 
	}, $original, 'Undo Indented selection' ],

	[ sub {
		$text->redo;
		return $text->get('1.0', 'end - 1c'); 
	}, $indentedsel, 'Redo Idented selection' ],

	#testing unindent selection and undo redo
	[ sub {
		$text->selectAll;
		$text->unindent;
		return $text->get('1.0', 'end - 1c'); 
	}, $original, 'Unindented selection' ],

	[ sub {
		$text->undo;
		return $text->get('1.0', 'end - 1c'); 
	}, $indentedsel, 'Undo Unindented selection' ],

	[ sub {
		$text->redo;
		return $text->get('1.0', 'end - 1c'); 
	}, $original, 'Redo Unidented selection' ],

	#testing comment line 1 and undo redo
	[ sub {
		$text->unselectAll;
		$text->SetCursor('0.0 lineend');
		$text->comment;
		return $text->get('1.0', 'end - 1c'); 
	}, $commentline1, 'Comment line 1' ],

	[ sub {
		$text->undo;
		return $text->get('1.0', 'end - 1c'); 
	}, $original, 'Undo Comment line 1' ],

	[ sub {
		$text->redo;
		return $text->get('1.0', 'end - 1c'); 
	}, $commentline1, 'Redo Comment line 1' ],

	#testing uncomment line 1 and undo redo
	[ sub {
		$text->unselectAll;
		$text->SetCursor('0.0 lineend');
		$text->uncomment;
		return $text->get('1.0', 'end - 1c'); 
	}, $original, 'UnComment line 1' ],

	[ sub {
		$text->undo;
		return $text->get('1.0', 'end - 1c'); 
	}, $commentline1, 'Undo UnComment line 1' ],

	[ sub {
		$text->redo;
		return $text->get('1.0', 'end - 1c'); 
	}, $original, 'Redo UnComment line 1' ],

	#testing comment selection 1 and undo redo
	[ sub {
		$text->selectAll;
		$text->comment;
		return $text->get('1.0', 'end - 1c'); 
	}, $commentsel1, 'Comment selection 1' ],

	[ sub {
		$text->undo;
		return $text->get('1.0', 'end - 1c'); 
	}, $original, 'Undo Comment selection 1' ],

	[ sub {
		$text->redo;
		return $text->get('1.0', 'end - 1c'); 
	}, $commentsel1, 'Redo Comment selection 1' ],

	#testing uncomment selection 1 and undo redo
	[ sub {
		$text->selectAll;
		$text->uncomment;
		return $text->get('1.0', 'end - 1c'); 
	}, $original, 'UnComment selection 1' ],

	[ sub {
		$text->undo;
		return $text->get('1.0', 'end - 1c'); 
	}, $commentsel1, 'Undo UnComment selection 1' ],

	[ sub {
		$text->redo;
		return $text->get('1.0', 'end - 1c'); 
	}, $original, 'Redo UnComment selection 1' ],

	#testing comment line 2 and undo redo
	[ sub {
		$text->configure(-commentstart => '<<-');
		$text->configure(-commentend => '->>');
		$text->unselectAll;
		$text->SetCursor('0.0 lineend');
		$text->comment;
		return $text->get('1.0', 'end - 1c'); 
	}, $commentline2, 'Comment line 2' ],

	[ sub {
		$text->undo;
		return $text->get('1.0', 'end - 1c'); 
	}, $original, 'Undo Comment line 2' ],

	[ sub {
		$text->redo;
		return $text->get('1.0', 'end - 1c'); 
	}, $commentline2, 'Redo Comment line 2' ],

	#testing uncomment line 2 and undo redo
	[ sub {
		$text->unselectAll;
		$text->SetCursor('0.0 lineend');
		$text->uncomment;
		return $text->get('1.0', 'end - 1c'); 
	}, $original, 'UnComment line 2' ],

	[ sub {
		$text->undo;
		return $text->get('1.0', 'end - 1c'); 
	}, $commentline2, 'Undo UnComment line 2' ],

	[ sub {
		$text->redo;
		return $text->get('1.0', 'end - 1c'); 
	}, $original, 'Redo UnComment line 2' ],

	#testing comment selection 2 and undo redo
	[ sub {
		$text->selectAll;
		$text->comment;
		return $text->get('1.0', 'end - 1c'); 
	}, $commentsel2, 'Comment selection 2' ],

	[ sub {
		$text->undo;
		return $text->get('1.0', 'end - 1c'); 
	}, $original, 'Undo Comment selection 2' ],

	[ sub {
		$text->redo;
		return $text->get('1.0', 'end - 1c'); 
	}, $commentsel2, 'Redo Comment selection 2' ],

	#testing comment selection 2 and undo redo
	[ sub {
		$text->selectAll;
		$text->uncomment;
		return $text->get('1.0', 'end - 1c'); 
	}, $original, 'UnComment selection 2' ],

	[ sub {
		$text->undo;
		return $text->get('1.0', 'end - 1c'); 
	}, $commentsel2, 'Undo UnComment selection 2' ],

	[ sub {
		$text->redo;
		return $text->get('1.0', 'end - 1c'); 
	}, $original, 'Redo UnComment selection 2' ],

	#emptying document
	[ sub {
		$text->EmptyDocument;
		return $text->get('1.0', 'end - 1c'); 
	}, '', 'Reset widget' ],
);

starttesting;
