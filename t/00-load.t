#!/usr/bin/env perl -w

use common::sense;
use lib::abs '../lib';
use Test::More tests => 2;
use Test::NoWarnings;

BEGIN {
	use_ok( 'XML::Parser::Style::XMPP' );
}

diag( "Testing XML::Parser::Style::XMPP $XML::Parser::Style::XMPP::VERSION, Perl $], $^X" );
