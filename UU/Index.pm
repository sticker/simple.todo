package UU::Index;
use strict;
use base qw (UU::App);

sub setup {
	my $self = shift;
	$self->start_mode('index');
	$self->run_modes(
		index => 'do_index',
	);
}



sub do_index {
	my $self = shift;
	my $q = $self->query;
	$self->tt_process('index.tt', { query => $q });
}

1;
