#!/usr/bin/env bash

text=""
# static tooltip modules
[ "$1" = "arch" ] &&        tooltip=" archlinux        \n󰳽 <small>click-left: 󱓞 launcher</small>   \n󰳽 <small>click-middle: 󰌌 keybinds</small>         \n󰳽 <small>click-right: 󰗽 logout</small>    \n󰳽 <small>click-forward: 󰗈  rofi style select</small>"
[ "$1" = "clipboard" ] &&   tooltip="󰅇 clipboard history\n󰳽 <small>click-left:  copy</small>       \n󰳽 <small>click-middle: 󰛌 clear</small>            \n󰳽 <small>click-right:  delete</small>"
[ "$1" = "bar" ] &&         tooltip="󰟡 switch bar       \n󰳽 <small>click-left:  back</small>       \n󰳽 <small>click-middle:  dock</small>             \n󰳽 <small>click-right:  next</small>"
[ "$1" = "theme" ] &&       tooltip="󰟡 switch theme     \n󰳽 <small>click-left:  back</small>       \n󰳽 <small>click-middle: 󰟡 themes select</small>    \n󰳽 <small>click-right:  next</small>"
[ "$1" = "wallpaper" ] &&   tooltip="󰆊 switch wallpaper \n󰳽 <small>click-left:  back</small>       \n󰳽 <small>click-middle: 󰆊 wallpaper select</small> \n󰳽 <small>click-right:  next</small>"

# Print tooltip info (json)
echo "{\"text\":\"${text}\", \"tooltip\":\"${tooltip}\"}"