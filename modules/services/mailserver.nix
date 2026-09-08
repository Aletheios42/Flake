{ lib, config, ... }:
{
  options.correo = {
    enable = lib.mkEnableOption "activa el servidor de correo";
    fqdn = lib.mkOption { 
      type = lib.types.str;
      default = ""; 
    };
    dominios = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };

    accounts = lib.mkOption {
      description = "Listado de cuentas de correo";
      default = {};
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          hashedPassword = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null; 
            description = "crea hashes con 'mkpasswd -s'";
          };
          aliases = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
          };
          sieveScript = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Script Sieve para filtrado y orden automático de correos en el servidor";
          };
        };
      });
    };
  };

  config = lib.mkIf (config.correo.enable) {
    assertions = [
      {
        assertion = lib.all (p: builtins.elem p config.networking.firewall.allowedTCPPorts) [80 25 465 587 993 995];
        message = "mailserver: necesitas abrir 80, 25, 465, 587 y 993 995 en red.puertosPermitidos";
      }
      {
        assertion = config.correo.fqdn != "";
        message = "mailserver: necesitas tener un dominio";
      }
      {
        assertion = config.correo.dominios != [];
        message = "mailserver: necesitas al menos un dominio en correo.dominios";
      }
      {
        assertion = config.sops.enable;
        message = "mailserver requiere sops (sops.enable) para las credenciales de Mailgun";
      }
    ];

    # Secretos y plantilla para el mapa SASL de Postfix
    sops.secrets."mailgun/user" = {};
    sops.secrets."mailgun/password" = {};

    sops.templates."postfix-mailgun-sasl" = {
      owner = "postfix";
      group = "postfix";
      mode = "0400";
      content = ''
        [smtp.mailgun.org]:587 ${config.sops.placeholder."mailgun/user"}:${config.sops.placeholder."mailgun/password"}
      '';
    };

    # https://letsencrypt.org/repository/#let-s-encrypt-subscriber-agreement
    security.acme.acceptTerms = true;

    # Enable ACME HTTP-01 challenge with nginx
    services.nginx = {
      enable = true;
      virtualHosts.${config.correo.fqdn} = {
        useACMEHost = "wildcard";
        forceSSL = true;
      };
    };

    mailserver = {
      enable = true;
      stateVersion = 5;
      fqdn = config.correo.fqdn;
      domains = config.correo.dominios;
      accounts = config.correo.accounts;
      # Clave DKIM generada en rspamd
      dkim.keyDirectory = "/var/lib/rspamd/dkim";
      # Reference the existing ACME configuration created by nginx
      x509.useACMEHost = "wildcard"; 
    };

    # Configuración de Postfix para el relay con Mailgun
    services.postfix.settings.main = {
      relayhost = [ "[smtp.mailgun.org]:587" ];
      smtp_sasl_auth_enable = "yes";
      smtp_sasl_security_options = "noanonymous";
      smtp_sasl_password_maps = [ "texthash:${config.sops.templates."postfix-mailgun-sasl".path}" ];
      smtp_tls_security_level = lib.mkForce "encrypt";
      smtp_tls_note_starttls_offer = "yes";
    };

    # Gestión declarativa de permisos y carpetas del sistema
    systemd.tmpfiles.rules = [
      "d /var/lib/rspamd 0750 rspamd rspamd -"
      "d /var/lib/rspamd/dkim 0750 rspamd rspamd -"
      "d /var/vmail 0770 virtual-mail virtual-mail -"
      "d /var/lib/postfix 0700 postfix postfix -"
      "d /var/lib/dovecot 0755 dovecot2 dovecot2 -"
    ];

    environment.persistence."/persist/" = lib.mkIf (config.impermanencia.enable) {
      directories = [
        {directory = "/var/vmail"; mode = "0750";}
        {directory = "/var/lib/rspamd"; mode = "0750";}
        {directory = "/var/lib/postfix"; mode = "0750";}
        {directory = "/var/lib/dovecot"; mode = "0750";}
      ];
    };
  };
}
