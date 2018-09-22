
Build the latest Samba from the sources and run it in a Docker container with
a user provided configuration



## Usage

### Run with docker-compose

Here is an example of **docker-compose** file :

```yaml
---
version: '3'
  services:
    samba:
      build: ./samba
      image: samba:fromsrc
      hostname: samba
      deploy:
        resources:
          limits:
            cpus: '0.5'
            memory: 256M
      restart: always
      volumes:
        - "/var/lib/sss/pipes/:/var/lib/sss/pipes/"
        - "/srv/samba-share/etc:/usr/local/samba/etc"
        - "/srv/samba-share/private:/usr/local/samba/private"
        - "/srv/samba-share/locks:/usr/local/samba/locks"
        - "/srv/samba-share/home:/home"
        - "/data/share:/data/share"
      ports:
        - "192.168.0.10:137:137/udp"
        - "192.168.0.10:138:138/udp"
        - "192.168.0.10:139:139"
        - "192.168.0.10:445:445"
```

### Persistent volumes

* /var/lib/sss/pipes/ : to use auth user authentication
* /usr/local/samba/etc/ : Samba configuration
* /usr/local/samba/private/ : Samba persistent data
* /home/ : Use home directories
* .... : Whatever shared directories defined in Samba configuration
