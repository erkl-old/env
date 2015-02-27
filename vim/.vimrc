set nocompatible   " Give up compatibility with vi.
set noerrorbells   " Disable error bell.
set novisualbell   " Disable visual error bell.
set encoding=utf8  " Use UTF-8, of course.
set number         " Show line numbers.
set ruler          " Show the bottom ruler.
set nowrap         " Disable line wrapping.
set backspace=2    " Make backspace work like most other apps.
set scrolloff=6    " Preserve 6 lines of context when scrolling.
set autoread       " Check for file changes after external commands.

" Tabs should be 4 space characters wide.
set softtabstop=4
set shiftwidth=4
set tabstop=4
set smarttab
set expandtab

" Improve search in various ways.
set hlsearch
set incsearch
set ignorecase
set smartcase

" Because I like to live dangerously.
set noswapfile
set nobackup

" Never highlight matching brackets.
set noshowmatch
let loaded_matchparen = 1

" Enable syntax highlighting and filetype-specific plugins.
syntax enable
filetype plugin on
filetype indent on

" Disable the arrow keys in normal mode.
nnoremap <up> <nop>
nnoremap <down> <nop>
nnoremap <left> <nop>
nnoremap <right> <nop>

" Strip trailing whitespace before saving.
function! TrimWhitespace()
    let l = line(".")
    let c = col(".")
    %s/\s\+$//e
    call cursor(l, c)
endfun

autocmd BufWritePre * :call TrimWhitespace()
