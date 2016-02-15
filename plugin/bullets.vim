" Vim plugin for automated bulleted lists
" Last Change: Friday Feb 12, 2016
" Maintainer: Dorian Karter
" License: MIT
" FileTypes: markdown, text, gitcommit

" Prevent execution if already loaded ------------------   {{{
if exists('g:loaded_bullets_vim')
  finish
endif
let g:loaded_bullets_vim = 1
" Prevent execution if already loaded ------------------   }}}

" Define file types for autocmds -----------------------   {{{
if !exists('g:bullets_enabled_file_types')
  let g:bullets_enabled_file_types = ['markdown', 'text', 'gitcommit']
endif
" ------------------------------------------------------   }}}

" Preserve Vim compatibility and temporarily turn it on    {{{
let s:save_cpo = &cpo
set cpo&vim
" -------------------------------------------------------  }}}

" Generate bullets --------------------------------------  {{{
fun! bullets#insert_new_bullet()
  let curr_line_num = getpos(".")[1]
  let curr_line = getline(curr_line_num)
  let matches = matchlist(curr_line, '\v^\s*(-|*) ')
  if !empty(matches)
    " insert next bullet
    call append(curr_line_num, [matches[0]])
  else
    " insert an empty string so that we can start writing into line
    call append(curr_line_num, [""])
  endif

  " get back to insert mode on next line
  normal! j$
  startinsert!
endfun
" --------------------------------------------------------- }}}

" Keyboard mappings --------------------------------------- {{{
fun! s:add_mapping(mapping_type, mapping, action)
  let file_types = join(g:bullets_enabled_file_types, ",")
  execute "autocmd FileType "  . file_types . " " . a:mapping_type . " <buffer> " . a:mapping . " " . a:action
endfun

augroup TextBulletsMappings
  autocmd!

  " automatic bullets
  call s:add_mapping("inoremap", "<cr>", "<esc>:call bullets#insert_new_bullet()<cr>")
  call s:add_mapping("nnoremap", "o", ":call bullets#insert_new_bullet()<cr>")

  " indentation
  call s:add_mapping("inoremap", "<C-l>", "<esc>>>A")
  call s:add_mapping("inoremap", "<C-h>", "<esc><<A")
augroup END
" --------------------------------------------------------- }}}

" Restore previous external compatibility options --------- {{{
let &cpo = s:save_cpo
" --------------------------------------------------------  }}}


