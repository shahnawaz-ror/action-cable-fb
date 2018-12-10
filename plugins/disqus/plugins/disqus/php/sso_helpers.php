<?php
/**
 * JSON ENCODE for PHP < 5.2.0
 * Checks if json_encode is not available and defines json_encode
 * to use php_json_encode in its stead
 * Works on iteratable objects as well - stdClass is iteratable, so all WP objects are gonna be iteratable
 */
if(!function_exists('cf_json_encode')) {
	function cf_json_encode($data) {
        // json_encode is sending an application/x-javascript header on Joyent servers
        // for some unknown reason.
// 		if(function_exists('json_encode')) { return json_encode($data); }
// 		else { return cfjson_encode($data); }
		return cfjson_encode($data);
	}

	function cfjson_encode_string($str) {
		if(is_bool($str)) {
			return $str ? 'true' : 'false';
		}

		return str_replace(
			array(
				'"'
				, '/'
				, "\n"
				, "\r"
			)
			, array(
				'\"'
				, '\/'
				, '\n'
				, '\r'
			)
			, $str
		);
	}

	function cfjson_encode($arr) {
		$json_str = '';
		if (is_array($arr)) {
			$pure_array = true;
			$array_length = count($arr);
			for ( $i = 0; $i < $array_length ; $i++) {
				if (!isset($arr[$i])) {
					$pure_array = false;
					break;
				}
			}
			if ($pure_array) {
				$json_str = '[';
				$temp = array();
				for ($i=0; $i < $array_length; $i++) {
					$temp[] = sprintf("%s", cfjson_encode($arr[$i]));
				}
				$json_str .= implode(',', $temp);
				$json_str .="]";
			}
			else {
				$json_str = '{';
				$temp = array();
				foreach ($arr as $key => $value) {
					$temp[] = sprintf("\"%s\":%s", $key, cfjson_encode($value));
				}
				$json_str .= implode(',', $temp);
				$json_str .= '}';
			}
		}
		else if (is_object($arr)) {
			$json_str = '{';
			$temp = array();
			foreach ($arr as $k => $v) {
				$temp[] = '"'.$k.'":'.cfjson_encode($v);
			}
			$json_str .= implode(',', $temp);
			$json_str .= '}';
		}
		else if (is_string($arr)) {
			$json_str = '"'. cfjson_encode_string($arr) . '"';
		}
		else if (is_numeric($arr)) {
			$json_str = $arr;
		}
		else if (is_bool($arr)) {
			$json_str = $arr ? 'true' : 'false';
		}
		else {
			$json_str = '"'. cfjson_encode_string($arr) . '"';
		}
		return $json_str;
	}
}

// Calculate HMAC-SHA1 according to RFC2104
// From http://www.php.net/manual/en/function.sha1.php#39492
// http://www.ietf.org/rfc/rfc2104.txt
function dsq_hmacsha1($data, $key) {
    $blocksize=64;
    $hashfunc='sha1';

    if (strlen($key)>$blocksize) {
        $key=pack('H*', $hashfunc($key));
    }

    $key=str_pad($key,$blocksize,chr(0x00));
    $ipad=str_repeat(chr(0x36),$blocksize);
    $opad=str_repeat(chr(0x5c),$blocksize);

    $hmac = pack(
                'H*',$hashfunc(
                    ($key^$opad).pack(
                        'H*',$hashfunc(
                            ($key^$ipad).$data
                        )
                    )
                )
            );
    return bin2hex($hmac);
}

function mt_dsq_get_user() {
    global $mt;

    // Fetch session ID from cookie.
    if ( !empty($_COOKIE['mt_commenter']) ) {
        $session_id = $_COOKIE['mt_commenter'];
    } else if ( !empty($_COOKIE['mt_user']) ) {
        list($user, $session_id, $remember) =
            explode('::', urldecode($_COOKIE['mt_user']));
    }

    if ( empty($session_id) ) {
        return false;
    }

    // TODO(jason): Do we care to try session_id from mt_user if we
    //              aren't successful with mt_commenter?
    $sql = "SELECT session_data FROM mt_session WHERE session_id='"
        . $mt->db->escape($session_id) . "'";
    $session_data = $mt->db->get_var($sql);
    $session_data = $mt->db->unserialize($session_data);

    if ( !empty($session_data['author_id']) ) {
        $author = $mt->db->fetch_author($session_data['author_id']);
        return $author;
    }
}

function mt_dsq_get_avatar_url($user) {
    global $mt;

    $asset_id = isset($user['author_userpic_asset_id']) ? $user['author_userpic_asset_id'] : 0;
    $asset = $mt->db->fetch_assets(array('id' => $asset_id));
    if (!$asset) {
        return '';
    }

    require_once("MTUtil.php");
    $avatar_url = userpic_url($asset[0], $mt->blog_id, $author);

    if ( substr($avatar_url, 0, 1) == '/' ) {
        $permalink = get_permalink();
        $permalink = explode("/", $permalink);
        $avatar_url = "$permalink[0]//${permalink[2]}${avatar_url}";
    }

    return $avatar_url;
}

function mt_dsq_get_sso($user, $key) {
    if ($user) {
        $user_data = array(
            'username' => $user["author_nickname"],
            'id' => $user["author_id"],
            'email' => $user["author_email"],
            'url' => $user["author_url"],
            'avatar' => mt_dsq_get_avatar_url($user)
        );
    } else {
        $user_data = array();
    }

    $user_data = base64_encode(cf_json_encode($user_data));
    $time = time();
    $hmac = dsq_hmacsha1($user_data.' '.$time, $key);
    $payload = "$user_data $hmac $time";
    return $payload;
}
?>
