package UU::Mail;
use strict;
use warnings;
use Data::Dumper;

use Jcode;
use Net::SMTP;
use Net::SMTP::SSL;

use Mail::POP3Client;
use MIME::Entity;
use Email::MIME::ContentType;

use YAML::Tiny;

use DateTime;

sub send {
	my ($from, $to, $subject, $body, @file_path) = @_;
	my $mailset = '/project/stodo/config/mailsetting.yaml';
	my $yaml = YAML::Tiny->read( $mailset );
	my $dirset = $yaml->[0]->[1];
	my $smtp_server = ($dirset->{smtp_server});
	my $smtp_port = ($dirset->{smtp_port});
	my $smtp_acc = ($dirset->{smtp_acc});
	my $smtp_pwd = ($dirset->{smtp_pwd});


	$subject = jcode($subject)->jis;
	$subject = jcode($subject)->mime_encode;
	$to = jcode($to)->jis;
	$to = jcode($to)->mime_encode;
	$from = jcode($from)->jis;
	$from = jcode($from)->mime_encode;
	$body = jcode($body)->jis;

	my $err;
	my $oSmtp;
	my $oMime;

	if (not $oSmtp = Net::SMTP::SSL->new(Host => $smtp_server, Port => $smtp_port, Debug => 0)) {
		die "Could not connect to server\n";
	}

	if($oSmtp->auth($smtp_acc,$smtp_pwd)){
		$oSmtp->mail($from . "\n");
		my @recepients = split(/,/, $to);
		foreach my $recp (@recepients) {
			$oSmtp->to($recp . "\n");
		}

		$oSmtp->data();

		$oMime = MIME::Entity->build(
			From => $from,
			To => $to,
			Subject => $subject,
			Data => $body
		);

		foreach my $fpath (@file_path) {
			my @fname_split = split(/-/, $fpath);
			my $file_name = $fname_split[3];
			print "file_name=$file_name\n";
			my $ext = substr($file_name, rindex($file_name,'.')+1);
			my $type = "images/";
			if($ext eq 'jpg'){
				$type .= 'jpeg';
			}
			else {
				$type .= $ext;
			}

			print "fpath=$fpath\n";
			print "type=$type\n";
			$oMime->attach(
				Path => $fpath,
				Type => $type,
				Encoding => "Base64"
			);
		}

		$oSmtp->datasend($oMime->stringify);
		$oSmtp->dataend();
		$oSmtp->quit;
	} else {
		$err = 'SMTP Server Authentication Error!!'
	}
}

sub receive {
	my $yaml_file = shift;
	my $yaml = YAML::Tiny->read( $yaml_file );
	my $dirset = $yaml->[0]->[2];
	my $maildir = ($dirset->{maildir});
	my $nowtime = DateTime->now(time_zone => 'Asia/Tokyo')->strftime('%Y%m%d%H%M%S');

	my $pop = new Mail::POP3Client(%{$yaml->[0]->[0]});
	for(my $i = 1; $i <= $pop->Count; $i++){
	        my $fh = new IO::File->new;
	        $fh->open("$maildir/mail-". $nowtime . "-" . $i, "w");
	        $pop->HeadAndBodyToFile($fh, $i);
	        $fh->close;
	}

	$pop->Close;
}

sub Email::MIME::super_decoded_body {
	my $self = shift;
	my $ct = parse_content_type($self->content_type);
	my $charset = $ct->{attributes}->{charset};
	return decode($charset, $self->body);
}

1;
