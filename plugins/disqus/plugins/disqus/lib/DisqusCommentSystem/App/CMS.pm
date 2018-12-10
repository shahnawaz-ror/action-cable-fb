package DisqusCommentSystem::App::CMS;

use strict;
use warnings;

use MIME::Base64 qw/encode_base64/;
use MT::Util qw( dirify );

sub template {
    my $app = MT->instance->app;
    my $q = $app->param();
    my $blog_id = $q->param('blog_id');
    my $plugin = MT->component('DisqusCommentSystem');
    my $scope = 'blog:'.$blog_id;
    my $config = $plugin->get_config_hash($scope);
    my $status = '';
    my $start;
    my $finish;
    if ($config->{disqus_last_import_id} && !$config->{disqus_import_finished}) {
        ($status, $start, $finish) = _check_import_status($config);
        $plugin->set_config_value('disqus_import_started', $start, $scope) if $start;
        $plugin->set_config_value('disqus_import_finished', $finish, $scope) if $finish;
    }
    my $tmpl = <<EOT;
    <script type="text/javascript">
    function dsqOpenDialog(mode, params) {
        if (window.openDialog) {
            return openDialog(false, mode, params);
        }
        else {
            return jQuery.fn.mtDialog.open('?__mode=' + mode + '&' + params);
        }
    }
    </script>
    <mt:var name="blog_id" value="$blog_id">
    <mt:var name="import_status" value="$status">
    <mt:if name="disqus_api_key">

        <mtapp:setting
            id="forum_url"
            label="<__trans phrase="DISQUS Forum URL">"
            label_class="top-label"
            hint="<__trans phrase="Enter your DISQUS site shortname.">"
            show_hint="0">
                   <input type="text" name="disqus_forum_url" id="disqus_forum_url" value="<TMPL_VAR NAME=DISQUS_FORUM_URL>">
                   <strong>.disqus.com</strong>
        </mtapp:setting>

        <mtapp:setting
            id="forum_api_key"
            label="<__trans phrase="DISQUS API Key">"
            label_class="top-label"
            hint="<__trans phrase="This is set for you when going through the installation steps.">"
            show_hint="1">
                   <input type="text" name="disqus_api_key" id="disqus_api_key" value="<TMPL_VAR NAME=DISQUS_API_KEY>">
        </mtapp:setting>

        <mtapp:setting
            id="partner_key"
            label="<__trans phrase="DISQUS Partner Key">"
            label_class="top-label"
            hint="<__trans phrase="Advanced: Used for single sign-on (SSO) integration.">"
            show_hint="1">
                   <input type="text" name="disqus_partner_key" id="disqus_partner_key" value="<TMPL_VAR NAME=DISQUS_PARTNER_KEY>">
        </mtapp:setting>

        <mtapp:setting
            id="replace"
            label="<__trans phrase="Use DISQUS on">"
            label_class="top-label"
            hint="<__trans phrase="NOTE: Your Movable Type comments will never be lost. ">"
            show_hint="1">
                   <input type="radio" name="disqus_replace" id="disqus_replace_all" value="all" <TMPL_IF NAME=DISQUS_REPLACE_ALL>checked="checked"</TMPL_IF>>&nbsp;Replace comments on all posts <br />
                   <input type="radio" name="disqus_replace" id="disqus_replace_empty" value="empty" <TMPL_IF NAME=DISQUS_REPLACE_EMPTY>checked="checked"</TMPL_IF>>&nbsp;Replace all entries with no comments (including future posts) <br />
                   <input type="radio" name="disqus_replace" id="disqus_replace_closed" value="closed" <TMPL_IF NAME=DISQUS_REPLACE_CLOSED>checked="checked"</TMPL_IF>>&nbsp;Replace comments only on entries with closed comments. <br />
                   <input type="radio" name="disqus_replace" id="disqus_replace_manual" value="manual" <TMPL_IF NAME=DISQUS_REPLACE_MANUAL>checked="checked"</TMPL_IF>>&nbsp;(Advanced) Comments will not be auto-replaced, you need to manually add a &lt;mt:DisqusComments&gt; tag to your templates.
        </mtapp:setting>

        <mtapp:setting
            id="use_api"
            label="<__trans phrase="Use API Method">"
            label_class="top-label"
            hint="<__trans phrase="This option requires that your published pages support PHP rendering. Comments will be rendered (via PHP) into the HTML output at page-load time (Good for SEO).">"
            show_hint="1">
                   <input type="checkbox" name="disqus_use_api" id="disqus_use_api" value="1" <TMPL_IF NAME=DISQUS_USE_API>checked="checked"</TMPL_IF>>
        </mtapp:setting>

        <mtapp:setting
            id="disable_sync"
            label="<__trans phrase="Disable comment syncing">"
            label_class="top-label"
            hint="<__trans phrase="This option only applies if &quot;Use API Method&quot; is checked.  This disables syncing comments to the local database.">"
            show_hint="1">
                   <input type="checkbox" name="disqus_disable_sync" id="disqus_disable_sync" value="1" <TMPL_IF NAME=DISQUS_DISABLE_SYNC>checked="checked"</TMPL_IF>>
        </mtapp:setting>

        <mtapp:setting
            id="export_to_disqus"
            label="<__trans phrase="Import comments into DISQUS">"
            hint="This will sync your Movable Type comments with DISQUS "
            class="actions-bar"
            show_hint="1">

            <div class="actions-bar-inner pkg actions">
                <a href="javascript:void(0)" onclick="<mt:if name="disqus_last_import_id">if (confirm('You\\'ve already imported your comments.  Are you sure you want to do this again?')) </mt:if>return dsqOpenDialog('export_to_disqus', 'blog_id=$blog_id&amp;return_args=__mode%3Dcfg_plugins%26%26blog_id%3D$blog_id')" class="primary-button"><__trans phrase="Import"></a>
            </div>
            <mt:if name="disqus_last_import_id"><p><strong>Import Status:</strong>
                  <mt:if name="disqus_import_finished">Finished at <mt:var name="disqus_import_finished">
                <mt:else name="disqus_import_started">Started at <mt:var name="disqus_import_started">
                <mt:else><mt:var name="import_status" _default="Pending">
                </mt:if>
                </p>
            </mt:if>
        </mtapp:setting>

        <mtapp:setting
            id="uninstall_disqus"
            label="<__trans phrase="Uninstall DISQUS">"
            hint=""
            class="actions-bar"
            show_hint="0">

            <div class="actions-bar-inner pkg actions">
                <a href="javascript:void(0)" onclick="if(confirm('Are you sure you want to uninstall DISQUS for this blog?')) return dsqOpenDialog('uninstall_disqus', 'blog_id=$blog_id&amp;return_args=__mode%3Dcfg_plugins%26%26blog_id%3D$blog_id')" class="primary-button"><__trans phrase="Uninstall DISQUS"></a>
            </div>
        </mtapp:setting>

    <mt:else>

    <mtapp:setting
        id="install_disqus"
        label="<__trans phrase="Install DISQUS">"
        hint=""
        class="actions-bar"
        show_hint="0">

        <div class="actions-bar-inner pkg actions">
            <a href="javascript:void(0)" onclick="return dsqOpenDialog('install_disqus', 'blog_id=$blog_id&amp;return_args=__mode%3Dcfg_plugins%26%26blog_id%3D$blog_id')" class="primary-button"><__trans phrase="Install DISQUS"></a>
        </div>
    </mtapp:setting>

    </mt:if>
EOT
}

