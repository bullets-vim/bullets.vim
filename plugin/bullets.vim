" Vim plugin for automated bulleted lists
" Last Change: Friday Feb 12, 2016
" Maintainer: Dorian Karter
" License: MIT
" FileTypes: markdown, text, gitcommit

" Preserve Vim compatibility and temporarily turn it on   {{{
let s:save_cpo = &cpo
set cpo&vim
" ------------------------------------------------------- }}}

" Generate bullets -------------------------------------- {{{
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
augroup TextBulletsMappings
  autocmd!
  autocmd FileType markdown,text,gitcommit inoremap <buffer> <cr> <esc>:call bullets#insert_new_bullet()<cr>
  autocmd FileType markdown,text,gitcommit nnoremap <buffer> o <esc>:call bullets#insert_new_bullet()<cr>
  autocmd FileType markdown,text,gitcommit inoremap <buffer> <c-\.> <esc>>>A
  autocmd FileType markdown,text,gitcommit inoremap <buffer> <c-\,> <esc><<A
augroup END
" --------------------------------------------------------- }}}

" Restore previous external compatibility options --------- {{{
let &cpo = s:save_cpo
" --------------------------------------------------------  }}}


