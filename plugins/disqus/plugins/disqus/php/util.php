<?php

class post_object {
	var $ID;
	var $guid;
	var $blog_id;
	var $comment_status;
}

function get_option($option) {
	global $disqus_vars;
	$settings = array();
	$settings["disqus_forum_url"] = $disqus_vars["disqus_forum_url"];
	$settings["disqus_api_key"] = $disqus_vars["disqus_api_key"];
	$settings["disqus_sort"] = "";
	//	$settings["disqus_forum_url"] = 'walla';
  	return $settings[$option];
}
function get_permalink() {
	global $disqus_vars;
  	return $disqus_vars["permalink"];
}
function get_the_title() {
	global $disqus_vars;
  	return $disqus_vars["title"];
}
function get_the_excerpt() {
	global $disqus_vars;
	return $disqus_vars["text"];
}
function get_the_offset() {
	global $disqus_vars;
	return $disqus_vars["offset"];
}
function trackback_url() {
	global $disqus_vars;
  	return "http://trackback.com";
}

?>
