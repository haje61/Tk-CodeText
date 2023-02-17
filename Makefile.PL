use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'CodeText';
my $ld = '$(INST_LIBDIR)';

WriteMakefile(
	NAME => "Tk::$pm",
	PREREQ_PM => {
		'Math::Round' => 0,
		'Syntax::Kamelon' => '0.20',
		'Test::Tk' => '2.00',
		'Tk' => '800.024',
	},
	ABSTRACT_FROM => "lib/Tk/$pm.pm",
	VERSION_FROM => "lib/Tk/$pm.pm",
	AUTHOR => 'Hans Jeuken <hanje at cpan dot org>',
	LICENSE				=> 'perl',
	(eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'git://github.com/haje61/Tk-CodeText.git',
				web  => 'https://github.com/haje61/Tk-CodeText',
			},
		}}) : ()
	),
);
