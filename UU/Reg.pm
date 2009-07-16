package UU::Reg;
use strict;
use base qw (UU::App);
use Jcode;

sub setup {
	my $self = shift;
	$self->start_mode('reg');
	$self->run_modes(
		reg => 'do_reg',
	);
}

sub do_reg {
	my $self = shift;
	my $q = $self->query;
	my $mail_address = $q->param('mail_address');
	my $mobile_address = $q->param('mobile_address');
	my $password = $q->param('p');

	if(!defined($mail_address) || $mail_address eq ''){
		my $mail_err = jcode('入力してください')->utf8;
		return $self->tt_process('index.tt', { mail_err => $mail_err });
	}
	if(!defined($mobile_address) || $mobile_address eq ''){
		my $mb_err = jcode('入力してください')->utf8;
		return $self->tt_process('index.tt', { mb_err => $mb_err });
	}

	if(!defined($password) || $password eq ''){
		my $pass_err = jcode('入力してください')->utf8;
		return $self->tt_process('index.tt', { pass_err => $pass_err });
	}


	my $entry_no = &UU::DB::entry_no_gen("std");

	my $db = UU::DB->connect();
	my $sth = $db->prepare("SELECT entry_no FROM stodo_user_info WHERE (mail_address = ? OR mobile_address = ?) AND status != 99");
	$sth->bind_param(1,$mail_address);
	$sth->bind_param(1,$mobile_address);
	$sth->execute;
	if($sth->rows > 0){
		my $error_msg = jcode('すでに登録されているアドレスです')->utf8;
		$sth->finish;
		$db->rollback;
		$db->disconnect;
		return $self->tt_process('index.tt', { error_msg => $error_msg });
	}

	my $agent = $ENV{'HTTP_USER_AGENT'};
	my $guid = '';
	if($agent =~ /^DoCoMo/){
		$guid = $ENV{'HTTP_X_DCMGUID'};
	}

	$sth = $db->prepare("INSERT INTO stodo_user_info VALUES (?,?,0,sysdate(),0,null,?,?,?)");
	$sth->bind_param(1, $entry_no);
	$sth->bind_param(2, $mail_address);
	$sth->bind_param(3, $password);
	$sth->bind_param(4, $guid);
	$sth->bind_param(5, $mobile_address);
	$sth->execute;
	my $rc = $sth->finish;
	if($rc != 1){
		$db->rollback;
		$db->disconnect;
		return $self->tt_process('system_error.tt');
	}
	$db->commit;
	$rc = $db->disconnect;

	my %body_data = (
		account => $mail_address,
		entry_no => $entry_no
	);

	my $mailtmp = Text::Template->new(SOURCE => '/project/stodo/mailtmp/RegMail.tpl');
	my $body = $mailtmp->fill_in(HASH => \%body_data) || warn "Couldn't fill in template: $Text::Template::ERROR";
	#warn "body=["."$body]";
	UU::Mail::send('simple.todo.info@gmail.com',$mail_address,'[Simple TODO]仮登録されました', $body);
	UU::Mail::send('simple.todo.info@gmail.com',$mobile_address,'[Simple TODO]仮登録されました', $body);

	return $self->tt_process('reg/reg_confirm.tt', { query => $q });
}

1;
