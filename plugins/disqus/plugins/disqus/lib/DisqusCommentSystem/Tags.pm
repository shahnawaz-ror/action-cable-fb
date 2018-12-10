package DisqusCommentSystem::Tags;

use strict;

use DisqusCommentSystem;

use MT::Template::Context;
use MT::Template::ContextHandlers;
use MT::Util qw ( encode_php );

# if_disqus_enabled
#   Returns the forum URL if disqus is enabled in the specific context,
#   otherwise nothing is returned.
sub is_disqus_enabled {
    my $ctx = shift;
    my $blog = $ctx->stash('blog');
    my $entry = $ctx->stash('entry');
    my $preview_template;
    my $plugin = MT->component('DisqusCommentSystem');

    my $config = $plugin->get_config_hash('blog:'.$blog->id);
    my $disqus_forum_url = $config->{disqus_forum_url};
    my $disqus_replace = $config->{disqus_replace};

    if (!$entry) { return; }
    eval { $preview_template = $ctx->var('preview_template'); };
    if ($preview_template) { return; }

    if ($disqus_replace eq 'empty' && $entry->comment_count > 0) {
        return;
    } elsif ($disqus_replace eq 'closed' && $entry->allow_comments) {
        return;
    }
    return $disqus_forum_url;
}

sub _if_comment_not_synced_from_disqus {
    my ($ctx, $args, $cond) = @_;
    my $comment = $ctx->stash('comment');
    my $not_disqus = 1;
    $not_disqus = 0 if ($comment->remote_service && $comment->remote_service eq 'disqus');  # zero means comment was synced from D
    $not_disqus;
}

sub _disqus_if_comments_active {
    # HACK: This is _hdlr_if_comments_active, but since it moved in MT5, we're
    #       pulling it into our module.
    my ($ctx, $args, $cond) = @_;
    my $blog = $ctx->stash('blog');
    my $cfg = $ctx->{config};
    my $active;
    if (my $entry = $ctx->stash('entry')) {
        $active = 1 if ($blog->accepts_comments && $entry->allow_comments
                        && $cfg->AllowComments);
        $active = 1 if $entry->comment_count;
    } else {
        $active = 1 if ($blog->accepts_comments && $cfg->AllowComments);
    }
    if ($active) {
        return 1;
    } else {
        return 0;
    }
}

sub _hdlr_disqus_comment_count {
    my ($ctx, $args) = @_;
    my $entry = $ctx->stash('entry');
    my $permalink = $entry->permalink();
    my $forum_url = is_disqus_enabled($ctx);
    my $count = $entry->comment_count;
    my $count_formatted = $ctx->count_format($count, $args);
    my $plugin = MT->component('DisqusCommentSystem');
    my $blog_id = $ctx->stash('blog')->id;
    my $config = $plugin->get_config_hash('blog:'.$blog_id);
    my $replace = $config->{disqus_replace};
    if (!$forum_url || $replace eq 'manual') {
        return $count_formatted;
    }
    my $script = "<script type='text/javascript' src='@{[DisqusCommentSystem::DISQUS_URL]}/forums/$forum_url/get_num_replies_for_entry.js?url=$permalink'></script><noscript>View</noscript>";
    $count_formatted =~ s/([0-9]+|No)/$script/;
    $count_formatted;
}

sub _hdlr_builtin_comment_count {
    my ($ctx, $args, $cond) = @_;
    my $e = $ctx->stash('entry')
        or return $ctx->_no_entry_error();
    my $count = $e->comment_count;
    return $ctx->count_format($count, $args);
}

sub _hdlr_disqus_comment_count_manual {
    my ($ctx, $args) = @_;
    my $entry = $ctx->stash('entry');
    my $permalink = $entry->permalink();
    my $count = $entry->comment_count;
    my $count_formatted = $ctx->count_format($count, $args);
    my $plugin = MT->component('DisqusCommentSystem');
    my $blog_id = $ctx->stash('blog')->id;
    my $config = $plugin->get_config_hash('blog:'.$blog_id);
    my $forum_url = $config->{disqus_forum_url};
    my $script = "<script type='text/javascript' src='@{[DisqusCommentSystem::DISQUS_URL]}/forums/$forum_url/get_num_replies_for_entry.js?url=$permalink'></script><noscript>View</noscript>";
    $count_formatted =~ s/([0-9]+|No)/$script/ if $forum_url;
    $count_formatted;
}

