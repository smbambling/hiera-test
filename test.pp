$managed_groups = hiera_array(managed_groups)

notice ( $managed_groups )

$managed_users = hiera_array(managed_users)

$managed_users.each | $user | {
  notice ( "Processing $user" )
  $u = hiera_hash(accounts::users).filter | $key, $val | { $key == $user }
  notice ( $u )
}

