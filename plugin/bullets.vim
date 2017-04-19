" Vim plugin for automated bulleted lists
" Last Change: Tue 18 Apr 2017
" Maintainer: Dorian Karter
" License: MIT
" FileTypes: markdown, text, gitcommit

" Preserve Vim compatibility settings -------------------  {{{
let s:save_cpo = &cpoptions
set cpoptions&vim
" -------------------------------------------------------  }}}

" Prevent execution if already loaded ------------------   {{{
if exists('g:loaded_bullets_vim')
  finish
endif
let g:loaded_bullets_vim = 1
" Prevent execution if already loaded ------------------   }}}

" Read user configurable options -----------------------   {{{
if !exists('g:bullets_enabled_file_types')
  let g:bullets_enabled_file_types = ['markdown', 'text', 'gitcommit']
endif

if !exists('g:bullets_enable_in_empty_buffers')
  let g:bullets_enable_in_empty_buffers = 1
end

if !exists('g:bullets_set_mappings')
  let g:bullets_set_mappings = 1
end

if !exists('g:bullets_mapping_leader')
  let g:bullets_mapping_leader = ''
end

if !exists('g:bullets_delete_last_bullet_if_empty')
  let g:bullets_delete_last_bullet_if_empty = 1
end
" ------------------------------------------------------   }}}

" Helper methods ----------------------------------------  {{{
fun! s:match_numeric_list_item(input_text)
  let l:num_bullet_regex  = '\v^((\s*)(\d+)(\.|\))(\s+))(.*)'
  let l:matches           = matchlist(a:input_text, l:num_bullet_regex)

  if empty(l:matches)
    return {}
  endif

  let l:leading_space     = l:matches[2]
  let l:num               = l:matches[3]
  let l:closure           = l:matches[4]
  let l:trailing_space    = l:matches[5]
  let l:text_after_bullet = l:matches[6]

  return {
        \ 'leading_space':     l:leading_space,
        \ 'trailing_space':    l:trailing_space,
        \ 'bullet':            l:num,
        \ 'closure':           l:closure,
        \ 'text_after_bullet': l:text_after_bullet
        \ }
endfun

fun! s:match_roman_list_item(input_text)
    let l:rom_bullet_regex  = '\v^((\s*)([IVXLCDM]+)(\.|\))(\s*))(.*)'
  let l:matches           = matchlist(a:input_text, l:rom_bullet_regex)
  if empty(l:matches)
    return {}
  endif

  let l:leading_space     = l:matches[2]
  let l:rom               = l:matches[3]
  let l:closure           = l:matches[4]
  let l:trailing_space    = l:matches[5]
  let l:text_after_bullet = l:matches[6]

  return {
        \ 'leading_space':     l:leading_space,
        \ 'trailing_space':    l:trailing_space,
        \ 'bullet':            l:rom,
        \ 'closure':           l:closure,
        \ 'text_after_bullet': l:text_after_bullet
        \ }
endfun

fun! s:match_bullet_list_item(input_text)
  let l:std_bullet_regex  = '\v(^\s*(-|*|\\item)( \[[x ]?\])? )(.*)'
  let l:matches           = matchlist(a:input_text, l:std_bullet_regex)

  if empty(l:matches)
    return {}
  endif

  let l:whole_bullet      = l:matches[1]
  let l:bullet            = l:matches[2]
  let l:text_after_bullet = l:matches[4]

  return {
        \ 'whole_bullet':      l:whole_bullet,
        \ 'bullet':            l:bullet,
        \ 'text_after_bullet': l:text_after_bullet
        \ }
endfun

