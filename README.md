# Test Commands

bundle install --path vendor --without system_tests

bundle exec puppet apply --certname=test.example.dev --hiera_config=hiera.yaml test.pp

# Account Management

### Overview

User and Group information now uses hiera as a data store.  The yaml files that
contain the information about each user and group however are not directly called
via an accounts module ( pe_accounts ) to create the resource.

Instead wrapper logic is used in the site.pp or a common/base profile ( if using roles/profiles )
to select users and groups information from the Yaml data store(s)
via a provided list and create the resources.

### Configuration

The hiera configuration need to be updated to extend two additional levels that
reside at the bottom of the hierarchy and the merge behavior needs
modified from native to deeper.

> Modifying the merge behavior requires the installation of the deep_merge gem
(Please see the Puppet Docs for installing this on your system)

```yaml
hiera.yaml
---
:hierarchy:
  - common
  - accounts/users
  - accounts/groups

:merge_behavior: deeper
:deep_merge_options:
  :knockout_prefix: '--'
```

### Populate User and Group Yaml Data Store(s)

The users and groups yaml files under the accounts directory contain user and
group information respectively.

```yaml
accoounts/groups.yaml
---
accounts::groups:
  group1:
    ensure: present
    gid: '9999'
  group2:
    ensure: present
    gid: '9998'
  group3:
    ensure: present
    gid: '9997'
```

```yaml
accounts/users.yaml
---
accounts::users:
  user1:
    ensure: present
    comment: 'User One'
    uid: '700'
    gid: '700'
    groups:
      - group1
      - group2
      - group3
  user2:
    ensure: present
    comment: 'User Two'
    uid: '701'
    gid: '702'
    groups:
      - group1
```

### Wrapper logic

The wrapper logic to manage the users and groups should ideally exist in either
the site.pp or a base profile that is applied to all nodes in your organization.

```puppet
# Fetch a list of managed groups
$managed_groups = hiera_hash(managed_groups)[groups]

# Create group resources based on the fetched list
$managed_groups.each | $group | {
  $g = hiera_hash(accounts::groups).filter | $key, $val | { $key == $group }
  create_resources('group', $g)
}

# Fetch list of managed users
$managed_users = hiera_array(managed_users)

# Create user resources based on the fetched list
$managed_users.each | $user | {
  $u = hiera_hash(accounts::users).filter | $key, $val | { $key == $user }
  notice ( $u )
}
```

##### Group Management logic

To manage groups the logic will use the hiera_hash() function to perform a merge
lookup to obtain a list of groups to manage. This returns a merged hash of matches
from throughout the hierarchy. In cases where two or more hashes share keys,
the hierarchy order determines which key/value pair will be used in the returned
hash, with the pair in the highest priority data source winning.

```puppet
$managed_groups = hiera_hash(managed_groups)[groups]
```

For each managed group in the fetched list the hiera_hash() function is again
used to perform a merge lookup. This returns a merged hash of matches from
throughout the hierarchy.

The create_resources() function is then used to mange the group resource with the
merged hash information provided from the hiera_hash lookup.

```puppet
$managed_groups.each | $group | {
  $g = hiera_hash(accounts::groups).filter | $key, $val | { $key == $group }
  create_resources('group', $g)
}
```

##### User Management logic

To manage users the logic will again use the hiera_array() function to perform
a merge lookup, to obtain a list of users to manage.

```puppet
$managed_users = hiera_array(managed_users)
```

For each managed user in the fetched list the hiera_hash() function is used to
perform a merge lookup. To obtain a merged hash of matches from throughout the
hierarchy.

The create_resources() function is then used to mange the user resource with the
merged hash information provided from the hiera_hash lookup.

```puppet
$managed_users.each | $user | {
  $u = hiera_hash(accounts::users).filter | $key, $val | { $key == $user }
  create_resources(pe_accounts::user, $u)
}
```

### Group Management

##### Specify Managed Groups

A list of groups that should be managed on the each system is populated via a
hiera_array lookup, which performs a merged lookup of the managed_groups element
in hiera.

```puppet
$managed_groups = hiera_array(managed_groups)
```

A common set of groups can be added at various levels of your hierarchy.

For example the commons.yaml file may contain a list of groups that should be
applied to every system in your infrastructure.


```yaml
common.yaml
---
managed_groups:
  groups:
   - group1
   - group2
   - group3
```

While the node specific "fqdn".yaml files may contain a list of groups that only
apply to a certain node.

> Note that you can use the knockout_prefix to exclude a group if desired

```yaml
nodes/test.example.dev.yaml
---
managed_groups:
  groups:
    - --group3
```

##### Modify Group Attributes

The attributes of a group can also be overridden at various levels of your hierarchy.

For example you can make sure a specific group is removed from a node or modify the gid.

```yaml
nodes/test.example.dev.yaml
---
accounts:groups:
  group1:
    ensure: absent
  group2:
    gid: '9999'
```

### User Management

##### Specify Managed Users

A list of users that should be managed on each system is populated via a
hiera_array lookup, which performs a merged lookup of the managed_users element
in hiera.

A common set of users can be added at various levels of your hierarchy.

For example the commons.yaml file may contain a list of users that should be
applied to every system in your infrastructure.

```yaml
common.yaml
---
managed_users:
  - user1
```

While the specific "fqdn".yaml files may contain a list of users that only
apply to a certain node.

> Note that you can use the knockout_prefix to exclude a group if desired

```yaml
nodes/test.example.dev.yaml
---
managed_users:
  - --user1
  - user2
```

##### Modify User Attributes

The attributes of a user can also be overridden at various levels of your hierarchy.

For example you can make sure a user is removed from a node, update
the comment or managed the gruop membership.

```yaml
nodes/test.example.dev.yaml
---
accounts::users:
  user1:
    ensure: present
    comment: 'User One Updated'
    groups:
      - --group3
  user2:
    comment: 'User Two Updated'
```
