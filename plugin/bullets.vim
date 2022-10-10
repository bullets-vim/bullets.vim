scriptencoding utf-8
" Vim plugin for automated bulleted lists
" Last Change: Sat Jan 29 06:56:14 PM CST 2022
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

" Extra key mappings in addition to default ones.
" If you don’t need default mappings set 'g:bullets_set_mappings' to '0'.
" N.B. 'g:bullets_mapping_leader' has no effect on these mappings.
"
" Example:
"   let g:bullets_custom_mappings = [
"     \ ['imap', '<cr>', '<Plug>(bullets-newline)'],
"     \ ]
if !exists('g:bullets_custom_mappings')
  let g:bullets_custom_mappings = []
endif

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

if !exists('g:bullets_renumber_on_change')
  let g:bullets_renumber_on_change = 1
endif

if !exists('g:bullets_nested_checkboxes')
  " Enable nested checkboxes that toggle parents and children when the current
  " checkbox status changes
  let g:bullets_nested_checkboxes = 1
endif

if !exists('g:bullets_checkbox_markers')
  " The ordered series of markers to use in checkboxes
  " If only two markers are listed, they represent 'off' and 'on'
  " When more than two markers are included, the (n) intermediate markers
  " represent partial completion where each marker is 1/n of the total number
  " of markers.
  " E.g. the default ' .oOX': ' ' = 0 < '.' <= 1/3 < 'o' < 2/3 < 'O' < 1 = X
  " This scheme is borrowed from https://github.com/vimwiki/vimwiki
  let g:bullets_checkbox_markers = ' .oOX'

  " You can use fancy symbols like this:
  " let g:bullets_checkbox_markers = '✗○◐●✓'

  " You can disable partial completion markers like this:
  " let g:bullets_checkbox_markers = ' X'
endif

if !exists('g:bullets_checkbox_partials_toggle')
  " Should toggling on a partially completed checkbox set it to on (1), off
  " (0), or disable toggling partially completed checkboxes (-1)
  let g:bullets_checkbox_partials_toggle = 1
endif

if !exists('g:bullets_auto_indent_after_colon')
  " Should a line ending in a colon result in the next line being indented (1)?
  let g:bullets_auto_indent_after_colon = 1
endif

" ------------------------------------------------------   }}}

