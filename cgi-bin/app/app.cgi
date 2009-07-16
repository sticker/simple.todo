#!/usr/bin/perl

use strict;
use lib qw (/project/stodo/src);
use CGI::Application::Dispatch;

CGI::Application::Dispatch->dispatch(
	prefix => 'UU',
	default => 'Index',
#	table => {
#		index => 'Index',
#		reg => 'Reg',
#		reg_comp => 'Reg::Complete',
#	},
);
