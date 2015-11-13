$managed_groups = hiera_hash(managed_groups)[groups]

notice ( $managed_groups )

$managed_groups.each | $group | {
  notice ( "Processing $group" )
  $g = hiera_hash(accounts::groups).filter | $key, $val | { $key == $group }
  # create_resources('group', $g)
  notice ( $g )
}

$managed_users = hiera_array(managed_users)

$managed_users.each | $user | {
  notice ( "Processing $user" )
  $u = hiera_hash(accounts::users).filter | $key, $val | { $key == $user }
  # create_resources(pe_accounts::user, $u)
  notice ( $u )
}

