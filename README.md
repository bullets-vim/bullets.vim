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


# TODO

- [ ] eliminate trailing bullet on previous line if user pressed <cr> twice
- [x] allow indenting while in insert mode
- [x] scope the keybindings and functions to markdown and perhaps text
- [ ] allow checkbox auto bullet
- [ ] prefix shortcuts and allow disabling them 
- [ ] add numbered list
- [ ] add alphabetic list
- [ ] allow user to define a global var with custom bullets
- [x] check if plugin initialized and don't load if it did
- [ ] allow <C-cr> for return without creating a bullet
- [x] create a text object for bullets
- [ ] create a text object for bullet list indentation
- [x] create a text object for todos
- [ ] detect lists that have multiline bullets (should have no empty lines between
  lines).




