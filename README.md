hellxcb
=============

![](1pic.png)

→ tiny(!) and monsterous!
----------------------
This is xcb port of monsterwm tiling window manager.
For more detailed README refer to [monsterwm][]

The code editor in the picture above is Microsoft Visual Code Editor -- not **Studio Editor**

Installation
------------

Open up `config.h`
and edit to suit your needs.
Build and install.

    $ $EDITOR_OF_CHOICE config.h
    $ make -j8 # where 8 are CPU cores
    # make install

To have mouse cursor, open up `.xinitrc` and append somewhere before the `case` label the following `xsetroot -cursor_name left_ptr`

The statusline in the picture above is made of https://github.com/su8/doomy . You can use `sed` to make a named tag/workspace from `/tmp/hellxcb.txt` , just use `cat /tmp/hellxcb.txt | sed -E 's/tag: 1/tag: web/g; s/tag: 2/:tag dev/g; s/tag: 3/tag: misc/g; s/tag: 4/tag: float/g'` and redirect it `/tmp/doomy.txt` if you use https://github.com/su8/doomy

The packages needed for example would be
`libxcb` `xcb-util` `xcb-util-wm` `xcb-util-keysym` `gcc` `make` `xorg` 

Bugs
----

I have fixed - https://github.com/Cloudef/monsterwm-xcb/issues/8 . When closing pop-up dialogs you must use `alt + z` to bring the focusing back to normal.

Fill bugs only on hellxcb, when you are sure the bug doesn't occur on [monsterwm][].

[monsterwm issues][monsterwm-bug]

   [monsterwm-bug]: https://github.com/c00kiemon5ter/monsterwm/issues
   [monsterwm-xcb-bug]: https://github.com/Cloudef/monsterwm-xcb/issues

Count all windows in all tags/workspace
---

```c
static unsigned int workspaces[][2] = { {0, 0}, {0, 0}, {0, 0}, {0, 0}};
...

    // add them to some functions, seek them, it's not one only
    workspaces[0][1] = 0U;
    workspaces[1][1] = 0U;
    workspaces[2][1] = 0U;
    workspaces[3][1] = 0U;
...
    for (unsigned int x = 0; x < DESKTOPS; x++) {
        for (client *c=head; c; c=c->next) {
            if (c) continue;
            workspaces[x][1]++;
        }
        // use one of the below
        //change_desktop(&(Arg){.i = x});
        //select_desktop(x);
    }
}

...
// inside of `select_desktop'
fprintf(fp, "[tag: %d] [mode: %s] [windows: %u] [tag win: %u] [dev win: %u] [misc win: %u] [float win: %u]", i + 1, styles_arr[mode], numOfWindows, workspaces[0][1], workspaces[1][1], workspaces[2][1], workspaces[3][1]);
...

```

Thanks
------

[Cloudef](https://github.com/Cloudef) for [monsterwm-xcb](https://github.com/Cloudef/monsterwm-xcb),
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
  [monsterwm-xcb]: https://github.com/Cloudef/monsterwm-xcb