" Parse Bullet Type -------------------------------------------  {{{
fun! s:parse_bullet(line_num, line_text)

  let l:bullet = s:match_bullet_list_item(a:line_text)
  " Must be a bullet to be a checkbox
  let l:check = !empty(l:bullet) ? s:match_checkbox_bullet_item(a:line_text) : {}
  " Cannot be numeric if a bullet
  let l:num = empty(l:bullet) ? s:match_numeric_list_item(a:line_text) : {}
  " Cannot be alphabetic if numeric or a bullet
  let l:alpha = empty(l:bullet) && empty(l:num) ? s:match_alphabetical_list_item(a:line_text) : {}
  " Cannot be roman if numeric or a bullet
  let l:roman = empty(l:bullet) && empty(l:num) ? s:match_roman_list_item(a:line_text) : {}

  let l:kinds = s:filter([l:bullet, l:check, l:num, l:alpha, l:roman], '!empty(v:val)')

  for l:data in l:kinds
    let l:data.starting_at_line_num = a:line_num
  endfor

  return l:kinds

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
  " match any symbols listed in g:bullets_checkbox_markers as well as the
  " default ' ', 'x', and 'X'
  let l:checkbox_bullet_regex =
        \ '\v(^(\s*)([-\*] \[(['
        \ . g:bullets_checkbox_markers
        \ . ' xX])?\])(\s+))(.*)'
  let l:matches = matchlist(a:input_text, l:checkbox_bullet_regex)

  if empty(l:matches)
    return {}
  endif

  let l:bullet_length     = strlen(l:matches[1])
  let l:leading_space     = l:matches[2]
  let l:bullet            = l:matches[3]
  let l:checkbox_marker   = l:matches[4]
  let l:trailing_space    = l:matches[5]
  let l:text_after_bullet = l:matches[6]

  return {
        \ 'bullet_type':       'chk',
        \ 'bullet_length':     l:bullet_length,
        \ 'leading_space':     l:leading_space,
        \ 'bullet':            l:bullet,
        \ 'checkbox_marker':   l:checkbox_marker,
        \ 'closure':           '',
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

  if a:max_indent < 0
    " sanity check
    return []
  endif

  " Support for wrapped text bullets, even if the wrapped line is not indented
  " It considers a blank line as the end of a bullet
  " DEMO: https://raw.githubusercontent.com/dkarter/bullets.vim/master/img/wrapped-bullets.gif
  while l:lnum > 1 && (l:curr_indent != 0 || l:bullet_kinds != [] || !(l:ltxt =~# '\v^(\s+$|$)'))
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

    while l:prev_bullet_types != [] && l:bullet_indent <= indent(l:prev_search_starting_line)
      let l:prev_search_starting_line -= g:bullets_line_spacing
      let l:prev_bullet_types = s:closest_bullet_types(l:prev_search_starting_line, l:bullet_indent)
    endwhile

    if len(l:prev_bullet_types) == 0 || l:bullet_indent > indent(l:prev_search_starting_line)

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
  let l:checkbox_markers = split(g:bullets_checkbox_markers, '\zs')
  return a:bullet.bullet[0].' [' . l:checkbox_markers[0] . ']'
endfun
" }}}

" Generate bullets --------------------------------------  {{{
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
  let l:indent_next = s:line_ends_in_colon(l:curr_line_num) && g:bullets_auto_indent_after_colon

  " check if current line is a bullet and we are at the end of the line (for
  " insert mode only)
  if l:bullet != {} && (l:normal_mode || s:is_at_eol())
    " was any text entered after the bullet?
    if l:bullet.text_after_bullet ==# ''
      " We don't want to create a new bullet if the previous one was not used,
      " instead we want to delete the empty bullet - like word processors do
      if g:bullets_delete_last_bullet_if_empty
        call setline(l:curr_line_num, '')
        let l:send_return = 0
      endif
    elseif !(l:bullet.bullet_type ==# 'abc' && s:abc2dec(l:bullet.bullet) + 1 > s:abc_max)

      let l:next_bullet = s:next_bullet_str(l:bullet)
      if l:bullet.bullet_type ==# 'chk'
        let l:next_bullet_list = [l:next_bullet]
      else
        let l:next_bullet_list = [s:pad_to_length(l:next_bullet, l:bullet.bullet_length)]
      endif

      " prepend blank lines if desired
      if g:bullets_line_spacing > 1
        let l:next_bullet_list += map(range(g:bullets_line_spacing - 1), '""')
        call reverse(l:next_bullet_list)
      endif

      " insert next bullet
      call append(l:curr_line_num, l:next_bullet_list)


      " go to next line after the new bullet
      let l:col = strlen(getline(l:next_line_num)) + 1
      call setpos('.', [0, l:next_line_num, l:col])

      " indent if previous line ended in a colon
      if l:indent_next
        " demote the new bullet
        call s:change_bullet_level_and_renumber(-1)
        " reset cursor position after indenting
        let l:col = strlen(getline(l:next_line_num)) + 1
        call setpos('.', [0, l:next_line_num, l:col])
      elseif g:bullets_renumber_on_change
        call s:renumber_whole_list()
      endif

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

" Helper for Colon Indent
"   returns 1 if current line ends in a colon, else 0
fun! s:line_ends_in_colon(lnum)
  return getline(a:lnum)[strlen(getline(a:lnum))-1:] ==# ':'
endfun
" --------------------------------------------------------- }}}

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

fun! s:toggle_checkbox(lnum)
  " Toggles the checkbox on line a:lnum.
  " Returns the resulting status: (1) checked, (0) unchecked, (-1) unchanged
  let l:lnum = a:lnum
  let l:indent = indent(l:lnum)
  let l:bullet = s:closest_bullet_types(l:lnum, l:indent)
  let l:bullet = s:resolve_bullet_type(l:bullet)
  let l:checkbox_content = l:bullet.checkbox_marker
  if empty(l:bullet) || !has_key(l:bullet, 'checkbox_marker')
    return -1
  endif

  let l:checkbox_markers = split(g:bullets_checkbox_markers, '\zs')
  let l:partial_markers = join(l:checkbox_markers[1:-2], '')
  if g:bullets_checkbox_partials_toggle > 0
        \ && l:checkbox_content =~# '\v[' . l:partial_markers . ']'
    " Partially complete
    let l:marker = g:bullets_checkbox_partials_toggle ?
          \ l:checkbox_markers[-1] :
          \ l:checkbox_markers[0]
  elseif l:checkbox_content =~# '\v[ ' . l:checkbox_markers[0] . ']'
    let l:marker = l:checkbox_markers[-1]
  elseif l:checkbox_content =~# '\v[xX' . l:checkbox_markers[-1] . ']'
    let l:marker = l:checkbox_markers[0]
  else
    return -1
  endif

  call s:set_checkbox(l:lnum, l:marker)
  return l:marker ==? l:checkbox_markers[-1]
endfun

fun! s:set_checkbox(lnum, marker)
  let l:initpos = getpos('.')
  let l:pos = s:find_checkbox_position(a:lnum)
  if l:pos >= 0
    call s:replace_char_in_line(a:lnum, l:pos, a:marker)
    call setpos('.', l:initpos)
  endif
endfun

fun! s:toggle_checkboxes_nested()
  " toggle checkbox on the current line, as well as its parents and children
  let l:lnum = line('.')
  let l:indent = indent(l:lnum)
  let l:bullet = s:closest_bullet_types(l:lnum, l:indent)
  let l:bullet = s:resolve_bullet_type(l:bullet)

  " Is this a checkbox? Do nothing if it's not, otherwise toggle the checkbox
  if empty(l:bullet) || l:bullet.bullet_type !=# 'chk'
    return
  endif

  let l:checked = s:toggle_checkbox(l:lnum)

  if g:bullets_nested_checkboxes
    " Toggle children and parents
    let l:completion_marker = s:sibling_checkbox_status(l:lnum)
    call s:set_parent_checkboxes(l:lnum, l:completion_marker)

    " Toggle children
    if l:checked >= 0
      call s:set_child_checkboxes(l:lnum, l:checked)
    endif
  endif
endfun

fun! s:set_parent_checkboxes(lnum, marker)
  " set the parent checkbox of line a:lnum, as well as its parents, based on
  " the marker passed in a:marker
  if !g:bullets_nested_checkboxes
    return
  endif

  let l:parent = s:get_parent(a:lnum)
  if !empty(l:parent) && l:parent.bullet_type ==# 'chk'
    " Check for siblings' status
    let l:pnum = l:parent.starting_at_line_num
    call s:set_checkbox(l:pnum, a:marker)
    let l:completion_marker = s:sibling_checkbox_status(l:pnum)
    call s:set_parent_checkboxes(l:pnum, l:completion_marker)
  endif
endfun

fun! s:set_child_checkboxes(lnum, checked)
  " set the children checkboxes of line a:lnum based on the value of a:checked
  " 0: unchecked, 1: checked, other: do nothing
  if !g:bullets_nested_checkboxes || !(a:checked == 0 || a:checked == 1)
    return
  endif

  let l:children = s:get_children_line_numbers(a:lnum)
  if !empty(l:children)
    let l:checkbox_markers = split(g:bullets_checkbox_markers, '\zs')
    for l:child in l:children
      let l:marker = a:checked ? l:checkbox_markers[-1] :
            \ l:checkbox_markers[0]
      call s:set_checkbox(l:child, l:marker)
      call s:set_child_checkboxes(l:child, a:checked)
    endfor
  endif
endfun

command! SelectCheckboxInside call <SID>select_checkbox(1)
command! SelectCheckbox call <SID>select_checkbox(0)
command! ToggleCheckbox call <SID>toggle_checkboxes_nested()
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
      if l:roman =~# '^' . l:letters
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
  let l:levels = {} " stores all the info about the current outline/list

  for l:line in l:selection_lines
    let l:indent = indent(l:line.nr)
    let l:bullet = s:closest_bullet_types(l:line.nr, l:indent)
    let l:bullet = s:resolve_bullet_type(l:bullet)
    let l:curr_level = s:get_level(l:bullet)
    if l:curr_level > 1
      " then it's an AsciiDoc list and shouldn't be renumbered
      break
    endif

    if !empty(l:bullet) && l:bullet.starting_at_line_num == l:line.nr
      " skip wrapped lines and lines that aren't bullets
      if (l:indent > l:prev_indent || !has_key(l:levels, l:indent))
          \ && l:bullet.bullet_type !=# 'chk' && l:bullet.bullet_type !=# 'std'
        if !has_key(l:levels, l:indent)
          let l:levels[l:indent] = {'index': 1}
        endif

        " use the first bullet at this level to define the bullet type for
        " subsequent bullets at the same level. Needed to normalize bullet
        " types when there are multiple types of bullets at the same level.
        let l:levels[l:indent].islower = l:bullet.bullet ==# tolower(l:bullet.bullet)
        let l:levels[l:indent].type = l:bullet.bullet_type
        let l:levels[l:indent].bullet = l:bullet.bullet " for standard bullets
        let l:levels[l:indent].closure = l:bullet.closure " normalize closures
        let l:levels[l:indent].trailing_space = l:bullet.trailing_space
      else
        if l:bullet.bullet_type !=# 'chk' && l:bullet.bullet_type !=# 'std'
          let l:levels[l:indent].index += 1
        endif

        if l:indent < l:prev_indent
          " Reset the numbering on all all child items. Needed to avoid continuing
          " the numbering from earlier portions of the list with the same bullet
          " type in some edge cases.
          for l:key in keys(l:levels)
            if l:key > l:indent
              call remove(l:levels, l:key)
            endif
          endfor
        endif
      endif

      let l:prev_indent = l:indent

      if l:bullet.bullet_type !=# 'chk' && l:bullet.bullet_type !=# 'std'
        if l:levels[l:indent].type ==? 'rom'
          let l:bullet_num = s:arabic2roman(l:levels[l:indent].index, l:levels[l:indent].islower)
        elseif l:levels[l:indent].type ==? 'abc'
          let l:bullet_num = s:dec2abc(l:levels[l:indent].index, l:levels[l:indent].islower)
        elseif l:levels[l:indent].type ==# 'num'
          let l:bullet_num = l:levels[l:indent].index
        endif

        let l:new_bullet =
              \ l:bullet_num
              \ . l:levels[l:indent].closure
              \ . l:levels[l:indent].trailing_space
        if l:levels[l:indent].index > 1
          let l:new_bullet = s:pad_to_length(l:new_bullet, l:levels[l:indent].pad_len)
        endif
        let l:levels[l:indent].pad_len = len(l:new_bullet)
        let l:renumbered_line = l:bullet.leading_space
              \ . l:new_bullet
              \ . l:bullet.text_after_bullet
        call setline(l:line.nr, l:renumbered_line)
      elseif l:bullet.bullet_type ==# 'chk'
        " Reset the checkbox marker if it already exists, or blank otherwise
        let l:marker = has_key(l:bullet, 'checkbox_marker') ?
              \ l:bullet.checkbox_marker : ' '
        call s:set_checkbox(l:line.nr, l:marker)
      endif
    endif
  endfor
endfun

fun! s:renumber_whole_list(...)
  " Renumbers the whole list containing the cursor.
  " Does not renumber across blank lines.
  " Takes 2 optional arguments containing starting and ending cursor positions
  " so that we can reset the existing visual selection after renumbering.
  let l:first_line = s:first_bullet_line(line('.'))
  let l:last_line = s:last_bullet_line(line('.'))
  if l:first_line > 0 && l:last_line > 0
    " Create a visual selection around the current list so that we can call
    " s:renumber_selection() to do the renumbering.
    call setpos("'<", [0, l:first_line, 1, 0])
    call setpos("'>", [0, l:last_line, 1, 0])
    call s:renumber_selection()
    if a:0 == 2
      " Reset the starting visual selection
      call setpos("'<", [0, a:1[0], a:1[1], 0])
      call setpos("'>", [0, a:2[0], a:2[1], 0])
      execute 'normal! gv'
    endif
  endif
endfun

command! -range=% RenumberSelection call <SID>renumber_selection()
command! RenumberList call <SID>renumber_whole_list()
" --------------------------------------------------------- }}}

" Changing outline level ---------------------------------- {{{
fun! s:change_bullet_level(direction)
  let l:lnum = line('.')
  let l:curr_line = s:parse_bullet(l:lnum, getline(l:lnum))

  if a:direction == 1
    if l:curr_line != [] && indent(l:lnum) == 0
      " Promoting a bullet at the highest level will delete the bullet
      call setline(l:lnum, l:curr_line[0].text_after_bullet)
      execute 'normal! $'
      return
    else
      execute 'normal! <<$'
    endif
  else
    execute 'normal! >>$'
  endif

  if l:curr_line == []
    " If the current line is not a bullet then don't do anything else.
    return
  endif

  let l:curr_indent = indent(l:lnum)
  let l:curr_bullet= s:closest_bullet_types(l:lnum, l:curr_indent)
  let l:curr_bullet = s:resolve_bullet_type(l:curr_bullet)

  let l:curr_line = l:curr_bullet.starting_at_line_num
  let l:closest_bullet = s:closest_bullet_types(l:curr_line - g:bullets_line_spacing, l:curr_indent)
  let l:closest_bullet = s:resolve_bullet_type(l:closest_bullet)

  if l:closest_bullet == {}
    " If there is no parent/sibling bullet then this bullet shouldn't change.
    return
  endif

  let l:islower = l:closest_bullet.bullet ==# tolower(l:closest_bullet.bullet)
  let l:closest_indent = indent(l:closest_bullet.starting_at_line_num)

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
  if (l:curr_indent == l:closest_indent)
    " The closest bullet is a sibling so the current bullet should
    " increment to the next bullet marker.

    let l:next_bullet = s:next_bullet_str(l:closest_bullet)
    let l:next_bullet_str = s:pad_to_length(l:next_bullet, l:closest_bullet.bullet_length)
          \ . l:curr_bullet.text_after_bullet

  elseif l:closest_index + 1 >= len(g:bullets_outline_levels)
        \ && l:curr_indent > l:closest_indent
    " The closest bullet is a parent and its type is the last one defined in
    " g:bullets_outline_levels so keep the existing bullet.
    " TODO: Might make an option for whether the bullet should stay or be
    " deleted when demoting past the end of the defined bullet types.
    return
  elseif l:closest_index + 1 < len(g:bullets_outline_levels) || l:curr_indent < l:closest_indent
    " The current bullet is a child of the closest bullet so figure out
    " what bullet type it should have and set its marker to the first
    " character of that type.

    let l:next_type = g:bullets_outline_levels[l:closest_index + 1]
    let l:next_islower = l:next_type ==# tolower(l:next_type)
    let l:trailing_space = ' '
    let l:curr_bullet.closure = l:closest_bullet.closure

    " set the bullet marker to the first character of the new type
    if l:next_type ==? 'rom'
      let l:next_num = s:arabic2roman(1, l:next_islower)
    elseif l:next_type ==? 'abc'
      let l:next_num = s:dec2abc(1, l:next_islower)
    elseif l:next_type ==# 'num'
      let l:next_num = '1'
    else
      " standard bullet; the last character of l:next_type contains the bullet
      " symbol to use
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

fun! s:change_bullet_level_and_renumber(direction)
  " Calls change_bullet_level and then renumber_whole_list if required
  call s:change_bullet_level(a:direction)
  if g:bullets_renumber_on_change
      call s:renumber_whole_list()
  endif
endfun

fun! s:visual_change_bullet_level(direction)
  " Changes the bullet level for each of the selected lines
  let l:start = getpos("'<")[1:2]
  let l:end = getpos("'>")[1:2]
  let l:selected_lines = range(l:start[0], l:end[0])
  for l:lnum in l:selected_lines
    " Iterate the cursor position over each line and then call
    " s:change_bullet_level for that cursor position.
    call setpos('.', [0, l:lnum, 1, 0])
    call s:change_bullet_level(a:direction)
  endfor
  if g:bullets_renumber_on_change
    " Pass the current visual selection so that it gets reset after
    " renumbering the list.
    call s:renumber_whole_list(l:start, l:end)
  endif
endfun

command! BulletDemote call <SID>change_bullet_level_and_renumber(-1)
command! BulletPromote call <SID>change_bullet_level_and_renumber(1)
command! -range=% BulletDemoteVisual call <SID>visual_change_bullet_level(-1)
command! -range=% BulletPromoteVisual call <SID>visual_change_bullet_level(1)

" --------------------------------------------------------- }}}

" Keyboard mappings --------------------------------------- {{{

" Automatic bullets
inoremap <silent> <Plug>(bullets-newline) <C-]><C-R>=<SID>insert_new_bullet()<cr>
nnoremap <silent> <Plug>(bullets-newline) :call <SID>insert_new_bullet()<cr>

" Renumber bullet list
vnoremap <silent> <Plug>(bullets-renumber) :RenumberSelection<cr>
nnoremap <silent> <Plug>(bullets-renumber) :RenumberList<cr>

" Toggle checkbox
nnoremap <silent> <Plug>(bullets-toggle-checkbox) :ToggleCheckbox<cr>

" Promote and Demote outline level
inoremap <silent> <Plug>(bullets-demote) <C-o>:BulletDemote<cr>
nnoremap <silent> <Plug>(bullets-demote) :BulletDemote<cr>
vnoremap <silent> <Plug>(bullets-demote) :BulletDemoteVisual<cr>
inoremap <silent> <Plug>(bullets-promote) <C-o>:BulletPromote<cr>
nnoremap <silent> <Plug>(bullets-promote) :BulletPromote<cr>
vnoremap <silent> <Plug>(bullets-promote) :BulletPromoteVisual<cr>

fun! s:add_local_mapping(with_leader, mapping_type, mapping, action)
  let l:file_types = join(g:bullets_enabled_file_types, ',')
  execute 'autocmd FileType ' .
        \ l:file_types .
        \ ' ' .
        \ a:mapping_type .
        \ ' <silent> <buffer> ' .
        \ (a:with_leader ? g:bullets_mapping_leader : '') .
        \ a:mapping .
        \ ' ' .
        \ a:action

  if g:bullets_enable_in_empty_buffers
    execute 'autocmd BufEnter * if bufname("") == "" | ' .
          \ a:mapping_type .
          \ ' <silent> <buffer> ' .
          \ (a:with_leader ? g:bullets_mapping_leader : '') .
          \ a:mapping .
          \ ' ' .
          \ a:action .
          \ '| endif'
  endif
endfun

augroup TextBulletsMappings
  autocmd!

  if g:bullets_set_mappings
    " Automatic bullets
    call s:add_local_mapping(1, 'imap', '<cr>', '<Plug>(bullets-newline)')
    call s:add_local_mapping(1, 'inoremap', '<C-cr>', '<cr>')

    call s:add_local_mapping(1, 'nmap', 'o', '<Plug>(bullets-newline)')

    " Renumber bullet list
    call s:add_local_mapping(1, 'vmap', 'gN', '<Plug>(bullets-renumber)')
    call s:add_local_mapping(1, 'nmap', 'gN', '<Plug>(bullets-renumber)')

    " Toggle checkbox
    call s:add_local_mapping(1, 'nmap', '<leader>x', '<Plug>(bullets-toggle-checkbox)')

    " Promote and Demote outline level
    call s:add_local_mapping(1, 'imap', '<C-t>', '<Plug>(bullets-demote)')
    call s:add_local_mapping(1, 'nmap', '>>', '<Plug>(bullets-demote)')
    call s:add_local_mapping(1, 'vmap', '>', '<Plug>(bullets-demote)')
    call s:add_local_mapping(1, 'imap', '<C-d>', '<Plug>(bullets-promote)')
    call s:add_local_mapping(1, 'nmap', '<<', '<Plug>(bullets-promote)')
    call s:add_local_mapping(1, 'vmap', '<', '<Plug>(bullets-promote)')
  end

  for s:custom_key_mapping in g:bullets_custom_mappings
    call call('<SID>add_local_mapping', [0] + s:custom_key_mapping)
  endfor
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

fun! s:get_level(bullet)
  if a:bullet == {} || a:bullet.bullet_type !=# 'std'
    return 0
  else
    return len(a:bullet.bullet)
  endif
endfun

fun! s:first_bullet_line(lnum, ...)
  " returns the line number of the first bullet in the list containing the
  " given line number, up to the first blank line
  " returns -1 if lnum is not in a list
  " Optional argument: only consider bullets at or above this indentation
  let l:lnum = a:lnum
  let l:first_line = -1
  let l:curr_indent = indent(l:lnum)
  let l:bullet_kinds = s:closest_bullet_types(l:lnum, l:curr_indent)
  let l:blank_lines = 0
  let l:list_start = 0

  let l:min_indent = exists('a:1') ? a:1 : 0
  if l:min_indent < 0
    " sanity check
    return -1
  endif

  while l:lnum >= 1 && !l:list_start && l:curr_indent >= l:min_indent
    if l:bullet_kinds != []
      let l:first_line = l:lnum
      let l:blank_lines = 0
    else
      let l:blank_lines += 1
      let l:list_start = l:blank_lines >= g:bullets_line_spacing
    endif
    let l:lnum -= 1
    let l:curr_indent = indent(l:lnum)
    let l:bullet_kinds = s:closest_bullet_types(l:lnum, l:curr_indent)
  endwhile
  return l:first_line
endfun

fun! s:last_bullet_line(lnum, ...)
  " returns the line number of the last bullet in the list containing the
  " given line number, down to the end of the list
  " returns -1 if lnum is not in a list
  " Optional argument: only consider bullets at or above this indentation
  let l:lnum = a:lnum
  let l:buf_end = line('$')
  let l:last_line = -1
  let l:curr_indent = indent(l:lnum)
  let l:bullet_kinds = s:closest_bullet_types(l:lnum, l:curr_indent)
  let l:blank_lines = 0
  let l:list_end = 0

  let l:min_indent = exists('a:1') ? a:1 : 0
  if l:min_indent < 0
    " sanity check
    return -1
  endif

  while l:lnum <= l:buf_end && !l:list_end && l:curr_indent >= l:min_indent
    if l:bullet_kinds != []
      let l:last_line = l:lnum
      let l:blank_lines = 0
    else
      let l:blank_lines += 1
      let l:list_end = l:blank_lines >= g:bullets_line_spacing
    endif
    let l:lnum += 1
    let l:curr_indent = indent(l:lnum)
    let l:bullet_kinds = s:closest_bullet_types(l:lnum, l:curr_indent)
  endwhile
  return l:last_line
endfun

fun! s:get_parent(lnum)
  " returns the parent bullet of the given line number, lnum, with indentation
  " at or below the given indent.
  " if there is no parent, returns an empty dictionary
  let l:indent = indent(a:lnum)
  if l:indent < 0
    return {}
  endif
  let l:parent = s:closest_bullet_types(a:lnum, l:indent - 1)
  let l:parent = s:resolve_bullet_type(l:parent)
  return l:parent
endfun

fun! s:get_sibling_line_numbers(lnum)
  " returns a list with line numbers of the sibling bullets with the same
  " indentation as a:indent, starting from the given line number, a:lnum
  let l:indent = indent(a:lnum)
  let l:first_sibling = s:first_bullet_line(a:lnum, l:indent)
  let l:last_sibling = s:last_bullet_line(a:lnum, l:indent)
  let l:siblings = []
  for l:lnum in range(l:first_sibling, l:last_sibling)
    if indent(l:lnum) == l:indent
      let l:bullet = s:parse_bullet(l:lnum, getline(l:lnum))
      if !empty(l:bullet)
        call add(l:siblings, l:lnum)
      endif
    endif
  endfor
  return l:siblings
endfun

fun! s:get_children_line_numbers(lnum)
  " returns a list with line numbers of the immediate children bullets with
  " indentation greater than line a:lnum

  " sanity check
  if a:lnum < 1
    return []
  endif

  " find the first child (if any) so we can figure out the indentation for the
  " rest of the children
  let l:lnum = a:lnum + 1
  let l:indent = indent(a:lnum)
  let l:buf_end = line('$')
  let l:curr_indent = indent(l:lnum)
  let l:bullet_kinds = s:closest_bullet_types(l:lnum, l:curr_indent)
  let l:child_lnum = 0
  let l:blank_lines = 0

  while l:lnum <= l:buf_end && l:child_lnum == 0
    if l:bullet_kinds != [] && l:curr_indent > l:indent
      let l:child_lnum = l:lnum
    else
      let l:blank_lines += 1
      let l:child_lnum = l:blank_lines >= g:bullets_line_spacing ? -1 : 0
    endif
    let l:lnum += 1
    let l:curr_indent = indent(l:lnum)
    let l:bullet_kinds = s:closest_bullet_types(l:lnum, l:curr_indent)
  endwhile

  if l:child_lnum > 0
    return s:get_sibling_line_numbers(l:child_lnum)
  else
    return []
  endif
endfun

fun! s:sibling_checkbox_status(lnum)
  " Returns the marker corresponding to the proportion of siblings that are
  " completed.
  let l:siblings = s:get_sibling_line_numbers(a:lnum)
  let l:num_siblings = len(l:siblings)
  let l:checked = 0
  let l:checkbox_markers = split(g:bullets_checkbox_markers, '\zs')
  for l:lnum in l:siblings
    let l:indent = indent(l:lnum)
    let l:bullet = s:closest_bullet_types(l:lnum, l:indent)
    let l:bullet = s:resolve_bullet_type(l:bullet)
    if !empty(l:bullet) && has_key(l:bullet, 'checkbox_marker')
      let l:checkbox_content = l:bullet.checkbox_marker

      if l:checkbox_content =~# '\v[xX' . l:checkbox_markers[-1] . ']'
        " Checked
        let l:checked += 1
      endif
    endif
  endfor
  let l:divisions = len(l:checkbox_markers) - 1.0
  let l:completion = float2nr(ceil(l:divisions * l:checked / l:num_siblings))
  return l:checkbox_markers[l:completion]
endfun

fun! s:replace_char_in_line(lnum, chari, item)
  let l:curline = getline(a:lnum)
  let l:before = strcharpart(l:curline, 0, a:chari)
  let l:after = strcharpart(l:curline, a:chari + 1)
  call setline(a:lnum, l:before . a:item . l:after)
endfun

fun! s:select_bullet_text(lnum)
  let l:curr_line = s:parse_bullet(a:lnum, getline(a:lnum))
  if l:curr_line != []
    let l:startpos = l:curr_line[0].bullet_length + 1
    call setpos('.',[0,a:lnum,l:startpos])
    normal! v
    call setpos('.',[0,a:lnum,len(getline(a:lnum))])
  endif
endfun

fun! s:select_bullet_item(lnum)
  let l:curr_line = s:parse_bullet(a:lnum, getline(a:lnum))
  if l:curr_line != []
    let l:startpos = len(l:curr_line[0].leading_space) + 1
    call setpos('.',[0,a:lnum,l:startpos])
    normal! v
    call setpos('.',[0,a:lnum,len(getline(a:lnum))])
  endif
endfun

command! SelectBullet call <SID>select_bullet_item(line('.'))
command! SelectBulletText call <SID>select_bullet_text(line('.'))
" ------------------------------------------------------- }}}

" Restore previous external compatibility options --------- {{{
let &cpoptions = s:save_cpo
" --------------------------------------------------------  }}}
