use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'Pod::TikiWiki',
    VERSION_FROM  => 'lib/Pod/TikiWiki.pm',
    PREREQ_PM     => { 
        'Pod::Parser'     => 0,
    },
    EXE_FILES     => [ 'bin/pod2tikiwiki' ],
    ABSTRACT_FROM => 'lib/Pod/TikiWiki.pm',
    AUTHOR        => 'Cédric Bouvier <cbouvi@cpan.org>',
);
