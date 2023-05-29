package MyKamelon;
use strict;
use warnings;

use base qw(Syntax::Kamelon);

sub new {
	my $class = shift;
	my $widget = shift;
	my $self = $class->SUPER::new(@_);
	$self->{WIDGET} = $widget;
	return $self
}

sub ParseResultEndRegion {
	my $self = shift;
	my $region = pop @_;
	my $formatter = $self->Formatter;
	my $widget = $self->Widget;
	my $top = $formatter->FoldStackTop;
	if (defined $top) {
		my $begin = $formatter->FoldStackTop->{start};
		$formatter->FoldEnd($region);
		$widget->foldsCheck if (($begin >= $widget->visualBegin) and ($begin <= $widget->visualEnd));
	}
	my $parser = pop @_;
	return &$parser($self, @_);
}

sub Widget { return $_[0]->{WIDGET} }

###########################################################################

package Tk::CodeText;


=head1 NAME

Tk:CodeText - Programmer's Swiss army knife Text widget

=cut


use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.40';

use base qw(Tk::Derived Tk::Frame);

use Syntax::Kamelon;
use Tk;

require Tk::CodeText::StatusBar;
require Tk::CodeText::TagsEditor;
require Tk::CodeText::Theme;
require Tk::DialogBox;
require Tk::Font;
require Tk::XText;


Construct Tk::Widget 'CodeText';

my @defaultattributes = (
	'Alert' => [-background => '#DB7C47', -foreground => '#FFFFFF'],
	'Annotation' => [-foreground => '#5A5A5A'],
	'Attribute' => [-foreground => '#00B900', -weight => 'bold'],
	'BaseN' => [-foreground => '#0000A9'],
	'BuiltIn' => [-foreground => '#B500E6'],
	'Char' => [-foreground => '#FF00FF'],
	'Comment' => [foreground => '#5A5A5A', -slant => 'italic'],
	'CommentVar' => [-foreground => '#5A5A5A', -slant => 'italic', -weight => 'bold'],
	'Constant' => [-foreground => '#0000FF', -weight => 'bold'],
	'ControlFlow' => [-foreground => '#0062AD'],
	'DataType' => [-foreground => '#0080A8', -weight => 'bold'],
	'DecVal' => [-foreground => '#9C4E2B'],
	'Documentation' => [-foreground => '#7F5A41', -slant => 'italic'],
	'Error' => [-background => '#FF0000', -foreground => '#FFFF00'],
	'Extension' => [-foreground => '#9A53D1'],
	'Float' => [-foreground => '#9C4E2B', -weight => 'bold'],
	'Function' => [-foreground => '#008A00'],
	'Import' => [-foreground => '#950000', -slate => 'italic'],
	'Information' => [foreground => '#5A5A5A', -weight => 'bold'],
	'Keyword' => [-weight => 'bold'],
	'Normal' => [],
	'Operator' => [-foreground => '#85530E'],
	'Others' => [-foreground => '#FF6200'],
	'Preprocessor' => [-slant => 'italic'],
	'RegionMarker' => [-background => '#00CFFF'],
	'SpecialChar' => [-foreground => '#9A53D1'],
	'SpecialString' => [-foreground => '#FF4449'],
	'String' => [-foreground => '#FF0000'],
	'Variable' => [-foreground => '#0000FF', -weight => 'bold'],
	'VerbatimString' => [-foreground => '#FF4449', -weight => 'bold'],
	'Warning' => [-background => '#FFFF00', -foreground => '#FF0000'],
);

my $minusimg = '#define indicatorclose_width 11
#define indicatorclose_height 11
static unsigned char indicatorclose_bits[] = {
   0xff, 0x07, 0x01, 0x04, 0x01, 0x04, 0x01, 0x04, 0x01, 0x04, 0xfd, 0x05,
   0x01, 0x04, 0x01, 0x04, 0x01, 0x04, 0x01, 0x04, 0xff, 0x07 };
';

my $plusimg = '#define indicatoropen_width 11
#define indicatoropen_height 11
static unsigned char indicatoropen_bits[] = {
   0xff, 0x07, 0x01, 0x04, 0x21, 0x04, 0x21, 0x04, 0x21, 0x04, 0xfd, 0x05,
   0x21, 0x04, 0x21, 0x04, 0x21, 0x04, 0x01, 0x04, 0xff, 0x07 };
';


=head1 SYNOPSIS

 require Tk::CodeText;
 my $text= $window->CodeText(@options)->pack;

=head1 DESCRIPTION

B<Tk::CodeText> aims to be a Scintilla like text widget for Perl/Tk.

