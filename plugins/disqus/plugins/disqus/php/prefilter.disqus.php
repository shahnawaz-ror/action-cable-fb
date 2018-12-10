<?php
function smarty_prefilter_disqus($tpl_source, &$ctx2) {
	// $tpl_source = preg_replace('/for style/is','for fun',$tpl_source);
	$tpl_source = preg_replace('/{{mtifcommentsactive\b[^}]*?}}.*?{{mtcomments\b[^}]*?}}.*?{{\/mtcomments}}.*?{{\/mtifcommentsactive}}/is', '{{mtdisquscomments}}', $tpl_source);
	return $tpl_source;
}

?>