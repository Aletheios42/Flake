{ pkgs, ... }:
let
  scriptsDir = ./.;

  # Nombres de scripts con dependencias especiales (se definen aparte)
  bootstrapNames = [
    "bootstrap-keygen.sh"
    "bootstrap-deploy.sh"
    "bootstrap-verify.sh"
  ];

  # Auto-discovery de scripts simples (sin deps especiales)
  simpleScripts = map (name: pkgs.writeShellScriptBin
    (builtins.replaceStrings [".sh"] [""] name)
    (builtins.readFile (scriptsDir + "/${name}"))
  ) (builtins.filter
    (name: builtins.match ".*\\.sh" name != null
           && !(builtins.elem name bootstrapNames))
    (builtins.attrNames (builtins.readDir scriptsDir))
  );

  # Bootstrap scripts con dependencias explicitas
  bootstrap-keygen = pkgs.writeShellApplication {
    name = "bootstrap-keygen";
    runtimeInputs = [ pkgs.openssh pkgs.ssh-to-age ];
    text = builtins.readFile ./bootstrap-keygen.sh;
  };

  bootstrap-deploy = pkgs.writeShellApplication {
    name = "bootstrap-deploy";
    runtimeInputs = [ pkgs.openssh pkgs.nix ];
    text = builtins.readFile ./bootstrap-deploy.sh;
  };

  bootstrap-verify = pkgs.writeShellApplication {
    name = "bootstrap-verify";
    runtimeInputs = [ pkgs.openssh pkgs.ssh-to-age ];
    text = builtins.readFile ./bootstrap-verify.sh;
  };
in
{
  userPackages.scripts = simpleScripts ++ [
    bootstrap-keygen
    bootstrap-deploy
    bootstrap-verify
  ];
}
