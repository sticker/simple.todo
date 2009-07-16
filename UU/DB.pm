package UU::DB;
use strict;
use Data::Dumper;
use DBI;

sub connect {
	my $ds = 'DBI:mysql:dev;host=127.0.0.1;port=/tmp/mysql.sock';
        my $user = 'dev_user';
        my $pass = 'dev';
        my $db = DBI->connect($ds,$user,$pass) || die "Got error $DBI::errstr when connecting to $ds\n";
	$db->{AutoCommit} = 0;
	$db->{RaiseError} = 1;
	$db;
}

sub entry_no_gen {
	my $prefix = shift @_;

	(my $mday,my $mon,my $year) = (localtime(time))[3..5];
	$year += 1900;
	$mon += 1;

	my @chars;
	push @chars,('a'..'z');
	push @chars,('A'..'Z');
	push @chars,('0'..'9');

	my $entry_no = '';
	$entry_no .= $prefix.$year.$mon.$mday;
	$entry_no .= $chars[int(rand($#chars+1))] for(1..6);
	$entry_no;
}

sub next_todo_no {
	my $db = $_[0];
	my $entry_no = $_[1];

	my $sth = $db->prepare("SELECT count(*) FROM stodo_todo_info WHERE entry_no = ?");
	$sth->bind_param(1, $entry_no);
	$sth->execute;
	my @rec = $sth->fetchrow_array;
	$sth->finish;
	return $rec[0]+1;
}


#print "entry_no:".entry_no_gen('abc')."\n";


1;
