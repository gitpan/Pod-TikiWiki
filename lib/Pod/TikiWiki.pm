package Pod::TikiWiki;
use strict;

# $Id: TikiWiki.pm,v 1.6 2004/06/18 08:30:09 cbouvi Exp $
#
#  Copyright © 2004 Cédric Bouvier
#
#  This library is free software; you can redistribute it and/or modify it
#  under the terms of the GNU General Public License as published by the Free
#  Software Foundation; either version 2 of the License, or (at your option)
#  any later version.
#
#  This library is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#  more details.
#
#  You should have received a copy of the GNU General Public License along with
#  this library; if not, write to the Free Software Foundation, Inc., 59 Temple
#  Place, Suite 330, Boston, MA  02111-1307  USA
#
# $Log: TikiWiki.pm,v $
# Revision 1.6  2004/06/18 08:30:09  cbouvi
# Handles =pod and =cut
#
# Revision 1.5  2004/06/17 11:47:53  cbouvi
# Fixed handling of bullet lists. Removed unnecessary blank lines from output
#
# Revision 1.4  2004/06/17 07:56:22  cbouvi
# Converted from utf-8 to latin9
#
# Revision 1.3  2004/06/16 15:07:23  cbouvi
# Added POD
#
# Revision 1.2  2004/06/16 12:45:09  cbouvi
# Better handling of definition lists
#
# Revision 1.1.1.1  2004/06/16 10:25:00  cbouvi
# Initial import
#

use Pod::Parser;
use vars qw/ @ISA $VERSION /;

$VERSION = 0.2;
@ISA = qw/ Pod::Parser /;

sub bullet {

    my $self = shift;

    return '' unless @{$self->{lists}};
    my $bullet = $self->{lists}[-1] x @{$self->{lists}};
    $bullet =~ tr/d/*/;
    return $bullet;
}

sub command {

    my ($self, $command, $paragraph, $line_num) = @_;

    my $expansion;
    my $out_fh =  $self->output_handle();
    for ( $command ) {
        /pod/ || /cut/ and return;
        /begin/ and do {
            $self->{ignore_section} = 1;
            return;
        };
        /end/ and do {
            $self->{ignore_section} = 0;
            return;
        };
        /head(\d)/ and do {
            $expansion = $self->interpolate($paragraph, $line_num);
            $expansion = ('!' x $1) . $expansion . "\n";
            last;
        };
        /over/ and do {
            push @{$self->{lists}}, undef;
            return;
        };
        /back/ and do {
            if ( $self->{current_item} ) {
                print $out_fh $self->bullet() . ' ' . $self->{current_item} . "\n";
                $self->{current_item} = undef;
            }
            pop @{$self->{lists}};
            return;
        };
        /item/ and do {
            my $list_type = $self->{lists}[-1] ||= 
                $paragraph =~ /^\d+\.?\s*/
                ? '#'
                : $paragraph =~ /^[*o-]+\s*/
                ? '*'
                : 'd';
            $paragraph =~ s/^[*o-]+\s*//;
            $paragraph =~ s/^\d+\.?\s*//;

            if ( $self->{current_item} ) {
                print $out_fh $self->bullet() . ' ' . $self->{current_item} . "\n";
                $self->{current_item} = undef;
            }

            $expansion = $self->interpolate($paragraph, $line_num);
            if ( $list_type eq 'd' ) {
                # Definition Item
                # The definition will be given by the next paragraph if any.
                $expansion =~ s/\s*$//;
                $self->{current_item} = $expansion;
                return;
            }
            else {
                $expansion = $self->bullet() . ' ' . $expansion;
            }
            last;
        };
    }

    print $out_fh $expansion;
}

sub include_definition_title {

    my ($self, $paragraph) = @_;

    if ( $self->{current_item} ) {
        $paragraph = ';' . $self->{current_item} . ": $paragraph";
        $self->{current_item} = undef;
    }
    else {
        $paragraph .= "\n";
    }
    return $paragraph;
}

sub textblock {

    my ($self, $paragraph, $line_num) = @_;
    return if $self->{ignore_section};

    my $expansion = $self->interpolate($paragraph, $line_num);

    $expansion = $self->include_definition_title($expansion);

    my $out_fh = $self->output_handle();
    print $out_fh "$expansion\n";
}

sub interior_sequence {

    my ($self, $seq_command, $seq_argument) = @_;

    my %markup = (
        B => [ '__', '__' ],
        I => [ "''", "''" ],
        F => [ '-+', '+-' ],
        C => [ '-+', '+-' ],
    );

    return $markup{$seq_command}[0] . $seq_argument . $markup{$seq_command}[1];
}

sub verbatim {

    my ($self, $paragraph, $line_num) = @_;

    return if $self->{ignore_section};

    my $out_fh = $self->output_handle();
    $paragraph =~ s/[\r\n]*$//;
    $paragraph = "~pp~$paragraph~/pp~";
    $paragraph = $self->include_definition_title($paragraph);
    print $out_fh "$paragraph\n";
}

sub interpolate {

    my $self = shift;
    local $_ = $self->SUPER::interpolate(@_);
    tr/ \t\r\n/ /s;
    s/\s+$//;
    return $_;
}

1;

=head1 NAME

Pod::TikiWiki - converts a POD file to a TikiWiki page.

=head1 SYNOPSIS

    use Pod::TikiWiki;

    my $p = new Pod::TikiWiki;
    $p->parse_from_file('in.pod');

=head1 DESCRIPTION

This class converts a file in POD syntax to the TikiWiki syntax. See
http://tikiwiki.org/tiki-index.php?page=WikiSyntax for a description of the
syntax.

Pod::TikiWiki derives from Pod::Parser and therefore inherits all its methods.

=head2 Supported formatting

=over 4

=item *

Heading directives (C<=head[1234]>) are handled with the appropriate number of bangs.

    =head1 NAME    --> !NAME
    =head2 Methods --> !!Methods

=item *

List items are rendered with a number of hashes (C<#>, for ordered lists) or asterisks (C<*>, for unordered lists).

    =over

    =item *
                   --> * Text
    Text

    =over

    =item 1
                   --> ## Text
    Text

    =back

    =back

Items with a string are rendered into a definition list, the definition being the next paragraph

    =item Text
                   --> ;Text: Definition
    Definition

=item *

Interior sequences C<B>, C<I>, C<F>, and C<C> are honored. Both C<F> and C<C>
are rendered as monospaced text.

    B<bold>       --> __bold__
    I<italic>     --> ''italic''
    F<file>       --> -+file+-
    C<code>       --> -+code+-

=back

=head1 LIMITATIONS

=over

=item *

Only the above four interior sequences are handled. C<S>, C<L>, C<X>, C<E> are
ignored.

=item *

Tiki syntax being unstructured, the nesting of list item and regular paragraphs
may not be well rendered on the final page.

=item *

...

=back

=head1 SEE ALSO

L<perlpod>, L<Pod::Parser>

=head1 AUTHOR

Copyright © 2004 Cédric Bouvier <cbouvi@cpan.org>

This module is free software. You can redistribute and/or modify it under the
terms of the GNU General Public License.

=cut