sub _hdlr_disqus_comments {
    my ($ctx, $args) = @_;
    my $plugin = MT->component('DisqusCommentSystem');
    my $entry = $ctx->stash('entry');
    my $permalink = $entry->permalink();

    my $title = encode_php($entry->title, 'qq');
    my $text = encode_php($entry->text, 'qq');
    my $ret = "";

    my $blog_id = $ctx->stash('blog')->id;
    my $config = $plugin->get_config_hash('blog:'.$blog_id);
    my $use_api = $config->{disqus_use_api};
    my $forum_url = $config->{disqus_forum_url};
    my $disqus_partner_key = $config->{disqus_partner_key};
    my $disqus_disable_sync = $config->{disqus_disable_sync} ? 1 : 0;

    if ($use_api) {
        my $disqus_api_key = $config->{disqus_api_key};
        my $cgi_server_path = MT::Template::Context::_hdlr_cgi_server_path($ctx, $args);
        my $trackback_url = MT::Template::Context::_hdlr_entry_tb_link($ctx, $args);
        my $entry_id = $entry->id;
        my $basename = $entry->basename;
        my $entry_allow_comments = $entry->allow_comments ? 'open' : 'closed';
        my $offset = $ctx->stash('blog')->server_offset || 0;
        my $config_file = MT->instance->{cfg_file};

        $ret = <<"API";
                <link rel="stylesheet" href="@{[DisqusCommentSystem::DISQUS_URL]}/stylesheets/$forum_url/disqus.css?v=2.0" type="text/css" media="screen" />
                <?php
                class post_object {
                    var \$ID;
                    var \$guid;
                    var \$blog_id;
                }
                \$post = new post_object();
                \$post->ID = $entry_id;
                \$post->blog_id = $blog_id;
                \$post->guid = "$basename";
                \$post->comment_status = "$entry_allow_comments";

                function get_option(\$option) {
                    \$settings = array(
                        "disqus_forum_url" => "$forum_url",
                        "disqus_api_key" => "$disqus_api_key",
                        "disqus_sort" => "",
                        "disqus_partner_key" => "$disqus_partner_key",
                        "disqus_disable_sync" => "$disqus_disable_sync"
                    );
                    return \$settings[\$option];
                }
                function get_permalink() {
                  return "$permalink";
                }
                function get_the_title() {
                  return "$title";
                }
                function get_the_excerpt() {
                  return "$text";
                }
                function get_the_offset() {
                  return $offset;
                }
                function start_mt() {
                    include('$cgi_server_path/php/mt.php');
                    \$mt = new MT($blog_id, '$config_file');
                    return \$mt;
                }
                function trackback_url() {
                  return "$trackback_url";
                }

                include('$cgi_server_path/plugins/disqus/php/disqus.php');
                  include(dsq_comments_template(1));
                ?>
API
    } else {
        if ($disqus_partner_key) {
            my $cgi_path = MT::Template::Context::_hdlr_cgi_path($ctx, $args);
            my $comment_script = MT::Template::Context::_hdlr_comment_script($ctx, $args);

            $ret = <<"EOT";
                <script type="text/javascript" src="${cgi_path}${comment_script}?__mode=disqus_sso&blog_id=${blog_id}"></script>
EOT
        }

        $ret .= <<"EOT";
            <div id="comments"></div><div id="disqus_thread"></div>
            <div style="display:none;" id="disqus_post_title">$title</div>
            <div style="display:none;" id="disqus_post_message">$text</div>
            <script type="text/javascript">
                var disqus_domain = '@{[DisqusCommentSystem::DISQUS_DOMAIN]}';
                var disqus_shortname = '$forum_url';
                var disqus_url = '$permalink';
                var disqus_title = document.getElementById('disqus_post_title').innerHTML;
                var disqus_message = document.getElementById('disqus_post_message').innerHTML;
            </script>
            <script type="text/javascript" src="http://$forum_url.@{[DisqusCommentSystem::DISQUS_DOMAIN]}/embed.js"></script>
            <noscript>Please enable JavaScript to view the <a href="http://disqus.com/?ref_noscript=$forum_url">comments powered by Disqus.</a></noscript>
EOT
    }
    return $ret;
}

sub _hdlr_disqusify {
    # MT->log("start disquify");
    my ($ctx, $args, $cond) = @_;
    my $plugin = MT->component('DisqusCommentSystem');
    my $forum_url = is_disqus_enabled($ctx);
    my $blog_id = $ctx->stash('blog')->id;
    my $config = $plugin->get_config_hash('blog:'.$blog_id);
    my $replace = $config->{disqus_replace};

    # use Data::Dumper;
    # MT->log("disqus forum url is $forum_url");
    # MT->log("uncompiled is" . Dumper($ctx->stash('uncompiled')));

    # Check if no MTComments, since the tag may be used multiple times.  If
    # there does not exist an MTComments block, then do not replace.
    if (!$forum_url || !($ctx->stash('uncompiled') =~ /<MT:?Comments.*?>/i) || ($replace eq 'manual')) {
        my $active = _disqus_if_comments_active($ctx, $args, $cond);
        if ($active) {
            return MT::Template::Context::_hdlr_pass_tokens($ctx, $args, $cond);
        } else {
            return MT::Template::Context::_hdlr_pass_tokens_else($ctx, $args, $cond);
        }
    }

    # from this point forward we know Disqus should be used in this Context
       my $ret = _hdlr_disqus_comments($ctx,$args);

    if($ctx->stash('uncompiled') =~ m'<MT:?CommentsHeader>(.*)</MT:?CommentsHeader>.*<MT:?CommentsFooter>(.*)</MT:?CommentsFooter>'is) {
        my $header = $1;
        my $footer = $2;
        # Remove all MT template tags
        $header =~ s/\s*\(?<\$?MT:?.*?\$?>\)?//ig;
        $ret = $header . $ret . $footer;
    }
      # $ctx->stash('uncompiled',$ret);
    $ret;
}


1;
