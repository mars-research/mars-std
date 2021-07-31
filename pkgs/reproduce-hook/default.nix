{ lib, ncurses, python3, runCommand }:

let
  inherit (lib) mkOption types;

  schema = {
    options = {
      cloudlab = mkOption {
        description = ''
          The CloudLab/Emulab instance type to require.

          If true, all instance types are accepted.
        '';
        type = types.either types.bool types.str;
        example = "c220g2";
        default = false;
      };
      pci = mkOption {
        description = ''
          PCI(e) devices to require.
        '';
        type = types.listOf pciType;
        example = [
          { pciId = "808610fb"; description = "Intel 82599 10GbE NIC"; }
        ];
        default = [];
      };
      notes = mkOption {
        description = ''
          Notes that will be printed.
        '';
        type = types.str;
        default = "";
      };
    };
  };

  pciType = types.submodule {
    options = {
      pciId = mkOption {
        description = "PCI ID";
        example = "10de1171";
        type = types.str;
      };
      description = mkOption {
        description = "Human-readable description";
        example = "NVIDIA Tesla M40 GPU";
        type = types.nullOr types.str;
        default = null;
      };
    };
  };

  pyVerifier = python3.withPackages (ps: [ ps.colorama ]);

  wrapperSource = "https://github.com/mars-research/mars-std/blob/master/pkgs/reproduce-hook/default.nix";
in

{ name ? "reproduce"              # Name
, shellName ? "reproduce"         # Shell attribute name
, requirements ? {}               # Requirements
, script                          # Script
, teamEmail ? "aburtsev@uci.edu"  # E-mail
, citation ? ""                   # Preferred Citation
, ...
} @ args:

let
  extraArgs = builtins.removeAttrs args [ "name" "shellName" "requirements" "script" "teamEmail" "citation" ];
  checkedRequirements = (lib.evalModules {
    modules = [
      schema 
      {
        config = requirements;
      }
    ];
  }).config;

  colorSnippet = ''
    seq_bold=$(${ncurses}/bin/tput bold)
    seq_normal=$(${ncurses}/bin/tput sgr0)
    seq_green=$(${ncurses}/bin/tput setaf 2)
    seq_yellow=$(${ncurses}/bin/tput setaf 3)

    bold() {
      echo -n "$seq_bold$@$seq_normal"
    }

    highlight() {
      echo -n "$seq_bold$seq_green$@$seq_normal"
    }

    highlightcmd() {
      echo -n "$seq_bold$seq_yellow$@$seq_normal"
    }
  '';

  cannotBeBuilt = attribute: ''
    ${colorSnippet}

    echo "This derivation cannot be built. You can run it with $(highlight nix-shell -A ${attribute})."
    exit 1
  '';

  inspect = runCommand "inspect-hook" (extraArgs // {
    preferLocalBuild = true;
    allowSubstitutes = false;
    shellHookOnly = true;

    shellHook = ''
      ${colorSnippet}

      echo "$(highlight How To Inspect the Reproduction Script)"
      echo
      echo "The script along with system requirements are defined"
      echo "in the file $(highlight flake.nix)."
      echo
      echo "We make use of a wrapper which will create the output"
      echo "directories, verify system requirements and finally run"
      echo "the actual script. This wrapper is available at [1]. You"
      echo "can see the exact version (git commit hash) of the wrap-"
      echo "per in use by inspecting $(highlight flake.lock) and searching for"
      echo "\"mars-std\"."
      echo
      echo "[1] $(highlight ${wrapperSource})."

      exit 0
    '';
  }) (cannotBeBuilt "${shellName}.inspect");

  hook = runCommand "reproduce-hook" (extraArgs // {
    inherit name shellName teamEmail citation;

    preferLocalBuild = true;
    allowSubstitutes = false;
    shellHookOnly = true;

    REQUIREMENTS = builtins.toJSON checkedRequirements;

    shellHook = ''
      set -euo pipefail

      ${colorSnippet}

      tmp=$(mktemp -d)
      >&2 echo "Created temporary directory $(bold $tmp)."

      out=repro-$(date -Iseconds)
      mkdir $out
      >&2 echo "Created results directory $(highlight $out)."

      cd $tmp

      >&2 echo "Checking system requirements..."
      ${pyVerifier}/bin/python ${./verify-environment.py}

      >&2 echo
      >&2 echo "=========="
      ${script}
      >&2 echo "=========="
      >&2 echo

      rm -rf $tmp

      >&2 echo "The reproduction script ran successfully."
      >&2 echo
      >&2 echo "Next steps:"
      >&2 echo "1. The results are available under the directory $(highlight $out)."
      >&2 echo "2. Were you able to reproduce the results? Have you encountered any problems? Let us know! Please send us an email at $(bold $teamEmail)."

      if [ -n "$citation" ]; then
        >&2 echo "3. Please use the following citation:"
        >&2 echo "$citation"
      fi

      >&2 echo
      >&2 echo "To see how you can inspect the process: $(highlightcmd nix-shell -A $shellName.inspect)"

      exit 0
    '';
  }) (cannotBeBuilt shellName);
in hook // {
  inherit inspect;
}
