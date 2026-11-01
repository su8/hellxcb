/* wmbench: time a window manager on an X display, without the cost of starting real clients.
 *   ready   - ms from start until the WM set _NET_SUPPORTED on the root window
 *   map     - ms until the WM mapped N windows that asked to be mapped at once
 *   settle  - ms until the last ConfigureNotify of those windows (layout done)
 *   destroy - ms from destroying the windows until a probe window is mapped again
 * usage: wmbench N  (start it right after the WM; prints "ready map settle destroy")
 * tests/bench.sh runs it against several builds */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <poll.h>
#include <xcb/xcb.h>

static double now_ms(void) {
    struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec * 1e3 + t.tv_nsec / 1e6;
}

static xcb_connection_t *c;
static xcb_screen_t *s;

static xcb_window_t mkwin(void) {
    xcb_window_t w = xcb_generate_id(c);
    uint32_t mask = XCB_EVENT_MASK_STRUCTURE_NOTIFY;
    xcb_create_window(c, XCB_COPY_FROM_PARENT, w, s->root, 0, 0, 200, 150, 0,
                      XCB_WINDOW_CLASS_INPUT_OUTPUT, s->root_visual, XCB_CW_EVENT_MASK, &mask);
    return w;
}

/* wait for events until pred is done or timeout; returns time of last matching event */
static int wait_events(int *mapped, int want, double *last_cfg, double quiet_ms, double timeout_ms) {
    double start = now_ms(), last = now_ms();
    for (;;) {
        xcb_generic_event_t *e;
        while ((e = xcb_poll_for_event(c))) {
            int t = e->response_type & ~0x80;
            if (t == XCB_MAP_NOTIFY) { ++*mapped; last = now_ms(); }
            if (t == XCB_CONFIGURE_NOTIFY && last_cfg) { *last_cfg = now_ms(); last = now_ms(); }
            free(e);
        }
        if (xcb_connection_has_error(c)) return -1;
        if (*mapped >= want && (quiet_ms <= 0 || now_ms() - last > quiet_ms)) return 0;
        if (now_ms() - start > timeout_ms) return -1;
        struct pollfd p = { xcb_get_file_descriptor(c), POLLIN, 0 };
        poll(&p, 1, 1);
    }
}

int main(int argc, char **argv) {
    int n = argc > 1 ? atoi(argv[1]) : 50;
    double t0 = now_ms();
    c = xcb_connect(NULL, NULL);
    if (xcb_connection_has_error(c)) { fputs("cannot open display\n", stderr); return 1; }
    s = xcb_setup_roots_iterator(xcb_get_setup(c)).data;

    xcb_intern_atom_reply_t *a = xcb_intern_atom_reply(c, xcb_intern_atom(c, 0, 14, "_NET_SUPPORTED"), NULL);
    for (;;) { /* poll for the WM */
        xcb_get_property_reply_t *r = xcb_get_property_reply(c,
            xcb_get_property(c, 0, s->root, a->atom, XCB_ATOM_ANY, 0, 1), NULL);
        int ok = r && r->type != XCB_NONE; free(r);
        if (ok) break;
        if (now_ms() - t0 > 10000) { fputs("no WM\n", stderr); return 1; }
        struct timespec ts = { 0, 1000000 }; nanosleep(&ts, NULL);
    }
    double ready = now_ms() - t0;
    free(a);

    xcb_window_t *w = calloc((size_t)n, sizeof *w);
    for (int i = 0; i < n; i++) w[i] = mkwin();
    xcb_flush(c);
    int mapped = 0; double last_cfg = 0, t1 = now_ms();
    for (int i = 0; i < n; i++) xcb_map_window(c, w[i]);
    xcb_flush(c);
    if (wait_events(&mapped, n, NULL, 0, 10000)) { fprintf(stderr, "map timeout: ready %.1f ms, %d of %d mapped\n", ready, mapped, n); return 1; }
    double map = now_ms() - t1;
    last_cfg = now_ms();
    wait_events(&mapped, n, &last_cfg, 300, 10000);
    double settle = last_cfg - t1;

    double t2 = now_ms();
    for (int i = 0; i < n; i++) xcb_destroy_window(c, w[i]);
    xcb_window_t probe = mkwin();
    xcb_map_window(c, probe);
    xcb_flush(c);
    mapped = 0;
    if (wait_events(&mapped, 1, NULL, 0, 10000)) { fputs("probe timeout\n", stderr); return 1; }
    double destroy = now_ms() - t2;

    printf("%.1f %.1f %.1f %.1f\n", ready, map, settle, destroy);
    xcb_disconnect(c);
    return 0;
}
