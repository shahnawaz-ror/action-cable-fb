<?php
function smarty_function_mtdisquscommentcount($args, &$ctx) {
	define('DISQUS_URL', 'http://disqus.com');
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

	if (!$forum_url) {
		return $mt_count;
	}

	// if we have come this far, Disqus is active in this context
	require_once("function.mtentrypermalink.php");
	$permalink = smarty_function_mtentrypermalink($args, $ctx);
	$script = "<script type='text/javascript' src='http://disqus.com/forums/" . strtolower($forum_url) . "/get_num_replies_for_entry.js?url=" . urlencode($permalink) . "'></script><noscript>View</noscript>";
	$dq_count = preg_replace('/([0-9]+|No)/is',$script,$mt_count);
	return $dq_count;
}

// replicated here because the 4.25 file is missing the closing php tag, and require_once won't work to include the function - case opened: http://bugs.movabletype.org/default.asp?100620
function smarty_function_mtentrycommentcount($args, &$ctx) {
	$entry = $ctx->stash('entry');
	$count = $entry['entry_comment_count'];
	return $ctx->count_format($count, $args);
}

?>
