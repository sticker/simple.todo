package UU::Cp;
use strict;
use base qw (UU::App);
use CGI::Session qw(-ip_match);
use CGI::Session::Driver;
use CGI::Application::Plugin::Session;
use Jcode;
use Data::Dumper;

sub setup {
	my $self = shift;
	$self->start_mode('cp');
	$self->run_modes(
		cp => 'do_cp',
	);
}

sub do_cp {
	my $self = shift;
	my $session = $self->session;
	my $cgi = CGI->new;
	my $agent = $ENV{'HTTP_USER_AGENT'};
	warn Dumper($agent);
	if($agent =~ /^DoCoMo/){
		my $guid = $ENV{'HTTP_X_DCMGUID'};
		warn Dumper($guid);
		my $db = UU::DB->connect();
		my $sth = $db->prepare("SELECT entry_no FROM stodo_user_info WHERE guid = ? AND status != 99");
		$sth->bind_param(1, $guid);
		$sth->execute;
		$sth->finish;
		$db->disconnect;
		if($sth->rows != 1){
			my $error_msg = 'ログインできませんでした';
			return $self->tt_process('login.tt', { error_msg => $error_msg });
		}
		else {
			return $self->tt_process('cp/index.tt');
		}
	}
	else {
		my $sid = $cgi->cookie('CGISESSID')||$cgi->param('CGISESSID')||undef;
		if ( defined $sid && $sid eq $session->id ) {
			if( defined $session->param('entry_no') ){
				return $self->tt_process('cp/index.tt');
			}
		}
	}

	my $q = $self->query;

	my $mail_address = $q->param('mail_address');
	my $password = $q->param('p');

	if(!defined($mail_address) || $mail_address eq ''){
		my $mail_err = jcode('入力してください')->utf8;
		return $self->tt_process('login.tt', { mail_err => $mail_err });
	}

	if(!defined($password) || $password eq ''){
	        my $pass_err = jcode('入力してください')->utf8;
	        return $self->tt_process('login.tt', { pass_err => $pass_err });
	}


	my $db = UU::DB->connect();

	my $sth = $db->prepare("SELECT entry_no FROM stodo_user_info WHERE mail_address = ? AND password = ? AND status != 99");
	$sth->bind_param(1, $mail_address);
	$sth->bind_param(2, $password);
	$sth->execute;

	if($sth->rows != 1){
		my $error_msg = jcode('ログインできませんでした。アカウントとパスワードを確認してください。')->utf8;
		$sth->finish;
		$db->disconnect;
		return $self->tt_process('login.tt', { error_msg => $error_msg });
	}
	else {
		my @rec = $sth->fetchrow_array;
		$sth->finish;
		$db->disconnect;
		my $entry_no = $rec[0];
		$session->param('entry_no' => $entry_no);
		$session->flush();
		return $self->tt_process('cp/index.tt');
	}
}

1;
