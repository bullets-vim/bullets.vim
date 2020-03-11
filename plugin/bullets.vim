" Vim plugin for automated bulleted lists
" Last Change: March 2, 2020
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

if !exists('g:bullets_line_spacing')
  let g:bullets_line_spacing = 1
end

if !exists('g:bullets_pad_right')
  let g:bullets_pad_right = 1
end

if !exists('g:bullets_max_alpha_characters')
  let g:bullets_max_alpha_characters = 2
end
" calculate the decimal equivalent to the last alphabetical list item
let s:power = g:bullets_max_alpha_characters
let s:abc_max = -1
while s:power >= 0
  let s:abc_max += pow(26,s:power)
  let s:power -= 1
endwhile

if !exists('g:bullets_outline_levels')
  " Capitalization matters: all caps will make the symbol caps, lower = lower
  " Standard bullets should include the marker symbol after 'std'
  let g:bullets_outline_levels = ['ROM', 'ABC', 'num', 'abc', 'rom', 'std-', 'std*', 'std+']
endif

" ------------------------------------------------------   }}}

" Parse Bullet Type -------------------------------------------  {{{
fun! s:parse_bullet(line_num, line_text)
  let l:kinds = s:filter(
        \ [
        \  s:match_bullet_list_item(a:line_text),
        \  s:match_checkbox_bullet_item(a:line_text),
        \  s:match_numeric_list_item(a:line_text),
        \  s:match_roman_list_item(a:line_text),
        \  s:match_alphabetical_list_item(a:line_text),
        \ ],
        \ '!empty(v:val)'
        \ )

  return s:map(l:kinds, 'extend(v:val, { "starting_at_line_num": ' . a:line_num . ' })')
endfun

fun! s:match_numeric_list_item(input_text)
  let l:num_bullet_regex  = '\v^((\s*)(\d+)(\.|\))(\s+))(.*)'
  let l:matches           = matchlist(a:input_text, l:num_bullet_regex)

  if empty(l:matches)
    return {}
  endif

  let l:bullet_length     = strlen(l:matches[1])
  let l:leading_space     = l:matches[2]
  let l:num               = l:matches[3]
  let l:closure           = l:matches[4]
  let l:trailing_space    = l:matches[5]
  let l:text_after_bullet = l:matches[6]

  return {
        \ 'bullet_type':       'num',
        \ 'bullet_length':     l:bullet_length,
        \ 'leading_space':     l:leading_space,
        \ 'trailing_space':    l:trailing_space,
        \ 'bullet':            l:num,
        \ 'closure':           l:closure,
        \ 'text_after_bullet': l:text_after_bullet
        \ }
endfun


fun! s:match_roman_list_item(input_text)
  let l:rom_bullet_regex  = join([
        \ '\v\C',
        \ '^(',
        \   '(\s*)',
        \   '(',
        \     'M{0,4}%(CM|CD|D?C{0,3})%(XC|XL|L?X{0,3})%(IX|IV|V?I{0,3})',
        \     '|',
        \     'm{0,4}%(cm|cd|d?c{0,3})%(xc|xl|l?x{0,3})%(ix|iv|v?i{0,3})',
        \   ')',
        \   '(\.|\))',
        \   '(\s+)',
        \ ')',
        \ '(.*)'], '')
  let l:matches           = matchlist(a:input_text, l:rom_bullet_regex)
  if empty(l:matches)
    return {}
  endif

  let l:bullet_length     = strlen(l:matches[1])
  let l:leading_space     = l:matches[2]
  let l:rom               = l:matches[3]
  let l:closure           = l:matches[4]
  let l:trailing_space    = l:matches[5]
  let l:text_after_bullet = l:matches[6]

  return {
        \ 'bullet_type':       'rom',
        \ 'bullet_length':     l:bullet_length,
        \ 'leading_space':     l:leading_space,
        \ 'trailing_space':    l:trailing_space,
        \ 'bullet':            l:rom,
        \ 'closure':           l:closure,
        \ 'text_after_bullet': l:text_after_bullet
        \ }
endfun

