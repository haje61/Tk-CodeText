package MyKamelon;
use strict;
use warnings;

use base qw(Syntax::Kamelon);

sub new {
	my $class = shift;
	my $widget = shift;
	my $self = $class->SUPER::new(@_);
	$self->{WIDGET} = $widget;
	$self->CreateExtIndex;
	return $self
}

sub CreateExtIndex {
	my $self = shift;
	my $idx = $self->GetIndexer;
	my $index = $idx->{INDEX};
	my %eindex = ();
	for ($idx->AvailableSyntaxes) {
		my $lang = $_;
		my $extl = $index->{$lang}->{'ext'};
		my @o = split(/;/, $extl);
		for (@o) {
			my $e = $_;
			if (exists $eindex{$e}) {
				my $p = $eindex{$e};
				push @$p, $lang;
			} else {
				$eindex{$e} = [ $lang ];
			}
		}
	}
	if (%eindex) {
		$self->{EXTENSIONS} = \%eindex;
	}
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

sub SuggestSyntax {
	my ($self, $file) = @_;
	my $hsh = $self->{EXTENSIONS};
	my $ext;
	if ($file =~ /(\.[^\.]+)$/) {
		$ext = $1;
	}
	return undef unless defined $ext;
	my $key = "*$ext";
	return $hsh->{$key}->[0] if exists $hsh->{$key};
	return undef;
}

sub Widget { return $_[0]->{WIDGET} }

###########################################################################

package Tk::CodeText;


=head1 NAME

Tk:XText - Extended Text widget

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

 require Tk::XText;
 my $text= $window->XText(@options)->pack;

=head1 DESCRIPTION

=head1 OPTIONS

=over 4

=item Switch: B<-autoindent>

=item Switch: B<-commentend>

=item Switch: B<-commentstart>

=item Switch: B<-disablemenu>

=item Switch: B<-indentchar>

=item Switch: B<-match>

=item Switch: B<-matchoptions>

=item Switch: B<-modifycall>

=item Switch: B<-scrollbars>

=item Switch: B<-updatecall>

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
	$self->{SAVEFIRSTVISIBLE} = '1.0';
	$self->{SAVELASTVISIBLE} = '1.0';
	
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
	my $text = $ef->Scrolled('XText',
		-relief => 'flat',
		-modifycall => ['modifiedCheck', $self],
		-scrollbars => $scrollbars,
	)->pack(-side => 'left', -expand =>1, -fill => 'both');

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
		-autoindent => [qw/PASSIVE autoindent Autoindent/, 0],
		-commentchar => '-commentstart', #depricated
		-configdir => [qw/PASSIVE configdir ConfigDir/, ''],
		-highlightinterval => [qw/METHOD highlightinterval HighlightInterval/, 1],
		-minusimg => ['PASSIVE', undef, undef, $self->Bitmap(
			-data => $minusimg,
			-foreground => $fg,
		)],
		-plusimg => ['PASSIVE', undef, undef, $self->Bitmap(
			-data => $plusimg,
			-foreground => $fg,
		)],
		-rules => '-attributes', #depricated
		-rulesdir => '-configdir', #depricated
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

sub clear {
	my $self = shift;
	$self->Kamelon->Reset;
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

sub isHidden {
	my ($self, $line) = @_;
	my @names = $self->tagNames("$line.0");
	my $hit = grep({ $_ eq 'Hidden'} @names);
	return $hit;
}

sub Kamelon {
	return $_[0]->{KAMELON}
}

=item B<lnumberCheck>

=cut

sub lnumberCheck {
	my $self = shift;

	return unless $self->{POSTCONFIG};

	my $line = $self->visualBegin;
	my $last = $self->visualEnd;
	$self->SaveFirstVisible($line);
	$self->SaveLastVisible($line);

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

	while (defined $nimf->[$count]) {
		my $l = pop @$nimf;
		$l->placeForget;
		$l->destroy;
	}
}

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

sub tags {
	return $_[0]->Kamelon->AvailableAttributes
}

sub theme {
	return $_[0]->{THEME}
}

sub themeDialog {
	my $self = shift;
	my $theme = $self->theme;
	my $dialog = $self->DialogBox(
		-buttons => ['Ok', 'Cancel'],
		-default_button => 'Ok',
		-cancel_button => 'Cancel',
	);
	my $editor = $dialog->add('TagsEditor',
		-relief => 'sunken',
		-borderwidth => 2,
		-widget => $self,
	)->pack(-expand => 1, -fill => 'both', -padx => 2, -pady => 2);
	my $toolframe =  $dialog->add('Frame',
	)->pack(-fill => 'x');
	$toolframe->Button(
		-command => sub {
			my $file = $self->getSaveFile;
			$editor->save($file) if defined $file;
		},
		-text => 'Save',
	)->pack(-side => 'left', -padx => 5, -pady => 5);
	$toolframe->Button(
		-text => 'Load',
		-command => sub {
			my $file = $self->getOpenFile;
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
	my $bg = $self->cget('-background');
	my $fg = $self->cget('-foreground');
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

sub ViewMenuItems {
	my $self = shift;

	my $f;
	tie $f, 'Tk::Configure', $self, '-showfolds';
	my $n;
	tie $n, 'Tk::Configure', $self, '-shownumbers';
	my $s;
	tie $s, 'Tk::Configure', $self, '-showstatus';

	my @values = (-onvalue => 1, -offvalue => 0);
	my $items = $self->Subwidget('XText')->ViewMenuItems;
	push @$items,
		[command => "Colors", -command => [themeDialog => $self]],
		'separator',
		[checkbutton => 'Show code folds', @values, -variable => \$f],
		[checkbutton => 'Show line numbers', @values, -variable => \$n],
		[checkbutton => 'Show status bar', @values, -variable => \$s];
	return $items
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
