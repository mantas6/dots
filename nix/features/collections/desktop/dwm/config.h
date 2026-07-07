/* See LICENSE file for copyright and license details. */
/*
 * dwm configuration - migrated from the previous awesome wm setup.
 * Base functionality comes from official suckless patches; this file is the
 * customization layer on top of them.
 */

#include <X11/XF86keysym.h>

/* appearance */
static const unsigned int borderpx  = 1;        /* border pixel of windows */
static const unsigned int snap      = 32;       /* snap pixel */
static const int showbar            = 1;        /* 0 means no bar */
static const int topbar             = 1;        /* 0 means bottom bar */
static const char *fonts[]          = { "Ubuntu:bold:size=12", "AnonymicePro Nerd Font:size=12" };
static const char dmenufont[]       = "Ubuntu:bold:size=12";
static unsigned int baralpha        = 0xd9;     /* bar opacity ~0.85 (matches old awesome wibar) */
static unsigned int borderalpha     = OPAQUE;
static const char col_gray1[]       = "#222222";
static const char col_gray2[]       = "#444444";
static const char col_gray3[]       = "#bbbbbb";
static const char col_gray4[]       = "#eeeeee";
static const char col_cyan[]        = "#005577";
static const char *colors[][3]      = {
	/*               fg         bg         border   */
	[SchemeNorm] = { col_gray3, col_gray1, col_gray2 },
	[SchemeSel]  = { col_gray4, col_cyan,  col_cyan  },
};

/* tagging */
static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" };

static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	 */
	/* class            instance   title           tags mask   iscentered  isfloating  monitor */
	{ "Natron",         NULL,      NULL,           1 << 4,     0,          0,          -1 },
	{ "Gimp",           NULL,      NULL,           1 << 5,     0,          0,          -1 },
	{ "Conky",          NULL,      NULL,           0,          0,          1,          -1 },
	/* floating clients (matched by class / instance / title), placed centered */
	{ "Arandr",         NULL,      NULL,           0,          1,          1,          -1 },
	{ "Blueman-manager",NULL,      NULL,           0,          1,          1,          -1 },
	{ "Gpick",          NULL,      NULL,           0,          1,          1,          -1 },
	{ "Kruler",         NULL,      NULL,           0,          1,          1,          -1 },
	{ "MessageWin",     NULL,      NULL,           0,          1,          1,          -1 },
	{ "Tor Browser",    NULL,      NULL,           0,          1,          1,          -1 },
	{ "Wpa_gui",        NULL,      NULL,           0,          1,          1,          -1 },
	{ "veromix",        NULL,      NULL,           0,          1,          1,          -1 },
	{ "xtightvncviewer",NULL,      NULL,           0,          1,          1,          -1 },
	{ "scratchpad",     NULL,      NULL,           0,          1,          1,          -1 },
	{ "oneshot",        NULL,      NULL,           0,          1,          1,          -1 },
	{ NULL,             "DTA",     NULL,           0,          1,          1,          -1 },
	{ NULL,             "copyq",   NULL,           0,          1,          1,          -1 },
	{ NULL,             "pinentry",NULL,           0,          1,          1,          -1 },
	{ NULL,             NULL,      "Event Tester", 0,          1,          1,          -1 },
};

/* layout(s) */
static const float mfact     = 0.65; /* factor of master area size [0.05..0.95] */
static const int nmaster     = 1;    /* number of clients in master area */
static const int resizehints = 1;    /* 1 means respect size hints in tiled resizals */
static const int lockfullscreen = 1; /* 1 will force focus on the fullscreen window */

static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[]=",      tile },    /* first entry is default (awesome: tile) */
	{ "[M]",      monocle }, /* awesome: max */
	{ NULL,       NULL },    /* terminator required by cyclelayouts patch */
};

