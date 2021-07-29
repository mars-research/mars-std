# Simple customization script for Cloudlab Ubuntu 20.04 images
#
# Really ugly, but something we have to deal with for now. Cloudlab/Emulab
# requires an agent (testbed.service) in the OS to dynamically create the
# project users. Probably can be made to work on NixOS but don't really have
# the time for it.
#
# The OS must phone home with the agent on boot. Otherwise, the machine will
# never enter "ready" state and will be forcibly power-cycled via IPMI after
# a while. This behavior can be disabled on a per-image basis by contacting
# the testbed admins (what we do with our OS dev images).
#
# In case you are feeling adventurous, keep in mind that the agent is in Perl
# and makes a lot of assumption about the filesystem layout. Good luck!

{ symlinkJoin, writeScript, writeShellScript, writeShellScriptBin, writeText

# direnv
, direnv

# utilities
, cachix
, git
, home-manager
, neovim
, mars-research

# terminfo
, alacritty
, kitty

# resize rootfs
, cloud-utils
, e2fsprogs
, gnugrep
, parted
, utillinux
}:

let
  neovimWithAlias = neovim.override {
    viAlias = true;
    vimAlias = true;
  };

  direnvProfile = writeScript "direnv.sh" ''
    export EDITOR=vim
    export PATH=$PATH:${direnv}/bin

    run_direnv_hook() {
      if [ -n "$BASH_VERSION" ]; then
        eval "$(direnv hook bash)"
      elif [ -n "$ZSH_VERSION" ]; then
        eval "$(direnv hook zsh)"
      fi
    }

    case "$-" in *i*) run_direnv_hook ;; esac
  '';

  # Naive script to grow the rootfs
  growScriptPath = symlinkJoin {
    name = "grow-script-path";
    paths = [
      e2fsprogs cloud-utils.guest utillinux gnugrep parted
    ];
  };

  growScript = writeShellScript "cloudlab-grow-root.sh" ''
    set -euo pipefail

    export PATH=${growScriptPath}/bin:$PATH

    TARGET=/dev/sda

    if [ ! -e $TARGET ]; then
      >&2 echo "$TARGET does not exist"
      exit 1
    fi

    echo "Disabling swap..."
    swapoff -a

    echo "Deleting swap partitions..."
    sfdisk -d $TARGET | grep -Ev 'type=(0|82)' | sfdisk --force $TARGET

    echo "Resizing root partition..."
    growpart $TARGET 1
    partprobe $TARGET

    echo "Resizing filesystem (this can take a while)..."
    resize2fs $TARGET*

    echo "All done!"
  '';

  growService = writeText "cloudlab-grow-root.service" ''
    [Unit]
    Description=Grow root partition

    [Service]
    Type=oneshot
    Restart=no
    ExecStart=${growScript}
  '';

  growLauncher = writeShellScriptBin "cloudlab-grow-root" ''
    echo "Warning: You will no longer be able to create a disk image from this node!"
    echo "You have 5 seconds to cancel by pressing Ctrl-C..."
    sleep 5

    sudo systemctl start cloudlab-grow-root.service
  '';
in writeShellScriptBin "cloudlab-ubuntu-customize" ''
  set -euo pipefail

  hostname | grep -Eq "cloudlab|emulab"
  if [[ $? != 0 ]]; then
    echo "This script should only be run on Cloudlab/Emulab machines."
    exit 1
  fi

  echo "Going to make changes. Press Ctrl-C to cancel."
  sleep 5

  echo "Setting up environment..."

  # Install terminfos
  cat ${alacritty.terminfo}/share/terminfo/a/alacritty > /usr/lib/terminfo/a/alacritty
  cat ${kitty.terminfo}/share/terminfo/x/xterm-kitty > /usr/lib/terminfo/x/xterm-kitty

  # Install direnv profile
  cat ${direnvProfile} > /etc/profile.d/direnv.sh
  ln -sf ${direnvProfile} /nix/var/nix/gcroots/direnv-profile

  # Install utilities
  /nix/var/nix/profiles/default/bin/nix-env -i ${cachix} ${git} ${home-manager} ${neovimWithAlias} ${mars-research.mars-tools}

  # Install rootfs grow script
  cat ${growService} > /etc/systemd/system/cloudlab-grow-root.service
  ln -sf ${growScript} /nix/var/nix/gcroots/grow-script
  /nix/var/nix/profiles/default/bin/nix-env -i ${growLauncher}

  # Remove motd ad
  echo "ENABLED=0" > /etc/default/motd-news
  systemctl start motd-news

  # Configure nix
  cp ${./nix.conf} /etc/nix/nix.conf

  # Make nix-copy-closure work
  ln -sf /nix/var/nix/profiles/default/bin/nix-store /usr/local/bin/nix-store

  echo 'All done! Click the "Create Disk Image" button on the web portal to take a snapshot'
''