fun! s:match_alphabetical_list_item(input_text)
  if g:bullets_max_alpha_characters == 0
    return {}
  endif

  let l:max = string(g:bullets_max_alpha_characters)
  let l:abc_bullet_regex = join([
        \ '\v^((\s*)(\u{1,',
        \ l:max,
        \ '}|\l{1,',
        \ l:max,
        \ '})(\.|\))(\s+))(.*)'], '')

  let l:matches = matchlist(a:input_text, l:abc_bullet_regex)

  if empty(l:matches)
    return {}
  endif

  let l:bullet_length     = strlen(l:matches[1])
  let l:leading_space     = l:matches[2]
  let l:abc               = l:matches[3]
  let l:closure           = l:matches[4]
  let l:trailing_space    = l:matches[5]
  let l:text_after_bullet = l:matches[6]

  return {
        \ 'bullet_type':       'abc',
        \ 'bullet_length':     l:bullet_length,
        \ 'leading_space':     l:leading_space,
        \ 'trailing_space':    l:trailing_space,
        \ 'bullet':            l:abc,
        \ 'closure':           l:closure,
        \ 'text_after_bullet': l:text_after_bullet
        \ }
endfun

fun! s:match_checkbox_bullet_item(input_text)
  let l:checkbox_bullet_regex = '\v(^(\s*)- \[[x ]?\](\s+))(.*)'
  let l:matches               = matchlist(a:input_text, l:checkbox_bullet_regex)

  if empty(l:matches)
    return {}
  endif

  let l:bullet_length     = strlen(l:matches[1])
  let l:leading_space     = l:matches[2]
  let l:trailing_space    = l:matches[3]
  let l:text_after_bullet = l:matches[4]

  return {
        \ 'bullet_type':       'chk',
        \ 'bullet_length':     l:bullet_length,
        \ 'leading_space':     l:leading_space,
        \ 'trailing_space':    l:trailing_space,
        \ 'text_after_bullet': l:text_after_bullet
        \ }
endfun

fun! s:match_bullet_list_item(input_text)
  let l:std_bullet_regex  = '\v(^(\s*)(-|\*+|\.+|#\.|\+|\\item)(\s+))(.*)'
  let l:matches           = matchlist(a:input_text, l:std_bullet_regex)

  if empty(l:matches)
    return {}
  endif

  let l:bullet_length     = strlen(l:matches[1])
  let l:leading_space     = l:matches[2]
  let l:bullet            = l:matches[3]
  let l:trailing_space    = l:matches[4]
  let l:text_after_bullet = l:matches[5]

  return {
        \ 'bullet_type':       'std',
        \ 'bullet_length':     l:bullet_length,
        \ 'leading_space':     l:leading_space,
        \ 'bullet':            l:bullet,
        \ 'closure':           '',
        \ 'trailing_space':    l:trailing_space,
        \ 'text_after_bullet': l:text_after_bullet
        \ }
endfun
" -------------------------------------------------------  }}}

" Resolve Bullet Type ----------------------------------- {{{
fun! s:closest_bullet_types(from_line_num, max_indent)
  let l:lnum = a:from_line_num
  let l:ltxt = getline(l:lnum)
  let l:curr_indent = indent(l:lnum)
  let l:bullet_kinds = s:parse_bullet(l:lnum, l:ltxt)

  " Support for wrapped text bullets
  " DEMO: https://raw.githubusercontent.com/dkarter/bullets.vim/master/img/wrapped-bullets.gif
  while l:lnum > 1 && (l:curr_indent != 0 || l:bullet_kinds != [])
        \ && (a:max_indent < l:curr_indent || l:bullet_kinds == [])
    if l:bullet_kinds != []
      let l:lnum = l:lnum - g:bullets_line_spacing
    else
      let l:lnum = l:lnum - 1
    endif
    let l:ltxt = getline(l:lnum)
    let l:bullet_kinds = s:parse_bullet(l:lnum, l:ltxt)
    let l:curr_indent = indent(l:lnum)
  endwhile

  return l:bullet_kinds
endfun

fun! s:resolve_bullet_type(bullet_types)
  if empty(a:bullet_types)
    return {}
  elseif len(a:bullet_types) == 2 && s:has_rom_and_abc(a:bullet_types)
    return s:resolve_rom_or_abc(a:bullet_types)
  elseif len(a:bullet_types) == 2 && s:has_chk_and_std(a:bullet_types)
    return s:resolve_chk_or_std(a:bullet_types)
  else
    return a:bullet_types[0]
  endif