It uses L<Syntax::Kamelon> for syntax highlighting, code folding
and syntax sensitive commenting and unmommenting, both single line
and multiple line.

It displays line numbers and code folding markers. Also a status bar
with content info and tools for setting tab size, indent style andsyntax.

It provides an advanced, word based, undo/redo stack that keeps track
of the last saving point and selections.

Furthermore we have an autoindent feature as well as matching of
{}, () and [] pairs.

=head1 OPTIONS

=over 4

=item Switch: B<-autoindent>

By default 0. If set the text will be indented to the 
level and style of the previous line.

=item Name: B<configDir>

=item Class: B<ConfigDir>

=item Switch: B<-configdir>

An empty string by default. If set to an
existing folder that folder will be used
for saving and loading theme files.

=item Switch: B<-disablemenu>

By default 0. If set the right-click context menu is disabled.

=item Name: B<highlightInterval>

=item Class: B<HighlightInterval>

=item Switch: B<-highlightinterval>

By default 1 milisecond. Highlighting is done on a
line by line basis. This is the time between lines.

=item Name: B<indentStyle>

=item Class: B<IndentStyle>

=item Switch: B<-indentstyle>

Default value 'tab'. You can also set it to a number.
In that case an indent will be the number of spaces.

=item Switch: B<-match>

Default value '[]{}()'. Specifies which items to match
against nested occurrences.

=item Switch: B<-matchoptions>

Default: [-background => 'red', -foreground => 'yellow'].
Specifies the options for the match tag.

=item Switch: B<-minusimg>

Image used for the collapse state of a folding point.
By default it is a bitmap defined in this module.

=item Switch: B<-plusimg>

Image used for the expand state of a folding point.
By default it is a bitmap defined in this module.

=item Switch: B<-scrollbars>

Default value 'osoe'. Specifies if and how scrollbars
are to be used. If you set it to an ampty string no
scrollbars will be created. See also L<Tk::Scrolled>.

Only available at create time.

=item Name: B<showFolds>

=item Class: B<ShowFolds>

=item Switch: B<-showfolds>

Default value 1. If cleared the folding markers
will be hidden.

=item Name: B<showNumbers>

=item Class: B<ShowNumbers>

=item Switch: B<-shownumbers>

Default value 1. If cleared the line numbers
will be hidden.

=item Name: B<showStatus>

=item Class: B<ShowStatus>

=item Switch: B<-showstatus>

Default value 1. If cleared the status bar
will be hidden.

=item Name: B<syntax>

=item Class: B<Syntax>

=item Switch: B<-syntax>

Default value 'None'. Sets and returns the currently
used syntax definition.

=item Switch: B<-themefile>

Default value undef. Sets and loads a theme file with tags information 
for highlighting. A call to cget returns the name of the loaded theme file.
See also L<Tk::CodeText::Theme>.

=item Name: B<updateLines>

=item Class: B<UpdateLines>

=item Switch: B<-updatelines>

Default value 100. If is used during save and load operation. 
It specifies after how many lines an update on the progress bar on
the status bar should occur.

=back

=cut

=head1 METHODS

=over 4

=cut

