# Home Intercom

Really, this is my attempt to setup a system for providing intercom
functionality between rooms in my house.  There are other parts
to this project as well (a transcoding server, Kurento for the ability
to monitor IP cameras, and a home automation server.)

Right now these all run on a small intel NUC with a 250 GB SSD, and 
running XEN, with each system being setup with it's own LVM volume 
for storage.

The first setup in setup is to install fusionpbx on Debian (Jessie) using
the install script that they provide.

Once you have that setup, you'll need to add a set of firewall rules to
/etc/iptables/rules.v4, like the following (I stick it just below the 
port 443 rule):

```
-A INPUT -p tcp -m tcp --dport 7443 -j ACCEPT
```

This rule allows the WebRTC server to properly support inbound connections.

Next, go into the fusionpbx UI, and make the following changes:

#.  Under Advanced --> Variables add the following:
    - Edit "global_codec_prefs" and add ",VP8,VP9" to the end of the value.
    - Edit "outbound_codec_prefs" and add ",VP8,VP9" to the end of the value.


> Despite documentation you might read to the contrary, with the latest version of FreeSwitch the VP8 and VP9
> codecs are compiled into the server, you need not add/enable any modules in order to get the
> support.  Just add them into the codecs and you will be set.


    - Under "SIP Profile: External", make the following changes/additions (if it's already there, change it
      if not, add it!)
         - external_tls_port = 5081
         - external_ssl_enable = true
         - external_ssl_dir = $${conf_dir}/tls
    - Under "SIP Profile: Internal", make the following changes/additions (if it's already there, change it
      if not, add it!)
         - internal_tls_port = 5081
         - internal_ssl_enable = true
         - internal_ssl_dir = $${conf_dir}/tls

#. Under Advanced --> SIP Profiles --> Internal add the following:
    - wss-binding = :7443

####
Setting up SSL
####

None of the above settings (All that you need to change to get WebRTC working) will work until you have your SSL
certificates setup.  That's what this section is about:


1.  Submit your certificate request to your signing authority and get back the resulting files (typically a certificate, key, and chain set of files.)

2. Create a new file called agent.pem, like so:

   - ```cat <CERTIFICATE>.crt > agent.pem```
   - ```cat <CERTIFICATE>.key >> agent.pem```
   - ```cat <CERTIFICATE>.chain >> agent.pem```

3.  Copy the resulting file to /etc/freeswitch/tls:

   - ```sudo cp agent.pem /etc/freeswitch/tls```
   - ```sudo cp agent.pem /etc/freeswitch/tls/wss.pem```
   - ```sudo chown www-data.www-data /etc/freeswitch/{agent,wss}.pem```
   - ```sudo chmod o-rwx /etc/freeswitch/{agent,wss}.pem```
   
4. Copy the CA file (provided by you cert signing authority) to /etc/freeswitch/tls/cafile.pem:

  - ```sudo cp <CERTFILE> /etc/freeswitch/tls/cafile.pem```

5.  Setup your nginx config for fusionpbx so it uses the same signed
    certificate, so then visiting the site in your web browser won't
    result in untrusted server/unsigned key warnings.
 
   - Copy the certificate, key, and bundoe to /etc/ssl/private (there are
      other places that the files could go also, but I just stuck them all in
      the same directory.)
   - Make sure the key file has www-data.www-data ownership, and isn't world readable.
   - sudo vi /etc/nginx/sites-available/fusionpbx ensure the following lines are set to match (modify as needed:)

```    
        ssl_certificate         /etc/ssl/private/<CERTIFICATE>crt;
        ssl_certificate_key     /etc/ssl/private/<CERTIFICATE>.key;
        ssl_trusted_certificate /etc/ssl/private/<CERTIFICATE>.ca-bundle;
```

####
Restarting the Server
####

At this point I would just reboot the server, you could 
get by by simply restarting nginx and freeswitch, and 
reloading the iptables rules, but a reboot does it also.


####
Verifying stuff works
####

1.  You should see a 'WSS-BIND-URL' when looking at the cli output:

```
     fs_cli -x 'sofia status profile internal' | grep WSS-BIND-URL
```

2.   The netstat output should show you that freeswitch listens on ports 7443,
     5061, 5060, 5081, 5080 and 8021 (note that 8021 is for signalling, and it 
     only listens on 127.0.0.1):
     
     ```
     sudo netstat -tapn|grep freeswitch
     ```

3.  You should be able to connect with openssl to the various ports (and find that
    the certs are valid:)

```
    openssl s_client -connect <HOSTNAME>:443
    openssl s_client -connect <HOSTNAME>:5061
    openssl s_client -connect <HOSTNAME>:5081
    openssl s_client -connect <HOSTNAME>:7443
```


