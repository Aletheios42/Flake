{pkgs, ...}:
{
  # --- CONSOLA & KEYMAP ---
  console.earlySetup = true; #Aplica key repeat y dealy en las tty
  console.keyMap = "es";
  ## mirar si esto esta duplicado con i3.nix

    # --- FUENTES ---
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
  ];

}
