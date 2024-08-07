#   08/07/2024 https://github.com/su8/hellwm
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.

#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.

#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#   MA 02110-1301, USA.

VERSION = xcb-su8-git
WMNAME  = hellxcb

DEBUG 	 = 0

PREFIX ?= /usr/local
BINDIR ?= ${PREFIX}/bin
MANPREFIX ?= ${PREFIX}/share/man

PACKAGE=hellxcb
PROG=hellxcb.c

ADDITIONALFLAGS += -DVERSION=\"${VERSION}\" -DWMNAME=\"${WMNAME}\"

INCS = -I. -I. `pkg-config --cflags xcb xcb-aux xcb-icccm xcb-keysyms xcb-ewmh`
LIBS = -lX11 -lc `pkg-config --libs xcb xcb-icccm xcb-keysyms`

CFLAGS += ${ADDITIONALFLAGS} -g2 -Wall -Wextra -O2 -I/usr/include/freetype2 -I/usr/X11R6/include -L/usr/X11R6/lib -I/usr/include/X11 -lX11 -lXft -std=c99 -pipe -pedantic -Wundef -Wshadow -W -Wwrite-strings -Wcast-align -Wstrict-overflow=5 -Wconversion -Wpointer-arith -Wstrict-prototypes -Wformat=2 -Wsign-compare -Wendif-labels -Wredundant-decls -Winit-self
LDFLAGS  += ${LIBS}

all:
	$(CC) $(CFLAGS) $(LDFLAGS) -o $(PACKAGE) $(PROG)

clean:
	@echo cleaning
	@rm -fv ${WMNAME} ${OBJ} ${WMNAME}-${VERSION}.tar.gz
	@rm -f $(PACKAGE)

install:
	@install -D -s -m 755 $(PACKAGE) /usr/bin/$(PACKAGE)
	@echo installing manual page to ${DESTDIR}${MANPREFIX}/man.1
	@install -Dm644 ${WMNAME}.1 ${DESTDIR}${MANPREFIX}/man1/${WMNAME}.1

uninstall:
	@echo removing manual page from ${DESTDIR}${MANPREFIX}/man1
	@rm -f ${DESTDIR}${MANPREFIX}/man1/${WMNAME}.1
	@rm -f /usr/bin/$(PACKAGE)

.PHONY: all clean install uninstall
