#!/usr/bin/perl

use strict;
use lib qw (/project/stodo/src);
use UU::DB;
use UU::Mail;
use UU::TodoMail;

use YAML::Tiny;
use Text::Template;
use Data::Dumper;
use File::Copy;
use IO::File;

use Mail::POP3Client;
#use MIME::Parser;
use Email::MIME;
#use Email::MIME::Attachment::Stripper;
use Email::MIME::XPath;
use Email::MIME::ContentType;

#use Image::Magick;

use Jcode;
#use Encode;
use DateTime;

my $mailset = '/project/stodo/config/mailsetting.yaml';
my $yaml = YAML::Tiny->read( $mailset );
#my $maildir = "./mail";
#my $mailbkdir = "./mail_bk";
#my $imgdir = "./img";

#my $pop = new Mail::POP3Client(%{$yaml->[0]});

#my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
#my $fmt0 = "%04d%02d%02d%02d%02d%02d";
#my $nowtime = sprintf($fmt0, $year+1900,$mon+1,$mday,$hour,$min,$sec);
#for(my $i = 1; $i <= $pop->Count; $i++){
#	my $fh = new IO::File->new;
#	$fh->open("$maildir/msg-". $nowtime . $i, "w");
#	$pop->HeadAndBodyToFile($fh, $i);
#	$fh->close;
#}

UU::Mail::receive($mailset);
my $dirset = $yaml->[0]->[2];
my $maildir = ($dirset->{maildir});
my $mailbkdir = ($dirset->{mailbkdir});
my $docrootdir = ($dirset->{docrootdir});
my $imgpath = ($dirset->{imgpath});
my $imgdir = "$docrootdir/$imgpath";
my $nowtime = DateTime->now(time_zone => 'Asia/Tokyo')->strftime('%Y%m%d%H%M%S');
my $logtime = DateTime->now(time_zone => 'Asia/Tokyo')->strftime('%Y/%m/%d %H:%M:%S');


my $db = UU::DB->connect();
opendir(DIR,$maildir);
for my $file (readdir(DIR)) {
	unless ($file eq '.' || $file eq '..') {
		my $filepath = "$maildir/$file";
		print $logtime . "====================================\n";
		print "TARGET FILE=$filepath\n";
		my $io = IO::File->new($filepath, 'r') or die $!;
		my $message;
		while(<$io>){
			$message .= $_;
		}
		#warn Dumper($message);
		my $email = Email::MIME->new($message);
		my $from = jcode($email->header('From'))->euc;
		my $subject = jcode($email->header('Subject'))->euc;
		print "from=$from\n";
		print "subject=$subject\n";

		my $sth = $db->prepare("SELECT entry_no FROM stodo_user_info WHERE (mail_address = ? OR mobile_address = ?) AND status = 1");
		$sth->bind_param(1, $from);
		$sth->bind_param(2, $from);
		$sth->execute;
		my @eno = $sth->fetchrow_array;
		$sth->finish;
		if(scalar @eno > 1){
			warn "ERROR ¥á¡¼¥ë¥¢¥É¥ì¥¹½ÅÊ£ÅÐÏ¿¤¢¤ê". scalar @eno;
			next;
		}
		my $entry_no = $eno[0];


		my $comp_flg = 0;
		if(defined($subject) && uc(substr($subject, 0, 3)) eq 'RE:'){
			$comp_flg = 1;	
		}

		my ($part) = $email->xpath_findnodes('//*[@content_type=~"^text"][1]');
		my $body = "";
		if(!defined($part)){
			print "no body message\n";
			if($comp_flg == 1){
				$sth = $db->prepare("UPDATE stodo_todo_info SET status = 1 WHERE entry_no = ? AND status = 0");
				$sth->bind_param(1, $entry_no);
				$sth->execute;
				$sth->finish;
				$db->commit;
			}


		}
		else {
			$body = jcode($part->body)->euc;
			print "body=$body\n";
			$body =~ s/\t//;
			$body =~ s/^\s+(.*?)\s+$/$1/;
			my @tlist = split(/\r\n/, $body);

			foreach( @tlist ){
				my $t = $_;

				if($comp_flg == 1){
					my $idx = index($t, '¢£');
					if($idx == -1){
						next;
					}
					else {
						print "t=$t\n";
						my $comp_todo = substr($t, $idx+2);
						print "comp_todo=$comp_todo\n";
						$sth = $db->prepare("UPDATE stodo_todo_info SET status = 1 WHERE entry_no = ? AND todo = ? AND status = 0");
						$sth->bind_param(1, $entry_no);
						$sth->bind_param(2, $comp_todo);
						$sth->execute;
						$sth->finish;
						$db->commit;
					}
				}
				else {
					my $next_todo_no = UU::DB::next_todo_no($db, $entry_no);

					$sth = $db->prepare("INSERT INTO stodo_todo_info VALUES (?,?,0,sysdate(),?,null)");
					$sth->bind_param(1, $entry_no);
					$sth->bind_param(2, $t);
					$sth->bind_param(3, $next_todo_no);
					$sth->execute;
					my $rc = $sth->finish;
					if($rc != 1){
						$db->rollback;
						warn "ERROR TODOÅÐÏ¿¼ºÇÔ";
						next;
					}
					$db->commit;
				}
			}
		}



		my @parts = $email->xpath_findnodes('//*[@content_type=~"^image/"]');
		my $att_num = @parts;

		for (my $i = 0; $i < $att_num; $i++){
			my $fh = IO::File->new;
			#my $att_fname = "$imgdir/". $parts[$i]->{ct}->{attributes}->{name};
			my $att_fname = "$entry_no-$nowtime-$i-". $parts[$i]->{ct}->{attributes}->{name};
			$fh->open("$imgdir/$att_fname","w");
			print $fh $parts[$i]->body;
			$fh->close;

			my $next_todo_no = UU::DB::next_todo_no($db, $entry_no);
			$sth = $db->prepare("INSERT INTO stodo_todo_info VALUES (?,?,0,sysdate(),?,?)");
			$sth->bind_param(1, $entry_no);
			$sth->bind_param(2, "[²èÁü]");
			$sth->bind_param(3, $next_todo_no);
			$sth->bind_param(4, "$imgpath/$att_fname");
			$sth->execute;
			my $rc = $sth->finish;
			if($rc != 1){
				$db->rollback;
				warn "ERROR TODOÅÐÏ¿¼ºÇÔ";
				next;
			}
			$db->commit;

		}





		if($subject eq '' && $body eq '' && $att_num == 0){
			UU::TodoMail::get_todo($from, $docrootdir);
		}



		move $filepath, "$mailbkdir/$file" or die $!; 
	}
}
closedir(DIR);
$db->disconnect;

#$pop->Close;

exit;
