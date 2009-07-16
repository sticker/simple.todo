package UU::Cp::List;
use strict;
use base qw (UU::App);
use CGI::Session qw(-ip_match);
use CGI::Application::Plugin::Session;
use Jcode;
use Data::Dumper;

sub setup {
	my $self = shift;
	$self->start_mode('cp_list');
	$self->run_modes(
		cp_list => 'do_cplist',
	);
}

sub do_cplist {
	my $self = shift;
	my $session = $self->session;

	my $cgi = CGI->new;
	my $sid = $cgi->cookie('CGISESSID')||$cgi->param('CGISESSID')||undef;
	if ( !defined $sid || $sid ne $session->id ) {
		if( !defined $session->param('entry_no') ){
			return $self->tt_process('login.tt');
		}
	}



	my $q = $self->query;

	my $entry_no = $session->param('entry_no');
	my @comp_todo_no = $q->param('comp_todo_no');
	my $insert_todo = jcode($q->param('insert_todo'))->ujis;
	my $db = UU::DB->connect();
	my $sth;

	#warn Dumper(@comp_todo_no);
	foreach(@comp_todo_no) {
		my $t = $_;
		$sth = $db->prepare("UPDATE stodo_todo_info SET status = 1 WHERE entry_no = ? AND todo_no = ?");
		$sth->bind_param(1, $entry_no);
		$sth->bind_param(2, $t);
		$sth->execute;;
		$sth->finish;
		$db->commit;
	}

	if( defined $insert_todo && $insert_todo ne ""){
		$sth = $db->prepare("SELECT count(*) FROM stodo_todo_info WHERE entry_no = ?");
		$sth->bind_param(1, $entry_no);
		$sth->execute;
		my @rec = $sth->fetchrow_array;
		$sth->finish;

		$sth = $db->prepare("INSERT INTO stodo_todo_info VALUES (?,?,0,sysdate(),?,null)");
		$sth->bind_param(1, $entry_no);
		$sth->bind_param(2, $insert_todo);
		$sth->bind_param(3, $rec[0]+1);
		$sth->execute;
		$sth->finish;
		$db->commit;
	}

	#$sth = $db->prepare("SELECT todo,status,created_date,todo_no,file_path FROM stodo_todo_info WHERE entry_no = ? AND status != 99 order by todo_no");
	$sth = $db->prepare("SELECT todo,status,created_date,todo_no,file_path FROM stodo_todo_info WHERE entry_no = ? AND status = 0 order by todo_no");
	$sth->bind_param(1, $entry_no);
	$sth->execute;
	#my @todo_ary = ();
	#while ( my $tbl_ary_ref = $sth->fetchrow_arrayref ){
	#	my ($t, $status, $todo_no) = @$tbl_ary_ref;
	#	my @ary = (jcode($t)->utf8, $status, $todo_no);
	#	push(@todo_ary, @ary);
	#}
	#warn Dumper(@todo_ary);

	my $tbl_ary_ref = $sth->fetchall_arrayref; 
	#warn Dumper($tbl_ary_ref);

	#for(my $i = 0; $i < $tbl_ary_ref->[0]; $i++){
	foreach my $each (@$tbl_ary_ref) {
		$each->[0] = jcode($each->[0])->utf8;
	}

	$sth->finish;
	$db->disconnect;


	return $self->tt_process('cp/list.tt', { todo => $tbl_ary_ref, entry_no => $entry_no });
}

1;
