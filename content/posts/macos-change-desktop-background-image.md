---
title: "MacOS Big Sur 11.3: Change desktop background image for all desktops"
date: 2021-05-01T14:08:40-04:00
draft: true
---

If you just want the solution, it's at the very bottom.

![multiple desktops](/multiple-desktops-with-images.png#l)

# Introduction

In MacOS Big Sur 11.3, it has now gotten harder to update the desktop background for all MacOS desktops in one operation. MacOS [provides](https://web.archive.org/web/20210219174518/https://support.apple.com/guide/mac-help/change-your-desktop-picture-mchlp3013/mac) a way to set the desktop background image for the current desktop, but it doesn't provide a way to set the background image for all desktops, there is no "Apply Image to All Desktops" button.

Previously you could work around this in a few ways (solutions from Stack Exchange):

- Set the image in the preference panel in one desktop, then drag the panel to the other desktops via Mission Control. [^1]
- Make the preference panel visible in all desktops, then switch through each desktop and click the same image. [^2]
- AppleScript to tell every desktop to change its image [^3]
- "Set the wallpaper for Desktop 1, delete all other desktops, then recreate them. New desktops created always share Desktop 1’s wallpaper." [^4]

All but the last solution do not work any more. I don't like deleting and recreating my desktops, so I decided to debug and fix the AppleScript solution.

# Debugging AppleScript

Here is the AppleScript solution from Stack Exchange Apple:

```
tell application "System Events"
    tell every desktop
        set picture to "path/to/picture.png"
    end tell
end tell
```

I saved it to a file test.scpt. When I ran this, it only set the current desktop image, and no others. After some fiddling I confirmed that the "tell every desktop" block only ran once. You can verify this by just adding a `log "here"` after `set picture`.

At this point I wondered, is it just the "tell every" iterator broken? Maybe I can iterate the desktops by index. So I tried another Stack Exchange answer using indexing[^5]:

```
tell application "System Events"
    set desktopCount to count of desktops
    repeat with desktopNumber from 1 to desktopCount
        tell desktop desktopNumber
            set picture to "/Library/Desktop Pictures/Beach.jpg"
        end tell
    end repeat
end tell
```

This also fails to iterate through the desktops. It only finds a single desktop, 1, regardless of which desktop you are on. I tried `tell desktop 2` but that always fails even though I have 3 desktops. So iteration and indexing through MacOS desktops in AppleScript is broken. Time for another approach!

# One-time Solution

After some research and trail-and-error, I came up with a solution.

## Create AppleScript

Create a file called change_desktop.scpt:

```
on run picture_file
    tell application "System Events"
        tell desktop 1
            set picture to picture_file
        end tell
        tell application "System Events"
            key code 124 using {control down}
        end tell
        delay 0.5
    end tell
end run
```

This script will change the current desktop, then switch to the next desktop (on the right). `on run picture_file` is how you pass in a command line argument. I'm taking in the picture name as an argument. `key code 124 using {control down}` is telling AppleScript to hold down the control key and the right arrow. Then after setting the desktop image I call `delay 0.5` because the `tell application` and `tell desktop` commands are actually nonblocking, and I need to wait to give them time to run else the image fails to set.

## Zsh run script

Go to the leftmost desktop, then run the following:

```
NEW_PIC="/System/Library/Desktop Pictures/Peak.heic" # Change to your desired picture
NUM_DESKTOPS=5 # Change to the number of desktops at the top in Mission Control
for i in {0..NUM_DESKTOPS}; do osascript change_desktop.scpt $NEW_PIC; done
```

If you want it to be a one-liner, you can omit variables and just call it like this:

```
for i in {0..5}; do osascript change_desktop.scpt "/System/Library/Desktop Pictures/Peak.heic"; done
```

Here I am iterating through the desktops in `zsh`, because AppleScript only ever gets the desktop the script was started in (desktop 1). desktop 1 isn't updated until you restart the AppleScript runtime, as far as I can tell.

# Download my utility

If you find yourself running this often, I made a utility script for this use.

Download it and install it from the GitHub [here](https://github.com/GabrielDougherty/desktop-image-switcher)

Then the same operation is as easy as:

```
desktop-image-switcher "/System/Library/Desktop Pictures/Peak.heic" 3
```

I used the same approach as before, the only difference being I inlined the AppleScript into the zsh script and wrote them to temp files. That way the script is self-contained.

[^1]: https://apple.stackexchange.com/a/333016/416280
[^2]: https://apple.stackexchange.com/a/415790/416280
[^3]: https://apple.stackexchange.com/a/270961/416280
[^4]: https://apple.stackexchange.com/a/71072/416280
[^5]: https://apple.stackexchange.com/a/141842/416280