sub Populate {
	my ($self,$args) = @_;
	
	my $scrollbars = delete $args->{'-scrollbars'};
	$scrollbars = 'osoe' unless defined $scrollbars;
	my $theme = delete $args->{'-theme'};
	unless (defined $theme) {
		$theme = Tk::CodeText::Theme->new;
		$theme->put(@defaultattributes);
	}

	$self->SUPER::Populate($args);

	$self->{COLORINF} = [];
	$self->{COLORED} = 1;
	$self->{FOLDBUTTONS} = {};
	$self->{FOLDINF} = [];
	$self->{FOLDSVISIBLE} = 0;
	$self->{KAMELON} = MyKamelon->new($self,
		formatter => ['Base',
			foldingdepth => 'all',
		],
	);
	$self->{HIGHLIGHTINTERVAL} = 1;
	$self->{LOOPACTIVE} = 0;
	$self->{NOHIGHLIGHTING} = 1;
	$self->{NUMBERSVISIBLE} = 0;
	$self->{NUMBERINF} = [];
	$self->{POSTCONFIG} = 0;
	$self->{STATUSVISIBLE} = 0;
	$self->{SYNTAX} = 'None';
	$self->{THEME} = $theme;
	$self->{SAVEFIRSTVISIBLE} = 1;
	$self->{SAVELASTVISIBLE} = 1;
	
	#create editor frame
	my $ef = $self->Frame(
		-relief => 'sunken',
		-borderwidth => 2,
	)->pack(
		-expand => 1,
		-fill => 'both',
	);

	#create the frame for the line numbers
	my $numbers = $ef->Frame(
		-width => 40,
	);

	#create the frame for code folding
	my $folds = $ef->Frame(
		-width => 18,
	);

	#create the textwidget
	my @opt = (
		-width => 20,
		-height => 10,
		-findandreplacecall => sub { $self->FindAndOrReplace(@_) },
		-modifycall => ['modifiedCheck', $self],
		-relief => 'flat',
		-scrollbars => $scrollbars,
	);
	my $text;
	if ($scrollbars eq '') {
		$text = $ef->XText(@opt)
	} else {
		$text = $ef->Scrolled('XText', @opt)
	}
	$text->pack(-side => 'left', -expand =>1, -fill => 'both');
	
	#create the find and replace panel
	my @pack = (-side => 'left', -padx => 2, -pady => 2);
	my $sandr = $self->Frame;
	$self->Advertise(SandR => $sandr);

	#searchframe
	my $rframe; #the variable for the replaceframe must exist
	my $sframe = $sandr->Frame->pack(-fill => 'x');
	$sframe->Label(
		-anchor => 'e',
		-text => 'Find',
		-width => 7,
	)->pack(@pack);
	my $find = '';
	$sframe->Entry(
		-textvariable => \$find,
	)->pack(@pack, -expand => 1, -fill => 'x');
	$sframe->Button(
		-text => 'Next',
	)->pack(@pack); 
	$sframe->Button(
		-text => 'Previous',
	)->pack(@pack);
	my $case = 1;
	$sframe->Checkbutton(
		-text => 'Case',
		-variable => \$case,
	)->pack(@pack);
	my $reg = 0;
	$sframe->Checkbutton(
		-text => 'Reg',
		-variable => \$reg,
	)->pack(@pack);
	$sframe->Button(
		-command => ['FindClose', $self],
		-text => 'Close',
	)->pack(@pack);

	#replaceframe
	$rframe = $sandr->Frame;
	$rframe->Label(
		-anchor => 'e',
		-text => 'Replace',
		-width => 7,
	)->pack(@pack);
	$self->Advertise(Replace => $rframe);
	my $replace = '';
	$rframe->Entry(
		-textvariable => \$replace,
	)->pack(@pack, -expand => 1, -fill => 'x');
	$rframe->Button(
		-text => 'Replace',
	)->pack(@pack); 
	$rframe->Button(
		-text => 'Replace all',
	)->pack(@pack);

	#create the statusbar
	my $statusbar = $self->StatusBar(
		-widget => $self,
	);
	$self->after(10, ['StatusUpdate', $statusbar]);

	$self->Advertise(XText => $text);
	$self->Advertise(Numbers => $numbers);
	$self->Advertise(Folds => $folds);
	$self->Advertise(Statusbar => $statusbar);

	# hack for getting proper bitmap foreground
	my $l = $self->Label;
	my $fg = $l->cget('-foreground');
	$l->destroy;

	$self->ConfigSpecs(
		-configdir => [qw/PASSIVE configdir ConfigDir/, ''],
		-highlightinterval => [qw/METHOD highlightInterval HighlightInterval/, 1],
		-minusimg => ['PASSIVE', undef, undef, $self->Bitmap(
			-data => $minusimg,
			-foreground => $fg,
		)],
		-plusimg => ['PASSIVE', undef, undef, $self->Bitmap(
			-data => $plusimg,
			-foreground => $fg,
		)],
		-showfolds => [qw/METHOD showFolds ShowFolds/, 1],
		-shownumbers => [qw/METHOD showNumers ShowNumbers/, 1],
		-showstatus => [qw/METHOD showStatus ShowStatus/, 1],
		-syntax => [qw/METHOD syntax Syntax/, 'None'],
		-themefile => ['METHOD'],
		DEFAULT => [ $text ],
	);

	$self->Delegates(
		DEFAULT => $text,
	);

	$self->tagConfigure('Hidden', -elide => 1);

	my $yscroll = $text->Subwidget('yscrollbar');
	my $scrollcommand = $yscroll->cget( -command );
	$yscroll->configure(
		-command => sub {
			$scrollcommand->Call(@_);
			$self->contentCheckLight;
		}
	);

	#configure all the bindings for the text widget
	$text->bind('<KeyPress>', [$self, 'OnKeyPress', Ev('K') ]);
	#lazy events
	my @levents = qw(
		ButtonPress ButtonRelease-1 
		ButtonRelease-2 B2-Motion 
		B1-Motion MouseWheel
	);
	foreach my $levent (@levents) {
		my $bindsub = $text->bind("<$levent>");
		if ($bindsub) {
			$text->bind("<$levent>", sub {
				$bindsub->Call;
				$self->contentCheckLight;
			});
		} else {
			$text->bind( "<$levent>", sub { $self->contentCheckLight } );
		}
	}
	#forced events
	my @events = qw(Expose Visibility Configure Return);
	foreach my $event (@events) {
		my $bindsub = $text->bind("<$event>");
		if ($bindsub) {
			$text->bind("<$event>", sub {
				$bindsub->Call;
				$self->contentCheck;
			});
		} else {
			$text->bind( "<$event>", sub { $self->contentCheck } );
		}
	}
 	$self->after(1, sub {
		$self->{POSTCONFIG} = 1;
		$self->themeUpdate;
		$self->lnumberCheck;
 	});
}

