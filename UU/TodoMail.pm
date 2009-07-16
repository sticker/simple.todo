package UU::TodoMail;
use strict;
use warnings;
use Data::Dumper;
use lib qw (/project/stodo/src);
use UU::DB;
use UU::Mail;

sub get_todo {
	my ($address, $docrootdir) = @_;
	my $db = UU::DB->connect();
	my $sth = $db->prepare("SELECT todo FROM stodo_todo_info WHERE entry_no = (SELECT entry_no FROM stodo_user_info WHERE (mail_address = ? OR mobile_address = ?) AND status = 1 ) AND status = 0 AND file_path is null");
	$sth->bind_param(1, $address);
	$sth->bind_param(2, $address);
	$sth->execute;
	my $todo_ref = $sth->fetchall_arrayref;
	$sth->finish;

	my $body = "";
	foreach my $t ( @$todo_ref ){
		$body .= "■" . $t->[0] . "\n";
	}


	$sth = $db->prepare("SELECT file_path FROM stodo_todo_info WHERE entry_no = (SELECT entry_no FROM stodo_user_info WHERE (mail_address = ? OR mobile_address = ?) AND status = 1 ) AND status = 0 AND file_path is not null");
	$sth->bind_param(1, $address);
	$sth->bind_param(2, $address);
	$sth->execute;
	my $fpath_ref = $sth->fetchall_arrayref;
	$sth->finish;
	$db->disconnect;

	my @file_path;
	foreach my $fpath (@$fpath_ref) {
		push(@file_path, "$docrootdir/$fpath->[0]");
	}

	UU::Mail::send('simple.todo.info@gmail.com',$address,'[Simple TODO]TODO取得結果',$body, @file_path);

}

1;
