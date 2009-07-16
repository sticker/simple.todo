package UU::Login;
use strict;
use base qw (UU::App);
use CGI::Session qw(-ip_match);
use CGI::Application::Plugin::Session;
use Jcode;
use Data::Dumper;

sub setup {
	my $self = shift;
	$self->start_mode('login');
	$self->run_modes(
		login => 'do_login',
	);
}

sub do_login {
	my $self = shift;
	my $session = $self->session;
	my $cgi = CGI->new;
	my $sid = $cgi->cookie('CGISESSID')||$cgi->param('CGISESSID')||undef;
	warn Dumper($sid);
	warn Dumper($session->id);
	warn Dumper($session->param('entry_no'));
	if ( defined $sid && $sid eq $session->id ) {
		if( defined $session->param('entry_no') ){
			return $self->tt_process('cp/index.tt');
		}
	}


	return $self->tt_process('login.tt');
}

1;
