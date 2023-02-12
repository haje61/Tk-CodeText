package MyKamelon;

use strict;
use warnings;

use base qw(Syntax::Kamelon);

sub new {
	my $class = shift;
	my %args = (@_);

	my $widget = delete $args{widget};
   my $self = $class->SUPER::new(%args);
   $self->{WIDGET} = $widget;
	return $self
}

# TODO
sub ParseResultBeginRegion {
	my $self = shift;
	my $region = pop @_;
# 	$self->{FORMATTER}->FoldBegin($region);
	my $parser = pop @_;
	return &$parser($self, @_);
}

# TODO
sub ParseResultEndRegion {
	my $self = shift;
	my $region = pop @_;
# 	$self->{FORMATTER}->FoldEnd($region);
	my $parser = pop @_;
	return &$parser($self, @_);
}

sub Widget { return $_[0]->{WIDGET} }

###########################################################################

package Tk::CodeText;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.40';

use base qw(Tk::Derived Tk::Frame);

use Syntax::Kamelon;
use Tk;
require Tk::XText;


Construct Tk::Widget 'CodeText';

my @defaultattributes = (
	['Alert', -background => 'orange', -foreground => 'blue'],
	['Annotation', -foreground => 'darkgrey'],
	['Attribute', -foreground => 'green', -font => [-weight => 'bold']],
	['BaseN', -foreground => 'darkgreen'],
	['BuiltIn', -foreground => 'purple'],
	['Char', -foreground => 'magenta'],
	['Comment', -font => [-slant => 'italic']],
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

my $save_pixmap = '
/* XPM */
static char *save[]={
"16 16 4 1",
". c None",
"# c #000000",
"a c #808080",
"b c #ffff00",
"................",
"..############..",
".#aaaaaaaaaaaa#.",
".#aaaaaaaaaaaa#.",
".#aaaaaaaaaaaa#.",
".#aaaaaaaaaaaa#.",
".#aaaaaaaaaaaa#.",
".#aaaaaaaaaaaa#.",
".#aa########aa#.",
".#aa########aa#.",
".#aa########aa#.",
".#aa########aa#.",
".#aa#bbbbbb#aa#.",
".#aa#bbbbbb#aa#.",
"..############..",
"................"};
';

sub Populate {
	my ($self,$args) = @_;

	my $saveimage = delete $args->{'-saveimage'};
	$saveimage = $self->Pixmap(-data => $save_pixmap) unless defined $saveimage;

	$self->SUPER::Populate($args);

	$self->{COLORINF} = [];
	$self->{COLORED} = 1;
	$self->{KAMELON} = Syntax::Kamelon->new(
# 		widget => $self,
#		syntax => 'Perl',
	);
	$self->{HIGHLIGHTINTERVAL} = 1;
	$self->{LOOPACTIVE} = 0;
	$self->{NOHIGHLIGHTING} = 1;
	
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
	)->pack(-side => 'left', -fill => 'y');

	#create the frame for code folding
	my $folds = $ef->Frame(
		-width => 10,
	)->pack(-side => 'left', -fill => 'y');

	#create the textwidget
	my $text = $ef->Scrolled('XText',
		-relief => 'flat',
		-modifycall => ['highlightCheck', $self],
		-scrollbars => 'osoe',
	)->pack(-side => 'left', -expand =>1, -fill => 'both');
	$self->Advertise(XText => $text);

	#create the statusbar
	my $pos = '';
	my $lines = '';
	my $size = '';
	my $ovr = '';

	my $sb = $self->Frame->pack(
		-padx => 2,
		-pady => 2,
		-fill => 'x'
	);

	my $modlab = $sb->Label(
		-image => $saveimage,
	);
	my $poslab = $sb->Label(
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
	$sb->Button(
		-text=> 'Reset',
		-relief => 'flat',
		-command => ['clear', $text], 
	)->pack(-side => 'left');

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
			$modlab->pack(
				-side => 'left',
				-before => $poslab,
			);
		} else {
			$modlab->packForget
		}
		$self->after(200, $call);
	};
	
	$self->after(5000, $call);

	$self->ConfigSpecs(
		-attributes => [qw/METHOD attributes Attributes/,  \@defaultattributes],
		-autoindent => [qw/PASSIVE autoindent Autoindent/, 0],
		-commentchar => '-commentstart', #depricated
		-configdir => [qw/PASSIVE configdir ConfigDir/, ''],
		-highlightinterval => [qw/METHOD highlightinterval HighlightInterval/, 1],
		-rules => '-attributes', #depricated
		-rulesdir => '-configdir', #depricated
		-syntax => [qw/METHOD syntax Syntax/, 'None'],
		DEFAULT => [ $text ],
	);
	$self->Delegates(
		DEFAULT => [ $text ],
	);
}