=item B<canUndo>

Returns true if the undo stack has content.

=cut

=item B<canRedo>

Returns true if the redo stack has content.

=cut

=item B<clear>

Delets all text. Clears the undo and redo stack. Clears the modified flag.
Resets hightlighting to syntax 'None'

=cut

sub clear {
	my $self = shift;
	$self->Kamelon->Reset;
	$self->configure(-syntax => 'None');
	$self->Subwidget('XText')->clear;
}

sub Colored {
	my $self = shift;
	$self->{COLORED} = shift if @_;
	return $self->{COLORED}
}

sub ColorInf {
	my $self = shift;
	$self->{COLORINF} = shift if @_;
	return $self->{COLORINF}
}

=item B<comment>

Comments the current line or selection.

=cut

sub contentCheck {
	my $self = shift;
	$self->lnumberCheck;
	$self->foldsCheck;
}

sub contentCheckLight {
	my $self = shift;
	my $start = $self->SaveFirstVisible;
	my $end = $self->SaveLastVisible;
	$self->contentCheck if (($start ne $self->visualBegin) or ($end ne $self->visualEnd));
}

sub FindAndOrReplace {
	my ($self, $flag) = @_;
	my $geosave = $self->toplevel->geometry;
	my $sandr = $self->Subwidget('SandR');
	if ($flag) {
		$self->Subwidget('Replace')->packForget
	} else {
		$self->Subwidget('Replace')->pack(
			-fill => 'x',
		);
	}
	$sandr->pack(
		-fill => 'x',
		-before => $self->Subwidget('Statusbar'),
	);
	$self->toplevel->geometry($geosave);

}

sub FindClose {
	my $self = shift;
	$self->Subwidget('SandR')->packForget;
}

sub foldButton {
	my ($self, $line) = @_;
	my $folds = $self->Kamelon->Formatter->Folds;
	my $fbuttons = $self->FoldButtons;
	unless (exists $fbuttons->{$line}) {
		my $data = $folds->{$line};
		my @opt = ();
		my $state;
		if ($self->isHidden($line + 1)) {
			push @opt, -image => $self->cget('-plusimg');
			$state = 'collapsed';
		} else {
			push @opt, -image => $self->cget('-minusimg');
			$state = 'expanded';
		}
		my $b = $self->Subwidget('Folds')->Button(@opt,
			-command => ['foldFlip', $self, $line],
			-relief => 'flat',
		);
		$fbuttons->{$line} = {
			button => $b,
			data => $data,
			state => $state,
		};
	}
	return $fbuttons->{$line};
}

sub FoldButtons {
	my $self = shift;
	$self->{FOLDBUTTONS} = shift if @_;
	return $self->{FOLDBUTTONS}
}

sub foldCollapse {
	my ($self, $line) = @_;
	my $data = $self->FoldButtons->{$line};
	$data->{'state'} = 'collapsed';
	$data->{'button'}->configure(-image => $self->cget('-plusimg'));
	my $end = $data->{'data'}->{'end'};
	$line ++;
	while ($line < $end) {
		$self->hideLine($line);
		$line ++;
	}
	$self->lnumberCheck;
	$self->foldsCheck;
}

=item B>foldCollapseAll>

Collapses all folding points.

=cut

sub foldCollapseAll {
	my $self = shift;
	my $folds = $self->Kamelon->Formatter->Folds;
	for (sort keys %$folds) {
		$self->foldButton($_); #just make sure a fold button exists
		$self->foldCollapse($_);
	}
}

