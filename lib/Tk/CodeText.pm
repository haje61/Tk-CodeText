package Tk::CodeText;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.40';
use base qw(Tk::Derived Tk::Frame);
use strict;

Construct Tk::Widget 'CodeText';

require Tk::XText;

sub Populate {
	my ($self,$args) = @_;
	$self->SUPER::Populate($args);
	my $text = $self->XText->pack(-expand =>1, -fill => 'both');
	$self->ConfigSpecs(
		DEFAULT => [ $text ],
	);
	$self->Delegates(
		DEFAULT => [ $text ],
	);
}

1;

__END__
