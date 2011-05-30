#!/usr/bin/env perl -w

use common::sense;
use lib::abs '../lib';
use Test::More tests => 14;
use Test::NoWarnings;
use XML::Parser;
use XML::Parser::Style::XMPP;

sub dumper (@) { diag explain @_; return; }

my $xml = q{<?xml version='1.0' encoding='UTF-8'?>
<stream:stream xmlns:stream="http://etherx.jabber.org/streams" xmlns="jabber:client" from="rambler.ru" id="123456789X" xml:lang="en" version="1.0">


<stream:features>
<mechanisms xmlns="urn:ietf:params:xml:ns:xmpp-sasl">
<mechanism>PLAIN</mechanism>
<required/>
</mechanisms>
<auth xmlns="http://jabber.org/features/iq-auth"/>
</stream:features>

<success xmlns="urn:ietf:params:xml:ns:xmpp-sasl"/>

<iq xmlns="jabber:client" type="result" id="bind_1" to="xxx@rambler.ru/xxx">
<bind xmlns="urn:ietf:params:xml:ns:xmpp-bind">
<jid>xxx@rambler.ru/xxx-1111111</jid>
</bind>
</iq>
</stream:stream>

};

my @sequence = (
    'stream_start',
    'stream:features',
    'success',
    'iq',
    'stream_end',
);

my $parser = XML::Parser->new(
    Style => 'XMPP',
    On => {
        StreamStart => sub {
            my $s = shift;
            diag "Stream start ".$s->toString();
            is shift(@sequence), "stream_start", 'stream order';
            my ($ns) = $s->getNamespaces;
            is $ns->getValue,'jabber:client', 'stream ns';
            is $s->getAttribute('id'), '123456789X', 'stream id';
        },
        Stanza => {
            '' => sub {
                my $s = shift;
                diag "Got stanza: ".$s->toString();
                is shift(@sequence), $s->nodeName, 'sequence';
            },
            iq => sub {
                my $s = shift;
                diag "Got iq: ".$s->toString()."\n";
                is shift(@sequence), $s->nodeName, 'iq sequence';
                is +($s->getNamespaces)[0]->getValue, 'jabber:client', 'iq ns';
                is $s->getAttribute('id'), 'bind_1', 'iq id';
                my ($bind,$bindns);
                ($bind) = $s->getElementsByTagName( 'bind' );
                ok $bind, 'have bind by gebtn';
                {
                    local $TODO = "Need to understand a design: either xpath or DOM";
                    ($bindns) = $s->getElementsByTagNameNS( 'urn:ietf:params:xml:ns:xmpp-bind','bind' );
                    ok $bindns, 'have bind by gebtnNS';
                    
                    ($bind) = $s->find('//bind');
                    ok $bind, 'have bind by bare xpath';

                    my $xc = XML::LibXML::XPathContext->new($s);
                    $xc->registerNs('bind', 'urn:ietf:params:xml:ns:xmpp-bind');
                    ($bindns) = $xc->find('//bind:bind');
                    ok $bindns, 'have bind by NS aware xpath';
                }
                
=for rem
                #warn "\ngetElementByTagNameNS: " . $s->getElementsByTagNameNS( 'urn:ietf:params:xml:ns:xmpp-bind','bind' );
                return;
                #$s->setNamespace( 'stream', '' )

                my $xc = XML::LibXML::XPathContext->new($s);
                $xc->registerNs('bind', 'urn:ietf:params:xml:ns:xmpp-bind');
                eval{ warn "\nxp.find: " . $xc->find('//bind') };
                eval{ warn "\nxp.findNS: " . $xc->find('//bind:bind') };
                eval{ warn "\ns.find: " . $s->find('//bind') };
                eval{ warn "\ns.findNS: " . $s->find('//bind:bind') };
                
                warn "done";
=cut
            },
        },
        StreamEnd => sub {
            diag "Stream end";
            is shift(@sequence), "stream_end";
        },
    }
);

my $sax = $parser->parse_start();

for my $line ( split /\n/, $xml ) {
    $sax->parse_more($line);
}