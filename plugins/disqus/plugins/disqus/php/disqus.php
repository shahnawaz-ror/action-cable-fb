<?php
/*
Plugin Name: DISQUS Comment System
Plugin URI: http://disqus.com/
Description: The DISQUS comment system replaces your WordPress comment system with your comments hosted and powered by DISQUS. Head over to the Comments admin page to set up your DISQUS Comment System.
Author: DISQUS.com <team@disqus.com>
Version: 2.11.4349
Author URI: http://disqus.com/

*/

require_once('lib/api.php');

define('DISQUS_URL',			'http://disqus.com');
define('DISQUS_API_URL',		DISQUS_URL);
define('DISQUS_DOMAIN',			'disqus.com');
define('DISQUS_IMPORTER_URL',	'http://import.disqus.net');
define('DISQUS_MEDIA_URL',		'http://media.disqus.com');
define('DISQUS_RSS_PATH',		'/latest.rss');


// comment by mark -- probably can delete the following, but leaving it for now....
function dsq_plugin_basename($file) {
	$file = dirname($file);

	// From WP2.5 wp-includes/plugin.php:plugin_basename()
	$file = str_replace('\\','/',$file); // sanitize for Win32 installs
	$file = preg_replace('|/+|','/', $file); // remove any duplicate slash
	$file = preg_replace('|^.*/' . PLUGINDIR . '/|','',$file); // get relative path from plugins dir

	if ( strstr($file, '/') === false ) {
		return $file;
	}

	$pieces = explode('/', $file);
	return !empty($pieces[count($pieces)-1]) ? $pieces[count($pieces)-1] : $pieces[count($pieces)-2];
}

if ( !defined('WP_CONTENT_URL') ) {
	define('WP_CONTENT_URL', get_option('siteurl') . '/wp-content');
}
if ( !defined('PLUGINDIR') ) {
	define('PLUGINDIR', 'wp-content/plugins'); // Relative to ABSPATH.  For back compat.
}

define('DSQ_PLUGIN_URL', WP_CONTENT_URL . '/plugins/' . dsq_plugin_basename(__FILE__));

/**
 * DISQUS WordPress plugin version.
 *
 * @global	string	$dsq_version
 * @since	1.0
 */
$dsq_version = '2.11';
$mt_dsq_version = '2.0';
/**
 * Response from DISQUS get_thread API call for comments template.
 *
 * @global	string	$dsq_response
 * @since	1.0
 */
$dsq_response = '';
/**
 * Comment sort option.
 *
 * @global	string	$dsq_sort
 * @since	1.0
 */
$dsq_sort = 1;
/**
 * Flag to determine whether or not the comment count script has been embedded.
 *
 * @global	string	$dsq_cc_script_embedded
 * @since	1.0
 */
$dsq_cc_script_embedded = false;
/**
 * DISQUS API instance.
 *
 * @global	string	$dsq_api
 * @since	1.0
 */
global $dsq_api;
$dsq_api = new DisqusAPI(get_option('disqus_forum_url'), get_option('disqus_api_key'));
// echo var_dump($dsq_api);
/**
 * Helper functions.
 */

function dsq_legacy_mode() {
	return get_option('disqus_forum_url') && !get_option('disqus_api_key');
}

function dsq_is_installed() {
	return get_option('disqus_forum_url') && get_option('disqus_api_key');
}



function dsq_manage_dialog($message, $error = false) {
	global $wp_version;

	echo '<div '
		. ( $error ? 'id="disqus_warning" ' : '')
		. 'class="updated fade'
		. ( ($wp_version < 2.5 && $error) ? '-ff0000' : '' )
		. '"><p><strong>'
		. $message
		. '</strong></p></div>';
}

