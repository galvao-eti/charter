#!/usr/bin/perl

###################################################
# Charter - A web crawler written in Perl         #
#                                                 #
# @author Er Galvão Abbott <galvao@galvao.eti.br> #
###################################################

use strict;
use utf8;
use warnings;

use Data::Dumper;
use HTML::TreeBuilder;
use JSON;
use LWP;

my $depth = 0;
my $depthLimit = 0;

# For some odd reason perl is registering the tld as ARGV[0] instead of 1.
# @todo Investigate this later
my @chart = (
    {
        protocol => 'https',
        tld      => $ARGV[0],
        location => '/',
        method   => 'GET',
    },
);

my $agent = LWP::UserAgent->new;
$agent->agent('charter/0.1.0');

chartIt();

sub chartIt
{
    for (my $c = 0; $c < @chart; $c++) {
        my $request = HTTP::Request->new($chart[$c]{method} => sprintf(
                '%s://%s%s',
                $chart[$c]{protocol},
                $chart[$c]{tld},
                $chart[$c]{location}
            )
        );

        my $response = $agent->request($request);

        if ($response->is_success) {
            my @nodes = parse(HTML::TreeBuilder->new, $response->content);
        }
    }
}

sub parse
{
    my ($treeBuilder, $content) = @_;
    $content = $treeBuilder->parse($content);
    $treeBuilder->eof();

    # RFC 3986 RegEx, as noted in Appendix B
    # # @see https://www.rfc-editor.org/rfc/rfc3986#appendix-B
    my $regEx = qr/^(([^:\/?#]+):)?(\/\/([^\/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?/;

    my @nodes = $treeBuilder->guts();
    my @found = $nodes[0]->find_by_tag_name('a');

    for (my $f = 0; $f < @found; $f++) {
        if (defined(my $target = $found[$f]->attr('href'))) {
            if ($target =~ /$regEx/i) {
                my %entry = (
                    protocol => $2,
                    tld      => $4,
                    location => $5,
                );

                if (defined $7) {
                    $entry{queryString} = $7;
                }

                push @chart, {%entry};
            }
        }
    }

    print Dumper @chart;
    exit;
}