endfun

fun! s:contains_type(bullet_types, type)
  return s:has_item(a:bullet_types, 'v:val.bullet_type ==# "' . a:type . '"')
endfun

fun! s:find_by_type(bullet_types, type)
  return s:find(a:bullet_types, 'v:val.bullet_type ==# "' . a:type . '"')
endfun

" Roman Numeral vs Alphabetic Bullets ---------------------------------- {{{
fun! s:resolve_rom_or_abc(bullet_types)
    let l:first_type = a:bullet_types[0]
    let l:prev_search_starting_line = l:first_type.starting_at_line_num - g:bullets_line_spacing
    let l:bullet_indent = indent(l:first_type.starting_at_line_num)
    let l:prev_bullet_types = s:closest_bullet_types(l:prev_search_starting_line, l:bullet_indent)

    while l:prev_bullet_types != [] && l:bullet_indent > indent(l:prev_search_starting_line)
      let l:prev_search_starting_line -= g:bullets_line_spacing
      let l:prev_bullet_types = s:closest_bullet_types(l:prev_search_starting_line, l:bullet_indent)
    endwhile

    if len(l:prev_bullet_types) == 0

      " can't find previous bullet - so we probably have a rom i. bullet
      return s:find_by_type(a:bullet_types, 'rom')

    elseif len(l:prev_bullet_types) == 1 && s:has_rom_or_abc(l:prev_bullet_types)

      " previous bullet is conclusive, use it's type to continue
      return s:find_by_type(a:bullet_types, l:prev_bullet_types[0].bullet_type)

    elseif s:has_rom_and_abc(l:prev_bullet_types)

      " inconclusive - keep searching up recursively
      let l:prev_bullet = s:resolve_rom_or_abc(l:prev_bullet_types)
      return s:find_by_type(a:bullet_types, l:prev_bullet.bullet_type)

    else

      " parent has unrelated bullet type, we'll go with rom
      return s:find_by_type(a:bullet_types, 'rom')

    endif
endfun

fun! s:has_rom_or_abc(bullet_types)
  let l:has_rom = s:contains_type(a:bullet_types, 'rom')
  let l:has_abc = s:contains_type(a:bullet_types, 'abc')
  return l:has_rom || l:has_abc
endfun

fun! s:has_rom_and_abc(bullet_types)
  let l:has_rom = s:contains_type(a:bullet_types, 'rom')
  let l:has_abc = s:contains_type(a:bullet_types, 'abc')
  return l:has_rom && l:has_abc
endfun
" ------------------------------------------------------- }}}

" Checkbox vs Standard Bullets ----------------------------------------- {{{
fun! s:resolve_chk_or_std(bullet_types)
  " if it matches both regular and checkbox it is most likely a checkbox
  return s:find_by_type(a:bullet_types, 'chk')
endfun

fun! s:has_chk_and_std(bullet_types)
  let l:has_chk = s:contains_type(a:bullet_types, 'chk')
  let l:has_std = s:contains_type(a:bullet_types, 'std')
  return l:has_chk && l:has_std
endfun
" ------------------------------------------------------- }}}

" ------------------------------------------------------- }}}

" Build Next Bullet -------------------------------------- {{{
fun! s:next_bullet_str(bullet)
  let l:bullet_type = get(a:bullet, 'bullet_type')

  if l:bullet_type ==# 'rom'
    let l:next_bullet_marker = s:next_rom_bullet(a:bullet)
  elseif l:bullet_type ==# 'abc'
    let l:next_bullet_marker = s:next_abc_bullet(a:bullet)
  elseif l:bullet_type ==# 'num'
    let l:next_bullet_marker = s:next_num_bullet(a:bullet)
  elseif l:bullet_type ==# 'chk'
    let l:next_bullet_marker = s:next_chk_bullet(a:bullet)
  else
    let l:next_bullet_marker = a:bullet.bullet
  endif
  let l:closure = has_key(a:bullet, 'closure') ? a:bullet.closure : ''
  return a:bullet.leading_space . l:next_bullet_marker . l:closure  . ' '
