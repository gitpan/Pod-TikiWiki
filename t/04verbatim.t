use Test;
BEGIN {
    %tests = (
        <<EOF1 => <<EOF2,

=pod

    verbatim paragraph
    on two lines

=cut

EOF1
~pp~    verbatim paragraph
    on two lines~/pp~

EOF2
    );
    plan tests => scalar(keys %tests);
}
use Pod::TikiWiki;

$c = new Pod::TikiWiki;
chdir 't' if -d 't';

while ( ($pod, $expected) = each %tests ) {
    open OUT, "> tmp.pod" or die "Cannot write to tmp.pod: $!";
    print OUT $pod;
    close OUT;

    $c->parse_from_file('tmp.pod', 'out.tmp');

    open IN, "out.tmp" or die "Cannot open out.tmp: $!";
    {
        local $/;
        $tiki = <IN>;
    }
    close IN;

    unlink 'tmp.pod', 'out.tmp';

    ok($tiki eq $expected);
}
