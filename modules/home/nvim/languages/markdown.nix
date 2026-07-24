{lib, ...}: {
  programs.nvf.settings.vim = {
    languages.markdown = {
      enable = true;
      format = {
        enable = true;
      };
      lsp.enable = true;
      treesitter.enable = true;
      extensions.render-markdown-nvim.enable = true;
    };

    # soft word-wrap for prose (global wrap is off for code)
    autocmds = [
      {
        event = ["FileType"];
        pattern = ["markdown"];
        desc = "wrap prose at word boundaries";
        callback = lib.generators.mkLuaInline ''
          function()
            vim.opt_local.wrap = true
            vim.opt_local.linebreak = true
          end
        '';
      }
    ];
  };
}