sub attributes {
	my $self = shift;
	if (@_) {
		$self->{ATTRIBUTES} = shift;
		#the ->after is necessary here, at create time the widget would not yet return the
		#correct font information to configure the attributes correctly.
		#TODO: find a solution for this.
		$self->after(5, ['attributesConfigure', $self]);
		
	}
	return $self->{ATTRIBUTES};
}

sub attributesConfigure {
	my $self = shift;
	my $new = $self->{ATTRIBUTES};
	my @tags = $self->tags;
	for (@tags) {
		$self->Subwidget('XText')->tagDelete($_)
	}
	foreach my $r (@$new) {
		my @raw = @$r;
		my $tagname = shift @raw;
		my $hit = grep({ $_ eq $tagname} @tags);
		if ($hit) {
			my %opt = (@raw);
			if (exists $opt{'-font'}) {
				my $f = $opt{'-font'};
				$opt{'-font'} = $self->attributesFontCompose($f);
			}
			$self->Subwidget('XText')->tagConfigure($tagname, %opt);
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

sub highlightCheck {
	my ($self, $pos) = @_;
	return if $self->NoHighlighting;
	my $line = $self->Subwidget('XText')->linenumber($pos);
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
	my $xt = $self->Subwidget('XText');
	my $begin = "$num.0"; my $end = $xt->index("$num.0 lineend + 1c");
#	remove all existing tags in this line
	foreach my $tn ($self->tags) {
		$xt->tagRemove($tn, $begin, $end);
	}	
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
	my $colored = $self->Colored;
	my $xt = $self->Subwidget('XText');
	if ($colored <= $xt->linenumber('end - 1c')) {
		$self->LoopActive(1);
#		print " doing line $colored\n";
		$self->highlightLine($colored);
		$colored ++;
		$self->Colored($colored);
# 		my $int = $self->cget('-highlightinterval');
		$self->after($self->highlightinterval, ['highlightLoop', $self]);
	} else {
		$self->LoopActive(0);
#		print " stopping\n";
	}
}

sub highlightPurge {
	my ($self, $line) = @_;
	if ($line <= $self->Colored) {
		$self->Colored($line);
		my $cli = $self->ColorInf;
		if (@$cli) { splice(@$cli, $line) };
		$self->highlightLoop unless $self->LoopActive;
	}
}

sub Kamelon {
	return $_[0]->{KAMELON}
}

sub LoopActive {
	my $self = shift;
	$self->{LOOPACTIVE} = shift if @_;
	return $self->{LOOPACTIVE}
}

sub NoHighlighting {
	my $self = shift;
	$self->{NOHIGHLIGHTING} = shift if @_;
	return $self->{NOHIGHLIGHTING}
}

sub syntax {
	my ($self, $new) = @_;
	my $kam = $self->Kamelon;
	if (defined($new)) {
		if ($new eq 'None') {
			$self->NoHighlighting(1);
		} else {
			print "syntax\n";
			$kam->Syntax($new);
			$self->NoHighlighting(0);
			$self->Colored(1);
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

1;

__END__
