hellxcb
=============

→ tiny(!) and monsterous!
----------------------
This is xcb port of monsterwm tiling window manager.
For more detailed README refer to [monsterwm][]

Installation
------------

You need xcb and xcb-utils then,
open up `config.h`
and edit to suit your needs.
Build and install.

    $ $EDITOR_OF_CHOICE config.h
    $ make
    # make install

The packages in Arch Linux needed for example would be
`libxcb` `xcb-util` `xcb-util-wm` `xcb-util-keysym` `gcc` `make` `xorg` `X11`

Bugs
----

Fill bugs only on hellxcb, when you are sure the bug doesn't occur on [monsterwm][].

[monsterwm issues][monsterwm-bug]

   [monsterwm-bug]: https://github.com/c00kiemon5ter/monsterwm/issues
   [monsterwm-xcb-bug]: https://github.com/Cloudef/monsterwm-xcb/issues

Thanks
------

[the suckless team][skls] for [dwm][],
[moetunes][] for [dminiwm][],
[pyknite][] for [catwm][],
[c00kiemonster][cookiemonster] for [monsterwm][]

  [skls]: http://suckless.org/
  [dwm]:  http://dwm.suckless.org/
  [moetunes]: https://github.com/moetunes
  [dminiwm]:  https://bbs.archlinux.org/viewtopic.php?id=126463
  [pyknite]: https://github.com/pyknite
  [catwm]:   https://github.com/pyknite/catwm
  [monsterwm]: https://github.com/c00kiemon5ter/monsterwm
  [cookiemonster]: https://github.com/c00kiemon5ter
