{ pkgs, lib, config, ... }:
let
  llama = config.ai.llama;
  user  = config.vars.usuarioPrincipal;
in
{
  options.editor.enable = lib.mkEnableOption "Activa nvim";

  config = lib.mkIf config.editor.enable {

    environment.systemPackages = [ pkgs.chafa ]; # renderer de imagenes para snacks.nvim

    programs.nvf = {
      enable = true;
      settings.vim = {

        # --- Opciones generales ---
        options = {
          number = true; relativenumber = true;
          splitbelow = true; splitright = true;
          wrap = false; expandtab = true; tabstop = 2; shiftwidth = 2;
          scrolloff = 6;
          virtualedit = "block";
          inccommand = "split";
          ignorecase = true;
          termguicolors = true;
          undofile = true;
          conceallevel = 2;
          concealcursor = "nc";
        };

        globals.mapleader = " ";

        # --- Tema ---
        theme = { enable = true; name = "gruvbox"; style = "dark"; };

        # --- Treesitter ---
        treesitter = {
          enable = true;
          highlight.enable = true;
          grammars = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
            go lua python rust nix bash c
          ];
          textobjects = {
            enable = true;
            setupOpts.select = {
              enable = true;
              lookahead = true;
              keymaps = {
                af = "@function.outer";
                "if" = "@function.inner";
                ac = "@class.outer";
                ic = "@class.inner";
              };
            };
          };
        };

        luaConfigRC.treesitter-path = ''
          local parser_dirs = vim.api.nvim_get_runtime_file("parser", true)
          for _, dir in ipairs(parser_dirs) do
            vim.opt.runtimepath:prepend(vim.fn.fnamemodify(dir, ":h"))
          end
        '';

        # --- LSP ---
        lsp = { enable = true; lspconfig.enable = true; };

        languages = {
          enableTreesitter = true;
          nix.enable = true;    lua.enable = true;    bash.enable = true;
          clang.enable = true;  rust.enable = true;   zig.enable = true;
          assembly.enable = true; go.enable = true;   python.enable = true;
          terraform.enable = true; helm.enable = true; hcl.enable = true;
          sql.enable = true;    html.enable = true;   css.enable = true;
          svelte.enable = true; typescript.enable = true; php.enable = true;
          typst.enable = true;  yaml.enable = true;   markdown.enable = true;
        };

        # --- Autocompletado ---
        autocomplete.nvim-cmp = {
          enable = true;
          mappings = {
            complete       = "<C-Space>";
            confirm        = "<C-y>";
            next           = "<C-n>";
            previous       = "<C-p>";
            close          = "<C-e>";
            scrollDocsUp   = "<C-u>";
            scrollDocsDown = "<C-d>";
          };
          sources = {
            nvim_lsp = "[LSP]";
            path     = "[Path]";
            buffer   = "[Buf]";
          };
        };

        # --- Lua configs ---
        luaConfigRC.no-auto-comment = ''
          vim.api.nvim_create_autocmd("BufEnter", {
            callback = function()
              vim.opt_local.formatoptions:remove({ "c", "r", "o" })
            end,
          })
        '';

        luaConfigRC."avante-voice" = ''
          local _avante_voice_job = nil

          function AvanteVoiceToggle()
            if _avante_voice_job then
              AvanteVoiceStop()
            else
              vim.notify("Grabando... (<leader>av o <leader>as para parar)", vim.log.levels.INFO)
              _avante_voice_job = vim.fn.jobstart("ai-transcribe", {
                stdout_buffered = true,
                on_stdout = function(_, data)
                  local text = vim.fn.trim(table.concat(data, "\n"))
                  if text ~= "" then
                    vim.schedule(function()
                      require("avante.api").ask({ question = text })
                    end)
                  end
                end,
                on_exit = function(_, code)
                  _avante_voice_job = nil
                  if code ~= 0 then
                    vim.schedule(function()
                      vim.notify("Error en transcripcion de voz", vim.log.levels.ERROR)
                    end)
                  end
                end,
              })
            end
          end

          function AvanteVoiceStop()
            if _avante_voice_job then
              vim.fn.jobstart("ai-transcribe --stop")
              vim.notify("Parando grabacion... transcribiendo", vim.log.levels.INFO)
            else
              vim.notify("No hay grabacion en curso", vim.log.levels.WARN)
            end
          end
        '';

        luaConfigRC."avante-model-selector" = ''
          local _avante_current_model = nil

          local function get_opencode_models()
            local models = {}

            local bedrock_models = {
              "amazon-bedrock/us.anthropic.claude-sonnet-4-20250514-v1:0",
              "amazon-bedrock/us.anthropic.claude-haiku-4-20250514-v1:0",
              "amazon-bedrock/us.anthropic.claude-opus-4-20250514-v1:0",
              "amazon-bedrock/us.anthropic.claude-sonnet-4-5-20250929-v1:0",
              "amazon-bedrock/us.anthropic.claude-opus-4-6-v1:0",
            }
            for _, m in ipairs(bedrock_models) do table.insert(models, m) end

            local go_models = {
              "opencode-go/qwen3-coder",
              "opencode-go/deepseek-r1",
              "opencode-go/devstral",
            }
            for _, m in ipairs(go_models) do table.insert(models, m) end

            table.insert(models, "llama.cpp/${llama.model}")
            table.insert(models, "llama.cpp-completion/${llama.completionModel}")

            return models
          end

          function AvanteModelSelect()
            local models = get_opencode_models()
            if #models == 0 then
              vim.notify("No se encontraron modelos", vim.log.levels.ERROR)
              return
            end
            require('fzf-lua').fzf_exec(models, {
              prompt = "OpenCode Model> ",
              actions = {
                ['default'] = function(selected)
                  if selected and #selected > 0 then
                    _avante_current_model = selected[1]
                    vim.env.OPENCODE_MODEL = _avante_current_model
                    vim.notify("Modelo: " .. _avante_current_model .. " (reinicia avante con :AvanteRestart)", vim.log.levels.INFO)
                  end
                end,
              },
            })
          end

          function AvanteRestart()
            local ok, avante = pcall(require, "avante")
            if ok and avante._acp_client then
              pcall(function() avante._acp_client:shutdown() end)
            end
            local env_table = nil
            if _avante_current_model then
              env_table = { OPENCODE_MODEL = _avante_current_model }
            end
            require('avante').setup({
              provider = "opencode",
              acp_providers = {
                ["opencode"] = {
                  command = "opencode",
                  args    = { "acp" },
                  env     = env_table,
                },
              },
            })
            vim.notify("Avante reiniciado" .. (_avante_current_model and (" con " .. _avante_current_model) or ""), vim.log.levels.INFO)
          end

          vim.api.nvim_create_user_command('AvanteModel', function() AvanteModelSelect() end, { desc = "Seleccionar modelo" })
          vim.api.nvim_create_user_command('AvanteRestart', function() AvanteRestart() end, { desc = "Reiniciar Avante" })
        '';

        # --- UI ---
        statusline.lualine = { enable = true; theme = "gruvbox"; };
        binds.whichKey.enable = true;
        telescope.enable = true;

        # --- Plugins ---
        extraPlugins = {
          vim-tmux-navigator = {
            package = pkgs.vimPlugins.vim-tmux-navigator;
            setup = "";
          };
          mini-files = {
            package = pkgs.vimPlugins.mini-nvim;
            setup = ''require('mini.files').setup({ content = { filter = nil } })'';
          };
          snacks = {
            package = pkgs.vimPlugins.snacks-nvim;
            setup = ''require('snacks').setup({ image = { enabled = true } })'';
          };
          avante = {
            package = pkgs.vimPlugins.avante-nvim;
            setup = ''
              require('avante').setup({
                provider = "opencode",
                acp_providers = {
                  ["opencode"] = { command = "opencode", args = { "acp" } },
                },
              })
            '';
          };
          minuet-ai = {
            package = pkgs.vimPlugins.minuet-ai-nvim;
            setup = ''
              require('minuet').setup({
                provider = 'openai_compatible',
                throttle = 1500,
                debounce = 600,
                notify = 'warn',
                provider_options = {
                  openai_compatible = {
                    api_key = 'TERM',
                    end_point = 'http://${llama.completionHost}:${toString llama.completionPort}/v1/chat/completions',
                    name = 'llama.cpp (1.5B)',
                    model = '${llama.completionModel}',
                    optional = {
                      max_tokens = 128,
                      temperature = 0.2,
                      top_p = 0.9,
                      stop = { '\n\n', '```' },
                    },
                  },
                },
              })
            '';
          };
          fzf-lua = {
            package = pkgs.vimPlugins.fzf-lua;
            setup = "require('fzf-lua').setup()";
          };
          vimtex = {
            package = pkgs.vimPlugins.vimtex;
            setup = ''
              vim.g.vimtex_view_method = 'zathura'
              vim.g.vimtex_compiler_method = 'latexmk'
              vim.g.vimtex_compiler_latexmk = { out_dir = '/tmp/vimtex' }
            '';
          };
          markdown-preview = {
            package = pkgs.vimPlugins.markdown-preview-nvim;
            setup = "";
          };
        };

        # --- Keymaps ---
        keymaps = [
          { key = "<Tab>";   mode = "n"; action = ":tabnext<CR>";     desc = "Next tab"; }
          { key = "<S-Tab>"; mode = "n"; action = ":tabprevious<CR>"; desc = "Prev tab"; }

          { key = "<F1>";  mode = "n"; action = ":set number! relativenumber!<CR>"; desc = "Toggle line numbers"; }
          { key = "<F2>";  mode = "n"; action = ":set listchars=space:·,tab:→\\ ,eol:↲,trail:•<CR>:set list!<CR>"; desc = "Toggle listchars"; }
          { key = "<F3>";  mode = "n"; action = ":set cursorline!<CR>"; desc = "Toggle cursorline"; }
          { key = "<F4>";  mode = "n"; action = "<cmd>lua local ft = vim.bo.ft; if ft=='markdown' then vim.cmd('MarkdownPreviewToggle') elseif ft=='tex' then vim.cmd('VimtexCompile') vim.cmd('VimtexView') elseif ft=='pdf' then vim.fn.jobstart({'zathura', vim.fn.expand('%')}) end<CR>"; desc = "Preview markup"; }
          { key = "<F5>";  mode = "n"; action = "za";  desc = "Toggle fold (current)"; }
          { key = "<F6>";  mode = "n"; action = "zA";  desc = "Toggle fold (recursive)"; }
          { key = "<F7>";  mode = "n"; action = "zi";  desc = "Toggle foldenable (all)"; }
          { key = "<F8>";  mode = "n"; action = "zM<cmd>set fdm=indent<CR>"; desc = "Fold all by indent"; }
          { key = "<F9>";  mode = "n"; action = ":set hlsearch!<CR>"; desc = "Toggle hlsearch"; }
          { key = "<F10>"; mode = "n"; action = ":noh<CR>"; desc = "Clear search highlight"; }
          { key = "<F11>"; mode = "n"; action = ":set spell!<CR>"; desc = "Toggle spell"; }
          { key = "<F12>"; mode = "n"; action = "<cmd>lua local d = vim.diagnostic; if d.is_disabled(0) then d.enable(0) else d.disable(0) end<CR>"; desc = "Toggle diagnostics"; }

          { key = "<leader>bl"; mode = "n"; action = "<cmd>lua require('fzf-lua').buffers()<CR>"; desc = "List buffers"; }
          { key = "<leader>bn"; mode = "n"; action = ":bnext<CR>";     desc = "Next buffer"; }
          { key = "<leader>bp"; mode = "n"; action = ":bprevious<CR>"; desc = "Prev buffer"; }
          { key = "<leader>bd"; mode = "n"; action = ":bdelete<CR>";   desc = "Delete buffer"; }

          { key = "gd"; mode = "n"; action = "<cmd>lua require('fzf-lua').lsp_definitions()<CR>";     desc = "Go to definition"; }
          { key = "gr"; mode = "n"; action = "<cmd>lua require('fzf-lua').lsp_references()<CR>";      desc = "Go to references"; }
          { key = "gt"; mode = "n"; action = "<cmd>lua require('fzf-lua').lsp_typedefs()<CR>";        desc = "Go to type def"; }
          { key = "gi"; mode = "n"; action = "<cmd>lua require('fzf-lua').lsp_implementations()<CR>"; desc = "Go to implementation"; }
          { key = "K";  mode = "n"; action = "<cmd>lua vim.lsp.buf.hover()<CR>"; desc = "Hover docs"; }

          { key = "<leader>ff"; mode = "n"; action = "<cmd>lua require('fzf-lua').files()<CR>";        desc = "Find files"; }
          { key = "<leader>fg"; mode = "n"; action = "<cmd>lua require('fzf-lua').live_grep()<CR>";    desc = "Live grep"; }
          { key = "<leader>fw"; mode = "n"; action = "<cmd>lua require('fzf-lua').grep_cword()<CR>";   desc = "Find word"; }
          { key = "<leader>fW"; mode = "n"; action = "<cmd>lua require('fzf-lua').grep_cWORD()<CR>";   desc = "Find WORD"; }
          { key = "<leader>fs"; mode = "n"; action = "<cmd>lua require('fzf-lua').grep_project()<CR>"; desc = "Search project"; }
          { key = "<leader>fo"; mode = "n"; action = "<cmd>lua require('fzf-lua').oldfiles()<CR>";     desc = "Find recent"; }
          { key = "<leader>fc"; mode = "n"; action = "<cmd>lua require('fzf-lua').files({cwd=vim.fn.stdpath('config')})<CR>"; desc = "Find in config"; }

          { key = "<leader>ls"; mode = "n"; action = "<cmd>lua require('fzf-lua').lsp_document_symbols()<CR>";  desc = "Doc symbols"; }
          { key = "<leader>lS"; mode = "n"; action = "<cmd>lua require('fzf-lua').lsp_workspace_symbols()<CR>"; desc = "Workspace symbols"; }
          { key = "<leader>ld"; mode = "n"; action = "<cmd>lua require('fzf-lua').diagnostics_document()<CR>";  desc = "Diagnostics"; }
          { key = "<leader>lD"; mode = "n"; action = "<cmd>lua require('fzf-lua').diagnostics_workspace()<CR>"; desc = "Workspace diagnostics"; }
          { key = "<leader>lr"; mode = "n"; action = "<cmd>lua vim.lsp.buf.rename()<CR>";      desc = "Rename"; }
          { key = "<leader>la"; mode = "n"; action = "<cmd>lua vim.lsp.buf.code_action()<CR>"; desc = "Code action"; }
          { key = "<leader>lf"; mode = "n"; action = "<cmd>lua vim.lsp.buf.format()<CR>";      desc = "Format"; }
          { key = "<leader>le"; mode = "n"; action = "<cmd>lua vim.diagnostic.open_float()<CR>"; desc = "Show error"; }
          { key = "<leader>ln"; mode = "n"; action = "<cmd>lua vim.diagnostic.goto_next()<CR>";  desc = "Next diagnostic"; }
          { key = "<leader>lp"; mode = "n"; action = "<cmd>lua vim.diagnostic.goto_prev()<CR>";  desc = "Prev diagnostic"; }

          { key = "<leader>gc"; mode = "n"; action = "<cmd>lua require('fzf-lua').git_commits()<CR>";  desc = "Git commits"; }
          { key = "<leader>gb"; mode = "n"; action = "<cmd>lua require('fzf-lua').git_branches()<CR>"; desc = "Git branches"; }
          { key = "<leader>gf"; mode = "n"; action = "<cmd>lua require('fzf-lua').git_files()<CR>";    desc = "Git files"; }

          { key = "<leader>hh"; mode = "n"; action = "<cmd>lua require('fzf-lua').helptags()<CR>"; desc = "Help tags"; }
          { key = "<leader>hk"; mode = "n"; action = "<cmd>lua require('fzf-lua').keymaps()<CR>";  desc = "Keymaps"; }
          { key = "<leader>hm"; mode = "n"; action = "<cmd>lua require('fzf-lua').manpages()<CR>"; desc = "Man pages"; }
          { key = "<leader>hc"; mode = "n"; action = "<cmd>lua require('fzf-lua').commands()<CR>"; desc = "Commands"; }

          { key = "<leader>qo"; mode = "n"; action = ":copen<CR>";  desc = "Open quickfix"; }
          { key = "<leader>qc"; mode = "n"; action = ":cclose<CR>"; desc = "Close quickfix"; }
          { key = "<leader>qn"; mode = "n"; action = ":cnext<CR>";  desc = "Next quickfix"; }
          { key = "<leader>qp"; mode = "n"; action = ":cprev<CR>";  desc = "Prev quickfix"; }

          { key = "<leader>e"; mode = "n"; action = "<cmd>lua require('mini.files').open()<CR>"; desc = "Open mini.files"; }
          { key = "<leader>E"; mode = "n"; action = "<cmd>lua require('mini.files').open(vim.api.nvim_buf_get_name(0))<CR>"; desc = "mini.files (current)"; }

          { key = "<leader>av"; mode = "n"; action = "<cmd>lua AvanteVoiceToggle()<CR>"; desc = "Voz toggle"; }
          { key = "<leader>as"; mode = "n"; action = "<cmd>lua AvanteVoiceStop()<CR>";   desc = "Voz stop"; }
          { key = "<leader>am"; mode = "n"; action = "<cmd>AvanteModel<CR>";   desc = "Seleccionar modelo"; }
          { key = "<leader>ar"; mode = "n"; action = "<cmd>AvanteRestart<CR>"; desc = "Reiniciar avante"; }
        ];
      };
    };

    myImpermanence.users.${user}.directories = [
      ".config/nvim"
      ".local/share/nvim"
      ".local/state/nvim"
      ".cache/nvim"
    ];
  };
}
