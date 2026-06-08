# Solutions - The Shell

## Tier 1

**1.1** The canonical list of valid login shells lives in `/etc/shells`:
```bash
cat /etc/shells > ~/sandbox/shells.txt
```

**1.2** Switching is just typing the shell's name:
```bash
zsh           # prompt changes; you're in zsh
echo $0       # -> zsh
bash          # -> back to bash
```
This is *temporary* - a new tab/session still uses your default shell. That's
what Tier 2.1 fixes.

## Tier 2

**2.1** Change the **default** (login) shell, recorded in `/etc/passwd`:
```bash
sudo chsh -s "$(which zsh)" $USER
# verify:
getent passwd $USER | cut -d: -f7      # -> /usr/bin/zsh
```
On a normal machine you'd run `chsh -s /usr/bin/zsh` and enter your password;
here sudo is passwordless.

**2.2** `~/.zshrc` is zsh's per-user startup file. Anything in it runs for every
interactive zsh:
```bash
echo "alias ll='ls -lah'" >> ~/.zshrc
# prove it loads:
zsh -ic 'alias ll'                     # -> ll='ls -lah'
```

**2.3** Themes are set with the `ZSH_THEME` variable (oh-my-zsh reads it):
```bash
echo 'ZSH_THEME="agnoster"' >> ~/.zshrc
```

## Tier 3

**3.1** Append the team aliases in one go with a heredoc:
```bash
cat >> ~/.zshrc <<'EOF'
alias gs='git status'
alias k='kubectl get pods'
alias dc='docker compose'
EOF
```
Each must resolve: `zsh -ic 'alias gs'` → `gs='git status'`.

**3.2** Plugins are declared as an array oh-my-zsh loads:
```bash
echo 'plugins=(git)' >> ~/.zshrc
```

### Why this matters
This exact `.zshrc` is what engineers keep in a **dotfiles** repo. New laptop, new
server, new container - clone the dotfiles, and your whole environment (shell,
aliases, theme, plugins) is reproduced in seconds. You just built the seed of one.

### Answers to the self-check

1. **Terminal** = the app/window that takes input and shows output. **Shell** =
   the program (bash/zsh) that interprets and runs the commands.
2. `echo $SHELL` reports your *login* shell. Typing `zsh` starts a zsh *inside*
   your current session but doesn't change `$SHELL` - so they disagree until you
   `chsh` and start a new login session.
3. `~/.zshrc`.
4. `chsh` makes zsh the default for **every** new session automatically; typing
   `zsh` only changes the current one and you'd have to repeat it forever.
