# just is a command runner, Justfile is very similar to Makefile, but simpler.

# settings
set hostname := `uname -n`
set shell := ["zsh", "-cu"]

# 


# ========================================================================
# System & Environment Management
# ========================================================================

# List all the just commands
default:
  @just --list


# --- Default & Utility Recipes ---
[group('global')]
choose:
  @just --choose

[group('global')]
fmt:
  @echo "Formatting {{ justfile() }}..."
  @just --unstable --fmt

# Display system information
system-info:
  @echo "CPU architecture: {{ arch() }}"
  @echo "Operating system type: {{ os_family() }}"
  @echo "Operating system: {{ os() }}"
  @echo "Home directory: {{ home_directory() }}"

# Update dotfiles repo
[working-directory("~/dotfiles")]
dots-update:
  @git pull

dots-edit:
  $EDITOR ~/dotfiles/config/just/.user.justfile

# Global justfile for common tasks
# Usage: j <recipe>

# Update all package managers and tools
update:
    @echo "Updating system packages and tools..."
    brew update && brew upgrade && brew cleanup
    command -v volta >/dev/null && volta list || true
    command -v nix >/dev/null && nix-env -u || true
    command -v rustup >/dev/null && rustup update || true

# Clean up system disk space
cleanup: cleanup-brew cleanup-nix cleanup-node
    @echo "System cleanup completed"

# Clean Homebrew cache and remove old versions
cleanup-brew:
    brew cleanup --prune=all
    brew autoremove

# Clean Nix store
cleanup-nix:
    command -v nix-collect-garbage >/dev/null && nix-collect-garbage -d || true

# Clean npm/node caches
cleanup-node:
    command -v npm >/dev/null && npm cache clean --force || true
    rm -rf ~/.npm/_cacache 2>/dev/null || true

# Show system information
info:
    @echo "System Information"
    @echo "=================="
    @echo "OS: $(uname -s) $(uname -r)"
    @echo "Architecture: $(uname -m)"
    command -v sw_vers >/dev/null && sw_vers || true
    @echo "\nBrew:"
    command -v brew >/dev/null && brew config | grep HOMEBREW || true
    @echo "\nShell: $SHELL ($(basename $SHELL))"
    @echo "\nNode: $(command -v node >/dev/null && node --version || echo 'not installed')"
    @echo "npm: $(command -v npm >/dev/null && npm --version || echo 'not installed')"
    @echo "Nix: $(command -v nix >/dev/null && nix --version || echo 'not installed')"
    @echo "Python: $(command -v python3 >/dev/null && python3 --version || echo 'not installed')"
    @echo "Ruby: $(command -v ruby >/dev/null && ruby --version || echo 'not installed')"

# # ========================================================================
# # dotfiles Management
# # ========================================================================

# # Update dotfiles repo
# dotfiles-update:
#     @cd ~/dotfiles && git pull

# # Edit global justfile
# edit-just:
#     $EDITOR ~/dotfiles/config/just/justfile

# # Initialize or update Nix tools
# nix-setup:
#     @echo "Setting up Nix environment..."
#     mkdir -p ~/.config/nix
#     cp ~/dotfiles/config/nix/shell-compat.sh ~/.config/nix/ 2>/dev/null || true
#     chmod +x ~/.config/nix/shell-compat.sh 2>/dev/null || true
#     @echo "Nix environment setup complete"

# # Fix zsh configuration
# zsh-fix:
#     @echo "Fixing ZSH configuration..."
#     mkdir -p ~/.config/zsh
#     cp ~/dotfiles/config/zsh/.zshrc ~/.config/zsh/ 2>/dev/null || true
#     @echo "ZSH configuration fixed. Please restart your terminal."

# # Fix direnv integration with nix
# direnv-fix:
#     @echo "Fixing direnv integration..."
#     mkdir -p ~/.config/direnv
#     cp ~/dotfiles/config/direnv/direnvrc ~/.config/direnv/ 2>/dev/null || true
#     cp ~/dotfiles/config/direnv/nix.direnvrc ~/.config/direnv/ 2>/dev/null || true
#     cp ~/dotfiles/config/direnv/envrc.template ~/.config/direnv/ 2>/dev/null || true
#     @echo "Direnv configuration fixed"

# # Fix platform Nix integration
# nix-fix PATH="~/src/platform":
#     @echo "Fixing Nix integration for {{PATH}}..."
#     ~/dotfiles/scripts/fix-platform-nix.sh {{PATH}} 2>/dev/null || echo "Fix script not found or failed"

