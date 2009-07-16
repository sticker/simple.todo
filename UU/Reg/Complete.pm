package UU::Reg::Complete;
use strict;
use base qw (UU::App);


sub setup {
	my $self = shift;
	$self->start_mode('reg_comp');
	$self->run_modes(
		reg_comp => 'do_regcomp',
	);
}

sub do_regcomp {
	my $self = shift;
	my $q = $self->query;
	my $entry_no = $q->param('no');

	if(!defined($entry_no) || $entry_no eq ''){
		return $self->tt_process('reg/reg_ng.tt');
	}

	my $db = UU::DB->connect();
	my $sth = $db->prepare("SELECT entry_no FROM stodo_user_info WHERE entry_no = ? AND status = 1 AND complete_date is not null");
	$sth->bind_param(1, $entry_no);
	$sth->execute;
	$sth->finish;
	if($sth->rows == 1){
		$db->disconnect;
		return $self->tt_process('reg/reg_complete.tt', { entry_no => $entry_no });
	}

	$sth = $db->prepare("UPDATE stodo_user_info SET status = 1, complete_date = sysdate() WHERE entry_no = ? AND status = 0 AND complete_date is null");
	$sth->bind_param(1,$entry_no);
	my $result = $sth->execute;
	$sth->finish;

	if($result != 1){
		$db->rollback;
		$db->disconnect;
		return $self->tt_process('reg/reg_ng.tt');
	}

	$db->commit;
	$db->disconnect;
	return $self->tt_process('reg/reg_complete.tt', { entry_no => $entry_no });
}

1;
