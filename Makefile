include /etc/os-release

DIR=$(shell cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )

DISTRO_BASE=${ID_LIKE}
ifndef ID_LIKE
	DISTRO_BASE=${ID}
endif


.PHONY: all clean update

all:
	@echo Your distro base is: $(DISTRO_BASE)


clean:
	@echo $(ID_LIKE)

update: clean all

patates:


	# @echo Creating sym-links...
	# [ -f ~/.vimrc ] || ln -s $(PWD)/vimrc ~/.vimrc

	# @echo Installing packages...

	# @echo 
	# $(DIR)/user-setups-and-plugins.sh
	# @echo Creating sym-links...