sub foldExpand {
	my ($self, $line) = @_;
	my $data = $self->FoldButtons->{$line};
	$data->{'state'} = 'expanded';
	$data->{'button'}->configure(-image => $self->cget('-minusimg'));
	$self->lnumberCheck;
	my $end = $data->{'data'}->{'end'};
	$line ++;
	while ($line < $end) {
		$self->showLine($line);
		my $nested = $self->FoldButtons->{$line};
		if (defined $nested) {
			$self->foldExpand($line) unless ($nested->{'state'} eq 'collapsed');
			$line = $nested->{'data'}->{'end'};
			$self->showLine($line);
		} else {
			$line ++
		}
	}
	$self->foldsCheck;
}

=item B>foldExpandAll>

Expands all folding points.

=cut

sub foldExpandAll {
	my $self = shift;
	my $folds = $self->Kamelon->Formatter->Folds;
	for (sort keys %$folds) {
		$self->foldButton($_); #just make sure a fold button exists
		$self->foldExpand($_);
	}
}

sub foldFlip {
	my ($self, $line) = @_;
	my $data = $self->FoldButtons->{$line};
	if ($data->{'state'} eq 'collapsed') {
		$self->foldExpand($line);
	} elsif ($data->{'state'} eq 'expanded') {
		$self->foldCollapse($line);
	}
}

sub FoldInf {
	my $self = shift;
	$self->{FOLDINF} = shift if @_;
	return $self->{FOLDINF}
}

sub foldsCheck {
	my $self = shift;

	return unless $self->cget('-showfolds');

	my $folds = $self->Kamelon->Formatter->Folds;
	my $inf = $self->FoldInf;
	my $fframe = $self->Subwidget('Folds');
	my $line = $self->visualBegin;
	my $last = $self->visualEnd;
	my $fbuttons = $self->FoldButtons;

	#clear out currently mapped fold keys
	$self->foldsClear;

	my $count = 0;
	while ($line <= $last) {
		while ($self->isHidden($line)) { $line ++ }
		if (exists $folds->{$line}) {
			#vertical alignment with the line
			my ( $x, $y, $wi, $he ) = $self->dlineinfo("$line.0");
			my $but = $self->foldButton($line)->{'button'};
			my $bh = $but->reqheight;
			my $delta = int(($he - $bh) / 2);
			$but->place(-x => 0, -y => $y + $delta);
			$inf->[$count] = $but;
		}
		$count ++;
		$line ++;
	}
	while (@$inf >= $count) {
		pop @$inf;
	}
}

sub foldsClear {
	my $self = shift;
	my $inf = $self->FoldInf;
	my $count = 0;
	for (@$inf) { 
		if (defined $_) {
			$_->placeForget;
			$inf->[$count] = undef;
		};
		$count ++;
	}
}

=item B<fontCompose>I<($font, %options)>

Returns a new font based on $font.
The keys -family -size -weight -slant are supported 

=cut

sub fontCompose {
	my ($self, $font, %options) = @_;
	my $family = $self->fontActual($font, '-family');
	my $size = $self->fontActual($font, '-size');
	my $weight = '';
	my $slant = '';
	$slant = $options{'-slant'} if exists $options{'-slant'};
	$weight = $options{'-weight'} if exists $options{'-weight'};
	$slant = 'roman' if $slant eq '';
	$weight = 'normal' if $weight eq '';
	return $self->Font(
		-family => $family,
		-size => $size,
		-slant => $slant,
		-weight => $weight,
	);
}

=item B<getFontInfo>

Returns info about the font used in the text widget.
The info is a hash with keys -family -size -weight -slant -underline -overstrike. 

=cut

=item B<goTo>I<($index)>

Sets the insert cursor to $index.

=cut

sub hideLine {
	my ($self, $line) = @_;
	$self->tagAdd('Hidden', "$line.0", "$line.0 lineend + 1c");
}

sub highlightCheck {
	my ($self, $pos) = @_;
	return if $self->NoHighlighting;
	my $line = $self->linenumber($pos);
	$self->highlightPurge($line);
}

sub highlightinterval {
	my $self = shift;
	$self->{HIGHLIGHTINTERVAL} = shift if @_;
	return $self->{HIGHLIGHTINTERVAL}
}

sub highlightLine {
	my ($self, $num) = @_;
	my $kam = $self->Kamelon;
	$kam->LineNumber($num);
	my $xt = $self->Subwidget('XText');
	my $begin = "$num.0"; my $end = $xt->index("$num.0 lineend + 1c");
#	#remove all existing tags in this line
# 	foreach my $tn ($self->tags) {
# 		$xt->tagRemove($tn, $begin, $end);
# 	}	
	my $cli = $self->ColorInf;
	my $k = $cli->[$num - 1];
	$kam->StateSet(@$k);
	my $txt = $xt->get($begin, $end); #get the text to be highlighted
	if ($txt ne '') { #if the line is not empty
		my $pos = 0;
		my $start = 0;
		my @h = $kam->ParseRaw($txt);
		while (@h ne 0) {
			$start = $pos;
			$pos += length(shift @h);
			my $tag = shift @h;
			$xt->tagAdd($tag, "$num.$start", "$num.$pos");
		};
		$xt->tagRaise('sel');
	};
	$cli->[$num] = [ $kam->StateGet ];
}

