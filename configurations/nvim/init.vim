" Neovim entry point. Shares ~/.vimrc with Vim and adds Neovim-only extras.
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath

source ~/.vimrc

" --- Neovim-only ------------------------------------------------------------
set inccommand=split
tnoremap <Esc> <C-\><C-n>
