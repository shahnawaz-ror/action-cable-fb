<?php
	global $dsq_response, $mt_dsq_version;
	if ( !isset($mt) ) {
		$mt = start_mt();
	}

    include('sso_helpers.php');
?>

<div id="disqus_thread">
	<div id="dsq-content">
		<ul id="dsq-comments">
<?php foreach ( $dsq_response['posts'] as $comment ) : ?>
			<div id="comment-<?php echo $comment['id']; ?>"></div>

			<li id="dsq-comment-<?php echo $comment['id']; ?>">
				<div id="dsq-comment-header-<?php echo $comment['id']; ?>" class="dsq-comment-header">
					<cite id="dsq-cite-<?php echo $comment['id']; ?>">
<?php if($comment['user']['url']) : ?>
						<a id="dsq-author-user-<?php echo $comment['id']; ?>" href="<?php echo $comment['user']['url']; ?>" target="_blank" rel="nofollow"><?php echo $comment['user']['display_name']; ?></a>
<?php else : ?>
						<span id="dsq-author-user-<?php echo $comment['id']; ?>"><?php echo $comment['user']['display_name']; ?></span>
<?php endif; ?>
					</cite>
				</div>
				<div id="dsq-comment-body-<?php echo $comment['id']; ?>" class="dsq-comment-body">
					<div id="dsq-comment-message-<?php echo $comment['id']; ?>" class="dsq-comment-message"><?php echo $comment['message']; ?></div>
				</div>
			</li>
<?php endforeach; ?>
		</ul>
	</div>
</div>

<a href="http://disqus.com" class="dsq-brlink">blog comments powered by <span class="logo-disqus">Disqus</span></a>

<script type="text/javascript" charset="utf-8">
	var disqus_url = '<?php echo get_permalink(); ?> ';
	var disqus_container_id = 'disqus_thread';
	var facebookXdReceiverPath = '<?php echo $mt->config('StaticWebPath'). 'plugins/disqus/xd_receiver.htm' ?>';
<?php
    $dsq_partner_key = get_option('disqus_partner_key');
    if ( $dsq_partner_key ) {
        $user = mt_dsq_get_user();
        echo "var disqus_remote_auth_s2 = '" . mt_dsq_get_sso($user, $dsq_partner_key) . "';";
    }
?>
</script>

<!-- d tb code was here -->

<script type="text/javascript" charset="utf-8" src="<?php echo DISQUS_API_URL; ?>/scripts/<?php echo strtolower(get_option('disqus_forum_url')); ?>/disqus.js?v=2.0&slug=<?php echo $dsq_response['thread_slug']; ?>&pname=movabletype&pver=<?php echo $mt_dsq_version; ?>"></script>
