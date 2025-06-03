#!/usr/bin/env bash
# setup-fly-dev-env.sh
# Robust Fly.io dev environment setup script

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLOUD_INFRA_DIR="${HOME}/src/cloud-infra"
PROJECT_NAME="fly-dev-env"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${SCRIPT_DIR}/setup-fly-dev-${TIMESTAMP}.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
	echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >>"$LOG_FILE"
}

print_status() {
	echo -e "${BLUE}[*]${NC} $1"
	log "STATUS: $1"
}

print_success() {
	echo -e "${GREEN}[✓]${NC} $1"
	log "SUCCESS: $1"
}

print_error() {
	echo -e "${RED}[✗]${NC} $1"
	log "ERROR: $1"
}

print_warning() {
	echo -e "${YELLOW}[!]${NC} $1"
	log "WARNING: $1"
}

# Cleanup function
cleanup() {
	local exit_code=$?
	if [ $exit_code -ne 0 ]; then
		print_error "Setup failed! Check log file: $LOG_FILE"
		if [ -n "${PROJECT_DIR:-}" ] && [ -d "$PROJECT_DIR" ]; then
			print_warning "Cleaning up partial installation..."
			rm -rf "$PROJECT_DIR"
		fi
	fi
	exit $exit_code
}

trap cleanup EXIT

# Defensive directory creation
ensure_directory() {
	local dir="$1"
	if [ ! -d "$dir" ]; then
		print_status "Creating directory: $dir"
		mkdir -p "$dir" || {
			print_error "Failed to create directory: $dir"
			return 1
		}
	fi
}

