#   08/07/2024 https://github.com/su8/hellxcb
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

PREFIX ?= /usr/local
BINDIR ?= ${PREFIX}/bin
MANPREFIX ?= ${PREFIX}/share/man

PACKAGE=hellxcb
PROG=hellxcb.c

ADDITIONALFLAGS += -DVERSION=\"${VERSION}\" -DWMNAME=\"${WMNAME}\"

INCS = -I. `pkg-config --cflags xcb xcb-icccm xcb-keysyms xproto`
LIBS = `pkg-config --libs xcb xcb-icccm xcb-keysyms`

CFLAGS += ${ADDITIONALFLAGS} -g2 -Wall -Wextra -O2 -std=c99 -pipe -pedantic -Wundef -Wshadow -W -Wwrite-strings -Wcast-align -Wstrict-overflow=5 -Wconversion -Wpointer-arith -Wstrict-prototypes -Wformat=2 -Wsign-compare -Wendif-labels -Wredundant-decls -Winit-self
LDFLAGS  += ${LIBS}

all:
	$(CC) -o $(PACKAGE) $(PROG) $(CFLAGS) $(INCS) $(LDFLAGS)

clean:
	echo cleaning
	rm -fv $(PACKAGE) ${WMNAME}-${VERSION}.tar.gz

install:
	install -D -s -m 755 $(PACKAGE) ${DESTDIR}${BINDIR}/$(PACKAGE)
	echo installing manual page to ${DESTDIR}${MANPREFIX}/man.1
	install -Dm644 ${WMNAME}.1 ${DESTDIR}${MANPREFIX}/man1/${WMNAME}.1

check: all
	sh tests/smoke.sh ./$(PACKAGE)

uninstall:
	echo removing manual page from ${DESTDIR}${MANPREFIX}/man1
	rm -f ${DESTDIR}${MANPREFIX}/man1/${WMNAME}.1
	rm -f ${DESTDIR}${BINDIR}/$(PACKAGE)

.PHONY: all check clean install uninstall
