package DisqusCommentSystem::Callbacks;

use strict;
use warnings;

sub list_comment {
    my ($cb, $app, $template) = @_;
    # MT->log("list comment callback started");
    my $q = $app->param;
    my $mt_view = $q->param('mt_view');
    return if $mt_view;

    my $plugin = MT->component('DisqusCommentSystem');
    my $config = $plugin->get_config_hash('blog:'.$q->param('blog_id'));

    my $disqus_forum_url = $config->{disqus_forum_url};
    my $disqus_replace = $config->{disqus_replace};
    my $disqus_api_key = $config->{disqus_api_key};

    my $iframe = qq{<iframe src="http://disqus.com/comments/moderate/$disqus_forum_url/?template=movabletype" style="width: 120%; height: 800px"></iframe>};

    if ($disqus_forum_url && $disqus_replace && $disqus_api_key) {
        my $old = qq{<\$mt:var name="list_filter_form"\$>};
        $old = quotemeta($old);
        $$template =~ s/$old//;

        $old = qq{<mt:include name="include/header.tmpl">};
        my $new = qq{<mt:var name="show_display_options_link" value="0">};
        $$template =~ s/($old)/$new$1/;

        $old = qq{<mt:include name="include/comment_table.tmpl">};
        $old = quotemeta($old);
        $$template =~ s/$old/$iframe/;

        $$template =~ s/related_content/related_content_disabled/;
        $$template =~ s/html_body_footer/html_body_footer_diabled/;
        $$template =~ s/Manage Comments/Disqus Comment System/;
    }
}


1;
