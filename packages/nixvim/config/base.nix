{
  luaLoader.enable = true;

  # Use <Space> as leader key
  globals.mapleader = " ";

  # Setup clipboard support
  clipboard = {
    # Use xsel as clipboard provider
    # providers.xsel.enable = true;

    # Sync system clipboard
    register = "unnamedplus";
  };

  extraConfigLua = ''
    if (os.getenv('SSH_TTY') ~= nil)
    then
      vim.g.clipboard = {
        name = 'OSC 52',
        copy = {
          ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
          ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
        },
        paste = {
          ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
          ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
        },
      }
    end
  '';
}