# # ========================================================================
# # Git Helpers
# # ========================================================================

# # Setup conventional commits for current repo
# git-setup-conv:
#     echo "Setting up conventional commits for this repository..."
#     npm init -y >/dev/null 2>&1 || true
#     npm install --save-dev @commitlint/cli @commitlint/config-conventional commitizen cz-git husky
#     npx husky init
#     npx husky add .husky/commit-msg 'npx --no-install commitlint --edit "$1"'
#     echo 'module.exports = { extends: ["@commitlint/config-conventional"] };' > commitlint.config.js
#     echo '{ "path": "cz-git" }' > .czrc
#     echo "Conventional commits setup complete."
#     echo "Use 'git cz' or 'npx cz' to create commits."

# # Create a new branch for a feature
# git-feature NAME:
#     git checkout -b "feature/{{NAME}}"
#     git push -u origin "feature/{{NAME}}"

# # Create a new branch for a bugfix
# git-bugfix NAME:
#     git checkout -b "bugfix/{{NAME}}"
#     git push -u origin "bugfix/{{NAME}}"

# # Show recent branches
# git-recent:
#     git for-each-ref --sort=-committerdate --count=10 --format='%(refname:short)' refs/heads/

# # ========================================================================
# # Development Helpers
# # ========================================================================

# # Generate a .envrc file for current directory
# gen-envrc:
#     @echo "Generating .envrc file for current directory..."
#     @if [ -f ~/dotfiles/config/direnv/envrc.template ]; then \
#         cp ~/dotfiles/config/direnv/envrc.template ./.envrc; \
#     else \
#         echo 'use flake' > ./.envrc; \
#         echo 'PATH_add scripts' >> ./.envrc; \
#         echo 'PATH_add node_modules/.bin' >> ./.envrc; \
#     fi
#     @echo ".envrc file created. Run 'direnv allow' to enable it."

# # Create a new project from template
# new-project-node NAME:
#     mkdir -p {{NAME}}
#     cd {{NAME}} && npm init -y
#     cd {{NAME}} && echo 'node_modules' > .gitignore
#     cd {{NAME}} && echo '.env' >> .gitignore
#     cd {{NAME}} && echo "# {{NAME}}" > README.md
#     cd {{NAME}} && git init
#     cd {{NAME}} && git add .
#     cd {{NAME}} && git commit -m "Initial commit"
#     @echo "Node project created at {{NAME}}"

# # Create a new Python project
# new-project-python NAME:
#     mkdir -p {{NAME}}
#     cd {{NAME}} && python3 -m venv .venv
#     cd {{NAME}} && echo '.venv' > .gitignore
#     cd {{NAME}} && echo '__pycache__' >> .gitignore
#     cd {{NAME}} && echo '*.pyc' >> .gitignore
#     cd {{NAME}} && echo "# {{NAME}}" > README.md
#     cd {{NAME}} && git init
#     cd {{NAME}} && git add .
#     cd {{NAME}} && git commit -m "Initial commit"
#     @echo "Python project created at {{NAME}}"

# # ========================================================================
# # Utility Commands
# # ========================================================================

# # Copy current directory path to clipboard
# copy-path:
#     pwd | tr -d '\n' | pbcopy
#     @echo "Current directory path copied to clipboard"

# # Generate a random password
# password LENGTH="16":
#     LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*()-_=+[]{}|;:,.<>?' < /dev/urandom | head -c {{LENGTH}}; echo

# # Start a simple HTTP server in current directory
# serve PORT="8000":
#     @echo "Starting HTTP server on port {{PORT}}..."
#     python3 -m http.server {{PORT}}

# # Find big files in current directory
# find-big:
#     find . -type f -size +10M -exec ls -lh {} \; | sort -k5hr | head -n 10


# # Fix Nix integration
############################################################################
#
#  Darwin related commands
#
############################################################################

