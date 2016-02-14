" Vim plugin for automated bulleted lists
" Last Change: Friday Feb 12, 2016
" Maintainer: Dorian Karter
" License: MIT
" FileTypes: markdown, text, gitcommit

fun! bullets#MarkdownAutoList()
  let curr_line_num = getpos(".")[1]
  let curr_line = getline(curr_line_num)
  let matches = matchlist(curr_line, '\v^\s*(-|*) ')
  if !empty(matches)
    call append(curr_line_num, [matches[0]])
    normal! j$
    :startinsert!
  else
    call append(curr_line_num, [""])
    normal! j$
    :startinsert
  endif
endfun
" Keyboard mappings --------------------------------------- {{{
augroup TextBulletsMappings
  autocmd!
  autocmd FileType markdown,text,gitcommit inoremap <buffer> <cr> <esc>:call bullets#MarkdownAutoList()<cr>
  autocmd FileType markdown,text,gitcommit nnoremap <buffer> o <esc>:call bullets#MarkdownAutoList()<cr>
  autocmd FileType markdown,text,gitcommit inoremap <buffer> <c-\.> <esc>>>A
  autocmd FileType markdown,text,gitcommit inoremap <buffer> <c-\,> <esc><<A
augroup END
" --------------------------------------------------------- }}}

