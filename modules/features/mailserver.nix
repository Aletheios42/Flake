{ config, ... }: {
  # mailserver = {
  #   enable = true;
  #   fqdn = "mail.alejandropintosalcarazo.com";
  #   domains = [ "alejandropintosalcarazo.com" ];
  #   loginAccounts = {
  #     "aletheios42@alejandropintosalcarazo.com" = {
  #       hashedPasswordFile = config.sops.secrets."mailserver/aletheios42Pass".path;
  #       aliases = [ "admin@alejandropintosalcarazo.com" ];
  #     };
  #   };
  #   certificate = {
  #     useACMEHost = "mail.alejandropintosalcarazo.com";
  #   };
  #   enableImap = true;
  #   enableImapSsl = true;
  #   enableSubmission = true;
  #   enableSubmissionSsl = true;
  # };

  # DNS records necesarios (añadir en tu registrar):
  # MX  alejandropintosalcarazo.com → mail.alejandropintosalcarazo.com
  # A   mail.alejandropintosalcarazo.com → TU_IP
  # TXT alejandropintosalcarazo.com → "v=spf1 mx ~all"
  # TXT _dmarc → "v=DMARC1; p=quarantine; rua=mailto:admin@alejandropintosalcarazo.com"
  # DKIM: obtener clave tras primer nixos-rebuild en /var/dkim/
}