# #  TODO Feel free to remove this target if you don't need a proxy to speed up the build process
# [group('desktop')]
# darwin-set-proxy:
#   sudo python3 scripts/darwin_set_proxy.py
#
# [group('desktop')]
# darwin: darwin-set-proxy
#   nix build .#darwinConfigurations.{{hostname}}.system \
#     --extra-experimental-features 'nix-command flakes'
#
#   ./result/sw/bin/darwin-rebuild switch --flake .#{{hostname}}
#
# [group('desktop')]
# darwin-debug: darwin-set-proxy
#   nix build .#darwinConfigurations.{{hostname}}.system --show-trace --verbose \
#     --extra-experimental-features 'nix-command flakes'
#
#   ./result/sw/bin/darwin-rebuild switch --flake .#{{hostname}} --show-trace --verbose

# ############################################################################
# #
# #  nix related commands
# #
# ############################################################################
#
# # Update all the flake inputs
# [group('nix')]
# up:
#   nix flake update
#
# # Update specific input
# # Usage: just upp nixpkgs
# [group('nix')]
# upp input:
#   nix flake update {{input}}
#
# # List all generations of the system profile
# [group('nix')]
# history:
#   nix profile history --profile /nix/var/nix/profiles/system
#
# # Open a nix shell with the flake
# [group('nix')]
# repl:
#   nix repl -f flake:nixpkgs
#
# # remove all generations older than 7 days
# # on darwin, you may need to switch to root user to run this command
# [group('nix')]
# clean:
#   sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d
#
# # Garbage collect all unused nix store entries
# [group('nix')]
# gc:
#   # garbage collect all unused nix store entries(system-wide)
#   sudo nix-collect-garbage --delete-older-than 7d
#   # garbage collect all unused nix store entries(for the user - home-manager)
#   # https://github.com/NixOS/nix/issues/8508
#   nix-collect-garbage --delete-older-than 7d
#
# [group('nix')]
# fmt:
#   # format the nix files in this repo
#   nix fmt
#
# # Show all the auto gc roots in the nix store
# [group('nix')]
# gcroot:
#   ls -al /nix/var/nix/gcroots/auto/

#######################################

# set unstable := true
# set shell := ["/bin/zsh", "-cu"]

# Common Project Paths
platform_dir := "~/src/platform"
flonotes_fe_dir := "~/src/flonotes-fe"
vibes_dir := "~/src/vibes"
gpt_repo_dir := "~/src/gpt-repository-loader"



# # --- Flonotes / Ant Project Recipes ---
# [group('platform')]
# [working-directory: '~/src/platform']
# noggin-up:
#     @echo "Building and starting Noggin service..."
#     ant build noggin && ant up noggin

# [group('platform')]
# [working-directory: '~/src/platform']
# platform-up:
#     @echo "Building and starting Platform services..."
#     ant build api user s3 prefect-worker prefect-agent prefect-server data-seeder && \
#     ant up api user s3 prefect-worker prefect-agent prefect-server data-seeder

# [group('platform')]
# [working-directory: '~/src/platform']
# platform-otp:
#     @echo "Fetching OTP code from container named 'api'..."
#     @_container_id=$$(docker ps -qf name=api); \
#     if [ -n "$$_container_id" ]; then \
#         docker logs "$$_container_id" 2>&1 | rg "sent an otp code" | tail -n 1; \
#     else \
#         echo "Error: Container 'api' not found."; exit 1; \
#     fi

# [group('platform')]
# [working-directory: '~/src/platform']
# platform-noggin-test:
#     @echo "Running Noggin e2e tests..."
#     docker compose \
#         --profile test-e2e \
#         --file compose.integration.yaml \
#         run \
#         --build \
#         --rm \
#         --env $ANTHROPIC_API_KEY \
#         noggin-test-e2e

# [group('flonotes')]
# [working-directory: '~/src/flonotes-fe']
# flonotes-fe-build:
#     @echo "Deploying Flonotes Frontend locally..."
#     make deploy-local

# # --- Nix Environment Management ---
# [group('nix')]
# [no-cd]
# nix-update-all:
#     @echo "Updating all Nix flake inputs in $(pwd)..."
#     nix flake update

# [group('nix')]
# [no-cd]
# nix-update-input input:
#     @echo "Updating Nix flake input '{{input}}' in $(pwd)..."
#     nix flake update --update-input {{input}}

# [group('nix')]
# nix-history:
#     @echo "Nix system profile history:"
#     nix profile history --profile /nix/var/nix/profiles/system

# [group('nix')]
# [no-cd]
# nix-repl:
#     @echo "Opening Nix REPL for flake in $(pwd)..."
#     nix repl '.#nixpkgs'

# [group('nix')]
# nix-clean-profile:
#     @echo "Cleaning Nix system profile generations older than 7 days..."
#     sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 7d

