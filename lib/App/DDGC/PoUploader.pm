package App::DDGC::PoUploader;
BEGIN {
  $App::DDGC::PoUploader::AUTHORITY = 'cpan:GETTY';
}
{
  $App::DDGC::PoUploader::VERSION = '0.001';
}
# ABSTRACT: Command-line tool for uploading .po files to the DuckDuckGo Community Platform

use Moo;
use MooX::Options flavour => [qw( pass_through )], protect_argv => 0;
use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use Path::Class;

our $VERSION ||= '0.000';

option user => (
	format => 's',
	is => 'ro',
	required => 1,
);

option pass => (
	format => 's',
	is => 'ro',
	required => 1,
);

option domain => (
	is => 'ro',
	format => 's',
	predicate => 1,
);

option upload_uri => (
	is => 'ro',
	format => 's',
	lazy => 1,
	builder => 1,
);

sub _build_upload_uri { 'https://dukgo.com/translate/po_upload' }

option agent_string => (
	is => 'ro',
	format => 's',
	lazy => 1,
	builder => 1,
);

sub _build_agent_string {
	my ($self) = @_;
	my $class   = ref $self || $self;
	my $version = $class->VERSION; 
	return "$class/$version";
}

has _user_agent => (
	is => 'ro',
	builder => 1,
	lazy => 1,
);

sub _build__user_agent {
	my ( $self ) = @_;
	my $ua = LWP::UserAgent->new;
	$ua->agent($self->agent_string);
	$ua->env_proxy;
	return $ua;
}

sub get_request {
	my ( $self, $file ) = @_;
	my $req = POST(
		$self->upload_uri,
		Content_Type => 'form-data',
		Content => {
			CAN_MULTIPART => 1,
			HIDDENNAME => $self->user,
			po_upload => [ $file ],
			$self->has_domain ? ( token_domain => $self->domain ) : (),
		},
	);
	$req->authorization_basic($self->user, $self->pass);
	return $req;
}

sub upload_extra_argv {
	my ( $self ) = @_;
	for (@ARGV) {
		$self->upload($_);
	}
}

sub upload {
	my ( $self, $file ) = @_;
	die "File not found" unless -f $file;
	my $response = $self->_user_agent->request($self->get_request($file));
	die "Error: ".$response->code if $response->is_error || $response->is_redirect;
}

1;

__END__
=pod

=head1 NAME

App::DDGC::PoUploader - Command-line tool for uploading .po files to the DuckDuckGo Community Platform

=head1 VERSION

version 0.001

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

