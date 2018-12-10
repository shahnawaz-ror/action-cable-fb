package MT::Plugin::Disqus;

use strict;
use base 'MT::Plugin';

use vars qw($VERSION);
$VERSION = '2.02';
use MT;

my $plugin = new MT::Plugin::Disqus({
    name => 'DISQUS Comment System',
    id => 'DisqusCommentSystem',
    key => 'DisqusCommentSystem',
    version => $VERSION,
    description => 'Enables the DISQUS Comment System on Movable Type blogs',
    author_name => 'DISQUS',
    author_link => 'http://disqus.com/',
    plugin_link => 'http://disqus.com/',
    doc_link => 'http://disqus.com/',
    settings => new MT::PluginSettings([
        ['disqus_forum_url', { Scope => 'blog' }],
        ['disqus_replace', { Scope => 'blog'}],  # all, empty, closed
        ['disqus_api_key', { Scope => 'blog'}],  # needs to be populated via API call
        ['disqus_partner_key', { Scope => 'blog'}],
        ['disqus_use_api', { Scope => 'blog'}],
        ['disqus_cc_fix', { Scope => 'blog'}],
        ['disqus_last_import_id', { Scope => 'blog'}],
        ['disqus_import_started', { Scope => 'blog'}],
        ['disqus_import_finished', { Scope => 'blog'}],
        ['disqus_disable_sync', { Scope => 'blog'}]
    ]),
});

MT->add_plugin($plugin);

sub init_registry {
    my $component = shift;
    my $reg = {
        'applications' => {
            'cms' => {
                'methods' => {
                    'install_disqus' => '$DisqusCommentSystem::DisqusCommentSystem::App::CMS::install_disqus',
                    'export_to_disqus' => '$DisqusCommentSystem::DisqusCommentSystem::App::CMS::export',
                    'uninstall_disqus' => '$DisqusCommentSystem::DisqusCommentSystem::App::CMS::uninstall_disqus',
                },
            },
            'comments' => {
                'methods' => {
                    'disqus_sso' => '$DisqusCommentSystem::DisqusCommentSystem::App::Comments::disqus_sso',
                }
            },
        },
        'blog_config_template' => MT->handler_to_coderef('$DisqusCommentSystem::DisqusCommentSystem::App::CMS::template'),
        'callbacks' => {
            'MT::App::CMS::template_source.list_comment' => '$DisqusCommentSystem::DisqusCommentSystem::Callbacks::list_comment',
        },
        'tags' => {
            'function' => {
                'EntryCommentCount' => '$DisqusCommentSystem::DisqusCommentSystem::Tags::_hdlr_disqus_comment_count',
                'BuiltinEntryCommentCount' => '$DisqusCommentSystem::DisqusCommentSystem::Tags::_hdlr_builtin_comment_count',
                'EntryDisqusCommentCount' => '$DisqusCommentSystem::DisqusCommentSystem::Tags::_hdlr_disqus_comment_count_manual',
                'DisqusComments' => '$DisqusCommentSystem::DisqusCommentSystem::Tags::_hdlr_disqus_comments',
            },
            'block' => {
                'IfCommentsActive' => '$DisqusCommentSystem::DisqusCommentSystem::Tags::_hdlr_disqusify',
                'IfCommentNotSyncedFromDisqus?' => '$DisqusCommentSystem::DisqusCommentSystem::Tags::_if_comment_not_synced_from_disqus',
            },
        },
    };
    $component->registry($reg);
}

1;