fun! s:get_visual_selection_lines()
  let [l:lnum1, l:col1] = getpos("'<")[1:2]
  let [l:lnum2, l:col2] = getpos("'>")[1:2]
  let l:lines = getline(l:lnum1, l:lnum2)
  let l:lines[-1] = l:lines[-1][: l:col2 - (&selection ==# 'inclusive' ? 1 : 2)]
  let l:lines[0] = l:lines[0][l:col1 - 1:]
  let l:index = l:lnum1
  let l:lines_with_index = []
  for l:line in l:lines
    let l:lines_with_index += [{'text': l:line, 'nr': l:index}]
    let l:index += 1
  endfor
  return l:lines_with_index
endfun
" -------------------------------------------------------  }}}

" Generate bullets --------------------------------------  {{{
fun! s:next_bullet_str(bullet_type, line_data)
  if a:bullet_type ==# 'rom'
    let l:next_num = s:arabic2roman(s:roman2arabic(a:line_data.bullet) + 1)
    return a:line_data.leading_space . l:next_num . a:line_data.closure  . ' '
  elseif a:bullet_type ==# 'num'
    let l:next_num = a:line_data.bullet + 1
    return a:line_data.leading_space . l:next_num . a:line_data.closure  . ' '
  else
    return a:line_data.whole_bullet
  endif
endfun

fun! s:delete_empty_bullet(line_num)
  if g:bullets_delete_last_bullet_if_empty
    call setline(a:line_num, '')
  endif
endfun

fun! s:insert_new_bullet()
  let l:curr_line_num = line('.')
  let l:next_line_num = l:curr_line_num + 1
  let l:curr_line = getline(l:curr_line_num)
  let l:std_bullet_matches = s:match_bullet_list_item(l:curr_line)
  let l:num_bullet_matches = s:match_numeric_list_item(l:curr_line)
  let l:rom_bullet_matches = s:match_roman_list_item(l:curr_line)
  let l:bullet_type = ''
  let l:bullet = {}
  let l:bullet_content = ''
  let l:text_after_bullet = ''
  let l:send_return = 1
  let l:normal_mode = mode() ==# 'n'

  if !empty(l:std_bullet_matches)
    let l:bullet_type = 'std'
    let l:bullet = l:std_bullet_matches
  elseif !empty(l:num_bullet_matches)
    let l:bullet_type = 'num'
    let l:bullet = l:num_bullet_matches
  elseif !empty(l:rom_bullet_matches)
    let l:bullet_type = 'rom'
    let l:bullet = l:rom_bullet_matches
  endif

  " check if current line is a bullet and we are at the end of the line (for
  " insert mode only)
  if strlen(l:bullet_type) && (l:normal_mode || s:is_at_eol())
    " was any text entered after the bullet?
    if l:bullet.text_after_bullet ==# ''
      " We don't want to create a new bullet if the previous one was not used,
      " instead we want to delete the empty bullet - like word processors do
      call s:delete_empty_bullet(l:curr_line_num)
    else

      let l:next_bullet_str = s:next_bullet_str(l:bullet_type, l:bullet)

      " insert next bullet
      call append(l:curr_line_num, [l:next_bullet_str])
      " got to next line after the new bullet
      call setpos('.', [0, l:next_line_num, strlen(getline(l:next_line_num))+1])
      let l:send_return = 0
    endif
  endif

  if l:send_return || l:normal_mode
    " start a new line
    if l:normal_mode
      startinsert!
    endif

    let l:keys = l:send_return ? "\<CR>" : ''
    call feedkeys(l:keys, 'n')
  endif

  " need to return a string since we are in insert mode calling with <C-R>=
  return ''
endfun

fun! s:is_at_eol()
  return strlen(getline('.')) + 1 ==# col('.')
endfun

command! InsertNewBullet call <SID>insert_new_bullet()
" --------------------------------------------------------- }}}

" Checkboxes ---------------------------------------------- {{{
fun! s:find_checkbox_position(lnum)
  let l:line_text = getline(a:lnum)
  return matchend(l:line_text, '\v\s*(\*|-) \[')
endfun

fun! s:select_checkbox(inner)
  let l:lnum = line('.')
  let l:checkbox_col = s:find_checkbox_position(l:lnum)

  if l:checkbox_col
    call setpos('.', [0, l:lnum, l:checkbox_col])

    " decide if we need to select the whole checkbox with brackets or just the
    " inside of it
    if a:inner
      normal! vi[
    else
      normal! va[
    endif
  endif
endfun

fun! s:toggle_checkbox()
  let l:initpos = getpos('.')
  let l:lnum = line('.')
  let l:pos = s:find_checkbox_position(l:lnum)
  let l:checkbox_content = getline(l:lnum)[l:pos]
  " select inside checkbox
  call setpos('.', [0, l:lnum, l:pos])
  if l:checkbox_content ==? 'x'
    execute "normal! ci[\<Space>"
  else
    normal! ci[x
  endif
  call setpos('.', l:initpos)
endfun

command! SelectCheckboxInside call <SID>select_checkbox(1)
command! SelectCheckbox call <SID>select_checkbox(0)
command! ToggleCheckbox call <SID>toggle_checkbox()
" Checkboxes ---------------------------------------------- }}}

" Roman numerals --------------------------------------------- {{{

" Roman numeral functions lifted from tpope's speeddating.vim
" where they are in turn
" based on similar functions from VisIncr.vim
"
let s:a2r = [
           \ [1000, 'm'], [900, 'cm'], [500, 'd'], [400, 'cd'],
           \ [100, 'c'], [90 , 'xc'], [50 , 'l'], [40 , 'xl'],
           \ [10 , 'x'], [9  , 'ix'], [5  , 'v'], [4  , 'iv'],
           \ [1  , 'i']
           \ ]

function! s:roman2arabic(roman)
  let l:roman  = tolower(a:roman)
  let l:sign   = 1
  let l:arabic = 0
  while l:roman !=# ''
    if l:roman =~# '^[-n]'
      let l:sign = -l:sign
    endif
    for [l:numbers, l:letters] in s:a2r
      if l:roman =~ '^' . l:letters
        let l:arabic += l:sign * l:numbers
        let l:roman = strpart(l:roman,strlen(l:letters)-1)
        break
      endif
    endfor
    let l:roman = strpart(l:roman,1)
  endwhile
  return l:arabic
endfunction

function! s:arabic2roman(arabic)
  if a:arabic <= 0
    let l:arabic = -a:arabic
    let l:roman = 'n'
  else
    let l:arabic = a:arabic
    let l:roman = ''
  endif
  for [l:numbers, l:letters] in s:a2r
    let l:roman .= repeat(l:letters, l:arabic / l:numbers)
    let l:arabic = l:arabic % l:numbers
  endfor
  return toupper(l:roman)
endfunction

" Roman numerals ---------------------------------------------- }}}

" Renumbering --------------------------------------------- {{{
fun! s:renumber_selection()
  let l:selection_lines = s:get_visual_selection_lines()
  let l:index = 0

  for l:line in l:selection_lines
    let l:bullet = s:match_numeric_list_item(l:line.text)

    if !empty(l:bullet)
      let l:index += 1
      let l:renumbered_line =
            \ l:bullet.leading_space
            \ . l:index
            \ . l:bullet.closure
            \ . l:bullet.trailing_space
            \ . l:bullet.text_after_bullet
      call setline(l:line.nr, l:renumbered_line)
    else
      call setline(l:line.nr, l:line.text)
    endif
  endfor
endfun


command! -range=% RenumberSelection call <SID>renumber_selection()
" --------------------------------------------------------- }}}

" Bullets ------------------------------------------------- {{{
fun! s:find_bullet_position(lnum)
  let line_text = getline(a:lnum)
  return matchend(line_text, '\v^\s*(\*|-)')
endfun

fun! s:select_bullet(inner)
  let lnum = getpos(".")[1]
  let bullet_col = s:find_bullet_position(lnum)

  if bullet_col
    " decide if we need to select with the bullet or without
    let offset = a:inner? 2 : 0
    call setpos(".", [0, lnum, bullet_col + offset])
    normal! vg_
  endif
endfun

command! SelectBulletText call <SID>select_bullet(1)
command! SelectBullet call <SID>select_bullet(0)
" Bullets ------------------------------------------------- }}}

" Keyboard mappings --------------------------------------- {{{
fun! s:add_local_mapping(mapping_type, mapping, action)
  let l:file_types = join(g:bullets_enabled_file_types, ',')
  execute 'autocmd FileType ' .
        \ l:file_types .
        \ ' ' .
        \ a:mapping_type .
        \ ' <silent> <buffer> ' .
        \ g:bullets_mapping_leader .
        \ a:mapping .
        \ ' ' .
        \ a:action

  if g:bullets_enable_in_empty_buffers
    execute 'autocmd BufEnter * if bufname("") == "" | ' .
          \ a:mapping_type .
          \ ' <silent> <buffer> ' .
          \ g:bullets_mapping_leader .
          \ a:mapping .
          \ ' ' .
          \ a:action .
          \ '| endif'
  endif
endfun

augroup TextBulletsMappings
  autocmd!

  if g:bullets_set_mappings
    " automatic bullets
    call s:add_local_mapping('inoremap', '<cr>', '<C-]><C-R>=<SID>insert_new_bullet()<cr>')
    call s:add_local_mapping('inoremap', '<C-cr>', '<cr>')

    call s:add_local_mapping('nnoremap', 'o', ':call <SID>insert_new_bullet()<cr>')

    " Renumber bullet list
    call s:add_local_mapping('vnoremap', 'gN', ':RenumberSelection<cr>')

    " Toggle checkbox
    call s:add_local_mapping('nnoremap', '<leader>x', ':ToggleCheckbox<cr>')

    " Text Objects -------------------------------------------- {{{
    " inner bullet (just the text)
    call s:add_local_mapping('onoremap', 'ib', ':SelectBulletText<cr>')
    " a bullet including the bullet markup
    call s:add_local_mapping('onoremap', 'ab', ':SelectBullet<cr>')
    " inside a checkbox
    call s:add_local_mapping('onoremap', 'ic', ':SelectCheckboxInside<cr>')
    " a checkbox
    call s:add_local_mapping('onoremap', 'ac', ':SelectCheckbox<cr>')
    " Text Objects -------------------------------------------- }}}
  end
augroup END
" --------------------------------------------------------- }}}

" Restore previous external compatibility options --------- {{{
let &cpo = s:save_cpo
" --------------------------------------------------------  }}}