sub highlightLoop {
	my $self = shift;
	if ($self->NoHighlighting) {
		$self->LoopActive(0);
		return
	}
	my $colored = $self->Colored;
	my $xt = $self->Subwidget('XText');
	if ($colored <= $xt->linenumber('end - 1c')) {
		$self->LoopActive(1);
		$self->highlightLine($colored);
		$colored ++;
		$self->Colored($colored);
		$self->after($self->highlightinterval, ['highlightLoop', $self]);
	} else {
		$self->LoopActive(0);
	}
}

sub highlightPurge {
	my ($self, $line) = @_;
	$line = 1 unless defined $line;

	#purge highlightinfo
	$self->highlightRemove($line);
	$self->Colored($line);
	my $cli = $self->ColorInf;
	if (@$cli) { splice(@$cli, $line) };
		
	#purge folds
	$self->foldsClear;
	my $folds = $self->Kamelon->Formatter->Folds;
	for (keys %$folds) {
		delete $folds->{$_} if $_ >= $line
	}
	#clear out unused fold buttons
	my $btns = $self->FoldButtons;
	for (keys %$btns) {
		unless (exists $folds->{$_}) {
			my $b = delete $btns->{$_};
			$b->{'button'}->destroy;
		}
	}
	$self->highlightLoop unless $self->LoopActive;
}

sub highlightRemove {
	my ($self, $begin) = @_;
	$begin = 1 unless defined $begin;
	for ($self->tags) {
		$self->tagRemove($_, "$begin.0", 'end')
	}
}

=item B<indent>

Indents the current line or selection.

=item B<isHidden>I<($line)>

Returns true if $line is hidden by a colde fold.

=cut

sub isHidden {
	my ($self, $line) = @_;
	my @names = $self->tagNames("$line.0");
	my $hit = grep({ $_ eq 'Hidden'} @names);
	return $hit;
}

sub Kamelon {
	return $_[0]->{KAMELON}
}

=item B<linenumber>I<($index)>

Returns the line number of $index.

=cut

sub lnumberCheck {
	my $self = shift;

	my $line = $self->visualBegin;
	my $last = $self->visualEnd;
	$self->SaveFirstVisible($line);
	$self->SaveLastVisible($last);

	return unless $self->{POSTCONFIG};
	return unless $self->cget('-shownumbers');

	my $widget = $self->Subwidget('XText');
	my $count = 0;
	my $font = $widget->cget('-font');

	my $nimf = $self->{NUMBERINF};
	my $numframe = $self->Subwidget('Numbers');

	while ($line <= $last) {
		while ($self->isHidden($line)) { $line ++ }
		my ( $x, $y, $wi, $he ) = $self->dlineinfo("$line.0");

		#create a number label if it does not yet exist;
		unless (defined $nimf->[$count]) {
			my $l = $numframe->Label(
				-justify => 'right',
				-anchor => 'ne',
				-font => $font,
				-borderwidth => 0,
			);
			push @$nimf, $l;
		}

		#configure and position the number label
		my $lab = $nimf->[$count];
		$lab->configure(
			-text => $line,
			-width => length($last),
		);
		$lab->placeForget if $lab->ismapped;
		$lab->place(-x => 0, -y => $y);
		$line ++;
		$count ++;
	}

	my $numwidth = $nimf->[$count - 1]->reqwidth;
	$numframe->configure(-width => $numwidth);

	#remove redundant nummber labels
	while (defined $nimf->[$count]) {
		my $l = pop @$nimf;
		$l->placeForget;
		$l->destroy;
	}
}

=item B<load>I<($file)>

Clears the text widget and loads $file.
Returns 1 if successfull.

=cut

sub load{
	my ($self, $file) = @_;
	if ($self->Subwidget('XText')->load($file)) {
		my $syntax = $self->Kamelon->SuggestSyntax($file);
		$self->configure(-syntax => $syntax) if defined $syntax;
		return 1
	}
	return 0
}

sub LoopActive {
	my $self = shift;
	$self->{LOOPACTIVE} = shift if @_;
	return $self->{LOOPACTIVE}
}

