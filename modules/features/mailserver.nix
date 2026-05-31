{ lib, config, ... }:
{
  options.mi_mailserver = {
    enable = lib.mkEnableOption "Activa el servidor de correo";
    loginAccounts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          hashedPasswordFile = lib.mkOption { type = lib.types.str; };
          aliases = lib.mkOption { type = lib.types.listOf lib.types.str; default = []; };
        };
      });
      description = "Cuentas de correo del servidor";
    };
  };

  config = lib.mkIf config.mi_mailserver.enable {
    assertions = [
      {
        assertion = config.vars.dominio != "";
        message = "El dominio debe estar configurado para usar el mailserver.";
      }
      {
        assertion = config.mi_mailserver.loginAccounts != {};
        message = "Debe haber al menos una cuenta de correo configurada.";
      }
    ];

    mailserver = {
      enable = true;
      fqdn = "mail.${config.vars.dominio}";
      domains = [ config.vars.dominio ];
      
      loginAccounts = config.mi_mailserver.loginAccounts;

      certificateScheme = "acme-nginx";

      enableImap = true;
      enableImapSsl = true;
      enableSubmission = true;
      enableSubmissionSsl = true;

      virusScanning = false;
      
      enableNixpkgsReleaseCheck = false;
    };
  };
}
