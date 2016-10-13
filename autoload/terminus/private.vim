" Copyright 2015-present Greg Hurrell. All rights reserved.
" Licensed under the terms of the BSD 2-clause license.

function! s:escape(string) abort
  " Double each <Esc>.
  return substitute(a:string, "\<Esc>", "\<Esc>\<Esc>", 'g')
endfunction

function! terminus#private#wrap(string) abort
  if strlen(a:string) == 0
    return ''
  end

  let l:tmux_begin="\<Esc>Ptmux;"
  let l:tmux_end="\<Esc>\\"

  return l:tmux_begin . s:escape(a:string) . l:tmux_end
endfunction

function! terminus#private#focus_lost() abort
  let l:cmdline=getcmdline()
  let l:cmdpos=getcmdpos()

  silent doautocmd FocusLost %

  call setcmdpos(l:cmdpos)
  return l:cmdline
endfunction

function! terminus#private#focus_gained() abort
  let l:cmdline=getcmdline()
  let l:cmdpos=getcmdpos()

  " Our checktime autocmd will produce:
  "   E523: Not allowed here:   checktime
  silent! doautocmd FocusGained %

  call setcmdpos(l:cmdpos)
  return l:cmdline
endfunction

function! terminus#private#paste(ret) abort
  set paste
  return a:ret
endfunction

function! terminus#private#checkfocus() abort
  if exists('$TMUX') && exists('$TMUX_PANE')
    let l:pane_id=$TMUX_PANE
    let l:panes=split(system('tmux list-panes -F "#{pane_active} #{pane_id}"'), '\n')
    let l:active=filter(l:panes, 'match(v:val, "^1 ") == 0')
    if len(l:active) == 1
      let l:match=matchstr(l:active[0], '\v1 \zs\%\d+$')
      if l:match != ''
        let l:autocmd=(l:match == l:pane_id ? 'FocusGained' : 'FocusLost')
        execute 'silent! doautocmd ' . l:autocmd . ' %'
      endif
    endif
  endif
endfunction

function! terminus#private#handletimer(timer) abort
  if exists('g:TerminusPendingFocusTimer')
    unlet g:TerminusPendingFocusTimer
  endif
  call terminus#private#checkfocus()
endfunction

function! terminus#private#schedulecheck() abort
  if exists('g:TerminusPendingFocusTimer')
    call timer_stop(g:TerminusPendingFocusTimer)
  endif
  let g:TerminusPendingFocusTimer=timer_start(
        \   50,
        \   'terminus#private#handletimer'
        \ )
endfunction
