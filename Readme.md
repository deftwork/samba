# Samba

A [Docker](http://docker.com) file to build images for AMD & ARM devices with a installation of [Samba](https://www.samba.org/) that is the standard Windows interoperability suite of programs for Linux and Unix. This is my personal Multi-architecture docker recipe.

> Be aware! You should read carefully the usage documentation of every tool!

## Thanks to

- [Samba](https://www.samba.org/)
- [dastrasmue rpi-samba](https://github.com/dastrasmue/rpi-samba)

## Details

- [GitHub](https://github.com/DeftWork/samba)
- [Deft.Work my personal blog](http://deft.work/Samba)

| Docker Hub | Docker Pulls | Docker Stars | Size/Layers |
| --- | --- | --- | --- |
| [samba](https://hub.docker.com/r/elswork/samba "elswork/samba on Docker Hub") | [![](https://img.shields.io/docker/pulls/elswork/samba.svg)](https://hub.docker.com/r/elswork/samba "elswork/samba on Docker Hub") | [![](https://img.shields.io/docker/stars/elswork/samba.svg)](https://hub.docker.com/r/elswork/samba "elswork/samba on Docker Hub") | [![](https://images.microbadger.com/badges/image/elswork/samba.svg)](https://microbadger.com/images/elswork/samba "elswork/samba on microbadger.com") |

## Build Instructions

Build for amd64, armv7l, aarch64 architecture (thanks to its [Multi-Arch](https://blog.docker.com/2017/11/multi-arch-all-the-things/) base image)

``` sh
docker build -t elswork/samba .
```

## Usage

I use it to share files between Linux and Windows, but it has many other capabilities. 

### Serve 

Start a samba fileshare.


``` sh
docker run -d -p 137:137/udp -p 138:138/udp -p 139:139 -p 445:445 -p 445:445/udp --hostname 'filer' -v /mnt/store/smb:/share/folder  elswork/samba -u "your_username:your_password" -s "FileShare:/share/folder:rw:your_username"
``` 
On Windows point your filebrowser to `\\host-ip\FileShare` to preview site.
