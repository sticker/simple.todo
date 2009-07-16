package UU::Add;
use strict;
use base qw (UU::App);
use Jcode;
use Data::Dumper;

sub setup {
	my $self = shift;
	$self->start_mode('add');
	$self->run_modes(
		add => 'do_add',
	);
}

sub do_add {
	my $self = shift;
	my $q = $self->query;
	my $entry_no = $q->param('no');
	my $todo = $q->param('todo');

	if(!defined($entry_no) || $entry_no eq ''){
		return $self->tt_process('system_error.tt');
	}

	if(!defined($todo) || $todo eq ''){
		return $self->tt_process('system_error.tt');
	}

	my $db = UU::DB->connect();

	my $ujis_todo = jcode($todo)->ujis;
	$ujis_todo =~ s/\t//;
	$ujis_todo =~ s/^\s+(.*?)\s+$/$1/;
	my @tlist = split(/\r\n/, $ujis_todo);
	foreach( @tlist ){
		my $t = $_;
		my $sth = $db->prepare("SELECT count(*) FROM stodo_todo_info WHERE entry_no = ?");
		$sth->bind_param(1, $entry_no);
		$sth->execute;
		my @rec = $sth->fetchrow_array;
		$sth->finish;

		$sth = $db->prepare("INSERT INTO stodo_todo_info VALUES (?,?,0,sysdate(),?,null)");
		$sth->bind_param(1, $entry_no);
		$sth->bind_param(2, $t);
		$sth->bind_param(3, $rec[0]+1);
		$sth->execute;
		my $rc = $sth->finish;
		if($rc != 1){
			$db->rollback;
			$db->disconnect;
			return $self->tt_process('system_error.tt');
		}
		$db->commit;
	}
	$db->disconnect;

	return $self->tt_process('add/add_ok.tt', { query => $q });
}

1;
