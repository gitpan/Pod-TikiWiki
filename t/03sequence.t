use Test;
BEGIN {
    %tests = (
        "\n=head1 B<Heading 1>\n\n" => "!__Heading 1__\n",
        "\n=head2 I<Heading 2>\n\n" => "!!''Heading 2''\n",
        "\n=head3 F<Heading 3>\n\n" => "!!!-+Heading 3+-\n",
        "\n=head4 C<Heading 4>\n\n" => "!!!!-+Heading 4+-\n",
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
