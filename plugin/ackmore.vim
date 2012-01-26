" Ack integration.

" Run Ack on the current word starting at the root of this git repo
nnoremap <Leader>a :AckCurrentWord LAck<CR>
nnoremap <Leader>A :AckCurrentWord Ack<CR>
vnoremap <Leader>a :AckVisualRange LAck<CR>
vnoremap <Leader>A :AckVisualRange Ack<CR>

" Map 't' on the quickfix window to open the file:line selected
autocmd FileType qf nnoremap <buffer> t :call QFOpenCurrentInNewTab()<CR>
" Map 'q' to close the quickfix window
autocmd FileType qf nnoremap <buffer> q :cclose<CR>:lclose<CR>

" Make some commands that invoke functions.
command! -nargs=1 -range AckVisualRange call s:AckVisualRange(<f-args>)
command! -nargs=1 AckCurrentWord call s:AckCurrentWord(<f-args>)

function! SetGitRoot()
  if !exists("b:gitroot")
    " Keep track of the root of the current git repo, if any.
    " TODO(sissel): Probably should put this in a separate plugin
    let b:gitroot=system("git rev-parse --show-toplevel")
  endif
endfunction " SetGitRoot

function! s:AckCurrentWord(ackmethod)
  " Find the git root if we don't already know it.
  call SetGitRoot()

  " a:ackmethod will be 'Ack' or 'LAck'
  " Run Ack on the current word based on the git root.
  execute a:ackmethod . " <cword> " . b:gitroot
endfunction " AckCurrentWord

function! s:AckVisualRange(cmd)
  " Copy 'z' register
  let l:oldz = getreg("z")

  " use 'gv' to select the last visual mode selection
  " then yank it into register 'z'
  normal gv"zy
  let l:string = getreg("z")

  " Restore 'z' register
  call setreg("z", l:oldz)

  " Do it.
  call SetGitRoot()
  execute a:cmd l:string b:gitroot
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

