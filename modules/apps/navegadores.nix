{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true; # chrome

  programs.firefox = {
    enable = true;
    package = pkgs.librewolf;
    policies.ExtensionSettings = {
      "uBlock0@raymondhill.net" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        installation_mode = "force_installed";
      };
      "idontcareaboutcookies@kennydo.com" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/i-dont-care-about-cookies/latest.xpi";
        installation_mode = "force_installed";
      };
      "keepassxc-browser@keepassxc.redomino.com" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/keepassxc-browser/latest.xpi";
        installation_mode = "force_installed";
      };
      "jid1-MnnxcxisBPnSXQ@jetpack" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
        installation_mode = "force_installed";
      };
    };
  };

  userPackages.browsers = [
    pkgs.qutebrowser
    pkgs.google-chrome
  ];
}