function dsq_sync_comments($post, $comments) {
	global $mt;

	if (!isset($mt)) {
		$mt = start_mt();
	}
//	$offset = get_the_offset();
	// Get last_comment_date id for $post with Disqus metadata
	// (This is the date that is stored in the Disqus DB.)
//	$test_date = $mt->db->get_var('SELECT max(comment_created_on) FROM mt_comment WHERE comment_entry_id=127684;');
//	echo 'test_date is ' . $test_date;
//	$test_date = strtotime($test_date);
//	echo ' now date is ' . $test_date;

	//convert to utc
//	$test_date = $test_date - ($offset*60*60);
//	echo ' UTC date is ' . $test_date;

	$last_comment_date = $mt->db->get_var('SELECT max(comment_created_on) FROM mt_comment WHERE comment_entry_id=' . intval($post->ID) . " AND comment_remote_service='disqus';");
//	echo 'date is ' . $last_comment_date;
	if ( $last_comment_date ) {
		$last_comment_date = strtotime($last_comment_date);
//		echo ' ts is ' . $last_comment_date;
//		$last_comment_date = $last_comment_date - ($offset*60*60);
//		echo ' UTC ts is ' . $last_comment_date;
	}

	if ( !$last_comment_date ) {
		$last_comment_date = 0;
	}
	$added = 0;
	foreach ( $comments as $comment ) {
//		echo ' and comment[date] is ' . $comment['date'];
		if ( $comment['imported'] ) {
			continue;
		} else if ( $comment['date'] <= $last_comment_date ) {
			// If comment date of comment is <= last_comment_date, skip comment.
			continue;
		} else {
			// Else, insert_comment
			$commentdata = array(
				'comment_entry_id' => $post->ID,
				'comment_blog_id' => $post->blog_id,
				'comment_author' => $comment['user']['display_name'],
				'comment_email' => $comment['user']['email'],
				'comment_url' => $comment['user']['url'],
				'comment_ip' => $comment['user']['ip_address'],
				'comment_created_on' => date('Y-m-d H:i:s', $comment['date']),
				'comment_text' => $comment['message'],
				'comment_visible' => 1,
				'comment_junk_status' => 1,
				'comment_remote_service' => 'disqus',
				'comment_remote_id' => $comment['id'],
			);

			if ($mt->db->vendor == 'postgres') {
				// HACK: comment_id column in PostgreSQL does not use nextval() modifier.
				$commentdata['comment_id'] = $mt->db->get_var('SELECT nextval(\'mt_comment_id\');');
			}

			prepareVars($commentdata);

			$field_names = implode(', ', array_keys($commentdata));
			$values_list = array_values($commentdata);
			for ($i = 0; $i < sizeof($values_list); $i++) {
				$values_list[$i] = "'" . $values_list[$i] . "'";
			}
			$values_list = implode(', ', $values_list);
			$sql = "INSERT INTO mt_comment ($field_names) VALUES($values_list);";
			$rows = $mt->db->query($sql);

			$added = 1;
		}
	}
	if ($added) {
		$db_count = $mt->db->get_var('SELECT entry_comment_count FROM mt_entry WHERE entry_id=' . intval($post->ID));
		$api_count = count($comments);
		if ($db_count != $api_count) {
			$rows = $mt->db->query('UPDATE mt_entry set entry_comment_count =' . $api_count . ' WHERE entry_id=' . intval($post->ID));
		}
	}

}

/**
 *  Filters/Actions
 */

function dsq_get_style() {
	echo "<link rel=\"stylesheet\" href=\"" . DISQUS_API_URL ."/stylesheets/" .  strtolower(get_option('disqus_forum_url')) . "/disqus.css?v=2.0\" type=\"text/css\" media=\"screen\" />";
}

// add_action('wp_head','dsq_get_style');

function dsq_comments_template($value) {
	global $dsq_response;
	global $dsq_sort;
	global $dsq_api;
	global $post;

//	if ( ! (is_single() || is_page() || $withcomments) ) {
//		return;
//	}

//	if ( !dsq_can_replace() ) {
//		return $value;
//	}

//	if ( dsq_legacy_mode() ) {
//		return dirname(__FILE__) . '/comments-legacy.php';
//	}

	$permalink = get_permalink();
	$title = get_the_title();
	$excerpt = get_the_excerpt();

	$dsq_sort = get_option('disqus_sort');
	if ( is_numeric($_COOKIE['disqus_sort']) ) {
		$dsq_sort = $_COOKIE['disqus_sort'];
	}

	if ( is_numeric($_GET['dsq_sort']) ) {
		setcookie('disqus_sort', $_GET['dsq_sort']);
		$dsq_sort = $_GET['dsq_sort'];
	}

	// echo var_dump($dsq_api);
	// Call "get_thread" API method.
	$dsq_response = $dsq_api->get_thread($post, $permalink, $title, $excerpt);
// echo var_dump($dsq_response);
	if( $dsq_response < 0 ) {
		return false;
	}
	// Sync comments with database.
	if ( !get_option('disqus_disable_sync') ) {
		dsq_sync_comments($post, $dsq_response['posts']);
	}

	// TODO: If a disqus-comments.php is found in the current template's
	// path, use that instead of the default bundled comments.php
	//return TEMPLATEPATH . '/disqus-comments.php';
	$comments = array('none');
	return dirname(__FILE__) . '/comments.php';
}

