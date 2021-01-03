#!/bin/sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


test -f "$HOME/.vimrc"  &&  echo "$HOME/.vimrc exists" ||  ln -s "$DIR/conf/vim.rc" "$HOME/.vimrc"

# test ! -d "~/.vim/bundle/Vundle.vim" && git clone "https://github.com/VundleVim/Vundle.vim.git" "~/.vim/bundle/Vundle.vim"

test -d "~/.vim/pack/onedark/" && cd ~/.vim/pack/onedark/; echo "Vim onedark theme is found, trying to update..."; git pull --rebase || git clone https://github.com/joshdick/onedark.vim.git ~/.vim/pack/onedark
echo "Vim is set up..."