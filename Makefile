PREFIX=/usr/local
BINDIR=$(PREFIX)/bin

all:
	@echo "Run \"sudo make install\" to install shot"
	@echo "Run \"sudo make linux-dependencies\" to install dependencies on linux (Ubuntu)"

install:
	install -m 0755 shot.sh $(BINDIR)/shot

linux-dependencies:
	apt-get install scrot xclip zenity recordmydesktop x11-utils xdotool
