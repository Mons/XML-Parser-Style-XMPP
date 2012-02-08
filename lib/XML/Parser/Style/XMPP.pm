package #hide
	XML::LibXML::Node;
use XML::LibXML;
BEGIN {
	if (exists  $XML::LibXML::Node::{'(""'}) { # to string overload
		#warn "XML::LibXML::Node stringification already done";
	} else {
		#warn "Setup to_string overload";
		require overload;
		require Scalar::Util;
		overload->import(
			'""'     => sub { $_[0]->toString },
			'bool'   => sub { 1 },
			'0+'     => sub { Scalar::Util::refaddr($_[0]) },
			fallback => 1,
		);
	}
	#exit;
}

package XML::Parser::Style::XMPP;

use 5.008008;
use common::sense 2;m{
use strict;
use warnings;
};
use Carp;

=head1 NAME

XML::Parser::Style::XMPP - ...

=cut

our $VERSION = '0.01'; $VERSION = eval($VERSION);

=head1 SYNOPSIS

    package Sample;
    use XML::Parser::Style::XMPP;

    ...

=head1 DESCRIPTION

    ...

=cut


use XML::LibXML;

sub Init {
    my $e = shift;
    $e->{Stream} = undef;
    $e->{current} = undef;
    $e->{nested} = [];
    exists $e->{On}{Stanza}{''} or die "Have do default stanza handler: On.Stanza.''()";
}

sub Start {
    my $e = shift;
    #warn "start ".dumper \@_;
    my ($tag,%attrs) = @_;
    my $node = XML::LibXML::Element->new( $tag );
    #$node->setNamespace( $e->{Stream}{xmlns}, '', 0 ) if !@{ $e->{nested} };
    while (my ($k,$v) = each %attrs) {
        if (1 and $k =~ /^xmlns(?:|:(.+))$/) {
            #$node->setAttributeNS( $v );
            #warn "NS: $tag -> $v ($1)";
            $node->setNamespace( $v, defined $1 ? $1 : '', 0 );
        } else {
            $node->setAttribute( $k,$v );
        }
    }
    if ($e->{Stream}) {
        if ($e->{current}) {
            $e->{current}->appendChild($node);
            push @{ $e->{nested} }, $e->{current};
        }
        $e->{current} = $node;
    } else {
        #if ($tag =~ /^(.+):stream$/) {
            $e->{On}{StreamStart} and $e->{On}{StreamStart}($node);
            $e->{StreamAttrs} = \%attrs;
            $e->{Stream} = $node;
        #}
        #else {
        #    croak "Bad initial stream tag: <$tag>\n";
        #}
    }
}

sub Char {
    my $e = shift;
    unless ($e->{current}) {
        return if $_[0] =~ /^\s*$/;
        if (exists $e->{On}{StreamError}) {
            $e->{On}{StreamError}( "Character string in wrong place", $_[0] );
            return;
        } else {
            die "Character string <$_[0]> in wrong place\n";
        }
    }
    $e->{current}->appendTextNode(shift);
}

sub Proc {
    croak "Processing instruction not allowed in restricted XML";
}

sub Final {
    warn "Final?";
}

sub End {
    my $e = shift;
    my ($tag) = @_;
    #warn "end ".dumper \@_;
    if (!$e->{current}) {
        if ($tag =~ /^(.+):stream$/) {
            delete $e->{Stream};
            delete $e->{nested};
            delete $e->{current};
            $e->{On}{StreamEnd} and $e->{On}{StreamEnd}();
        } else {
            croak "Broken XML: end tag $tag at top level";
        }
        return;
    }
    my $node = $e->{current};
    #if ( $tag ne $e->{current}->nodeName ) {
    #    die "Broken XML: end tag $tag, while opened ".$e->{current}->nodeName;
    #}
    if (! @{ $e->{nested} } ) {
        exists $e->{On}{StanzaDebug} and $e->{On}{StanzaDebug}($node);
        
        exists $e->{On}{Stanza}{ $node->nodeName }
            ? $e->{On}{Stanza}{ $node->nodeName }($node)
            : $e->{On}{Stanza}{''}( $e->{current} );
        undef $e->{current};
    } else {
        $e->{current} = pop @{ $e->{nested} };
    }
}

=head1 AUTHOR

Mons Anderson, C<< <mons@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2011 Mons Anderson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

=cut

1;
