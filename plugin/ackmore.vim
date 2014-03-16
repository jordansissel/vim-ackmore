" Ack integration.

" Run Ack on the current word starting at the root of this repo
nnoremap <Leader>a :AckCurrentWord LAck<CR>
nnoremap <Leader>A :AckCurrentWord Ack<CR>
vnoremap <Leader>a :AckVisualRange LAck<CR>
vnoremap <Leader>A :AckVisualRange Ack<CR>

" Make some commands that invoke functions.
command! -nargs=1 -range AckVisualRange call AckVisualRange(<f-args>)
command! -nargs=1 AckCurrentWord call AckCurrentWord(<f-args>)

autocmd BufEnter * call SetVcsRoot()
function! SetVcsRoot()
  if !exists("b:vcsroot")
    " Keep track of the root of the current git or svn repo, if any.
    " TODO(sissel): Probably should put this in a separate plugin
    let b:vcsroot = system("git rev-parse --show-toplevel")
    if v:shell_error == 0
        let b:vcsroot = substitute(b:vcsroot, '\n$', '', '')
        let b:vcsroot_type = 'git'
        return
    endif
    let b:vcsroot = system("svn info|grep 'Working Copy Root Path:'")
    if v:shell_error == 0
        let b:vcsroot = substitute(b:vcsroot, 'Working Copy Root Path: ', '', '')
        let b:vcsroot = substitute(b:vcsroot, '\n$', '', '')
        let b:vcsroot_type = 'svn'
        return
    endif
    " if we didn't return a value yet, erase what we have so we don't
    " pass error text into ack searches
    let b:vcsroot = ''
    let b:vcsroot_type = 'none'
  endif
endfunction " SetVcsRoot

function! AckCurrentWord(ackmethod)
  " Find the VCS repo root if we don't already know it.
  call SetVcsRoot()

  " a:ackmethod will be 'Ack' or 'LAck'
  " Run Ack on the current word based on the repository root.
  execute a:ackmethod . " <cword> " . b:vcsroot
  call QfMappings()
endfunction " AckCurrentWord

function! AckVisualRange(cmd)
  " Copy 'z' register
  let l:oldz = getreg("z")

  " use 'gv' to select the last visual mode selection
  " then yank it into register 'z'
  normal gv"zy
  let l:string = getreg("z")

  " Restore 'z' register
  call setreg("z", l:oldz)

  " Do it.
  call SetVcsRoot()
  execute a:cmd l:string b:vcsroot
  call QfMappings()
endfunction

function! QFOpenCurrentInNewTab()
  " For some reason getqflist() and getloclist() don't seem to work
  " when Ack is being used. So we have to do this instead.
  let l:line = line(".") " Get the current line number
  let l:str = getline(l:line) " Get the current line string
  " split: filename|number|...
  let l:values = split(l:str, '|') " Split the line by '|'
  " open the file:line in a new tab at the given line number
  execute "tabe +" . l:values[1] . " " . l:values[0]
endfunction

function! QfMappings()
  " Map 't' on the quickfix window to open the file:line selected
  exec "nnoremap <buffer> t :call QFOpenCurrentInNewTab()<CR>"
  " Map 'q' to close the quickfix window
  exec "nnoremap <buffer> q :cclose<CR>:lclose<CR>"
endfunction
