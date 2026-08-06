//@ pragma UseQApplication
//@ pragma NativeTextRendering
//@ pragma DropExpensiveFonts
//@ pragma IconTheme MoreWaita
//@ pragma Env QSG_RHI_BACKEND=vulkan

import QtQuick
import Quickshell

import qs.Components.Feedback
import qs.Modules.Drawers
import qs.Modules.Clipboard
import qs.Modules.DynamicIsland
import qs.Modules.Lock
import qs.Modules.Polkit
import qs.Modules.Wallpaper
import qs.Modules.Settings

ShellRoot {
    Lockscreen {}
    Wall {}
    Polkit {}
    Drawers {}
    DynamicIsland {}
    Settings {}
    Toast {}
    Clipboard {}
}
