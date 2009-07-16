#!/usr/bin/perl

use strict;
use lib qw (/project/stodo/src);
use UU::DB;
use UU::Mail;

use Text::Template;
use Data::Dumper;


my $db = UU::DB->connect();
#my $sth = $db->prepare("SELECT u.mail_address, t.todo FROM stodo_user_info u, stodo_todo_info t WHERE u.entry_no = t.entry_no AND u.status = 1 AND t.status = 0");
my $sth = $db->prepare("SELECT distinct(u.entry_no) FROM stodo_user_info u ,stodo_todo_info t WHERE u.status = 1 AND t.status = 0");
$sth->execute;
my $tbl_ary_ref = $sth->fetchall_arrayref;
$sth->finish;

warn Dumper($tbl_ary_ref);
foreach my $rec ( @$tbl_ary_ref ) {
	my $entry_no = $rec->[0];
	$sth = $db->prepare("SELECT mail_address,mobile_address FROM stodo_user_info WHERE entry_no = ? AND status = 1");
	$sth->bind_param(1, $entry_no);
	$sth->execute;
	my $mail_address = $sth->fetch->[0]; 
	my $mobile_address = $sth->fetch->[1]; 
	$sth->finish;

	warn Dumper($mail_address);
	warn Dumper($mobile_address);

	$sth = $db->prepare("SELECT todo FROM stodo_todo_info WHERE entry_no = ? AND status = 0 ORDER BY todo_no");
	$sth->bind_param(1, $entry_no);
	$sth->execute;
	my $todo_ref = $sth->fetchall_arrayref;
	$sth->finish;

	warn Dumper($todo_ref);

	my $body = "";
	foreach my $t ( @$todo_ref ){
		warn Dumper($t->[0]);
		$body .= "■" . $t->[0] . "\n";
		warn Dumper($body);
	}

	UU::Mail::send('simple.todo.info@gmail.com',$mail_address,'[Simple TODO]リマインダ',$body);
	UU::Mail::send('simple.todo.info@gmail.com',$mobile_address,'[Simple TODO]リマインダ',$body);
}


$db->disconnect;
