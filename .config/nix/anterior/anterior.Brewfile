# Taps
tap "homebrew/bundle"
tap "homebrew/cask"
tap "homebrew/core"
tap "oven-sh/bun"

# Web Browsers
# Because nobody really wants to use Safari. Let's install another browser that floats your boat.
cask "google-chrome"

# Terminal Applications
# I prefer using warp as my terminal. You can use any terminal application you prefer.
# Would be nice to be on z-shell (zsh) though.
# NB: I like Ghostty (https://ghostty.org/), YMMV.
cask "warp"

# Code Editors
# Or another code editor that you like.
cask "visual-studio-code"

# Node.js Development
# Install NVM for managing Node versions
brew "nvm"
# recommend v22.14.0, to avoid nasty "type strip" errors
# After installation, remember to run:
# nvm install v22.14.0
# nvm use 22.14.0
# nvm alias default 22.14.0

# Bun - JavaScript runtime and toolkit
# Install specific version to ensure compatibility
brew "bun@1.1.21"

# Python Dependencies
# These DLLs are required by the `magic` and `weasyprint` python libraries 
# but not automatically picked up by `uv sync`
brew "libmagic"
brew "weasyprint"
# To develop locally with python you might have to add this to .zshrc to avoid weasyprint errors:
# export DYLD_FALLBACK_LIBRARY_PATH=/opt/homebrew/lib:$DYLD_FALLBACK_LIBRARY_PATH

# Go Programming Language
brew "go"

# Docker/Container Management
# Orbstack is an application that lets you manage your docker containers.
# You can also use Docker for macOS or equivalent application.
# The good thing about orbstack is that it gives you https vanity URLs 
# for each of your services out of the box.
# ⚠️ CRITICAL: Please turn on "Enable HTTPS for container domains" after installation
# and restart Orbstack for the setting to take effect
cask "orbstack"

# Networking Tools
# Tailscale is a secure VPN that we use to allow your machine join Anterior's private network.
# You will be able to access our deployed services once you are setup on tailscale.
cask "tailscale"
brew "tailscale" # CLI version

# Security & Password Management
# 1Password is our password manager of choice. Before you frown at it, know that
# not only do developers use it to manage their passwords while browsing the web,
# but a lot of our application/system secrets are also stored there in. So you will kinda need it.
# Enable the CLI integration: Go to Settings > "Developer" > CLI > Enable Integration
cask "1password"

# Development Environment Tools
# direnv is required to easily export env vars when you switch between directories
# Add this line to your ~/.zshrc: eval "$(direnv hook zsh)"
# Add this line to your ~/.bashrc: eval "$(direnv hook bash)"
brew "direnv"

# We use sops to manage keys in our AWS deployments
brew "sops"

# Collaboration & API Tools
cask "slack"
# Once installed, use shared credentials to login
cask "postman"

# Productivity Tools (Optional but Recommended)
# Raycast is a Spotlight replacement. It is significantly better and has so much 
# out-of-the-box features. You may have heard of Alfred, I had to pay for some
# features in Alfred that is free in Raycast (and better too!).
# I recommend even replacing the default `Cmd + Space` with Raycast instead of Spotlight.
cask "raycast"

# Rectangle is a window tiling tool. It helps you reorganize your windows
# and tile them using handy keyboard shortcuts.
cask "rectangle"

# Database Tools
# Since we interact a lot with DynamoDB, we will need a NoSQL viewer.
# I prefer using NoSQL workbench from AWS.
# NB: I like DataGrip (https://www.jetbrains.com/datagrip/)
cask "nosql-workbench"

# .NET Development
# If you plan to work on client side C# sdks, install these as well.
# By default dotnet will be installed with version 9. However, it is likely that
# our clients will be using lower versions (cuz, yeah, they're slow on the updates).
# We are going to install both .NET version 6 and 8.
cask "dotnet"
brew "dotnet@6"
brew "dotnet@8"
# After installation, you might want to run:
# brew unlink dotnet
# brew link --overwrite --force dotnet@6
# To have your dotnet CLI point to .NET v6
