# Description

Bullets.vim is a Vim plugin for automated bullet lists.

# Installation

With VimPlug:

```vim
Plug 'dkarter/bullets.vim'
```

Then source your bundle file and run `:PlugInstall`.


# Usage

In markdown or a text file start a bulleted list using `-` or `*`. Press return
to go to the next line, a new list item will be created.

# Configuration

You can choose which file types this plugin will work on:

```vim
let g:bullets_enabled_file_types = ['markdown', 'text', 'gitcommit']
```

Just add above to your .vimrc

# Documentation

```
:h bullets
```


# TODO

- [x] eliminate trailing bullet on previous line if user pressed <cr> twice
- [x] allow indenting while in insert mode (C-l: indent right, C-h: indent left)
- [x] scope the keybindings and functions to markdown and perhaps text
- [x] allow GFM-style checkbox auto bullet
- [x] prefix shortcuts and allow disabling them
- [x] add numbered list
- [ ] add alphabetic list
- [ ] allow user to define a global var with custom bullets
- [x] check if plugin initialized and don't load if it did
- [x] allow <C-cr> for return without creating a bullet (only possible in GuiVim
  unfortunately)
- [x] create a text object for bullets
- [ ] create a text object for bullet list indentation
- [x] create a text object for GFM-style checkboxes
- [ ] detect lists that have multiline bullets (should have no empty lines between
  lines).
- [x] check if user is at EOL before appending auto-bullet - they may just want to
  break the line at a certain point
- [ ] support for intelligent alphanumeric indented bullets e.g. 1. \t a. \t 1.
- [ ] reset numbers (user selects numbered bullets 3-5 and copies to middle of document, then reselects and resets them to 1-3)

