pi-server: Setup a Raspberry Pi to run Nextcloud and Plex
--
Dependencies / Assumptions:
1. This was developed on Rasperian 9. It may work on other Debian-based
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
   symbols, which might get interpreted by the shell).
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
   volume group called `nc-data`, a logical volume called `lv-data`
   and then formatted with a BTRFS file system.
   TODO: Provide more details on this step.
--
Steps:
1. Boot your pi from a fresh image. These scripts were developed under
   Rasperian, 2018-11-13 version.
2. If your image has not been configured to start ssh automatically, log
   in on console. Otherwise, I recommend copying your ssh key onto the pi
   with `ssh-copy-id -i .ssh/id_ecdsa.pub pi@$PIIP` where you may need
   to use a different public keyfile, and $PIIP is the IP of your PI (or
   hostname if that resolves on your network). The IP displays on the
   console when the PI boots, otherwise you can do a websearch for tools
   to discover it. Then you can `ssh pi@$PIIP`.
3. `sudo apt -y install git`
4. `git clone https://github.com/drzow/pi-server.git` (or your fork
   thereof)
5. `cd pi-server`
6. `./stage1.sh` This will reboot your pi.
7. If you did not set up ssh back in step (2), you should do so now, then
   `ssh pi@$PIIP`
8. `cd pi-server`
9. `./stage2.sh <1PasswordRepo> <1PasswordEmail>` where <1PasswordRepo>
   is the name of your 1Password instance, which you can access at
   https://<1PasswordRepo>.1password.com and <1PasswordEmail> is the
   email address used as the username for your 1Password account. As
   the second stage runs, it will prompt you for your account Secret
   Key, which is like a 40 character alphanumeric key with sections
   separated by dashes, then it will prompt you for your master password,
   which is the one you use all the time to unlock 1Password. It is
   best to be ssh'ed into your pi from a desktop where you have 1Password
   access such that you can copy both the secret key and your master
   password from your vault into your terminal. Stage 2 will update the
   system, set the password, configure Git, install docker, lvm, and
   a bunch of supporting packages, then reboot the pi again.
10. `ssh pi@$PIIP`
11. `cd pi-server`
12. `./stage3.sh <User>` This will mount the USB drive then pull and run the
    Nextcloud and Plex docker images. <User> should be the username of the
    regular NextCloud user you created or will create (in the next step)
    whose account will hold all of your Plex media.
13. If you previously set up NextCloud, stage 4 will run for you
    automatically, launch plex, and you are done! Otherwise, you can
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
    `./stage4.sh <User>`, which will launch Plex.
16. Enjoy!