/* key definitions */
#define MODKEY Mod4Mask
/* awesome mapping: Mod+N view, Mod+Shift+N move client to tag, Mod+Ctrl+N toggle client on tag */
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggletag,      {.ui = 1 << TAG} },

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */
static char dmenumon[2] = "0"; /* referenced by spawn(); component of dmenucmd */
static const char *dmenucmd[] = { "dmenu_run", "-m", dmenumon, "-fn", dmenufont, "-nb", col_gray1, "-nf", col_gray3, "-sb", col_cyan, "-sf", col_gray4, NULL };
static const char *termcmd[]      = { "alacritty", "-e", "tmux", NULL };
static const char *browsercmd[]   = { "chromium", NULL };
static const char *incognitocmd[] = { "chromium", "--incognito", NULL };
static const char *roficmd[]      = { "rofi", "-show", "drun", NULL };
static const char *emojicmd[]     = { "rofi", "-show", "emoji", NULL };
static const char *passcmd[]      = { "rofi-pass", NULL };

/* custom helpers (customization on top of the patches) */
static void
shiftview(const Arg *arg)
{
	Arg a;
	unsigned int seltag = selmon->tagset[selmon->seltags];
	int n = LENGTH(tags);
	if (arg->i > 0)
		a.ui = ((seltag << arg->i) | (seltag >> (n - arg->i)));
	else
		a.ui = ((seltag >> (-arg->i)) | (seltag << (n + arg->i)));
	a.ui &= (1 << n) - 1;
	view(&a);
}

/* move every client from the focused monitor to the adjacent monitor and
 * follow focus there - replicates the old awesome "Mod+Ctrl+o" behaviour */
static void
movealltomon(const Arg *arg)
{
	Monitor *m;
	Client *c;
	if (!mons->next)
		return;
	if ((m = dirtomon(arg->i)) == selmon)
		return;
	while ((c = selmon->clients)) {
		detach(c);
		detachstack(c);
		c->mon = m;
		attach(c);
		attachstack(c);
	}
	unfocus(selmon->sel, 1);
	selmon = m;
	focus(NULL);
	arrange(NULL);
}

#include "movestack.c"

