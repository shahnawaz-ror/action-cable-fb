<?php
global $mt;
$ctx = &$mt->context();
// $ctx->conditionals['mtnosearch'] = 1;

$ctx->add_conditional_tag('mtifcommentsactive', 'if_comments_active');
$ctx->add_tag('mtentrycommentcount', 'entry_comment_count');

function add_header_comment($tpl_source, &$ctx)
{
	// $tpl_source = preg_replace('/for style/is','for fun',$tpl_source);
	$tpl_source = preg_replace('/<MT:?Comments\b[^>]*?>.*?<\/MT:?Comments>/is', 'comments were here', $tpl_source);
	return $tpl_source;

}
// $ctx->register_prefilter('add_header_comment');

function if_comments_active($args, $content, &$ctx, &$repeat) {
	require_once("block.mtifcommentsactive.php");

	$blog_id = $ctx->stash('blog_id');
	$entry = $ctx->stash('entry');
	if (!$entry) {
		return smarty_block_mtifcommentsactive($args, $content, $ctx, $repeat);
	}
	// need to check for 'preview_template' ??
	$config = $ctx->mt->db->fetch_plugin_config('DisqusCommentSystem', 'blog:' . $blog_id);
	$disqus_forum_url = $config['disqus_forum_url'];
	$disqus_replace = $config['disqus_replace'];

	if ( ($disqus_replace == 'manual') ||
		 (($disqus_replace == 'empty') && ($entry['entry_comment_count'] > 0)) ||
		 (($disqus_replace == 'closed') && $entry['entry_allow_comments']) ||
		 !isset($config['disqus_api_key']) ) {
		return smarty_block_mtifcommentsactive($args, $content, $ctx, $repeat);
	} else {
		// if we have come this far, Disqus is active in this context
		$ctx->load_filter('pre', 'disqus');
		return smarty_block_mtifcommentsactive($args, $content, $ctx, $repeat);
	}
//	return '';
	// return var_dump($ctx->_tag_stack);
	//return 'b2';
//	return $config['disqus_replace'] . ' ' . $entry['entry_comment_count'];

//	$active = smarty_block_mtifcommentsactive($args, $content, $ctx, $repeat);
//	return $active;
}

function entry_comment_count($args, &$ctx) {
//	require_once("function.mtentrycommentcount.php");
//	return smarty_function_mtentrycommentcount($args, $ctx);
	$blog_id = $ctx->stash('blog_id');
	$entry = $ctx->stash('entry');
	$mt_count = smarty_function_mtentrycommentcount($args, $ctx);
	if (!$entry) {
		return $mt_count;
	}
	// need to check for 'preview_template' ??
	$config = $ctx->mt->db->fetch_plugin_config('DisqusCommentSystem', 'blog:' . $blog_id);
	$forum_url = $config['disqus_forum_url'];
	$disqus_replace = $config['disqus_replace'];

	if ( (($disqus_replace == 'empty') && ($entry['entry_comment_count'] > 0)) || (($disqus_replace == 'closed') && $entry['entry_allow_comments']) || ($disqus_replace == 'manual')  ) {
		return $mt_count;
	} else {
		// if we have come this far, Disqus is active in this context
		require_once("function.mtentrypermalink.php");
		$permalink = smarty_function_mtentrypermalink($args, $ctx);
		$script = "<script type='text/javascript' src='http://disqus.com/forums/" . strtolower($forum_url) . "/get_num_replies_for_entry.js?url=" . urlencode($permalink) . "'></script><noscript>View</noscript>";
		$dq_count = preg_replace('/([0-9]+|No)/is',$script,$mt_count);
		return $dq_count;
	}
}

// replicated here because the 4.25 file is missing the closing php tag, and require_once won't work to include the function - case opened: http://bugs.movabletype.org/default.asp?100620
function smarty_function_mtentrycommentcount($args, &$ctx) {
	$entry = $ctx->stash('entry');
	$count = $entry['entry_comment_count'];
	return $ctx->count_format($count, $args);
}

?>