# Check prerequisites
check_prerequisites() {
	print_status "Checking prerequisites..."

	local missing_tools=()
	local warnings=()

	# Check required tools
	for tool in fly git; do
		if ! command -v "$tool" &>/dev/null; then
			missing_tools+=("$tool")
		fi
	done

	# Check optional but recommended tools
	for tool in tailscale ssh-keygen; do
		if ! command -v "$tool" &>/dev/null; then
			warnings+=("$tool")
		fi
	done

	# Check cloud infrastructure directory
	if [ ! -d "$CLOUD_INFRA_DIR" ]; then
		print_warning "Cloud infrastructure directory not found: $CLOUD_INFRA_DIR"
		print_status "Creating cloud infrastructure directory..."
		ensure_directory "$CLOUD_INFRA_DIR"
	fi

	# Check if it's a git repo
	if [ -d "$CLOUD_INFRA_DIR" ] && ! git -C "$CLOUD_INFRA_DIR" rev-parse --git-dir &>/dev/null; then
		print_warning "$CLOUD_INFRA_DIR is not a git repository"
		read -p "Initialize as git repository? (y/N): " init_git
		if [[ "$init_git" =~ ^[Yy]$ ]]; then
			git -C "$CLOUD_INFRA_DIR" init
			print_success "Initialized git repository"
		fi
	fi

	if [ ${#missing_tools[@]} -ne 0 ]; then
		print_error "Missing required tools: ${missing_tools[*]}"
		print_warning "Please install missing tools:"
		[[ " ${missing_tools[*]} " =~ " fly " ]] && echo "  - Fly.io CLI: curl -L https://fly.io/install.sh | sh"
		return 1
	fi

	if [ ${#warnings[@]} -ne 0 ]; then
		print_warning "Missing optional tools: ${warnings[*]}"
		echo "  - Tailscale: curl -fsSL https://tailscale.com/install.sh | sh"
		echo "  - SSH keys: ssh-keygen -t ed25519"
		read -p "Continue without these tools? (y/N): " continue_anyway
		[[ ! "$continue_anyway" =~ ^[Yy]$ ]] && return 1
	fi

	print_success "Prerequisites check passed"
}

# Detect shell and update appropriate rc file
update_shell_config() {
	local shell_rc=""
	local shell_name=""

	# Detect shell
	if [ -n "${ZSH_VERSION:-}" ] || [ -n "${ZSH_NAME:-}" ] || [[ "${SHELL:-}" == *"zsh"* ]]; then
		shell_name="zsh"
		shell_rc="${HOME}/.zshrc"
	elif [ -n "${BASH_VERSION:-}" ] || [[ "${SHELL:-}" == *"bash"* ]]; then
		shell_name="bash"
		shell_rc="${HOME}/.bashrc"
	else
		print_warning "Unknown shell, defaulting to .profile"
		shell_rc="${HOME}/.profile"
	fi

	print_status "Detected shell: $shell_name"

	# Backup existing rc file
	if [ -f "$shell_rc" ]; then
		cp "$shell_rc" "${shell_rc}.backup.${TIMESTAMP}"
		print_success "Backed up $shell_rc"
	fi

	# Check if aliases already exist
	if grep -q "# Fly.io dev environment aliases" "$shell_rc" 2>/dev/null; then
		print_warning "Fly.io aliases already exist in $shell_rc"
		read -p "Replace existing aliases? (y/N): " replace_aliases
		if [[ "$replace_aliases" =~ ^[Yy]$ ]]; then
			# Remove existing aliases
			sed -i.tmp '/# Fly.io dev environment aliases/,/^$/d' "$shell_rc"
			rm -f "${shell_rc}.tmp"
		else
			return 0
		fi
	fi

	# Add aliases
	cat >>"$shell_rc" <<EOF

# Fly.io dev environment aliases
alias fly-dev='${CLOUD_INFRA_DIR}/${PROJECT_NAME}/connect-fly-dev.sh'
alias fly-code='${CLOUD_INFRA_DIR}/${PROJECT_NAME}/connect-fly-code.sh'
alias fly-ssh='ssh developer@\$(tailscale status 2>/dev/null | grep "fly-dev-" | awk "{print \\\$1}")'
alias fly-logs='fly logs --app ${FLY_APP_NAME}'
alias fly-restart='fly apps restart ${FLY_APP_NAME}'
alias fly-stop='fly scale count 0 --app ${FLY_APP_NAME}'
alias fly-start='fly scale count 1 --app ${FLY_APP_NAME}'

EOF

	print_success "Added aliases to $shell_rc"
	echo "Run 'source $shell_rc' to use aliases in current session"
}

# Get user inputs with validation
get_user_inputs() {
	print_status "Gathering configuration..."

	# App name with validation
	while true; do
		read -p "Enter Fly.io app name (lowercase, alphanumeric and hyphens only): " FLY_APP_NAME
		FLY_APP_NAME=${FLY_APP_NAME:-fly-dev-env}

		if [[ "$FLY_APP_NAME" =~ ^[a-z0-9-]+$ ]]; then
			break
		else
			print_error "Invalid app name. Use only lowercase letters, numbers, and hyphens."
		fi
	done

	# Check if app already exists
	if fly apps list 2>/dev/null | grep -q "^$FLY_APP_NAME"; then
		print_warning "App '$FLY_APP_NAME' already exists"
		read -p "Use existing app? (y/N): " use_existing
		if [[ ! "$use_existing" =~ ^[Yy]$ ]]; then
			print_error "Please choose a different app name"
			return 1
		fi
		EXISTING_APP=true
	else
		EXISTING_APP=false
	fi

	# Region selection
	print_status "Available regions:"
	echo "  US: den (Denver), iad (Virginia), lax (Los Angeles), ord (Chicago), sea (Seattle), sjc (San Jose)"
	echo "  EU: ams (Amsterdam), fra (Frankfurt), lhr (London), mad (Madrid), par (Paris)"
	echo "  Asia: hkg (Hong Kong), nrt (Tokyo), sin (Singapore), syd (Sydney)"

	read -p "Enter preferred region (default: sjc): " FLY_REGION
	FLY_REGION=${FLY_REGION:-sjc}

	# Tailscale setup (optional)
	if command -v tailscale &>/dev/null; then
		print_status "Tailscale detected. Set up Tailscale integration?"
		read -p "Configure Tailscale? (Y/n): " setup_tailscale
		if [[ ! "$setup_tailscale" =~ ^[Nn]$ ]]; then
			print_warning "Get an auth key from: https://login.tailscale.com/admin/settings/keys"
			read -s -p "Enter Tailscale auth key (or press Enter to skip): " TAILSCALE_AUTHKEY
			echo
		fi
	else
		print_warning "Tailscale not installed. Skipping Tailscale integration."
		TAILSCALE_AUTHKEY=""
	fi

	# SSH key handling
	SSH_KEY=""
	if command -v ssh-keygen &>/dev/null; then
		local ssh_key_files=()
		[ -f ~/.ssh/id_ed25519.pub ] && ssh_key_files+=("~/.ssh/id_ed25519.pub")
		[ -f ~/.ssh/id_rsa.pub ] && ssh_key_files+=("~/.ssh/id_rsa.pub")
		[ -f ~/.ssh/id_ecdsa.pub ] && ssh_key_files+=("~/.ssh/id_ecdsa.pub")

		if [ ${#ssh_key_files[@]} -gt 0 ]; then
			print_status "Found SSH keys:"
			select key_file in "${ssh_key_files[@]}" "Skip SSH setup"; do
				if [ "$key_file" = "Skip SSH setup" ]; then
					print_warning "Skipping SSH key setup"
					break
				elif [ -n "$key_file" ]; then
					SSH_KEY=$(cat "${key_file/#\~/$HOME}")
					print_success "Using SSH key: $key_file"
					break
				fi
			done
		else
			print_warning "No SSH keys found"
			read -p "Generate new SSH key? (y/N): " gen_key
			if [[ "$gen_key" =~ ^[Yy]$ ]]; then
				ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
				SSH_KEY=$(cat ~/.ssh/id_ed25519.pub)
				print_success "Generated new SSH key"
			fi
		fi
	fi

	# Summary with validation
	echo
	print_status "Configuration Summary:"
	echo "  App Name: $FLY_APP_NAME"
	echo "  Region: $FLY_REGION"
	echo "  Existing App: $EXISTING_APP"
	[ -n "${TAILSCALE_AUTHKEY:-}" ] && echo "  Tailscale: Configured"
	[ -n "${SSH_KEY:-}" ] && echo "  SSH: Configured"
	echo "  Project Location: $CLOUD_INFRA_DIR/$PROJECT_NAME"
	echo

	read -p "Continue with these settings? (y/N): " confirm
	[[ ! "$confirm" =~ ^[Yy]$ ]] && return 1

	return 0
}

# Create project with error handling
create_project() {
	print_status "Creating project structure..."

	PROJECT_DIR="${CLOUD_INFRA_DIR}/${PROJECT_NAME}"

	# Check if project already exists
	if [ -d "$PROJECT_DIR" ]; then
		print_warning "Project directory already exists: $PROJECT_DIR"
		read -p "Overwrite existing project? (y/N): " overwrite
		if [[ "$overwrite" =~ ^[Yy]$ ]]; then
			rm -rf "$PROJECT_DIR"
		else
			print_error "Aborting to prevent overwriting existing project"
			return 1
		fi
	fi

	ensure_directory "$PROJECT_DIR"
	cd "$PROJECT_DIR"

	# Create all files with proper error handling
	create_dockerfile || return 1
	create_start_script || return 1
	create_zellij_config || return 1
	create_fly_toml || return 1
	create_helper_scripts || return 1

	if [ -n "${SSH_KEY:-}" ]; then
		echo "$SSH_KEY" >authorized_keys
		chmod 600 authorized_keys
	else
		touch authorized_keys
		print_warning "No SSH key configured. SSH access will be limited."
	fi

	# Create .gitignore
	cat >.gitignore <<'EOF'
authorized_keys
.env
*.log
.DS_Store
fly-agent
EOF

	# Git operations
	if git -C "$CLOUD_INFRA_DIR" rev-parse --git-dir &>/dev/null; then
		git -C "$CLOUD_INFRA_DIR" add "$PROJECT_NAME"
		git -C "$CLOUD_INFRA_DIR" commit -m "Add Fly.io dev environment: $FLY_APP_NAME" || {
			print_warning "Failed to commit to git (may already be committed)"
		}
	fi

	print_success "Project structure created at: $PROJECT_DIR"
}

create_dockerfile() {
	cat >Dockerfile <<'EOF'
FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install essential packages
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    sudo \
    openssh-server \
    build-essential \
    python3 \
    python3-pip \
    nodejs \
    npm \
    tmux \
    htop \
    neovim \
    vim \
    ripgrep \
    fd-find \
    bat \
    zsh \
    locales \
    tzdata \
    ca-certificates \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Generate locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Install Tailscale (conditional - will only run if used)
RUN curl -fsSL https://tailscale.com/install.sh | sh || true

# Install Zellij
RUN ZELLIJ_VERSION=$(curl -s https://api.github.com/repos/zellij-org/zellij/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")') && \
    curl -L "https://github.com/zellij-org/zellij/releases/download/${ZELLIJ_VERSION}/zellij-x86_64-unknown-linux-musl.tar.gz" | tar xz -C /usr/local/bin

# Install code-server
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Create non-root user
RUN useradd -m -s /bin/zsh developer && \
    echo "developer:developer" | chpasswd && \
    usermod -aG sudo developer && \
    echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Setup SSH
RUN mkdir -p /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Switch to developer user
USER developer
WORKDIR /home/developer

# Install oh-my-zsh (optional but nice)
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true

# Create necessary directories
RUN mkdir -p ~/.ssh ~/.config/zellij ~/.config/code-server ~/.local/bin

# Copy configuration files
COPY --chown=developer:developer authorized_keys /home/developer/.ssh/authorized_keys
COPY --chown=developer:developer zellij-config.kdl /home/developer/.config/zellij/config.kdl
COPY --chown=developer:developer start.sh /home/developer/.local/bin/start.sh

# Set permissions
RUN chmod 700 ~/.ssh && \
    chmod 600 ~/.ssh/authorized_keys && \
    chmod +x ~/.local/bin/start.sh

# Create workspace directory
RUN mkdir -p ~/workspace

# Expose ports
EXPOSE 22 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD pgrep sshd && curl -f http://localhost:8080 || exit 1

CMD ["/home/developer/.local/bin/start.sh"]
EOF
}

create_start_script() {
	cat >start.sh <<'EOF'
#!/bin/bash
set -euo pipefail

# Logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# Function to check if a process is running
is_running() {
    pgrep -x "$1" > /dev/null 2>&1
}

# Start SSH server
log "Starting SSH server..."
sudo service ssh start || log "SSH start failed (may already be running)"

# Start Tailscale if auth key is provided
if [ -n "${TAILSCALE_AUTHKEY:-}" ]; then
    log "Starting Tailscale..."
    sudo tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &
    sleep 5
    
    log "Authenticating with Tailscale..."
    sudo tailscale up \
        --authkey="${TAILSCALE_AUTHKEY}" \
        --hostname="fly-dev-${FLY_REGION:-unknown}" \
        --accept-routes \
        --ssh || log "Tailscale auth failed"
fi

# Configure code-server
log "Configuring code-server..."
mkdir -p ~/.config/code-server
cat > ~/.config/code-server/config.yaml << EOL
bind-addr: 0.0.0.0:8080
auth: none
cert: false
EOL

# Start code-server
log "Starting code-server..."
code-server &
CODE_SERVER_PID=$!

# Wait for code-server to start
sleep 5

# Create or attach to Zellij session
log "Starting Zellij session..."
if ! zellij list-sessions 2>/dev/null | grep -q "main"; then
    zellij --session main --layout welcome &
else
    log "Zellij session 'main' already exists"
fi

# Create welcome layout for Zellij
mkdir -p ~/.config/zellij/layouts
cat > ~/.config/zellij/layouts/welcome.kdl << 'LAYOUT'
layout {
    pane split_direction="vertical" {
        pane {
            name "Welcome"
            command "bash"
            args "-c" "clear && echo 'Welcome to Fly.io Dev Environment' && echo '=================================' && echo '' && echo 'Zellij shortcuts:' && echo '  Ctrl+a c - New tab' && echo '  Ctrl+a n - Next tab' && echo '  Ctrl+a p - Previous tab' && echo '  Ctrl+a d - Detach' && echo '' && echo 'Code Server: http://localhost:8080' && echo '' && exec bash"
        }
    }
}
LAYOUT

# Monitor and restart services
log "Starting service monitor..."
while true; do
    # Check code-server
    if ! kill -0 $CODE_SERVER_PID 2>/dev/null; then
        log "Restarting code-server..."
        code-server &
        CODE_SERVER_PID=$!
    fi
    
    # Check SSH
    if ! is_running "sshd"; then
        log "Restarting SSH..."
        sudo service ssh start
    fi
    
    # Check Zellij session
    if ! zellij list-sessions 2>/dev/null | grep -q "main"; then
        log "Recreating Zellij session..."
        zellij --session main --layout welcome &
    fi
    
    sleep 30
done
EOF
	chmod +x start.sh
}

create_zellij_config() {
	cat >zellij-config.kdl <<'EOF'
default_shell "zsh"
pane_frames false
theme "tokyo-night"
copy_command "pbcopy"
scrollback_editor "/usr/bin/vim"

keybinds clear-defaults=true {
    normal {
        bind "Ctrl a" { SwitchToMode "tmux"; }
        bind "Ctrl q" { Quit; }
    }
    
    tmux {
        bind "Ctrl a" { SwitchToMode "normal"; }
        bind "d" { Detach; }
        bind "c" { NewTab; SwitchToMode "normal"; }
        bind "n" { GoToNextTab; SwitchToMode "normal"; }
        bind "p" { GoToPreviousTab; SwitchToMode "normal"; }
        bind "x" { CloseFocus; SwitchToMode "normal"; }
        bind "[" { SwitchToMode "scroll"; }
        bind "s" { 
            LaunchOrFocusPlugin "zellij:session-manager" {
                floating true
                move_to_focused_tab true
            }
            SwitchToMode "Normal"
        }
        bind "1" { GoToTab 1; SwitchToMode "normal"; }
        bind "2" { GoToTab 2; SwitchToMode "normal"; }
        bind "3" { GoToTab 3; SwitchToMode "normal"; }
        bind "4" { GoToTab 4; SwitchToMode "normal"; }
        bind "5" { GoToTab 5; SwitchToMode "normal"; }
    }
    
    scroll {
        bind "Ctrl c" { ScrollToBottom; SwitchToMode "normal"; }
        bind "q" { SwitchToMode "normal"; }
        bind "j" { ScrollDown; }
        bind "k" { ScrollUp; }
        bind "Ctrl d" { HalfPageScrollDown; }
        bind "Ctrl u" { HalfPageScrollUp; }
    }
}

themes {
    tokyo-night {
        fg "#a9b1d6"
        bg "#1a1b26"
        black "#414868"
        red "#f7768e"
        green "#73daca"
        yellow "#e0af68"
        blue "#7aa2f7"
        magenta "#bb9af7"
        cyan "#7dcfff"
        white "#c0caf5"
        orange "#ff9e64"
    }
}
EOF
}

create_fly_toml() {
	cat >fly.toml <<EOF
app = "$FLY_APP_NAME"
primary_region = "$FLY_REGION"
kill_signal = "SIGINT"
kill_timeout = 5

[build]
  dockerfile = "Dockerfile"

[env]
  PORT = "8080"
  FLY_REGION = "$FLY_REGION"
  SHELL = "/bin/zsh"

[experimental]
  auto_rollback = true

[[services]]
  http_checks = []
  internal_port = 8080
  protocol = "tcp"
  script_checks = []
  
  [services.concurrency]
    hard_limit = 25
    soft_limit = 20
    type = "connections"

  [[services.ports]]
    force_https = true
    handlers = ["http"]
    port = 80

  [[services.ports]]
    handlers = ["tls", "http"]
    port = 443

  [[services.http_checks]]
    interval = "30s"
    grace_period = "5s"
    method = "get"
    path = "/"
    protocol = "http"
    timeout = "2s"
    tls_skip_verify = false

# SSH service
[[services]]
  internal_port = 22
  protocol = "tcp"
  
  [[services.ports]]
    port = 22

# Persistent volume for data
[mounts]
  source = "dev_data"
  destination = "/home/developer/workspace"
  initial_size = "50gb"

[checks]
  [checks.ssh]
    type = "tcp"
    interval = "30s"
    timeout = "3s"
    port = 22
EOF
}

create_helper_scripts() {
	# Connection script
	cat >connect-fly-dev.sh <<'EOF'
#!/bin/bash
set -euo pipefail

# Try Tailscale first
if command -v tailscale &> /dev/null; then
    TAILSCALE_IP=$(tailscale status 2>/dev/null | grep "fly-dev-" | head -1 | awk '{print $1}')
    
    if [ -n "$TAILSCALE_IP" ]; then
        echo "Connecting via Tailscale to $TAILSCALE_IP..."
        exec ssh -t "developer@$TAILSCALE_IP" "zellij attach main || zellij --session main"
    fi
fi

# Fallback to Fly SSH
echo "Connecting via Fly SSH..."
FLY_APP_NAME=$(grep "^app = " fly.toml 2>/dev/null | cut -d'"' -f2)

if [ -z "$FLY_APP_NAME" ]; then
    echo "Error: Could not determine app name"
    exit 1
fi

fly ssh console --app "$FLY_APP_NAME" --command "su - developer -c 'zellij attach main || zellij --session main'"
EOF
	chmod +x connect-fly-dev.sh

	# Code server connection script
	cat >connect-fly-code.sh <<'EOF'
#!/bin/bash
set -euo pipefail

# Function to open URL
open_url() {
    local url=$1
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open "$url"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        xdg-open "$url" 2>/dev/null || echo "Please open: $url"
    else
        echo "Please open: $url"
    fi
}

# Try Tailscale first
if command -v tailscale &> /dev/null; then
    TAILSCALE_IP=$(tailscale status 2>/dev/null | grep "fly-dev-" | head -1 | awk '{print $1}')
    
    if [ -n "$TAILSCALE_IP" ]; then
        URL="http://$TAILSCALE_IP:8080"
        echo "Code server available at: $URL"
        open_url "$URL"
        exit 0
    fi
fi

# Fallback to Fly proxy
FLY_APP_NAME=$(grep "^app = " fly.toml 2>/dev/null | cut -d'"' -f2)

if [ -z "$FLY_APP_NAME" ]; then
    echo "Error: Could not determine app name"
    exit 1
fi

echo "Starting Fly proxy..."
fly proxy 8080:8080 --app "$FLY_APP_NAME" &
PROXY_PID=$!

sleep 2
URL="http://localhost:8080"
echo "Code server available at: $URL"
open_url "$URL"

echo "Press Ctrl+C to stop the proxy"
wait $PROXY_PID
EOF
	chmod +x connect-fly-code.sh
}

# Deploy to Fly.io with error handling
deploy_to_fly() {
	cd "$PROJECT_DIR"

	# Check if logged in to Fly
	if ! fly auth whoami &>/dev/null; then
		print_warning "Not logged in to Fly.io"
		fly auth login || {
			print_error "Failed to login to Fly.io"
			return 1
		}
	fi

	if [ "$EXISTING_APP" = false ]; then
		print_status "Creating Fly.io app..."
		fly apps create "$FLY_APP_NAME" --org personal || {
			print_error "Failed to create app. The name might be taken."
			return 1
		}
	fi

	print_status "Creating persistent volume..."
	if ! fly volumes list --app "$FLY_APP_NAME" 2>/dev/null | grep -q "dev_data"; then
		fly volumes create dev_data \
			--app "$FLY_APP_NAME" \
			--region "$FLY_REGION" \
			--size 50 \
			--yes || {
			print_warning "Volume creation failed (might already exist)"
		}
	else
		print_success "Volume already exists"
	fi

	if [ -n "${TAILSCALE_AUTHKEY:-}" ]; then
		print_status "Setting Tailscale auth key..."
		fly secrets set TAILSCALE_AUTHKEY="$TAILSCALE_AUTHKEY" --app "$FLY_APP_NAME"
	fi

	print_status "Deploying to Fly.io (this may take a few minutes)..."
	if ! fly deploy --app "$FLY_APP_NAME" --region "$FLY_REGION" --strategy immediate; then
		print_error "Deployment failed"
		print_warning "Check logs with: fly logs --app $FLY_APP_NAME"
		return 1
	fi

	print_status "Configuring instance..."
	fly scale count 1 --app "$FLY_APP_NAME"
	fly scale vm shared-cpu-1x --memory 2048 --app "$FLY_APP_NAME"

	print_success "Deployment complete!"
}

# Main execution
main() {
	print_status "Fly.io Dev Environment Setup"
	print_status "Log file: $LOG_FILE"
	echo

	# Run all steps
	check_prerequisites || exit 1
	get_user_inputs || exit 1
	create_project || exit 1
	deploy_to_fly || exit 1
	update_shell_config || true # Don't fail if this doesn't work

	echo
	print_success "Setup complete! 🎉"
	echo
	print_status "Quick start:"
	echo "  cd $PROJECT_DIR"
	echo "  ./connect-fly-dev.sh    # Connect to terminal"
	echo "  ./connect-fly-code.sh   # Open code server"
	echo
	print_status "After sourcing your shell config:"
	echo "  fly-dev    # Connect to terminal"
	echo "  fly-code   # Open code server"
	echo "  fly-logs   # View logs"
	echo "  fly-stop   # Stop instance (save money)"
	echo "  fly-start  # Start instance"
	echo

	if [ -n "${TAILSCALE_AUTHKEY:-}" ]; then
		print_warning "Note: Tailscale connection may take 1-2 minutes to establish"
	fi

	# Offer to source shell config
	if [[ "${SHELL:-}" == *"zsh"* ]]; then
		print_status "Source your shell config now? (recommended)"
		read -p "Run 'source ~/.zshrc'? (Y/n): " source_now
		[[ ! "$source_now" =~ ^[Nn]$ ]] && source ~/.zshrc
	fi
}

# Run main with error handling
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