sub modifiedCheck {
	my ($self, $index) = @_;
	$self->highlightCheck($index);
# 	$self->lnumberCheck;
}

sub NoHighlighting {
	my $self = shift;
	$self->{NOHIGHLIGHTING} = shift if @_;
	return $self->{NOHIGHLIGHTING}
}

sub OnKeyPress {
	my ($self, $key) = @_;
	if (length($key) > 1) {
		$self->contentCheckLight;
	} else {
		$self->contentCheck;
	}
}

=item B<redo>

Redoes the last undo.

=cut

=item B<save>I<($file)>

Saves the text into $file. Returns 1 if successfull.

=cut

sub SaveFirstVisible {
	my $self = shift;
	$self->{SAVEFIRSTVISIBLE} = shift if @_;
	return $self->{SAVEFIRSTVISIBLE}
}

sub SaveLastVisible {
	my $self = shift;
	$self->{SAVELASTVISIBLE} = shift if @_;
	return $self->{SAVELASTVISIBLE}
}

=item B<selectionExists>

Returns true if a selection exists

=cut

sub showfolds {
	my ($self, $flag) = @_;
	my $f = $self->Subwidget('Folds');
	if (defined $flag) {
		if ($flag) {
			my $before = $self->Subwidget('XText');
			$f->pack(
				-side => 'left',
				-before => $before,
				-fill => 'y',
			);
			$self->{FOLDSVISIBLE} = 1;
			$self->foldsCheck;
		} else {
			$self->{FOLDSVISIBLE} = 0;
			$f->packForget;
		}
	}
	return $self->{FOLDSVISIBLE}
}

sub showLine {
	my ($self, $line) = @_;
	$self->tagRemove('Hidden', "$line.0", "$line.0 lineend + 1c");
}

sub shownumbers {
	my ($self, $flag) = @_;
	my $f = $self->Subwidget('Numbers');
	if (defined $flag) {
		if ($flag) {
			my $before = $self->Subwidget('XText');
			$before = $self->Subwidget('Folds') if $self->{FOLDSVISIBLE};
			$f->pack(
				-side => 'left',
				-before => $before,
				-fill => 'y',
			);
			$self->{NUMBERSVISIBLE} = 1;
			$self->lnumberCheck;
		} else {
			$f->packForget;
			$self->{NUMBERSVISIBLE} = 0;
		}
	}
	return $self->{NUMBERSVISIBLE}
}

sub showstatus {
	my ($self, $flag) = @_;
	my $f = $self->Subwidget('Statusbar');
	if (defined $flag) {
		if ($flag) {
			$f->pack(
				-fill => 'x',
			);
			$self->{STATUSVISIBLE} = 1;
			$f->StatusUpdate;
		} else {
			$f->packForget;
			$self->{STATUSVISIBLE} = 0;
		}
	}
	return $self->{STATUSVISIBLE};
}


sub syntax {
	my ($self, $new) = @_;
	my $kam = $self->Kamelon;
	if (defined($new)) {
		$self->NoHighlighting(1);
		$self->highlightPurge;
		$self->Subwidget('XText')->configure(
			-mlcommentend => undef,
			-mlcommentstart => undef,
			-slcomment => undef,
		);
		unless ($new eq 'None') {
			$kam->Syntax($new);
			my $idx = $kam->GetIndexer;
			$self->Subwidget('XText')->configure(
				-mlcommentend => $idx->InfoMLCommentEnd($new),
				-mlcommentstart => $idx->InfoMLCommentStart($new),
				-slcomment => $idx->InfoSLComment($new),
			);
			$self->NoHighlighting(0);
			$self->Colored(0);
			$self->ColorInf([ [$kam->StateGet] ]);
			$self->highlightLoop unless $self->LoopActive;
		}
		$self->{SYNTAX} = $new;
	}
	return $self->{SYNTAX}
}

=item B<tags>

Returns the Kamelon list of AvailableAttributes.

=cut

sub tags {
	return $_[0]->Kamelon->AvailableAttributes
}

=item B<theme>

Returns a reference to the current theme object.
See also L<Tk::CodeText::Theme>

=cut

sub theme {
	return $_[0]->{THEME}
}

=item B<themeDialog>

Initiates a dialog for editing the colors and font information for highlighting.

=cut

