use Test;
BEGIN { plan tests => 3 }
use Pod::TikiWiki;

my $c = new Pod::TikiWiki;
ok($c);
ok(ref($c));
ok($c->isa('Pod::TikiWiki'));
