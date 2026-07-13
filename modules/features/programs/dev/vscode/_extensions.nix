{pkgs}: {
  default = with pkgs.vscode-extensions; [
    jnoortheen.nix-ide
    mkhl.direnv
    naumovs.color-highlight
    usernamehw.errorlens
    dracula-theme.theme-dracula
    ms-vscode-remote.remote-ssh
    (pkgs.vscode-utils.extensionFromVscodeMarketplace {
      name = "vscode-treefmt-nix";
      publisher = "VanCoding";
      version = "1.0.2";
      sha256 = "sha256-6srW1fCbXLZwQunNuUYh2pS9D2XBunt1IrCIMB7MaYA=";
    })
    (pkgs.vscode-utils.extensionFromVscodeMarketplace {
      name = "chatgpt";
      publisher = "openai";
      version = "26.5415.20818";
      sha256 = "sha256-Sr+qt5jsxjQ43GJarnXPMPMsxiPR7kmfthtbtYCEaHs=";
    })
  ];

  rust = with pkgs.vscode-extensions; [
    rust-lang.rust-analyzer
    tamasfe.even-better-toml
  ];

  web = with pkgs.vscode-extensions; [
    svelte.svelte-vscode
    bradlc.vscode-tailwindcss
    (pkgs.vscode-utils.extensionFromVscodeMarketplace {
      name = "vscode-shadcn-svelte";
      publisher = "Selemondev";
      version = "0.6.8";
      sha256 = "sha256-u623oSLBK14u30dDQwFl/QtjjV1410OUldsck0gafLo=";
    })
    (pkgs.vscode-utils.extensionFromVscodeMarketplace {
      name = "vs-code-extension";
      publisher = "inlang";
      version = "2.2.0";
      sha256 = "sha256-+BUtdmrPztTx7Hoc/SP4MNOPrUyT1n1DWabuxTUylnw=";
    })
  ];
}
