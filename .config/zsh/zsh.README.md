# Setup

```md
Below is a tight opinionated checklist for dialling-in each CLI tool. I’ve kept every suggestion macOS-centric, zsh-friendly and compatible with Nerd-Font terminals. Use the ”Δ” lines to spot what to add/modify in your current files; the rest of your existing config looks solid.

Tool	Key wins	What to change (Δ = new/replace)	Why / refs
Aerospace	• Keep gaps/accordion defaults – they’re tuned already
• Add window-hint mode for fast nav	Δ [mode.main.binding]
hyper-; = 'focus window-hint'	Gives i3-style “jump by letter” without fighting your Caps-to-Hyper layer.
Atuin (you called it fatuin)	• Turn on workspace filter & “enter_accept” for instant repeat
• Sync hourly instead of every cmd	Δ workspaces=true
Δ enter_accept=true
Δ auto_sync=true & sync_frequency="60m"	Faster recall + less background traffic; workspace filter plays nicely with git‐root jumps.
bat	• Let theme follow terminal palette
• Pipe to delta for all git pagers	Δ export BAT_THEME="--theme=OneHalfDark"
Δ export DELTA_PAGER="bat --plain --paging=never"	Bat now auto-detects light/dark on 0.24+; feeding it to delta keeps colour parity. 
GitHub
GitHub
fzf	• One env var beats wrapper scripts
• Respect tmux pop-up	Δ export FZF_DEFAULT_OPTS='--height 40% --border --cycle --layout=reverse --marker="✓" --bind=ctrl-j:down,ctrl-k:up'	40 % pop-up in tmux, reverse list, consistent key-nav. 
GitHub
GitHub
git	• Delta already configured; just surface interactive-add
• Protect main + forbid lease-violations	Δ [interactive] diffFilter = delta --color-only (you have this) ✅
Δ [push] default = current, followTags=true ✅
Δ [push] --force-with-lease = false	Safe-by-default pushes, delta for git add -p. 
GitHub
glow	• Use rich-display in Yazi only (already done)
• Set pager to bat outside	Δ export GLOW_PAGER="bat --plain --language=markdown"	Uniform styling & obeys your BAT_THEME.
Homebrew	• Avoid auto update in CI, keep analytics off	Δ HOMEBREW_NO_AUTO_UPDATE=1 (CI only)
Δ HOMEBREW_NO_ANALYTICS=1	Faster scripted installs; privacy.
htop	• Show IO & pids in 1-screen layout	Open htop → F2 Configure:
Δ Add IO Read/Write after CPU columns
Δ Fields order PID USER CPU% MEM% IO_R IO_W TIME
Save → writes to ~/.config/htop/htoprc	Gives instant disk choke visibility; plays well with 120-char width. 
Gist
just	• Turn on summary & shell-override once	justfile top:
makefile<br>set summary := "on"<br>set shell := ["zsh", "-cu"]<br>	Colourised “running …” banner and zsh-built-ins everywhere.
yazi	• Huge config is fine; cull plugins that duplicate core (eg. smart-enter now builtin)
• Move heavy previewers to async	In plugin.prepend_previewers remove: smart-enter, rich-preview (Yazi 0.2+)
Δ Add preview.max_file_size = "5MB"	Snappier first load, no double-call to Lua.
starship	• Use right-prompt for clock/battery
• Reduce scan latency	Δ right_format = "$time$battery"
Δ scan_timeout = 10
Δ add_newline = false
Δ palette = 'tokyo-night' (already in Yazi)	Keeps left prompt static; 10 ms scan is enough on M-chip. 
Starship: Cross-Shell Prompt
Starship: Cross-Shell Prompt
```