sub themeDialog {
	my $self = shift;
	my $theme = $self->theme;
	my $dialog = $self->DialogBox(
		-title => 'Theme editor',
		-buttons => ['Ok', 'Cancel'],
		-default_button => 'Ok',
		-cancel_button => 'Cancel',
	);
	my $editor = $dialog->add('TagsEditor',
		-defaultbackground => $self->Subwidget('XText')->cget('-background'),
		-defaultforeground => $self->Subwidget('XText')->cget('-foreground'),
		-defaultfont => $self->Subwidget('XText')->cget('-font'),
		-relief => 'sunken',
		-borderwidth => 2,
	)->pack(-expand => 1, -fill => 'both', -padx => 2, -pady => 2);
	my $toolframe =  $dialog->add('Frame',
	)->pack(-fill => 'x');
	$toolframe->Button(
		-command => sub {
			my $file = $self->getSaveFile(
				-filetypes => [
					['Highlight Theme' => '.ctt'],
				],
			);
			$editor->save($file) if defined $file;
		},
		-text => 'Save',
	)->pack(-side => 'left', -padx => 5, -pady => 5);
	$toolframe->Button(
		-text => 'Load',
		-command => sub {
			my $file = $self->getOpenFile(
				-filetypes => [
					['Highlight Theme' => '.ctt'],
				],
			);
			if (defined $file) {
				my $obj = Tk::CodeText::Theme->new;
				$obj->load($file);
				$editor->put($obj->get);
				$editor->updateAll
			}
		},
	)->pack(-side => 'left', -padx => 5, -pady => 5);
	
	$editor->put($theme->get);
	my $button = $dialog->Show(-popover => $self);
	if ($button eq 'Ok') {
		$theme->put($editor->get);
		$self->themeUpdate;
		$self->highlightPurge;
	}
	$dialog->destroy;
}

sub themefile {
	my $self = shift;
	if (@_) {
		my $file = shift;
		if ((defined $file) and (-e $file)) {
			$self->theme->load($file);
			#the ->after is necessary here, at create time the widget would not yet return the
			#correct font information to configure the tags correctly.
			#TODO: find a solution for this.
			$self->after(1, ['themeUpdate', $self]);;
		}
		$self->{THEMEFILE} = $file;
	}
	return $self->{THEMEFILE};
}

sub themeUpdate {
	my $self = shift;
	my $theme = $self->theme;
	my @values = $theme->get;
	my $font = $self->cget('-font');
	my $bg = $self->Subwidget('XText')->cget('-background');
	my $fg = $self->Subwidget('XText')->cget('-foreground');
	for ($theme->tagList) { $self->tagDelete($_) }
	while (@values) {
		my $tag = shift @values;
		my $options = shift @values;
		my %opt = @$options;
		my $nbg = $bg;
		my $nfg = $fg;
		my $nfont = $font;
		$nbg = $opt{'-background'} if exists $opt{'-background'};
		$nfg = $opt{'-foreground'} if exists $opt{'-foreground'};
		$nfont = $self->fontCompose($nfont, -slant => $opt{'-slant'}) if exists $opt{'-slant'};
		$nfont = $self->fontCompose($nfont, -weight => $opt{'-weight'}) if exists $opt{'-weight'};
		$self->tagConfigure($tag,
			-background => $nbg,
			-foreground => $nfg,
			-font => $nfont,
		);
	}
}

=item B<uncomment>

Uncomments the current line or selection.

=item B<undo>

Undoes the last edit operation.

=item B<unindent>

Unintents the current line or selection

=cut

sub ViewMenuItems {
	my $self = shift;

	my $a;
	tie $a, 'Tk::Configure', $self, '-autoindent';
	my $f;
	tie $f, 'Tk::Configure', $self, '-showfolds';
	my $n;
	tie $n, 'Tk::Configure', $self, '-shownumbers';
	my $s;
	tie $s, 'Tk::Configure', $self, '-showstatus';

	my @values = (-onvalue => 1, -offvalue => 0);
	my $v;
	tie $v,'Tk::Configure',$self,'-wrap';
	my @items = ( 
		[checkbutton => '~Auto indent', @values, -variable => \$a],
		['cascade'=> '~Wrap', -tearoff => 0, -menuitems => [
			[radiobutton => 'Word', -variable => \$v, -value => 'word'],
			[radiobutton => 'Character', -variable => \$v, -value => 'char'],
			[radiobutton => 'None', -variable => \$v, -value => 'none'],
		]],
		[command => '~Colors', -command => [themeDialog => $self]],
		'separator',
		[checkbutton => 'Code ~folds', @values, -variable => \$f],
		[checkbutton => '~Line numbers', @values, -variable => \$n],
		[checkbutton => '~Status bar', @values, -variable => \$s],
	);
	return \@items
}

=item B<visualBegin>

Returns the line number of the first visible line.

=cut

=item B<visualEnd>

Returns the line number of the last visible line.

=cut

=back

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4


=back

=cut

1;

__END__