endfun

fun! s:next_rom_bullet(bullet)
  let l:islower = a:bullet.bullet ==# tolower(a:bullet.bullet)
  return s:arabic2roman(s:roman2arabic(a:bullet.bullet) + 1, l:islower)
endfun

fun! s:next_abc_bullet(bullet)
  let l:islower = a:bullet.bullet ==# tolower(a:bullet.bullet)
  return s:dec2abc(s:abc2dec(a:bullet.bullet) + 1, l:islower)
endfun

fun! s:next_num_bullet(bullet)
  return a:bullet.bullet + 1
endfun

fun! s:next_chk_bullet(bullet)
  return '- [ ]'
endfun
" }}}

" Generate bullets --------------------------------------  {{{
fun! s:delete_empty_bullet(line_num)
  if g:bullets_delete_last_bullet_if_empty
    call setline(a:line_num, '')
  endif
endfun

fun! s:insert_new_bullet()
  let l:curr_line_num = line('.')
  let l:next_line_num = l:curr_line_num + g:bullets_line_spacing
  let l:curr_indent = indent(l:curr_line_num)
  let l:closest_bullet_types = s:closest_bullet_types(l:curr_line_num, l:curr_indent)
  let l:bullet = s:resolve_bullet_type(l:closest_bullet_types)
  " need to find which line starts the previous bullet started at and start
  " searching up from there
  let l:send_return = 1
  let l:normal_mode = mode() ==# 'n'

  " check if current line is a bullet and we are at the end of the line (for
  " insert mode only)
  if l:bullet != {} && (l:normal_mode || s:is_at_eol())
    " was any text entered after the bullet?
    if l:bullet.text_after_bullet ==# ''
      " We don't want to create a new bullet if the previous one was not used,
      " instead we want to delete the empty bullet - like word processors do
      call s:delete_empty_bullet(l:curr_line_num)
    elseif !(l:bullet.bullet_type ==# 'abc' && s:abc2dec(l:bullet.bullet) + 1 > s:abc_max)

      let l:next_bullet = s:next_bullet_str(l:bullet)
      let l:next_bullet_list = [s:pad_to_length(l:next_bullet, l:bullet.bullet_length)]

      " prepend blank lines if desired
      if g:bullets_line_spacing > 1
        let l:next_bullet_list += map(range(g:bullets_line_spacing - 1), '""')
        call reverse(l:next_bullet_list)
      endif

      " insert next bullet
      call append(l:curr_line_num, l:next_bullet_list)
      " got to next line after the new bullet
      let l:col = strlen(getline(l:next_line_num)) + 1
      call setpos('.', [0, l:next_line_num, l:col])
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
" where they are in turn based on similar functions from VisIncr.vim

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

function! s:arabic2roman(arabic, islower)
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
  return a:islower ? tolower(l:roman) : toupper(l:roman)
endfunction

" Roman numerals ---------------------------------------------- }}}

" Alphabetic ordinals ----------------------------------------- {{{

" Alphabetic ordinal functions
" Treat alphabetic ordinals as base-26 numbers to make things easy
fun! s:abc2dec(abc)
  let l:abc = tolower(a:abc)
  let l:dec = char2nr(l:abc[0]) - char2nr('a') + 1
  if len(l:abc) == 1
    return l:dec
  else
    return float2nr(pow(26, len(l:abc) - 1)) * l:dec + s:abc2dec(l:abc[1:len(l:abc) - 1])
  endif
endfun

fun! s:dec2abc(dec, islower)
  let l:a = a:islower ? 'a' : 'A'
  let l:rem = (a:dec - 1) % 26
  let l:abc = nr2char(l:rem + char2nr(l:a))
  if a:dec <= 26
    return l:abc
  else
    return s:dec2abc((a:dec - 1)/ 26, a:islower) . l:abc
  endif
endfun
" Alphabetic ordinals ----------------------------------------- }}}

" Renumbering --------------------------------------------- {{{
fun! s:renumber_selection()
  let l:selection_lines = s:get_visual_selection_lines()
  let l:prev_indent = -1
  let l:level = 0
  let l:indices = {}
  let l:pad_len = {}
  let l:types = {}
  let l:islower = {}

  for l:line in l:selection_lines
    let l:indent = indent(l:line.nr)
    let l:bullet = s:closest_bullet_types(l:line.nr, l:indent)
    let l:bullet = s:resolve_bullet_type(l:bullet)

    if !empty(l:bullet)
      let l:level = l:indent
      if l:indent > l:prev_indent
        let l:indices[l:level] = 1

        " use the first bullet at this level to define the bullet type for
        " subsequent bullets. Needed to normalize bullet types when there are
        " multiple types of bullets at the same indent level.
        let l:islower[l:level] = l:bullet.bullet ==# tolower(l:bullet.bullet)
        let l:types[l:level] = l:bullet.bullet_type

        " use the first bullet as the first padding length, and store it for
        " each indent level
        " 10. firstline  -> 1.  firstline
        " 1.  secondline -> 2.  secondline
        let l:pad_len[l:level] = l:bullet.bullet_length
      else
        let l:indices[l:level] += 1
      endif

      let l:prev_indent = l:indent

      if l:types[l:level] ==? 'rom'
        let l:bullet_num = s:arabic2roman(l:indices[l:level], l:islower[l:level])
      elseif l:types[l:level] ==? 'abc'
        let l:bullet_num = s:dec2abc(l:indices[l:level], l:islower[l:level])
      elseif l:types[l:level] ==# 'num'
        let l:bullet_num = l:indices[l:level]
      else
        " standard or checkbox
        let l:bullet_num = l:bullet.bullet
      endif

      let l:new_bullet =
            \ l:bullet.leading_space
            \ . l:bullet_num
            \ . l:bullet.closure
            \ . (l:pad_len[l:level] == 0 ? l:bullet.trailing_space : ' ')
      let l:new_bullet = s:pad_to_length(l:new_bullet, l:pad_len[l:level])
      let l:pad_len[l:level] = len(l:new_bullet)
      let l:renumbered_line = l:new_bullet . l:bullet.text_after_bullet
      call setline(l:line.nr, l:renumbered_line)
    else
      call setline(l:line.nr, l:line.text)
    endif
  endfor
endfun


command! -range=% RenumberSelection call <SID>renumber_selection()
" --------------------------------------------------------- }}}

" Changing outline level ---------------------------------- {{{
fun! s:change_bullet_level(direction)
  let l:lnum = line('.')
  let l:curr_line = s:parse_bullet(l:lnum, getline(l:lnum))

  if a:direction == 1
    if l:curr_line != [] && indent(l:lnum) == 0
      " Promoting a bullet at the highest level will delete the bullet
      call setline(l:lnum, l:curr_line[0].text_after_bullet)
      return
    else
      execute "normal! <<"
    endif
  else
    execute "normal! >>"
  endif

  let l:curr_indent = indent(l:lnum)
  let l:curr_bullet= s:closest_bullet_types(l:lnum, l:curr_indent)
  let l:curr_bullet = s:resolve_bullet_type(l:curr_bullet)

  if l:curr_bullet == {}
    " Only change the bullet level if it's currently a bullet.
    return
  endif

  let l:curr_line = l:curr_bullet.starting_at_line_num
  let l:closest_bullet = s:closest_bullet_types(l:curr_line - g:bullets_line_spacing, l:curr_indent)
  let l:closest_bullet = s:resolve_bullet_type(l:closest_bullet)

  if l:closest_bullet == {}
    " If there is no parent/sibling bullet then this bullet shouldn't change.
    return
  endif

  let l:islower = l:closest_bullet.bullet ==# tolower(l:closest_bullet.bullet)
  let l:closest_type = l:islower ? l:closest_bullet.bullet_type :
        \ toupper(l:closest_bullet.bullet_type)

  if l:closest_bullet.bullet_type ==# 'std'
    " Append the bullet marker to the type, e.g., 'std*'

    let l:closest_type = l:closest_type . l:closest_bullet.bullet
  endif

  let l:closest_index = index(g:bullets_outline_levels, l:closest_type)

  if l:closest_index == -1
    " We are in a list using markers that aren't specified in
    " g:bullets_outline_levels so we shouldn't try to change the current
    " bullet.
    return
  endif

  let l:closest_indent = indent(l:closest_bullet.starting_at_line_num)

  if (l:curr_indent == l:closest_indent)
    " The closest bullet is a sibling so the current bullet should
    " increment to the next bullet marker.

    let l:next_bullet = s:next_bullet_str(l:closest_bullet)
    let l:next_bullet_str = s:pad_to_length(l:next_bullet, l:closest_bullet.bullet_length)
          \ . l:curr_bullet.text_after_bullet

  elseif l:closest_index + 1 < len(g:bullets_outline_levels) || l:curr_indent < l:closest_indent
    " The current bullet is a child of the closest bullet so figure out
    " what bullet type it should have and set its marker to the first
    " character of that type.

    let l:next_index = l:closest_index + 1
    let l:next_type = g:bullets_outline_levels[l:next_index]
    let l:next_islower = l:next_type ==# tolower(l:next_type)
    let l:trailing_space = ' '

    let l:curr_bullet.closure = l:closest_bullet.closure

    " set the bullet marker to the first character of that type
    if l:next_type ==? 'rom'
      let l:next_num = s:arabic2roman(1, l:next_islower)
    elseif l:next_type ==? 'abc'
      let l:next_num = s:dec2abc(1, l:next_islower)
    elseif l:next_type ==# 'num'
      let l:next_num = '1'
    else
      " standard bullet; l:next_type contains the bullet symbol to use
      let l:next_num = strpart(l:next_type, len(l:next_type) - 1)
      let l:curr_bullet.closure = ''
    endif

    let l:next_bullet_str =
          \ l:curr_bullet.leading_space
          \ . l:next_num
          \ . l:curr_bullet.closure
          \ . l:trailing_space
          \ . l:curr_bullet.text_after_bullet

  else
    " We're outside of the defined outline levels
    let l:next_bullet_str =
          \ l:curr_bullet.leading_space
          \ . l:curr_bullet.text_after_bullet
  endif

  " Apply the new bullet
  call setline(l:lnum, l:next_bullet_str)
  execute 'normal! $'

  return
endfun

command! BulletDemote call <SID>change_bullet_level(-1)
command! BulletPromote call <SID>change_bullet_level(1)

" --------------------------------------------------------- }}}

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

    " Promote and Demote outline level
    call s:add_local_mapping('inoremap', '<C-t>', '<C-o>:BulletDemote<cr>')
    call s:add_local_mapping('nnoremap', '>>', ':BulletDemote<cr>')
    call s:add_local_mapping('inoremap', '<C-d>', '<C-o>:BulletPromote<cr>')
    call s:add_local_mapping('nnoremap', '<<', ':BulletPromote<cr>')

  end
augroup END
" --------------------------------------------------------- }}}

" Helpers -----------------------------------------------  {{{
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

fun! s:pad_to_length(str, len)
  if g:bullets_pad_right == 0 | return a:str | endif
  let l:len = a:len - len(a:str)
  let l:str = a:str
  if (l:len <= 0) | return a:str | endif
  while l:len > 0
    let l:str = l:str . ' '
    let l:len = l:len - 1
  endwhile
  return l:str
endfun

fun! s:is_indented(line_text)
  return a:line_text =~# '\v^\s+\w'
endfun

fun! s:map(list, fn)
  let new_list = deepcopy(a:list)
  call map(new_list, a:fn)
  return new_list
endfun

fun! s:filter(list, fn)
  let new_list = deepcopy(a:list)
  call filter(new_list, a:fn)
  return new_list
endfun

fun! s:find(list, fn)
  let l:fn = substitute(a:fn, 'v:val', 'l:item', 'g')
  for l:item in a:list
    let l:new_item = deepcopy(l:item)
    if execute('echon (' . l:fn . ')') ==# '1'
      return l:new_item
    endif
  endfor

  return 0
endfun

fun! s:has_item(list, fn)
  return !empty(s:find(a:list, a:fn))
endfun
" ------------------------------------------------------- }}}

" Restore previous external compatibility options --------- {{{
let &cpoptions = s:save_cpo
" --------------------------------------------------------  }}}
