---
title: "Spotify Flatpak Stuck in Fullscreen"
date: 2022-05-02T12:53:27-04:00
draft: false
---

# Problem Explanation

Today I updated my Spotify client via Pop!_Shop in Pop!_OS. After re-launching the client, it was stuck in fullscreen. All of the keyboard shortcuts I tried to get it into windowed mode failed, but I could Alt-Tab to a different window. My Spotify was installed with Flatpak, but that's basically transparent to the user when installing via Pop!_Shop.

# Troubleshooting

## Downgrading Spotify

At first I thought that there was a regression introduced by Spotify. So I went about downgrading the application. Following the [flatpak docs](https://docs.flatpak.org/en/latest/tips-and-tricks.html?highlight=downgrade#downgrading) at time of writing, it instructed me to look through the commit log with this command:

```
flatpak remote-info --log flathub <fully qualified package name>
```

So I ran it like this:

```
flatpak remote-info --log flathub com.spotify.Client | less
```

I piped into `less` because the command spat out a lot of output and I only wanted to see the beginning, the most recent commits.

I picked a command hash from a week ago, which was a known good version I had been using. I went about downgrading to that version. According to the documentation at time of writing, I downgrade an application by running:

```
sudo flatpak update \
  --commit=<commit hash> \
  <fully qualified application name>
```

So I ran that command:

```
sudo flatpak update \
--commit=4971174bdf1e863ebbc18651efd330eed5de28f917342e518fc116c88e7d723c
\
com.spotify.Client
```

Which returned:

```
Looking for updates
error: com.spotify.Client not installed
```

This was confusing because I already knew by checking `flatpak list` that Spotify was in fact installed. I Googled around and found this [issue](https://github.com/flatpak/flatpak-docs/issues/220) from 2020 which described my problem exactly. It turns out that I only need to run `flatpak update` as `sudo` if I had installed the application globally.

So I ran the command without `sudo`:

```
flatpak update \
--commit=4971174bdf1e863ebbc18651efd330eed5de28f917342e518fc116c88e7d723c
\
com.spotify.Client
```

...and that successfully downgraded Spotify to the "known good" version. Unfortunately that did not fix the original problem. It was still stuck in full screen.

## Clue from Spotify forums

I tried a different tack, which was just Googling for posts about my problem. I found such a post from 2012 (!!!) on the Spotify community forums: [Stuck in Full Screen](https://community.spotify.com/t5/Desktop-Linux/Stuck-in-Full-Screen/td-p/106749)

There were several solutions proposed in the thread, [the most promising one](https://community.spotify.com/t5/Desktop-Linux/Stuck-in-Full-Screen/m-p/2835461/highlight/true#M858) was to edit the preferences at `$HOME/.config/spotify/prefs` and just comment out every "app.*" property.

That `prefs` file did exist on my machine, but it was from an old Spotify installation. I knew from prior experience that Flatpaks are sandboxed, so maybe the configuration is sandboxed too. A [Stack Exchange post](https://unix.stackexchange.com/questions/460187/how-to-make-flatpak-applications-use-standard-locations-for-user-data-files) confirmed for me that flatpak application configuration is stored under `$HOME/.var/app`.

# Solution

To fix the problem, I edited `$HOME/.var/app/com.spotify.Client/config/spotify/prefs` and commented out all the lines related to "window":

```
# app.window.position.saved=true
# app.autostart-mode=""
# app.window.position.y=127
# app.window.position.x=60
autologin.canonical_username= "xxxxxxxxxxxxx"
storage.last-location="/home/gabriel/.var/app/com.spotify.Client/cache/spotify/Storage"
# app.window.position.width=1800
core.clock_delta=0
app.last-launched-version="1.1.84.716.gc5f8b819"
app.autostart-configured=true
```

Then I restarted Spotify. The window showed up like normal. Problem solved.

# Lessons and a PR

I have some takeaways from this experience:

1. This bug was difficult to solve and would probably stop a non-technical user in their tracks. Unless you are familiar with Alt-Tab or Super-Q keyboard shortcuts the only way to get out of Spotify would be to restart your computer. And if Spotify was set to start on login then your operating system could be basically soft bricked until you could get help from someone else, since Spotify would take up the whole screen.

2. The `flatpak update` use model is confusing. Flatpaks don't typically need to be installed with sudo. Combined with using the Pop!_Shop to install, there is no obvious way for an average user to know whether a flatpak package has been installed globally or per-user. Since normal `apt` packages are installed globally via Pop!_Shop. And flatpaks are also installed via the Pop!_Shop.

3. Flatpak doesn't conform to the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html) by default and this is A Bad Thing. The majority of Linux applications conform to the spec and write their configuration to `$HOME/.config`. Even the same version of applications, that aren't packaged by Flatpak, conform to the specification. It is super confusing to me that I need to remember the special way that my application was installed just to configure it.

4. Spotify support for Linux is subpar. I can hardly imagine this bug occurring on macOS or Windows.

5. Downgrading a flatpak package requires issuing shell commands. There is no way to do this in a GUI. Meanwhile the [Debian Synaptic Package Manager](https://ubuntuhandbook.org/index.php/2017/06/downgrade-a-package-in-ubuntu-via-synaptic/) and [OpenSUSE YaST](https://forums.opensuse.org/showthread.php/475293-How-do-I-downgrade-a-package) offer downgrading functionality. It would be good to have a GUI way to do this.

To partially solve #2 I submitted a [PR](https://github.com/flatpak/flatpak-docs/pull/328) to update the documentation to include downgrading a per-user installation. But it's still confusing.
