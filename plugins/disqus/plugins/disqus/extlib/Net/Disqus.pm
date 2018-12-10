package Net::Disqus;

use warnings;
use strict;

=head1 NAME

Net::Disqus - Perl interface to Disqus.com API

=cut

our $VERSION = '0.50';

use Encode;
use File::Spec;
use HTTP::Request::Common;
use LWP::UserAgent;
use MIME::Base64 qw/encode_base64/;
use URI::Escape;

use base qw(Class::Accessor);
Net::Disqus->mk_accessors(qw/user password credentials user_api_key forum_api_key short_name import_api ua return_feeds_as
    last_error/);

our $DISQUS_API_URL = 'http://disqus.com/';
our $DISQUS_IMPORTER_URL = 'http://import.disqus.com/';

our $Last_Http_Response;

=head1 SYNOPSIS

=cut

=head1 GENERAL FUNCTIONS

=head2 new(\%opts)

=cut

=head2 last_error()

=cut

sub new {
    my ($proto, $fields) = @_;
    my $class = ref $proto || $proto;

    $fields = {} unless defined $fields;

    my $self = { %$fields };

    $self->{return_feeds_as} ||= 'structure';

    # make a copy of $fields.
    bless $self, $class;
}


sub _connect {
    my $self = shift;

    unless ($self->ua) {
        $self->ua(new LWP::UserAgent)
            or die;
        push @{ $self->ua->requests_redirectable }, 'POST';
    }
}

sub _has_auth {
    my $self = shift;

    return ($self->user && $self->password) || $self->credentials;
}

=head2 validate()

Validates the current combination of login and remotekey.

=cut

sub validate {
    my $self = shift;
    $self->_http_req('GET', 'validate', 'need auth');
}

sub _api_url {
    my $self = shift;
    my $uri = shift;
    if ($self->import_api) {
        return $DISQUS_IMPORTER_URL . $uri;
    } else {
        return $DISQUS_API_URL . $uri;
    }
}

sub _http_req {
    my ($self, $method, $uri, $needauth, @args) = @_;
    # use Data::Dumper;

    $self->_connect();

    my ($needs_parsing, $format) = ($self->return_feeds_as eq 'structure', $self->return_feeds_as);
    $format = 'json' if $needs_parsing;

    my $req;
    if ($method eq 'GET') {
        my $get_uri = URI->new($self->_api_url($uri));
        $get_uri->query_form(response_type => $format) unless $format eq 'json';
        $get_uri->query_form(@args) if @args;

        $req = GET $get_uri->as_string;
    }
    else { # $method eq 'POST'
        my $post_uri = URI->new($self->_api_url($uri));
        # MT->log("args is: " . Dumper(\@args));
        $req = POST $post_uri, # [ credentials => $credentials ];
                @args;
        # MT->log("req is:" . Dumper($req));
    }


    if ($Last_Http_Response = $self->ua->request($req)) {
        # MT->log("reponse is:" . Dumper($Last_Http_Response));
        # MT->log("content is:" . Dumper($Last_Http_Response->content));
        # MT->log("success is:" . Dumper($Last_Http_Response->is_success));
        unless ($Last_Http_Response->is_success) {
            require JSON;       # should die if absent
            JSON->VERSION(2.0); # we need newer JSON
            # do some JSON magic
            $self->last_error(
                JSON::from_json($Last_Http_Response->content, { utf8 => 1})->{err}->{code}
            );
            return;
        }
    }
    else {
        $self->last_error('failed-req');
        return;
    }

    if ($needs_parsing) {
        require JSON;       # should die if absent
        JSON->VERSION(2.0); # we need newer JSON
        # do some JSON magic
        return JSON::from_json($Last_Http_Response->content, { utf8 => 1});
    }
    else {
        return $Last_Http_Response->content;
    }
}

sub _fetch_feed {
    my $self = shift;
    my $uri = shift;

    $self->_http_req('GET', $uri, undef, @_);
}

sub _post {
    my $self = shift;
    my $uri = shift;

    $self->_http_req('POST', $uri, 'need auth', @_);
}

sub get_forum_list {
    my $self = shift;
    my $credentials = $self->credentials;
    if ($self->_has_auth && !$credentials) {
        $credentials = encode_base64($self->user . ':' . $self->password, q{});
    }
    my @args = ();
    push @args, 'credentials' => $credentials;
    $self->_post('api/v2/get_forum_list/', Content => \@args);
}

sub get_forum_api_key {
    my $self = shift;
    my ($short_name) = @_;
    my $credentials = $self->credentials;
    if ($self->_has_auth && !$credentials) {
        $credentials = encode_base64($self->user . ':' . $self->password, q{});
    }
    my @args = ();
    push @args, 'short_name' => $short_name;
    push @args, 'credentials' => $credentials;

    $self->_post('api/v2/get_forum_api_key/',  Content => \@args);
}

sub get_thread {
    my $self = shift;

    $self->_post('api/v2/get_thread/', @_);
}

sub import_comments {
    my $self = shift;
    my ($filename, $platform) = @_;
    my $multipart = 1;

    my @args = ();
    push @args, (forum_api_key => $self->forum_api_key);
    push @args, (forum_url => $self->short_name);
    push @args, ('file' => ["$filename"]);
    push @args, (response_type => 'json_simple');
    push @args, (platform => $platform);

    $self->_post('api/import-raw-comments/', Content => \@args, Content_Type => 'form-data');
}

sub get_import_status {
    my $self = shift;
    my ($last_import_id) = @_;

    my @args = ();
    push @args, (forum_api_key => $self->forum_api_key);
    push @args, (forum_url => $self->short_name);
    push @args, (import_id => $last_import_id);
    push @args, (response_type => 'json_simple');

    $self->_post('api/get-import-status/',  Content => \@args);
}

1; # End of Net::Disqus
