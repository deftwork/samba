#!/bin/bash

CONFIG_FILE="/etc/samba/smb.conf"

hostname=`hostname`
set -e
if [[ ! -f $CONFIG_FILE ]]
then
cat >"$CONFIG_FILE" <<EOT
[global]
workgroup = WORKGROUP
netbios name = $hostname
server string = $hostname
security = user
create mask = 0664
directory mask = 0775
force create mode = 0664
force directory mode = 0775
#force user = smbuser
#force group = smbuser
load printers = no
printing = bsd
printcap name = /dev/null
disable spoolss = yes
guest account = nobody
max log size = 50
map to guest = bad user
socket options = TCP_NODELAY SO_RCVBUF=8192 SO_SNDBUF=8192
local master = no
dns proxy = no
EOT
fi
  while getopts ":u:s:h" opt; do
    case $opt in
      h)
        cat <<EOH
Samba server container

ATTENTION: This is a recipe highly adapted to my needs, it might not fit yours.
Deal with local filesystem permissions, container permissions and Samba permissions is a Hell, so I've made a workarround to keep things as simple as possible.
I want avoid that the usage of this conainer would affect current file permisions of my local system, so, I've "synchronized" the owner of the path to be shared with Samba user. This mean that some commitments and limitations must be assumed.

Container will be configured as samba sharing server and it just needs:
 * host directories to be mounted,
 * users (one or more uid:gid:username:usergroup:password tuples) provided,
 * shares defined (name, path, users).

 -u uid:gid:username:usergroup:password         add uid from user p.e. 1000
                                                add gid from group that user belong p.e. 1000
                                                add a username p.e. alice
                                                add a usergroup (wich user must belong) p.e. alice
                                                protected by 'password' (The password may be different from the user's actual password from your host filesystem)

 -s name:path:rw:user1[,user2[,userN]]
                              add share, that is visible as 'name', exposing
                              contents of 'path' directory for read+write (rw)
                              or read-only (ro) access for specified logins
                              user1, user2, .., userN

To adjust the global samba options, create a volume mapping to /config

Example:
docker run -d -p 445:445 \\
  -- hostname any-host-name \\ # Optional
  -v /any/path:/share/data \\ # Replace /any/path with some path in your system owned by a real user from your host filesystem
  elswork/samba \\
  -u "1000:1000:alice:alice:put-any-password-here" \\ # At least the first user must match (password can be different) with a real user from your host filesystem
  -u "1001:1001:bob:bob:secret" \\
  -u "1002:1002:guest:guest:guest" \\
  -s "Backup directory:/share/backups:rw:alice,bob" \\ 
  -s "Alice (private):/share/data/alice:rw:alice" \\
  -s "Bob (private):/share/data/bob:rw:bob" \\
  -s "Documents (readonly):/share/data/documents:ro:guest,alice,bob"

EOH
        exit 1
        ;;
      u)
        echo -n "Add user "
        IFS=: read uid group username groupname password <<<"$OPTARG"
        echo -n "'$username' "
        getent group | grep "$groupname:x:$group" &>/dev/null || addgroup -g "$group" -S "$groupname"
        getent passwd | grep "$username:x:$uid:$group" &>/dev/null || adduser -u "$uid" -G "$groupname" "$username" -SHD
        echo "with password '$password' "
        echo "$password" | tee - | smbpasswd -s -a "$username"
        echo "DONE"
        ;;
      s)
        echo -n "Add share "
        IFS=: read sharename sharepath readwrite users <<<"$OPTARG"
        echo -n "'$sharename' "
        echo "[$sharename]" >>"$CONFIG_FILE"
        echo -n "path '$sharepath' "
        echo "path = \"$sharepath\"" >>"$CONFIG_FILE"
        echo -n "read"
        if [[ "rw" = "$readwrite" ]] ; then
          echo -n "+write "
          echo "read only = no" >>"$CONFIG_FILE"
          echo "writable = yes" >>"$CONFIG_FILE"
        else
          echo -n "-only "
          echo "read only = yes" >>"$CONFIG_FILE"
          echo "writable = no" >>"$CONFIG_FILE"
        fi
        if [[ -z "$users" ]] ; then
          echo -n "for guests: "
          echo "browseable = yes" >>"$CONFIG_FILE"
          echo "guest ok = yes" >>"$CONFIG_FILE"
          echo "public = yes" >>"$CONFIG_FILE"
        else
          echo -n "for users: "
          users=$(echo "$users" |tr "," " ")
          echo -n "$users "
          echo "valid users = $users" >>"$CONFIG_FILE"
          echo "write list = $users" >>"$CONFIG_FILE"
        fi
        echo "DONE"
        ;;
      \?)
        echo "Invalid option: -$OPTARG"
        exit 1
        ;;
      :)
        echo "Option -$OPTARG requires an argument."
        exit 1
        ;;
    esac
  done
nmbd -D
exec ionice -c 3 smbd -F --no-process-group --configfile="$CONFIG_FILE" < /dev/null
