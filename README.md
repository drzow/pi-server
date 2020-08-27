pi-server: Setup a Raspberry Pi to run Nextcloud, Plex, and Samba
--
Dependencies / Assumptions:
1. This was developed on Rasperian 9. Testing is currently underway
   on Rasperian 10. It may work on other Debian-based
   systems.
2. You are using a US locale and keyboard; adjust the keyboard file
   appropriately if this is not the case.
3. You are in US/Central timezone; adjust stage2.sh appropriately if
   this is not the case. Given some demand, I could easily make this
   configurable.
3. You are using 1Password for password management, specifically the
   modern online instance, not the old stand alone software. I would
   be interested in patches that provide support for other password
   managers in a plugable fashion.
4. You will need a "Nextcloud" server entry with a strong password in
   the password field. I recommend 32 characters, alphanumeric (no
   symbols, which might get interpreted by the shell). The entry should
   also have a section titled "Backups" with a field labeled "username"
   containing the backups username you wish to use and a field labeled
   "password" with a strong password (as above). The password may be
   hidden.
5. You will need a "GitHub" login entry in 1Password with your username
   in its normal field and an "Additional Info" section with three
   key:value pairs:
   1. "email" with the email address you use for Git
   2. "name" with the name you use for Git
   3. "token" with a personal access token for GitHub (this assumes you
      have two-factor authentication set up for GitHub. You _do_ have
      two-factor turned on, don't you?)
6. The GitHub info was to make it convienient for me to work on these
   scripts. If others are not interested in that, it could be made
   optional.
7. The USB Drive is set up ahead of time as a LVM volume with a
   volume group called `nc_data`, a logical volume called `lv_data`,
   another logical volume called `backups`, 
   and both are formatted with a BTRFS file system.
   1. `sudo fdisk /dev/sda` (or whatever the block device is for your
      drive -- you can also use the /dev/disk/by-id/<ID> or any equalvalent
      path.
   2. If necessary, create the partition: `n`, `p`, `1`, `<Enter>`,
      `<Enter>`
   3. Set the partition type to Linux LVM: `t`, `8e`
   4. Write the updated partition table: `w`
   5. Make the partition an LVM physical volume: `sudo pvcreate /dev/sda1`
   6. Create the volume group: `sudo vgcreate nc_data /dev/sda1`
   7. Create the logical lv_data volume:
      `sudo lvcreate --size <VolumeSize>[KMGTPE] --name lv_data nc_data`
      Make the size however much you want to devote to Nextcloud/Plex.
   8. Create the BTR file system on it:
      `sudo mkfs.btrfs /dev/nc_data/lv_data`
   9. Create the logical backup volume:
      `sudo lvcreate --extents 100%FREE --name backups nc_data`
      This uses the rest of the physical volume for backups.
   10. Create the BTR file system on it:
       `sudo mkfs.btrfs /dev/nc_data/backups`

--

Steps:
1. Boot your pi from a fresh image. These scripts were developed under
   Rasperian, 2018-11-13 version.
2. If your image has not been configured to start ssh automatically, log
   in on console. Otherwise, I recommend copying your ssh key onto the pi
   with `ssh-copy-id -i ~/.ssh/id_ecdsa.pub pi@$PIIP` where you may need
   to use a different public keyfile, and $PIIP is the IP of your PI (or
   hostname if that resolves on your network). The IP displays on the
   console when the PI boots, otherwise you can do a websearch for tools
   to discover it. Then you can `ssh pi@$PIIP`.
3. `sudo apt -y install git`
4. `git clone https://github.com/drzow/pi-server.git` (or your fork
   thereof)
5. `cd pi-server/shell`
6. `./stage1.sh <hostname> <domain>` This will reboot your pi.
7. If you did not set up ssh back in step (2), you should do so now, then
   `ssh pi@$PIIP`
8. `cd pi-server/shell`
9. `./stage2.sh` 
   Stage 2 will update the
   system, configure Git, install docker, lvm, and
   a bunch of supporting packages, then reboot the pi again.
10. `ssh pi@$PIIP`
11. `cd pi-server/shell`
12. `./stage3.sh <1PasswordRepo> <1PasswordEmail> <User>`
    where <1PasswordRepo>
    is the name of your 1Password instance, which you can access at
    https://<1PasswordRepo>.1password.com and <1PasswordEmail> is the
    email address used as the username for your 1Password account. As
    the third stage runs, it will prompt you for your account Secret
    Key, which is like a 40 character alphanumeric key with sections
    separated by dashes, then it will prompt you for your master password,
    which is the one you use all the time to unlock 1Password. It is
    best to be ssh'ed into your pi from a desktop where you have 1Password
    access such that you can copy both the secret key and your master
    password from your vault into your terminal.
    The third stage will set the password,
    mount the USB drive then pull and run the
    Nextcloud docker image. <User> should be the username of the
    regular NextCloud user you created or will create (in the next step)
    whose account will hold all of your Plex media.
13. If you previously set up NextCloud, stage 4 will run for you
    automatically, launch plex and samba, and you are done! Otherwise, you can
    now go to https://$PIIP:4443 to set up NextCloudPi. Create a
    regular user, then log in as them, create a `Media` folder
    from your top-level page (so you should see it between the
    default `Documents` and `Photos` directories if you do not touch
    those). Go into the `Media` folder and create a `Plex` folder.
    Go into the `Plex` folder and create four folders:
    - `Config`
    - `Movies`
    - `Transcoding`
    - `TV`
    You can start populating the Movies and TV folders with material
    as you see fit.
15. If you just configured your folders, you will need to run
    `./stage4.sh <1PasswordRepo> <1PasswordEmail> <User>`,
    which will launch Plex. Where the arguments are as described for
    stage3.sh .
16. Enjoy!