function dsq_comment_count() {
	global $dsq_cc_script_embedded;

	if ( $dsq_cc_script_embedded ) {
		return;
	} else if ( (is_single() || is_page() || $withcomments || is_feed()) ) {
		return;
	}

	?>

	<script type="text/javascript">
	// <![CDATA[
		(function() {
			var links = document.getElementsByTagName('a');
			var query = '&';
			for(var i = 0; i < links.length; i++) {
				if(links[i].href.indexOf('#disqus_thread') >= 0) {
					links[i].innerHTML = 'View Comments';
					query += 'wpid' + i + '=' + encodeURIComponent(links[i].getAttribute('wpid')) + '&';
				}
			}
			document.write('<script charset="utf-8" type="text/javascript" src="<?php echo DISQUS_URL ?>/forums/<?php echo strtolower(get_option('disqus_forum_url')); ?>/get_num_replies_from_wpid.js?v=2.0' + query + '"><' + '/script>');
		})();
	//]]>
	</script>

	<?php

	$dsq_cc_script_embedded = true;
}

// Mark entries in index to replace comments link.
function dsq_comments_number($comment_text) {
	global $post;

	if ( dsq_can_replace() ) {
		ob_start();
		the_permalink();
		$the_permalink = ob_get_contents();
		ob_end_clean();

		return '</a><noscript><a href="http://' . strtolower(get_option('disqus_forum_url')) . '.' . DISQUS_DOMAIN . '/?url=' . $the_permalink .'">View comments</a></noscript><a class="dsq-comment-count" href="' . $the_permalink . '#disqus_thread" wpid="' . $post->ID . '">Comments</a>';
	} else {
		return $comment_text;
	}
}

function dsq_bloginfo_url($url) {
	if ( get_feed_link('comments_rss2') == $url ) {
		return 'http://' . strtolower(get_option('disqus_forum_url')) . '.' . DISQUS_DOMAIN . DISQUS_RSS_PATH;
	} else {
		return $url;
	}
}

// For WordPress 2.0.x
function dsq_loop_start() {
	global $comment_count_cache;

	if ( isset($comment_count_cache) ) {
		foreach ( $comment_count_cache as $key => $value ) {
			if ( 0 == $value ) {
				$comment_count_cache[$key] = -1;
			}
		}
	}
}

// comment by mark -- seems like WP admin stuff, probably can remove
function dsq_add_pages() {
	global $menu, $submenu;

	add_submenu_page('edit-comments.php', 'DISQUS', 'DISQUS', 8, 'disqus', dsq_manage);

	// TODO: This does not work in WP2.0.

	// Replace Comments top-level menu link with link to our page
	foreach ( $menu as $key => $value ) {
		if ( 'edit-comments.php' == $menu[$key][2] ) {
			$menu[$key][2] = 'edit-comments.php?page=disqus';
		}
	}

	// add_options_page('DISQUS', 'DISQUS', 8, 'disqus', dsq_manage);
}

function dsq_manage() {
	require_once('admin-header.php');
	include_once('manage.php');
}

// Always add Disqus management page to the admin menu
// add_action('admin_menu', 'dsq_add_pages');

function dsq_warning() {
	global $wp_version;

	if ( !get_option('disqus_forum_url') && !isset($_POST['forum_url']) && $_GET['page'] != 'disqus' ) {
		dsq_manage_dialog('You must <a href="edit-comments.php?page=disqus">configure the plugin</a> to enable the DISQUS comment system.', true);
	}

	if ( dsq_legacy_mode() && $_GET['page'] == 'disqus' ) {
		dsq_manage_dialog('DISQUS is running in legacy mode.  (<a href="edit-comments.php?page=disqus">Click here to configure</a>)');
	}
}

function dsq_check_version() {
	global $dsq_api;

	$latest_version = $dsq_api->wp_check_version();
	if ( $latest_version ) {
		dsq_manage_dialog('You are running an old version of the DISQUS plugin.  Please <a href="http://blog.disqus.com">check the blog</a> for updates.');
	}
}

// add_action('admin_notices', 'dsq_warning');
// add_action('admin_notices', 'dsq_check_version');

// Only replace comments if the disqus_forum_url option is set.
// add_filter('comments_template', 'dsq_comments_template');
// add_filter('comments_number', 'dsq_comments_number');
// add_filter('bloginfo_url', 'dsq_bloginfo_url');
// add_action('loop_start', 'dsq_loop_start');

// For comment count script.
if ( !get_option('disqus_cc_fix') ) {
	// add_action('loop_end', 'dsq_comment_count');
}
// add_action('wp_footer', 'dsq_comment_count');

function blog_date($format,$offset,$timestamp){
   if (date('I')) {$offset = $offset + 1;}
   $offset = $offset*60*60;
   $timestamp = $timestamp + $offset;
   return gmdate($format,$timestamp);
}

function prepareVars(&$vars){
	global $mt;
	# Adds escapes to all vars for passing into a mysql statement.
	foreach(array_keys($vars) as $key){
		$vars[$key] = $mt->db->escape($vars[$key]);
	}
}

?>
