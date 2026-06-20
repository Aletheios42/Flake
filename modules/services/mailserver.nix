{ lib, config, ... }:
{
  options.mi_mailserver = {
    enable = lib.mkEnableOption "Activa el servidor de correo";
    accounts = lib.mkOption {
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
        assertion = config.mi_mailserver.accounts != {};
        message = "Debe haber al menos una cuenta de correo configurada.";
      }
      {
        assertion = config.mi_sops.enable;
        message = "mi_mailserver requiere sops (mi_sops.enable)";
      }
    ];

    sops.secrets."mailserver/admin_pass" = {};
    # Configuramos un bloque de Nginx ficticio para forzar a ACME a generar 
    # el certificado del subdominio mail.
    services.nginx.virtualHosts."mail.${config.vars.dominio}" = {
      enableACME = true;
      forceSSL = true;
    };

    mailserver = {
      enable = true;
      fqdn = "mail.${config.vars.dominio}";
      domains = [ config.vars.dominio ];
      
      accounts = config.mi_mailserver.accounts;

      stateVersion = 4; 

      # Usamos el certificado ACME generado por Nginx
      x509.useACMEHost = "mail.${config.vars.dominio}";

      enableImap = true;
      enableImapSsl = true;
      enableSubmission = true;
      enableSubmissionSsl = true;

      virusScanning = false;
      
      enableNixpkgsReleaseCheck = false;
    };

    myImpermanence.system.directories = [ "/var/lib/dovecot" "/var/lib/postfix" "/var/vmail" ];
  };
}