sub _check_import_status {
    my ($config) = @_;
    my $forum_key = $config->{disqus_api_key};
    my $short_name = $config->{disqus_forum_url};
    my $last_import_id = $config->{disqus_last_import_id};
    use Net::Disqus;
    my $dq = Net::Disqus->new({ forum_api_key => $forum_key, short_name => $short_name, import_api => 1 });
    my $response = $dq->get_import_status($last_import_id);
    my $status = $response->{message}->{status_name};
    my $start = $response->{message}->{started_at};
    my $finish = $response->{message}->{finished_at};
    return ($status,$start, $finish);
}

sub install_disqus {
    my $app = shift;
    my $q = $app->param;
    my $plugin = MT->component('DisqusCommentSystem');
    my $scope = 'blog:'.$q->param('blog_id');
    my $config = $plugin->get_config_hash($scope);
    my @forums;
    my $installed;
    my $credentials = $q->param('credentials');

    if (($q->param('disqus_username') && $q->param('disqus_password')) || $q->param('credentials')) {
        require Net::Disqus;
        $credentials = encode_base64($q->param('disqus_username') . ':' . $q->param('disqus_password'), q{}) if !$credentials;
        my $dq = Net::Disqus->new({ credentials => $credentials });
        # use Data::Dumper;
        # MT->log("dq is " . Dumper($dq));
        if (!$q->param('short_name')) {
            # we have credentials but not forum short_name -- need to use API to get forum_list
            my $feed = $dq->get_forum_list();

            # MT->log("install feed:" . Dumper($feed));

            my $msg;
            if (!$feed) {
                my $error = $dq->last_error;
                $msg = 'An error occured, please try again';
                if ($error eq 'bad-credentials') {
                    $msg = 'Login failed: wrong username or password';
                }
                return $app->build_page( $plugin->load_tmpl('install_disqus.tmpl'),
                    { return_url => $app->return_uri, error => $msg } );
            }

            @forums = @{$feed->{forums}};
            if (!@forums) {
                $msg = 'No DISQUS forums configured. Go to DISQUS.com to add a website to your DISQUS profile.';
                return $app->build_page( $plugin->load_tmpl('install_disqus.tmpl'),
                    { return_url => $app->return_uri, error => $msg } );
            }

        } else {
            # we have a forum selection, now get the forum_api_key and save in settings
            my $short_name = $q->param('short_name');
            my $forum_key = $dq->get_forum_api_key($short_name)->{forum_api_key};
            $plugin->set_config_value('disqus_forum_url', $short_name, $scope);
            $plugin->set_config_value('disqus_api_key', $forum_key, $scope);
            $plugin->set_config_value('disqus_replace', $q->param('disqus_replace'), $scope) if $q->param('disqus_replace');
            $plugin->set_config_value('disqus_use_api', $q->param('disqus_use_api'), $scope);
            
            $installed = 1;
        }
    }

    $app->build_page( $plugin->load_tmpl('install_disqus.tmpl'),
        { return_url => $app->return_uri, forum_loop => \@forums, credentials => $credentials, installed => $installed } );
}

