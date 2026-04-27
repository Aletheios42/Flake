{ pkgs, lib, config, ... }:
{
  options.editor.enable = lib.mkEnableOption "Activa nvim";

  config = lib.mkIf(config.editor.enable) {

    programs.nvf = {
      enable = true;
      settings.vim = {

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
          concealcursor = "nc"; # "n" (normal), "c" (command)
        };

        globals.mapleader = " ";

        # Prefiero usar el clipboard de la app, y acceder al del sistema con el '+'
        # clipboard = {
        #   enable = true;
        #   registers = "unnamedplus";
        # };

        theme = {
          enable = true;
          name = "gruvbox";
          style = "dark";
        };

        # treesiter no expone la api, asi que textobject no funciona... abrir un issue y esperar a que funcione
        treesitter = {
          enable = true;
          highlight.enable = true;
          grammars = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
            go lua python rust nix bash c
          ];
          textobjects = {
            enable = true;
            setupOpts = {
              select = {
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
        };
        luaConfigRC.treesitter-path = ''
        local parser_dirs = vim.api.nvim_get_runtime_file("parser", true)
        for _, dir in ipairs(parser_dirs) do
          vim.opt.runtimepath:prepend(vim.fn.fnamemodify(dir, ":h"))
        end
        '';

        lsp = {
          enable = true;
          lspconfig.enable = true;
        };

        languages = {
          enableTreesitter = true;
          nix.enable = true; lua.enable = true; bash.enable = true;
          clang.enable = true; rust.enable = true; zig.enable = true; assembly.enable = true; go.enable = true; 
          python.enable = true; 
          terraform.enable = true; helm.enable = true; hcl.enable = true; sql.enable = true;
          html.enable = true; css.enable = true; svelte.enable = true; typescript.enable = true; php.enable = true;
          typst.enable = true; yaml.enable = true; markdown.enable = true;
        };

        luaConfigRC.go-imports-only = ''
        vim.api.nvim_create_autocmd("BufWritePre", {
          pattern = "*.go",
          callback = function()
            vim.lsp.buf.code_action({
              context = { only = { "source.organizeImports" } },
              apply = true,
            })
          end,
        })
        '';

        luaConfigRC.no-auto-comment = ''
        vim.api.nvim_create_autocmd("BufEnter", {
          callback = function()
            vim.opt_local.formatoptions:remove({ "c", "r", "o" })
          end,
        })
        '';

        autocomplete.nvim-cmp.enable = true;
        luaConfigRC.cmp-keymaps = ''
        local cmp = require('cmp')
        cmp.setup({
          mapping = {
            ['<C-n>'] = cmp.mapping.select_next_item(),
            ['<C-p>'] = cmp.mapping.select_prev_item(),
            ['<C-y>'] = cmp.mapping.confirm({ select = true }),
            ['<C-e>'] = cmp.mapping.abort(),
            ['<C-d>'] = cmp.mapping.scroll_docs(4),
            ['<C-u>'] = cmp.mapping.scroll_docs(-4),
            ['<Tab>']   = cmp.config.disable,
            ['<S-Tab>'] = cmp.config.disable,
            ['<CR>']    = cmp.config.disable,
          }
        })
        '';

        statusline.lualine = {
          enable = true;
          theme = "gruvbox";
        };

        binds.whichKey.enable = true;
        telescope.enable = true;

        extraPlugins =  {
          vim-tmux-navigator = {
            package = pkgs.vimPlugins.vim-tmux-navigator;
            setup = "";
          };
          obsidian-nvim = {
            package = pkgs.vimPlugins.obsidian-nvim;
            setup = ''
            require("obsidian").setup({
              workspaces = {
                {
                  name = "segundo-cerebro",
                  path = "~/Documentos/Segundo_Cerebro",
                },
              },

              notes_subdir = "0_Inbox",
              legacy_commands = false,

              -- LOGICA DE NOMBRES
              note_id_func = function(title)
                if title ~= nil then
                  return title
                else
                  return "Nota_" .. os.date("%Y-%m-%d_%H%M")
                end
              end,

              note_path_func = function(spec)
                local path = spec.dir / tostring(spec.id)
                return path:with_suffix(".md")
              end,

              -- FRONTMATTER
              frontmatter = {
                func = function(note)
                  local out = { 
                    ["Creación"] = os.date("%Y-%m-%d %H:%M"),
                    tags = note.tags or { "ToLink", "_Todo", "ToTag" },
                    ["Descripción"] = "" 
                  }
                  if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
                    for k, v in pairs(note.metadata) do out[k] = v end
                  end
                  return out
                end,
              },

              -- UI Y CONCEAL
              ui = { enable = true },

              -- ETIQUETAS
              tags_helper = {
                tag_prefix = "#",
              },

              templates = {
                subdir = "3_Plantillas",
                date_format = "%Y-%m-%d",
                time_format = "%H:%M",
              },

              attachments = {
                folder = "4_Multimedia",
              },

              -- SELECTOR
              picker = {
                name = "fzf-lua",
                note_mappings = {
                  insert_link = "<C-l>",
                },
              },

              -- CORRECCIÓN: Mover sort_by y sort_reversed aquí dentro
              search = {
                sort_by = "modified",
                sort_reversed = true,
              },
            })
            '';
          };
          leap = {
            package = pkgs.vimPlugins.leap-nvim;
            setup = ''
            require('leap').setup({})
            vim.keymap.set({'n','x','o'}, 's',  '<Plug>(leap-forward)')
            vim.keymap.set({'n','x','o'}, 'S',  '<Plug>(leap-backward)')
            '';
          };
          mini-files = {
            package = pkgs.vimPlugins.mini-nvim;
            setup = "require('mini.files').setup()";
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

        keymaps = [
          # Tabs
          { key = "<Tab>";   mode = "n"; action = ":tabnext<CR>";     desc = "Next tab"; }
          { key = "<S-Tab>"; mode = "n"; action = ":tabprevious<CR>"; desc = "Prev tab"; }

          # Function keys
          { key = "<F1>";  mode = "n"; action = ":set number! relativenumber!<CR>";       desc = "Toggle line numbers"; }
          { key = "<F2>"; mode = "n"; action = ":set listchars=space:·,tab:→\\ ,eol:↲,trail:•<CR>:set list!<CR>"; desc = "Toggle listchars"; }
          { key = "<F3>";  mode = "n"; action = ":set cursorline!<CR>";                   desc = "Toggle cursorline"; }
          { key = "<F4>"; mode = "n"; action = "<cmd>lua local ft = vim.bo.ft; if ft=='markdown' then vim.cmd('MarkdownPreviewToggle') elseif ft=='tex' then vim.cmd('VimtexCompile') vim.cmd('VimtexView') elseif ft=='pdf' then vim.fn.jobstart({'zathura', vim.fn.expand('%')}) end<CR>";  desc = "Preview markup"; }
          { key = "<F5>"; mode = "n"; action = "za";                          desc = "Toggle fold (current)"; }
          { key = "<F6>"; mode = "n"; action = "zA";                          desc = "Toggle fold (recursive)"; }
          { key = "<F7>"; mode = "n"; action = "zi";                          desc = "Toggle foldenable (all)"; }
          { key = "<F8>"; mode = "n"; action = "zM<cmd>set fdm=indent<CR>";   desc = "Fold all by indent"; }

          { key = "<F9>"; mode = "n"; action = ":set hlsearch!<CR>";        desc = "Toggle hlsearch"; }
          { key = "<F10>"; mode = "n"; action = ":noh<CR>";                 desc = "Clear search highlight"; }
          { key = "<F11>"; mode = "n"; action = ":set spell!<CR>";                         desc = "Toggle spell"; }
          { key = "<F12>"; mode = "n"; action = "<cmd>lua local c = vim.diagnostic.config; if c().virtual_lines then c({virtual_lines=false}) else c({virtual_lines=true}) end<CR>";  desc = "Toggle virtual lines"; }

          # Buffers (<leader>b)
          { key = "<leader>bl"; mode = "n"; action = "<cmd>lua require('fzf-lua').buffers()<CR>";  desc = "List buffers"; }
          { key = "<leader>bn"; mode = "n"; action = ":bnext<CR>";                                 desc = "Next buffer"; }
          { key = "<leader>bp"; mode = "n"; action = ":bprevious<CR>";                             desc = "Prev buffer"; }
          { key = "<leader>bd"; mode = "n"; action = ":bdelete<CR>";                               desc = "Delete buffer"; }

          # LSP goto (g sin leader)
          { key = "gd"; mode = "n"; action = "<cmd>lua require('fzf-lua').lsp_definitions()<CR>";      desc = "Go to definition"; }
          { key = "gr"; mode = "n"; action = "<cmd>lua require('fzf-lua').lsp_references()<CR>";       desc = "Go to references"; }
          { key = "gt"; mode = "n"; action = "<cmd>lua require('fzf-lua').lsp_typedefs()<CR>";         desc = "Go to type def"; }
          { key = "gi"; mode = "n"; action = "<cmd>lua require('fzf-lua').lsp_implementations()<CR>";  desc = "Go to implementation"; }
          { key = "K";  mode = "n"; action = "<cmd>lua vim.lsp.buf.hover()<CR>";                       desc = "Hover docs"; }

          # fzf-lua files and words (<leader>f)
          { key = "<leader>ff"; mode = "n"; action = "<cmd>lua require('fzf-lua').files()<CR>";        desc = "Find files"; }
          { key = "<leader>fg"; mode = "n"; action = "<cmd>lua require('fzf-lua').live_grep()<CR>";    desc = "Live grep"; }
          { key = "<leader>fw"; mode = "n"; action = "<cmd>lua require('fzf-lua').grep_cword()<CR>";   desc = "Find word"; }
          { key = "<leader>fW"; mode = "n"; action = "<cmd>lua require('fzf-lua').grep_cWORD()<CR>";   desc = "Find WORD"; }
          { key = "<leader>fs"; mode = "n"; action = "<cmd>lua require('fzf-lua').grep_project()<CR>"; desc = "Search project"; }
          { key = "<leader>fo"; mode = "n"; action = "<cmd>lua require('fzf-lua').oldfiles()<CR>";     desc = "Find recent"; }
          { key = "<leader>fc"; mode = "n"; action = "<cmd>lua require('fzf-lua').files({cwd=vim.fn.stdpath('config')})<CR>"; desc = "Find in config"; }

          # LSP acciones (<leader>l)
          { key = "<leader>ls"; mode = "n"; action = "<cmd>lua require('fzf-lua').lsp_document_symbols()<CR>";  desc = "LSP doc symbols"; }
          { key = "<leader>lS"; mode = "n"; action = "<cmd>lua require('fzf-lua').lsp_workspace_symbols()<CR>"; desc = "LSP ws symbols"; }
          { key = "<leader>ld"; mode = "n"; action = "<cmd>lua require('fzf-lua').diagnostics_document()<CR>";  desc = "LSP diagnostics"; }
          { key = "<leader>lD"; mode = "n"; action = "<cmd>lua require('fzf-lua').diagnostics_workspace()<CR>"; desc = "LSP ws diagnostics"; }
          { key = "<leader>lr"; mode = "n"; action = "<cmd>lua vim.lsp.buf.rename()<CR>";                       desc = "LSP rename"; }
          { key = "<leader>la"; mode = "n"; action = "<cmd>lua vim.lsp.buf.code_action()<CR>";                  desc = "LSP code action"; }
          { key = "<leader>lf"; mode = "n"; action = "<cmd>lua vim.lsp.buf.format()<CR>";                       desc = "LSP format"; }
          { key = "<leader>le"; mode = "n"; action = "<cmd>lua vim.diagnostic.open_float()<CR>";                desc = "LSP show error"; }
          { key = "<leader>ln"; mode = "n"; action = "<cmd>lua vim.diagnostic.goto_next()<CR>";                 desc = "Next diagnostic"; }
          { key = "<leader>lp"; mode = "n"; action = "<cmd>lua vim.diagnostic.goto_prev()<CR>";                 desc = "Prev diagnostic"; }

          # fzf-lua git (<leader>g)
          { key = "<leader>gc"; mode = "n"; action = "<cmd>lua require('fzf-lua').git_commits()<CR>";  desc = "Git commits"; }
          { key = "<leader>gb"; mode = "n"; action = "<cmd>lua require('fzf-lua').git_branches()<CR>"; desc = "Git branches"; }
          { key = "<leader>gf"; mode = "n"; action = "<cmd>lua require('fzf-lua').git_files()<CR>";    desc = "Git files"; }

          # Ayuda (<leader>h)
          { key = "<leader>hh"; mode = "n"; action = "<cmd>lua require('fzf-lua').helptags()<CR>";  desc = "Help tags"; }
          { key = "<leader>hk"; mode = "n"; action = "<cmd>lua require('fzf-lua').keymaps()<CR>";   desc = "Keymaps"; }
          { key = "<leader>hm"; mode = "n"; action = "<cmd>lua require('fzf-lua').manpages()<CR>";  desc = "Man pages"; }
          { key = "<leader>hc"; mode = "n"; action = "<cmd>lua require('fzf-lua').commands()<CR>";  desc = "Commands"; }

          # QuickFix (<leader>q)
          { key = "<leader>qo"; mode = "n"; action = ":copen<CR>";  desc = "Open quickfix"; }
          { key = "<leader>qc"; mode = "n"; action = ":cclose<CR>"; desc = "Close quickfix"; }
          { key = "<leader>qn"; mode = "n"; action = ":cnext<CR>";  desc = "Next quickfix"; }
          { key = "<leader>qp"; mode = "n"; action = ":cprev<CR>";  desc = "Prev quickfix"; }

          # Minifile (<leader>e)
          { key = "<leader>e";  mode = "n"; action = "<cmd>lua require('mini.files').open()<CR>";                             desc = "Open mini.files"; }
          { key = "<leader>E";  mode = "n"; action = "<cmd>lua require('mini.files').open(vim.api.nvim_buf_get_name(0))<CR>"; desc = "Open mini.files (current file)"; }

          # Segundo Cerebro
          { key = "<leader>on"; mode = "n"; action = "<cmd>Obsidian new<CR>";          desc = "Crear nueva nota en Inbox"; }
          { key = "<leader>oo"; mode = "n"; action = "<cmd>Obsidian quick_switch<CR>"; desc = "Selector rápido de notas"; }
          { key = "<leader>os"; mode = "n"; action = "<cmd>Obsidian search<CR>";       desc = "Buscador de texto global (grep)"; }
          { key = "<leader>ot"; mode = "n"; action = "<cmd>Obsidian tags<CR>";         desc = "Explorador de etiquetas (tags)"; }
          { key = "<leader>oi"; mode = "n"; action = "<cmd>Obsidian template<CR>";     desc = "Insertar plantilla de nota"; }
          { key = "<leader>ob"; mode = "n"; action = "<cmd>Obsidian backlinks<CR>";    desc = "Ver referencias a esta nota"; }
          { key = "<leader>of"; mode = "n"; action = "<cmd>Obsidian follow_link<CR>";  desc = "Seguir enlace (WikiLink)"; }
          { key = "<leader>od"; mode = "n"; action = "<cmd>Obsidian today<CR>";        desc = "Abrir nota del día"; }
          { key = "<leader>ox"; mode = "n"; action = "<cmd>Obsidian checkbox<CR>";     desc = "Alternar estado de tarea"; }
        ];
      };
    };
  };
}

