PREFIX=/usr/local
BINDIR=$(PREFIX)/bin

all:
	@echo "Run \"sudo make install\" to install shot"

install:
	install -m 0755 shot.sh $(BINDIR)/shot