# [group('nix')]
# nix-gc:
#     @echo "Running Nix garbage collection (older than 7 days)..."
#     @echo "System GC (requires sudo)..."
#     sudo nix-collect-garbage --delete-older-than 7d
#     @echo "User GC..."
#     nix-collect-garbage --delete-older-than 7d

# [group('nix')]
# [no-cd]
# nix-fmt:
#     @echo "Formatting Nix files in $(pwd)..."
#     nix fmt .

# [group('nix')]
# nix-gcroot:
#     @echo "Nix auto GC roots:"
#     ls -al /nix/var/nix/gcroots/auto/

# # --- Darwin System Management ---
# [private]
# _darwin-set-proxy:
#     @echo "Setting Darwin network proxy (requires sudo)..."
#     sudo python3 {{ justfile_directory() }}/scripts/darwin_set_proxy.py

# [group('darwin')]
# darwin-build: _darwin-set-proxy
#     @echo "Building Darwin configuration for '{{hostname}}'..."
#     nix build ".#darwinConfigurations.{{hostname}}.system" \
#         --extra-experimental-features 'nix-command flakes'
#     @echo "Switching to new Darwin configuration..."
#     ./result/sw/bin/darwin-rebuild switch --flake ".#{{hostname}}"

# [group('darwin')]
# darwin-build-debug: _darwin-set-proxy
#     @echo "Building Darwin configuration for '{{hostname}}' (DEBUG)..."
#     nix build ".#darwinConfigurations.{{hostname}}.system" --show-trace --verbose \
#         --extra-experimental-features 'nix-command flakes'
#     @echo "Switching to new Darwin configuration (DEBUG)..."
#     ./result/sw/bin/darwin-rebuild switch --flake ".#{{hostname}}" --show-trace --verbose

# # --- Utility Functions ---
# [group('utility')]
# system-info:
#     @echo "CPU architecture: {{ arch() }}"
#     @echo "Operating system type: {{ os_family() }}"
#     @echo "Operating system: {{ os() }}"
#     @echo "Home directory: {{ home_directory() }}"
#     @echo "Number of CPUs: {{ num_cpus() }}"

# # Example of parallel jobs recipe (commented out)
# # [group('utility')]
# # parallel-demo:
# #   #!/usr/bin/env -S parallel --shebang --ungroup --jobs {{ num_cpus() }}
# #   echo task 1 start; sleep 3; echo task 1 done
# #   echo task 2 start; sleep 3; echo task 2 done
# #   echo task 3 start; sleep 3; echo task 3 done
# #   echo task 4 start; sleep 3; echo task 4 done

# # --- Homebrew Management ---
# [group('brew')]
# [working-directory: '~/dotfiles']
# brew-bundle:
#     @echo "Installing packages from Brewfile..."
#     brew bundle --file=Brewfile

# # ==============================================================================
# # End of User Justfile
# # ==============================================================================
# # Remember to update the `hostname` variable!
# # Consider creating project-local Justfiles for project-specific recipes.
# # ==============================================================================

