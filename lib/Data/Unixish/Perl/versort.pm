package Data::Unixish::Perl::versort;

# DATE
# VERSION

use 5.010;
use strict;
use syntax 'each_on_array'; # to support perl < 5.12
use warnings;
#use Log::Any '$log';

use Data::Unixish::Util qw(%common_args);

our %SPEC;

$SPEC{versort} = {
    v => 1.1,
    summary => 'Sort version numbers',
    args => {
        %common_args,
        reverse => {
            summary => 'Whether to reverse sort result',
            schema=>[bool => {default=>0}],
            cmdline_aliases => { r=>{} },
        },
    },
    tags => [qw/ordering/],
};
sub versort {
    my %args = @_;
    my ($in, $out) = ($args{in}, $args{out});
    my $reverse = $args{reverse} ? -1 : 1;

    no warnings;
    my @buf;

    while (my ($index, $item) = each @$in) {
        my $rec = [$item];
        my $v;
        eval { $v = version->parse($item) };
        push @$rec, (defined($v) ? 0:1), $v; # cache invalidness & parsed version
        push @buf, $rec;
    }

    @buf = sort {
        my $cmp;

        # invalid versions are put at the back
        $cmp = $a->[1] <=> $b->[1];
        goto L1 if $cmp;

        if ($a->[1]) {
            # invalid versions are compared ascibetically
            $cmp = $a cmp $b;
        } else {
            # valid versions are compared
            $cmp = $a->[2] <=> $b->[2];
        }

      L1:
        $reverse * $cmp;
    } @buf;

    push @$out, $_->[0] for @buf;

    [200, "OK"];
}

1;
# ABSTRACT:

=head1 SYNOPSIS

In Perl:

 use Data::Unixish qw(lduxl);
 my @res;
 @res = lduxl('sort', "1.1", "1.10", "1.9"); # => ("1.1", "1.9", "1.10")
 @res = lduxl([sort => {reverse=>1}], "1.1", "1.10", "1.9"); # => ("1.10", "1.9", "1.1")

In command line:

 % echo -e "1.1\n1.10\n1.9" | dux Perl::versort --format=text-simple
 1.1
 1.9
 1.10


=head1 SEE ALSO

L<version>

=cut
