{ python3, runCommand }:

{ requirements ? {} # Requirements
, script            # Script
, ...
} @ args:

let
  extraArgs = builtins.removeAttrs args [ "requirements" "script" ];
in runCommand "reproduce-hook" (extraArgs // {
  preferLocalBuild = true;
  allowSubstitutes = false;
  shellHookOnly = true;

  REQUIREMENTS = builtins.toJSON requirements;

  shellHook = ''
    set -euo pipefail

    ${python3}/bin/python ${./verify-environment.py}

    ${script}

    exit 0
  '';
}) ''
  echo This derivation cannot be built. You can run it with nix-shell.
  exit 1
''
