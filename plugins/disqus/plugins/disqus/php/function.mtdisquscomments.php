<?php
function smarty_function_mtdisquscomments($args, &$ctx) {
	define('DISQUS_URL', 'http://disqus.com');
	// status: complete
	// parameters: none
	$entry = $ctx->stash('entry');
	$blog_id = $ctx->stash('blog_id');
	if (!$entry) {
		return '';
	}
	$entry_id = $entry['entry_id'];
	$basename = $entry['entry_basename'];
	$config = $ctx->mt->db->fetch_plugin_config('DisqusCommentSystem', 'blog:' . $blog_id);
	$forum_url = $config['disqus_forum_url'];
	$disqus_api_key = $config['disqus_api_key'];
	$include_path = dirname(__FILE__) . '/disqus.php';
	require_once("function.mtentrylink.php");
	$permalink = smarty_function_mtentrylink($args, $ctx);

	global $disqus_vars;
	$disqus_vars = array();
	$disqus_vars["disqus_forum_url"] = $forum_url;
	$disqus_vars["disqus_api_key"] = $disqus_api_key;
	$disqus_vars["permalink"] = $permalink;
	$disqus_vars["title"] = $entry["entry_title"];
	$disqus_vars["text"] = $entry["entry_text"];

	include('util.php');

	global $post;
	$post = new post_object();
	$post->ID = $entry_id;
	$post->guid = $basename;
	$post->blog_id = $blog_id;
	$post->comment_status = $entry['entry_allow_comments'] ? 'open' : 'closed';

	include($include_path);

	$style = <<<EOT
			<link rel="stylesheet" href="http://disqus.com/stylesheets/$forum_url/disqus.css?v=2.0" type="text/css" media="screen" />
EOT;
		echo $style;
		include(dsq_comments_template(1));
//		return $ret;
}

?>
