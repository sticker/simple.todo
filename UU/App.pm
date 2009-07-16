package UU::App;
use strict;
use lib qw (/project/stodo/src);
use base qw(CGI::Application);
use CGI::Carp qw(fatalsToBrowser);
use CGI::Application::Plugin::TT;
use CGI::Session qw(-ip_match);
use CGI::Session::Driver;
use CGI::Application::Plugin::Session;
use UU::DB;
use UU::Mail;
use Text::Template;
use DBI;

sub cgiapp_init {
	my $self = shift;
	$self->SUPER::cgiapp_init(@_);
	$self->session_config(
		CGI_SESSION_OPTIONS => [ "driver:File", $self->query, { Directory => '/project/stodo/session' } ],
		COOKIE_PARAMS       => { -path => '/', },
		SEND_COOKIE         => 1,
	);
	$self->tt_config(
		TEMPLATE_OPTIONS => {
			INCLUDE_PATH => "/project/stodo/src/tt",
		},
	);
}

sub cgiapp_prerun {
	my $self = shift;
	$self->header_props( -charset => 'utf-8');
}

1;
