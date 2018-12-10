package DisqusCommentSystem::App::Comments;

use strict;
use warnings;

use MIME::Base64 qw/encode_base64/;

sub disqus_sso {
    use Digest::HMAC_SHA1 qw(hmac_sha1_hex);
    use JSON qw(to_json);

    my $app = shift;
    my $q = $app->param;
    my $plugin = MT->component('DisqusCommentSystem');
    my $scope = 'blog:' . $q->param('blog_id');
    my $config = $plugin->get_config_hash($scope);
    my $partner_key = $config->{disqus_partner_key};
    my $remote_auth;

    if ( !$partner_key ) {
        return "// Disqus SSO is not configured.";
    }

    my ($_unused, $author) = $app->_get_commenter_session();
    if ( !$author ) {
        my ($username, $sessionid, $remember) = split( /::/, $app->cookie_val($app->user_cookie) );
        my $session = MT::Session->load({ id => $sessionid, kind => 'US' });
        $author = MT::Author->load($session->get('author_id')) if $session and $session->get('author_id');
    }

    if ( $author ){
        my $avatar_url = '';
        if ( $author->userpic ) {
            $avatar_url = $author->userpic_url() || '';
            my $blog = ($author->userpic->blog || MT::Blog->load($q->param('blog_id')));
            my $domain = '';

            if ( $blog ) {
                ($domain) = $blog->archive_url =~ m|(.+://[^/]+)|;
            }
            if ( substr($avatar_url, 0, 1) eq '/' ) {
                $avatar_url = $domain . $avatar_url;
            }
        }

        $remote_auth = to_json({
            'username' => $author->nickname,
            'id' => $author->id,
            'email' => $author->email,
            'url' => $author->url,
            'avatar' => $avatar_url
        });
    } else {
        $remote_auth = to_json({});
    }

    $remote_auth = encode_base64($remote_auth, '');
    my $remote_auth_ts = time();
    my $remote_auth_hmac = "$remote_auth $remote_auth_ts";
    $remote_auth_hmac = hmac_sha1_hex($remote_auth_hmac, $partner_key);
    "var disqus_remote_auth_s2 = '$remote_auth $remote_auth_hmac $remote_auth_ts';";
}

1;