sub uninstall_disqus {
    my $app = shift;
    my $q = $app->param;
    my $plugin = MT->component('DisqusCommentSystem');
    my $scope = 'blog:'.$q->param('blog_id');
    my $config = $plugin->get_config_hash($scope);

    $plugin->reset_config($scope);

    $app->build_page( $plugin->load_tmpl('uninstall_disqus.tmpl'),
        { return_url => $app->return_uri  } );
}

sub export {
    my $app = shift;
    my $q = $app->param;
    my $blog = MT->model('blog')->load($q->param('blog_id'));
    my $plugin = MT->component('DisqusCommentSystem');

    unless ($q->param('start_export')) {
        return $app->build_page( $plugin->load_tmpl('export.tmpl'),
            { return_url => $app->return_uri, export_complete => 0 } );
    }

    my $scope = 'blog:'.$q->param('blog_id');
    my $config = $plugin->get_config_hash($scope);
    my $forum_key = $config->{disqus_api_key};
    my $short_name = $config->{disqus_forum_url};

    ## Make sure dates are in English.
    $blog->language('en');

    ## Create template for exporting a single entry
    require MT::Template;
    require MT::Template::Context;
    my $header_tmpl = MT::Template->new;
    $header_tmpl->name('WXR Header Template');
    $header_tmpl->text(<<'HEADER');
    <?xml version="1.0" encoding="<$mt:PublishCharset$>"?>
    <rss version="2.0"
        xmlns:content="http://purl.org/rss/1.0/modules/content/"
        xmlns:wfw="http://wellformedweb.org/CommentAPI/"
        xmlns:dc="http://purl.org/dc/elements/1.1/"
        xmlns:wp="http://wordpress.org/export/1.0/"
    >
    <channel>
        <title><$mt:BlogName remove_html="1" encode_xml="1"$></title>
        <link><$mt:BlogURL encode_xml="1"$></link>
        <description><$mt:BlogDescription remove_html="1" encode_xml="1"$></description>
        <pubDate><mt:Entries lastn="1"><$mt:EntryModifiedDate utc="1" format="%a, %d %b %Y %H:%M:%S +0000"$></mt:Entries></pubDate>
        <generator>http://www.sixapart.com/movabletype/"></generator>
        <language><$mt:BlogLanguage ietf="1"$></language>
        <wp:wxr_version>1.0</wp:wxr_version>
        <wp:base_site_url><$mt:BlogURL encode_xml="1"$></wp:base_site_url>
        <wp:base_blog_url><$mt:BlogURL encode_xml="1"$></wp:base_blog_url>

        <mt:SubCategories top="1"><wp:category><wp:category_nicename><mt:CategoryBasename></wp:category_nicename><wp:category_parent><mt:ParentCategory><mt:CategoryLabel></mt:ParentCategory></wp:category_parent><wp:posts_private>0</wp:posts_private><wp:links_private>0</wp:links_private><wp:cat_name><mt:CategoryLabel encode_xml="1"></wp:cat_name><mt:if tag="CategoryDescription"><wp:category_description><mt:CategoryDescription encode_xml="1"></wp:category_description></mt:if></wp:category><mt:SubCatsRecurse>
        </mt:SubCategories>
HEADER
    my $tmpl = MT::Template->new;
    $tmpl->name('WXR Template');
    $tmpl->text(<<'TEXT');
    <item>
    <title><$mt:EntryTitle remove_html="1" encode_xml="1"$></title>
    <link><$mt:EntryPermalink encode_xml="1"$></link>
    <pubDate><$mt:EntryDate utc="1" format="%a, %d %b %Y %H:%M:%S +0000"$></pubDate>
    <dc:creator><mt:EntryAuthorUsername></dc:creator>
    <mt:EntryCategories>
    <category><mt:CategoryLabel encode_xml="1"></category>
    <category domain="category" nicename="<mt:CategoryBasename>"><mt:CategoryLabel encode_xml="1"></category>
    </mt:EntryCategories>

    <guid isPermaLink="false"><mt:EntryAtomID></guid>
    <description></description>
    <content:encoded><mt:EntryBody encode_xml="1"> <mt:EntryMore encode_xml="1"></content:encoded>
    <wp:post_id><mt:EntryID></wp:post_id>
    <wp:post_date><$mt:EntryDate format="%Y-%m-%d %H:%M:%S"$></wp:post_date>
    <wp:post_date_gmt><$mt:EntryDate utc="1" format="%Y-%m-%d %H:%M:%S"$></wp:post_date_gmt>
    <wp:comment_status><mt:IfCommentsActive>open<mt:Else>closed</mt:IfCommentsActive></wp:comment_status>
    <wp:ping_status><mt:IfPingsActive>open<mt:Else>closed</mt:IfPingsActive></wp:ping_status>
    <wp:post_name><mt:EntryBasename></wp:post_name>
    <wp:status><mt:setvarblock name="entry_status"><mt:EntryStatus lower_case="1"></mt:setvarblock><mt:if name="entry_status" eq="review"><mt:var name="entry_status" value="pending"><mt:else name="entry_status" eq="future"><mt:var name="entry_status" value="publish"></mt:if><mt:var name="entry_status"></wp:status>
    <wp:post_parent>0</wp:post_parent>
    <wp:menu_order>0</wp:menu_order>
    <wp:post_type><mt:If tag="EntryClass" eq="page">page<mt:Else>post</mt:If></wp:post_type>

    <mt:Comments><mt:IfCommentNotSyncedFromDisqus>
    <wp:comment>
    <wp:comment_id><mt:CommentID></wp:comment_id>
    <wp:comment_author><mt:CommentAuthor encode_xml="1"></wp:comment_author>
    <wp:comment_author_email><mt:CommentEmail></wp:comment_author_email>
    <wp:comment_author_url><mt:CommentURL></wp:comment_author_url>
    <wp:comment_author_IP><mt:CommentIP></wp:comment_author_IP>
    <wp:comment_date><$mt:CommentDate format="%Y-%m-%d %H:%M:%S"$></wp:comment_date>
    <wp:comment_date_gmt><$mt:CommentDate utc="1" format="%Y-%m-%d %H:%M:%S"$></wp:comment_date_gmt>
    <wp:comment_content><mt:CommentBody encode_xml="1"></wp:comment_content>
    <wp:comment_approved>1</wp:comment_approved>
    <wp:comment_type></wp:comment_type>
    <wp:comment_parent><mt:CommentParentID _default="0"></wp:comment_parent>
    <mt:if tag="CommenterID"><wp:comment_user_id><mt:CommenterID></wp:comment_user_id></mt:if>
    </wp:comment>
    </mt:IfCommentNotSyncedFromDisqus></mt:Comments>
    </item>
TEXT
    my $footer = <<'FOOTER';
    </channel>
    </rss>
FOOTER

    # open file handle for writing the file
    my $file = 'wxr_' . dirify( $blog->name ) . ".xml";
    require File::Spec;
    $file = File::Spec->catfile( $blog->site_path, $file );
    # open file for writing
    open(WXR, ">", $file) or die $!;

    if ($header_tmpl) {
        my $ctx = MT::Template::Context->new;
        $ctx->stash('blog', $blog);
        $ctx->stash('blog_id', $blog->id);
        $header_tmpl->blog_id($blog->id);
        my $res = $header_tmpl->build($ctx)
            or return MT->error(MT->translate(
                "WXR Header Export failed: [_1]", $tmpl->errstr));
        print WXR $res;
    }

    my $iter = MT::Entry->load_iter({ blog_id => $blog->id },
        { 'sort' => 'created_on', direction => 'ascend' });

    while (my $entry = $iter->()) {
        my $ctx = MT::Template::Context->new;
        $ctx->stash('entry', $entry);
        $ctx->stash('blog', $blog);
        $ctx->stash('blog_id', $blog->id);
        $tmpl->blog_id($blog->id);
        $ctx->{current_timestamp} = $entry->created_on;
        my $res = $tmpl->build($ctx)
            or return MT->error(MT->translate(
                "WXR Export failed on entry '[_1]': [_2]", $entry->title,
                $tmpl->errstr));
        print WXR $res;
    }
    print WXR $footer;
    close WXR;

    use Net::Disqus;
    my $dq = Net::Disqus->new({ forum_api_key => $forum_key, short_name => $short_name, import_api => 1 });
    my $response = $dq->import_comments($file, 'movabletype');

# use Data::Dumper;
# MT->log("reponse is " . Dumper($response));

    my $import_id = $response->{message}->{import_id};
    $plugin->set_config_value('disqus_last_import_id', $import_id, $scope) if $import_id;
    $plugin->set_config_value('disqus_import_started', '', $scope) if $import_id;
    $plugin->set_config_value('disqus_import_finished', '', $scope) if $import_id;

    unlink $file
       or return MT->error(MT->translate(
           "Deleting '[_1]' failed: [_2]", $file, "$!"));
#    return $response->{message}->{import_id};
    $app->build_page( $plugin->load_tmpl('export.tmpl'),
        { return_url => $app->return_uri, export_complete => $import_id } );
}


1;
