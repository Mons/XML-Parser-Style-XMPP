#!/usr/bin/env perl -w

use common::sense;
use lib::abs '../lib';
use Test::More tests => 21;
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
my $xml2 = q{<?xml version='1.0' encoding='UTF-8'?>
<stream:stream xmlns:stream="http://etherx.jabber.org/streams" xmlns="jabber:client" from="rambler.ru" id="123456789X" xml:lang="en" version="1.0">
<utf>тест</utf>
</stream:stream>
};utf8::encode($xml2);

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

@sequence = (
    'stream_start',
    'utf',
    'stream_end',
);

$parser = XML::Parser->new(
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
            utf => sub {
                my $s = shift;
                #diag "Got utf: ".$s->toString()."\n";
                is shift(@sequence), $s->nodeName, 'sequence';
                my $text = $s->textContent;
                is ($text, "тест", "string is ok");
                ok (utf8::is_utf8($text), "string is utf");
                
            },
        },
        StreamEnd => sub {
            diag "Stream end";
            is shift(@sequence), "stream_end", 'sequence';
        },
    }
);

$sax = $parser->parse_start();
for my $line ( split //, $xml2 ) {
    $sax->parse_more($line);
}
