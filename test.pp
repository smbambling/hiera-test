$managed_groups = hiera_array(managed_groups)

notice ( $managed_groups )

$managed_groups.each | $group | {
  notice ( "Processing $group" )
  $g = hiera_hash(accounts::groups).filter | $key, $val | { $key == $group }
  notice ( $g )
}

$managed_users = hiera_array(managed_users)

$managed_users.each | $user | {
  notice ( "Processing $user" )
  $u = hiera_hash(accounts::users).filter | $key, $val | { $key == $user }
  notice ( $u )
}