static const Key keys[] = {
	/* modifier                     key            function          argument */
	/* launchers / programs */
	{ MODKEY,                       XK_p,          spawn,            {.v = roficmd } },
	{ MODKEY,                       XK_m,          spawn,            {.v = emojicmd } },
	{ MODKEY,                       XK_n,          spawn,            {.v = passcmd } },
	{ MODKEY,                       XK_g,          spawn,            SHCMD("bm -r") },
	{ MODKEY,                       XK_u,          spawn,            SHCMD("maim -s | xclip -selection clipboard -t image/png -i") },
	{ MODKEY,                       XK_r,          spawn,            {.v = browsercmd } },
	{ MODKEY,                       XK_t,          spawn,            {.v = incognitocmd } },
	{ MODKEY,                       XK_e,          spawn,            {.v = termcmd } },
	{ MODKEY|ShiftMask,             XK_e,          spawn,            SHCMD("alacritty -o font.size=50 -e tmux") },
	{ MODKEY|ShiftMask,             XK_i,          spawn,            SHCMD("dwm-apps") },
	/* focus / navigation */
	{ MODKEY,                       XK_j,          focusstack,       {.i = +1 } },
	{ MODKEY,                       XK_k,          focusstack,       {.i = -1 } },
	{ MODKEY,                       XK_o,          focusmon,         {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_o,          tagmon,           {.i = +1 } },
	{ MODKEY|ControlMask,           XK_o,          movealltomon,     {.i = +1 } },
	/* layout manipulation */
	{ MODKEY|ShiftMask,             XK_j,          movestack,        {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_k,          movestack,        {.i = -1 } },
	{ MODKEY,                       XK_l,          setmfact,         {.f = +0.05} },
	{ MODKEY,                       XK_h,          setmfact,         {.f = -0.05} },
	{ MODKEY|ShiftMask,             XK_h,          incnmaster,       {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_l,          incnmaster,       {.i = -1 } },
	{ MODKEY,                       XK_space,      cyclelayout,      {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_space,      cyclelayout,      {.i = -1 } },
	{ MODKEY,                       XK_Return,     zoom,             {0} },
	/* client management */
	{ MODKEY,                       XK_w,          killclient,       {0} },
	{ MODKEY|ControlMask,           XK_space,      togglefloating,   {0} },
	{ MODKEY|ShiftMask,             XK_t,          togglealwaysontop,{0} },
	/* tags */
	{ MODKEY,                       XK_Escape,     view,             {0} },
	{ MODKEY,                       XK_a,          view,             {0} },
	TAGKEYS(                        XK_1,                            0)
	TAGKEYS(                        XK_2,                            1)
	TAGKEYS(                        XK_3,                            2)
	TAGKEYS(                        XK_4,                            3)
	TAGKEYS(                        XK_5,                            4)
	TAGKEYS(                        XK_6,                            5)
	TAGKEYS(                        XK_7,                            6)
	TAGKEYS(                        XK_8,                            7)
	TAGKEYS(                        XK_9,                            8)
	/* keyboard layout / display */
	{ MODKEY,                       XK_b,          spawn,            SHCMD("setxkbmap us") },
	{ MODKEY|ShiftMask,             XK_b,          spawn,            SHCMD("setxkbmap lt") },
	{ MODKEY|ShiftMask,             XK_x,          spawn,            SHCMD("xset dpms force off") },
	/* session / power */
	{ MODKEY|ShiftMask,             XK_r,          quit,             {1} }, /* restart in place */
	{ MODKEY|ShiftMask,             XK_q,          quit,             {0} },
	{ MODKEY,                       XK_Home,       spawn,            SHCMD("systemctl suspend") },
	{ MODKEY,                       XK_Delete,     spawn,            SHCMD("systemctl hibernate") },
	{ MODKEY|ShiftMask,             XK_Delete,     spawn,            SHCMD("systemctl reboot") },
	{ MODKEY|ControlMask,           XK_Delete,     spawn,            SHCMD("systemctl poweroff") },
	/* media / hardware keys */
	{ 0,                            XF86XK_AudioLowerVolume, spawn,  SHCMD("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-") },
	{ 0,                            XF86XK_AudioRaiseVolume, spawn,  SHCMD("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+") },
	{ 0,                            XF86XK_AudioMute,        spawn,  SHCMD("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle") },
	{ 0,                            XF86XK_AudioMicMute,     spawn,  SHCMD("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle") },
	{ 0,                            XF86XK_AudioPlay,        spawn,  SHCMD("playerctl play-pause") },
	{ 0,                            XF86XK_AudioNext,        spawn,  SHCMD("playerctl next") },
	{ 0,                            XF86XK_AudioPrev,        spawn,  SHCMD("playerctl previous") },
	{ 0,                            XF86XK_MonBrightnessUp,  spawn,  SHCMD("brightnessctl set 5%+") },
	{ 0,                            XF86XK_MonBrightnessDown,spawn,  SHCMD("brightnessctl set 5%-") },
};

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static const Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkLtSymbol,          0,              Button1,        cyclelayout,    {.i = +1 } },
	{ ClkLtSymbol,          0,              Button3,        cyclelayout,    {.i = -1 } },
	{ ClkLtSymbol,          0,              Button4,        cyclelayout,    {.i = +1 } },
	{ ClkLtSymbol,          0,              Button5,        cyclelayout,    {.i = -1 } },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
	{ ClkRootWin,           0,              Button4,        shiftview,      {.i = +1 } },
	{ ClkRootWin,           0,              Button5,        shiftview,      {.i = -1 } },
};

/* signal definitions */
/* trigger with `xsetroot -name "fsignal:<signum>"` - used by the dwm-apps script */
static Signal signals[] = {
	/* signum       function        argument */
	{ 1,            view,           {.ui = 1 << 0} },
	{ 2,            view,           {.ui = 1 << 1} },
	{ 3,            view,           {.ui = 1 << 2} },
	{ 4,            view,           {.ui = 1 << 3} },
	{ 5,            view,           {.ui = 1 << 4} },
	{ 6,            view,           {.ui = 1 << 5} },
	{ 7,            view,           {.ui = 1 << 6} },
	{ 8,            view,           {.ui = 1 << 7} },
	{ 9,            view,           {.ui = 1 << 8} },
};
