# Setting up debian bullseye chrooot in WSL2

## Installing WSL2 and debootstrap
Open windows terminal and do `wsl --install`, and reboot when prompted. On reboot, do `wsl -l -v` and ensure it's WSL version 2. If it's version 1, run `wsl --set-default-version 2`.

Open wsl2 by typing `wsl2`. Now we will prepare the host. Run the following inside WSL2:

```
sudo apt update && sudo apt upgrade -y
sudo apt install -y qemu-user-static binfmt-support debootstrap
sudo mkdir -p /mnt/arm64-bullseye
```

Download the base system: `sudo debootstrap --arch=arm64 --variant=minbase bullseye /mnt/arm64-bullseye http://deb.debian.org/debian/`

Link the emulator: `sudo cp /usr/bin/qemu-aarch64-static /mnt/arm64-bullseye/usr/bin/`

Mount the filesystems: `for i in dev dev/pts proc sys; do sudo mount --bind /$i /mnt/arm64-bullseye/$i; done`

## Getting into chroot and finishing setup
Run `sudo chroot /mnt/arm64-bullseye /bin/bash` to get into chroot. Once inside, run the following:

```
/debootstrap/debootstrap --second-stage
apt update
```

## Reaccessing
If you run windows terminal as admin you will start in your user folder `C:\Users\USER`. To access your build environment quickly, create a new file at this location and name it `bullseye.sh`. Open it in a text editor and paste the following:

```bash
#!/bin/bash
# Register QEMU
sudo docker run --rm --privileged multiarch/qemu-user-static --reset -p yes > /dev/null 2>&1

# Define path
TARGET="/mnt/data/arm64-bullseye"

# Mount essential filesystems
sudo mountpoint -q $TARGET/proc || sudo mount --bind /proc $TARGET/proc
sudo mountpoint -q $TARGET/dev  || sudo mount --bind /dev $TARGET/dev
sudo mountpoint -q $TARGET/sys  || sudo mount --bind /sys $TARGET/sys
sudo cp /etc/resolv.conf $TARGET/etc/resolv.conf

echo -ne "\033]0;Bullseye Chroot\007"
echo "Welcome to bullseye chroot (ARM64)!"

# Enter chroot
sudo chroot $TARGET /bin/bash
```

Save it, and when you open windows terminal you can simply run:

```
wsl
./bullseye.sh`
```

You may be prompted to create a password for the root user.