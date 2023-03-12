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
	$self->Formatter->FoldEnd($region);
	$self->Widget->foldsCheck;
	my $parser = pop @_;
	return &$parser($self, @_);
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
require Tk::XText;
require Tk::CodeText::StatusBar;


Construct Tk::Widget 'CodeText';

my @defaultattributes = (
	['Alert', -background => 'orange', -foreground => 'blue'],
	['Annotation', -foreground => 'darkgrey'],
	['Attribute', -foreground => 'green', -font => [-weight => 'bold']],
	['BaseN', -foreground => 'darkgreen'],
	['BuiltIn', -foreground => 'purple'],
	['Char', -foreground => 'magenta'],
	['Comment', foreground => 'darkgrey', -font => [-slant => 'italic']],
	['CommentVar', -foreground => 'darkgrey', -font => [-slant => 'italic']],
	['Constant', -foreground => 'blue', -font => [-weight => 'bold']],
	['ControlFlow', -foreground => 'darkblue'],
	['DataType', -foreground => 'blue'],
	['DecVal', -foreground => 'darkblue', -font => [-weight => 'bold']],
	['Documentation', -foreground => 'beige', -font => [-slant => 'italic']],
	['Error',  -background => 'red', -foreground => 'yellow'],
	['Extension', -foreground => 'violet'],
	['Float', -foreground => 'darkblue', -font => [-weight => 'bold']],
	['Function', -foreground => 'green'],
	['Import', -foreground => 'red'],
	['Information', foreground => 'darkgrey', -font => [-weight => 'bold']],
	['Keyword', -foreground => 'brown'],
	['Normal', ],
	['Operator', -foreground => 'orange', -background  => 'beige'],
	['Others', -foreground => 'orange'],
	['Preprocessor', ],
	['RegionMarker', -background => 'lightblue'],
	['SpecialChar', -foreground => 'purple', -background => 'beige'],
	['SpecialString', -foreground => 'orange'],
	['String', -foreground => 'red'],
	['Variable', -foreground => 'blue', -background => 'lightgreen'],
	['VerbatimString', -foreground => 'orange', -font => [-weight => 'bold']],
	['Warning', -background => 'yellow', -foreground => 'darkred'],
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

=item Switch: B<-updatecall>

=back

=cut

=head1 METHODS

=over 4

=cut

sub Populate {
	my ($self,$args) = @_;

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
		-scrollbars => 'osoe',
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
		-attributes => [qw/METHOD attributes Attributes/,  \@defaultattributes],
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
			$self->contentCheck;
		}
	);

	my @events = qw(
		Expose Visibility Configure
		KeyPress ButtonPress ButtonRelease-1 
		Return ButtonRelease-2 B2-Motion 
		B1-Motion MouseWheel
	);
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
		$self->lnumberCheck;
 	});
}

sub attributes {
	my $self = shift;
	if (@_) {
		$self->{ATTRIBUTES} = shift;
		#the ->after is necessary here, at create time the widget would not yet return the
		#correct font information to configure the attributes correctly.
		#TODO: find a solution for this.
		$self->after(1, ['attributesConfigure', $self]);
		
	}
	return $self->{ATTRIBUTES};
}

sub attributesConfigure {
	my $self = shift;
	my $new = $self->{ATTRIBUTES};

	my @tags = $self->tags;
	#clear all tags
	for (@tags) {
		$self->tagDelete($_)
	}
	#setup attributes
	foreach my $r (@$new) {
		my @raw = @$r;
		my $tagname = shift @raw;
		#check for valid tagname
		my $hit = grep({ $_ eq $tagname} @tags);
		if ($hit) {
			my %opt = (@raw);
			if (exists $opt{'-font'}) {
				my $f = $opt{'-font'};
				$opt{'-font'} = $self->attributesFontCompose($f);
			}
			$self->tagConfigure($tagname, %opt);
		}
	}
}

sub attributesFontCompose {
	my ($self, $l) = (@_);
	my @fat = qw(-family -overstrike -size -slant -underline -weight);
	my $deffont = $self->Subwidget('XText')->getFontInfo;
	my %fopt = (@$l);
	foreach my $att (@fat) {
		unless (exists $fopt{$att}) {
			$fopt{$att} = $deffont->{$att};
		}
	}
	my @res = (%fopt);
	return \@res;
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
	return unless $self->cget('-shownumbers');

	my $widget = $self->Subwidget('XText');
	my $count = 0;
	my $font = $widget->cget('-font');

	my $line = $self->visualBegin;
	my $last = $self->visualEnd;

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
			$self->NoHighlighting(0);
			$self->Colored(0);
			$self->ColorInf([ [$kam->StateGet] ]);
			my $idx = $kam->GetIndexer;
			$self->highlightLoop unless $self->LoopActive;
		}
		$self->{SYNTAX} = $new;
	}
	return $self->{SYNTAX}
}

sub tags {
	return $_[0]->Kamelon->AvailableAttributes
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
		'separator',
		[checkbutton => "Show code folds", @values, -variable => \$f],
		[checkbutton => "Show line numbers", @values, -variable => \$n],
		[checkbutton => "Show status bar", @values, -variable => \$s];
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
