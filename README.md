# Nvim config

kinda vibe-figged to setup things faster but eh

## C and C++ completion

`clangd` provides C and C++ suggestions through the `mini.completion` engine
included in the existing `mini.nvim` plugin. Completion opens automatically as
you type, with documentation, signature help, and function argument snippets.

- `<C-Space>`: trigger completion manually
- `<C-n>` / `<C-p>`: select the next / previous suggestion
- `<Tab>`: accept the selected suggestion (or the first suggestion if none is selected)
- `<C-y>`: also accept the selected suggestion
- `<C-e>`: dismiss completion
- `<Tab>` / `<S-Tab>`: jump between snippet arguments when the completion menu is closed

Keep `clangd` on your `PATH`. For project-specific include paths and compiler
flags, provide a `compile_commands.json` in the project root or `build/` directory.
The completion engine also works with the configured Rust language server and
falls back to buffer words when LSP suggestions are unavailable.

## C and C++ formatting

C and C++ buffers use Linux kernel-style formatting from `lua/c_style.lua`:

- real tabs with an 8-column width
- 8-column indentation with unindented `case` labels
- Linux-style braces and pointer alignment
- an 80-column text limit with a guide at column 81
- formatting through `clang-format` on save or with `<leader>cf`

The editor and formatter read the same style module so their indentation rules stay in sync.