# ###################
# # Optimized Justfile for Full-Stack TypeScript Development with HMR
# # Implements Hot Module Replacement for React frontend (Vite) and HonoJS backend
#
# # Default recipe to run when just is called without arguments
# default:
#     @just --list
#
# # Set default shell to bash with error handling
# set shell := ["bash", "-c"]
#
# # Environment variables with defaults
# export NODE_ENV := env_var_or_default("NODE_ENV", "development")
# export FRONTEND_PORT := env_var_or_default("FRONTEND_PORT", "3000")
# export BACKEND_PORT := env_var_or_default("BACKEND_PORT", "3001")
# export DEBUG_PORT := env_var_or_default("DEBUG_PORT", "9229")
# export USE_POLLING := env_var_or_default("USE_POLLING", "false")
#
# # Paths
# frontend_dir := "./frontend"
# backend_dir := "./backend"
# log_dir := "./logs"
#
# # Create necessary directories
# _ensure-dirs:
#     mkdir -p {{log_dir}}
#     mkdir -p {{frontend_dir}}/src
#     mkdir -p {{backend_dir}}/src
#
# # Install dependencies for both frontend and backend
# install: _ensure-dirs
#     cd {{frontend_dir}} && npm install
#     cd {{backend_dir}} && npm install
#     npm install --no-save concurrently
#
# # Start frontend development server with HMR enabled
# frontend: _ensure-dirs
#     #!/usr/bin/env bash
#     echo "Starting frontend development server with HMR on port ${FRONTEND_PORT}..."
#     cd {{frontend_dir}} && npm run dev 2>&1 | tee -a {{log_dir}}/frontend.log
#
# # Start backend development server with hot reload
# backend: _ensure-dirs
#     #!/usr/bin/env bash
#     echo "Starting backend development server with hot reload on port ${BACKEND_PORT}..."
#     cd {{backend_dir}} && npm run dev 2>&1 | tee -a {{log_dir}}/backend.log
#
# # Start both frontend and backend in development mode
# dev: _ensure-dirs
#     #!/usr/bin/env bash
#     echo "Starting full-stack development environment..."
#     npx concurrently -n "FRONTEND,BACKEND" -c "green,blue" \
#       "just frontend" \
#       "just backend"
#
# # Build frontend and backend for production
# build: _ensure-dirs
#     cd {{frontend_dir}} && npm run build
#     cd {{backend_dir}} && npm run build
#
# # Start production servers
# start: _ensure-dirs
#     cd {{backend_dir}} && npm run start
#
# # Clean build artifacts and logs
# clean:
#     rm -rf {{frontend_dir}}/dist
#     rm -rf {{backend_dir}}/dist
#     rm -rf {{log_dir}}/*.log
#
# # Setup frontend HMR configuration
# setup-frontend-hmr: _ensure-dirs
#     #!/usr/bin/env bash
#     echo "Setting up frontend HMR configuration..."
#     # Create or update vite.config.ts with HMR settings
#     cat > {{frontend_dir}}/vite.config.ts << 'EOF'
# import { defineConfig } from 'vite';
# import react from '@vitejs/plugin-react';
# import path from 'path';
#
# export default defineConfig({
#   plugins: [
#     react({
#       // Fast Refresh options
#       fastRefresh: true,
#     }),
#   ],
#   server: {
#     port: Number(process.env.FRONTEND_PORT || 3000),
#     host: true, // Needed for Docker
#     hmr: {
#       // Enable HMR
#       overlay: true,
#     },
#     watch: {
#       // Use polling in Docker environments where inotify doesn't work properly
#       usePolling: process.env.USE_POLLING === 'true',
#       interval: 1000,
#     },
#     proxy: {
#       '/api': {
#         target: process.env.VITE_BACKEND_URL || `http://localhost:${process.env.BACKEND_PORT || 3001}`,
#         changeOrigin: true,
#         secure: false,
#       },
#     },
#   },
#   build: {
#     sourcemap: true, // Enable for production builds
#   },
#   css: {
#     devSourcemap: true // Enable CSS source maps during development
#   },
#   resolve: {
#     alias: {
#       '@': path.resolve(__dirname, './src'),
#     },
#   },
# });
# EOF
#
#     # Create or update package.json with dev script
#     if [ ! -f {{frontend_dir}}/package.json ]; then
#         cat > {{frontend_dir}}/package.json << 'EOF'
# {
#   "name": "frontend",
#   "private": true,
#   "version": "0.1.0",
#   "type": "module",
#   "scripts": {
#     "dev": "vite",
#     "build": "tsc && vite build",
#     "preview": "vite preview"
#   },
#   "dependencies": {
#     "react": "^18.2.0",
#     "react-dom": "^18.2.0"
#   },
#   "devDependencies": {
#     "@types/react": "^18.2.15",
#     "@types/react-dom": "^18.2.7",
#     "@vitejs/plugin-react": "^4.0.3",
#     "typescript": "^5.0.2",
#     "vite": "^4.4.5"
#   }
# }
# EOF
#     else
#         echo "Frontend package.json already exists, skipping creation."
#     fi
#
#     # Create a basic index.html if it doesn't exist
#     if [ ! -f {{frontend_dir}}/index.html ]; then
#         cat > {{frontend_dir}}/index.html << 'EOF'
# <!DOCTYPE html>
# <html lang="en">
#   <head>
#     <meta charset="UTF-8" />
#     <meta name="viewport" content="width=device-width, initial-scale=1.0" />
#     <title>React App with HMR</title>
#   </head>
#   <body>
#     <div id="root"></div>
#     <script type="module" src="/src/main.tsx"></script>
#   </body>
# </html>
# EOF
#     fi
#
#     # Create a basic tsconfig.json if it doesn't exist
#     if [ ! -f {{frontend_dir}}/tsconfig.json ]; then
#         cat > {{frontend_dir}}/tsconfig.json << 'EOF'
# {
#   "compilerOptions": {
#     "target": "ES2020",
#     "useDefineForClassFields": true,
#     "lib": ["ES2020", "DOM", "DOM.Iterable"],
#     "module": "ESNext",
#     "skipLibCheck": true,
#     "moduleResolution": "bundler",
#     "allowImportingTsExtensions": true,
#     "resolveJsonModule": true,
#     "isolatedModules": true,
#     "noEmit": true,
#     "jsx": "react-jsx",
#     "strict": true,
#     "noUnusedLocals": true,
#     "noUnusedParameters": true,
#     "noFallthroughCasesInSwitch": true,
#     "baseUrl": ".",
#     "paths": {
#       "@/*": ["src/*"]
#     }
#   },
#   "include": ["src"],
#   "references": [{ "path": "./tsconfig.node.json" }]
# }
# EOF
#     fi
#
#     # Create a basic tsconfig.node.json if it doesn't exist
#     if [ ! -f {{frontend_dir}}/tsconfig.node.json ]; then
#         cat > {{frontend_dir}}/tsconfig.node.json << 'EOF'
# {
#   "compilerOptions": {
#     "composite": true,
#     "skipLibCheck": true,
#     "module": "ESNext",
#     "moduleResolution": "bundler",
#     "allowSyntheticDefaultImports": true
#   },
#   "include": ["vite.config.ts"]
# }
# EOF
#     fi
#
#     # Create a basic React app entry point
#     mkdir -p {{frontend_dir}}/src
#     if [ ! -f {{frontend_dir}}/src/main.tsx ]; then
#         cat > {{frontend_dir}}/src/main.tsx << 'EOF'
# import React from 'react'
# import ReactDOM from 'react-dom/client'
# import App from './App'
# import './index.css'
#
# ReactDOM.createRoot(document.getElementById('root')!).render(
#   <React.StrictMode>
#     <App />
#   </React.StrictMode>,
# )
# EOF
#     fi
#
#     if [ ! -f {{frontend_dir}}/src/App.tsx ]; then
#         cat > {{frontend_dir}}/src/App.tsx << 'EOF'
# import { useState } from 'react'
# import './App.css'
#
# function App() {
#   const [count, setCount] = useState(0)
#
#   return (
#     <div className="App">
#       <h1>Vite + React with HMR</h1>
#       <div className="card">
#         <button onClick={() => setCount((count) => count + 1)}>
#           count is {count}
#         </button>
#         <p>
#           Edit <code>src/App.tsx</code> and save to test HMR
#         </p>
#       </div>
#     </div>
#   )
# }
#
# export default App
# EOF
#     fi
#
#     if [ ! -f {{frontend_dir}}/src/index.css ]; then
#         cat > {{frontend_dir}}/src/index.css << 'EOF'
# :root {
#   font-family: Inter, system-ui, Avenir, Helvetica, Arial, sans-serif;
#   line-height: 1.5;
#   font-weight: 400;
#   color-scheme: light dark;
#   color: rgba(255, 255, 255, 0.87);
#   background-color: #242424;
#   font-synthesis: none;
#   text-rendering: optimizeLegibility;
#   -webkit-font-smoothing: antialiased;
#   -moz-osx-font-smoothing: grayscale;
#   -webkit-text-size-adjust: 100%;
# }
#
# body {
#   margin: 0;
#   display: flex;
#   place-items: center;
#   min-width: 320px;
#   min-height: 100vh;
# }
# EOF
#     fi
#
#     if [ ! -f {{frontend_dir}}/src/App.css ]; then
#         cat > {{frontend_dir}}/src/App.css << 'EOF'
# .App {
#   max-width: 1280px;
#   margin: 0 auto;
#   padding: 2rem;
#   text-align: center;
# }
#
# .card {
#   padding: 2em;
# }
#
# button {
#   border-radius: 8px;
#   border: 1px solid transparent;
#   padding: 0.6em 1.2em;
#   font-size: 1em;
#   font-weight: 500;
#   font-family: inherit;
#   background-color: #1a1a1a;
#   cursor: pointer;
#   transition: border-color 0.25s;
# }
# button:hover {
#   border-color: #646cff;
# }
# button:focus,
# button:focus-visible {
#   outline: 4px auto -webkit-focus-ring-color;
# }
# EOF
#     fi
#
#     echo "Frontend HMR configuration complete."
#
# # Setup backend hot reload configuration
# setup-backend-hmr: _ensure-dirs
#     #!/usr/bin/env bash
#     echo "Setting up backend hot reload configuration..."
#
#     # Create or update package.json with nodemon
#     if [ ! -f {{backend_dir}}/package.json ]; then
#         cat > {{backend_dir}}/package.json << 'EOF'
# {
#   "name": "backend",
#   "version": "0.1.0",
#   "private": true,
#   "scripts": {
#     "dev": "nodemon --watch src --ext ts,json --exec \"ts-node --transpile-only src/index.ts\" --signal SIGTERM",
#     "build": "tsc",
#     "start": "node dist/index.js",
#     "dev:debug": "nodemon --watch src --ext ts,json --exec \"node --inspect=0.0.0.0:9229 -r ts-node/register src/index.ts\" --signal SIGTERM"
#   },
#   "dependencies": {
#     "hono": "^3.2.5",
#     "@hono/node-server": "^1.0.1"
#   },
#   "devDependencies": {
#     "@types/node": "^18.15.11",
#     "nodemon": "^3.0.1",
#     "ts-node": "^10.9.1",
#     "typescript": "^5.1.6"
#   }
# }
# EOF
#     else
#         echo "Backend package.json already exists, skipping creation."
#     fi
#
#     # Create or update tsconfig.json with source map settings
#     cat > {{backend_dir}}/tsconfig.json << 'EOF'
# {
#   "compilerOptions": {
#     "target": "ES2020",
#     "module": "CommonJS",
#     "moduleResolution": "node",
#     "esModuleInterop": true,
#     "outDir": "dist",
#     "sourceMap": true,
#     "strict": true,
#     "lib": ["ES2020"],
#     "skipLibCheck": true
#   },
#   "include": ["src/**/*"],
#   "exclude": ["node_modules", "dist"]
# }
# EOF
#
#     # Create nodemon.json for fine-grained control
#     cat > {{backend_dir}}/nodemon.json << 'EOF'
# {
#   "watch": ["src"],
#   "ext": "ts,json",
#   "ignore": ["src/**/*.spec.ts"],
#   "exec": "ts-node --transpile-only src/index.ts",
#   "signal": "SIGTERM",
#   "env": {
#     "NODE_ENV": "development"
#   }
# }
# EOF
#
#     # Create a basic HonoJS server
#     mkdir -p {{backend_dir}}/src
#     if [ ! -f {{backend_dir}}/src/index.ts ]; then
#         cat > {{backend_dir}}/src/index.ts << 'EOF'
# import { Hono } from 'hono';
# import { logger } from 'hono/logger';
# import { cors } from 'hono/cors';
# import { serve } from '@hono/node-server';
#
# const app = new Hono();
#
# // Add middleware
# app.use('*', logger());
# app.use('*', cors({
#   origin: process.env.CORS_ORIGIN || 'http://localhost:3000',
#   allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
#   allowHeaders: ['Content-Type', 'Authorization'],
#   exposeHeaders: ['Content-Length', 'X-Request-Id'],
#   maxAge: 600,
#   credentials: true,
# }));
#
# // Add routes
# app.get('/', (c) => c.text('Hello, HonoJS!'));
# app.get('/api/health', (c) => c.json({ status: 'ok', timestamp: new Date().toISOString() }));
#
# // Graceful shutdown handling
# const server = serve({
#   fetch: app.fetch,
#   port: Number(process.env.BACKEND_PORT || 3001),
#   hostname: '0.0.0.0', // Important for Docker
# }, (info) => {
#   console.log(`Server is running on http://${info.hostname}:${info.port}`);
# });
#
# // Handle termination signals for clean restarts
# process.on('SIGTERM', () => {
#   console.log('SIGTERM received, shutting down gracefully');
#   server.close(() => {
#     console.log('Server closed');
#     process.exit(0);
#   });
# });
#
# process.on('SIGINT', () => {
#   console.log('SIGINT received, shutting down gracefully');
#   server.close(() => {
#     console.log('Server closed');
#     process.exit(0);
#   });
# });
#
# export default app;
# EOF
#     fi
#
#     echo "Backend hot reload configuration complete."
