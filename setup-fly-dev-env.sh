#!/bin/bash
# setup-fly-dev-env.sh
# Place this in ~/dotfiles and run from there

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
	echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
	echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
	echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
	echo -e "${YELLOW}[!]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
	print_status "Checking prerequisites..."

	local missing_tools=()

	for tool in fly tailscale ssh-keygen; do
		if ! command -v $tool &>/dev/null; then
			missing_tools+=($tool)
		fi
	done

	if [ ${#missing_tools[@]} -ne 0 ]; then
		print_error "Missing required tools: ${missing_tools[*]}"
		print_warning "Please install missing tools:"
		[[ " ${missing_tools[*]} " =~ " fly " ]] && echo "  - Fly.io CLI: curl -L https://fly.io/install.sh | sh"
		[[ " ${missing_tools[*]} " =~ " tailscale " ]] && echo "  - Tailscale: curl -fsSL https://tailscale.com/install.sh | sh"
		exit 1
	fi

	print_success "All prerequisites installed"
}

# Get user inputs
get_user_inputs() {
	print_status "Gathering configuration..."

	# App name
	read -p "Enter Fly.io app name (lowercase, no spaces): " FLY_APP_NAME
	FLY_APP_NAME=${FLY_APP_NAME:-fly-dev-env}

	# Region
	echo "Available regions: ams, iad, lax, lhr, nrt, sea, sgp, sjc, syd"
	read -p "Enter preferred region (default: sjc): " FLY_REGION
	FLY_REGION=${FLY_REGION:-sjc}

	# Tailscale auth key
	print_warning "Get an auth key from: https://login.tailscale.com/admin/settings/keys"
	read -s -p "Enter Tailscale auth key (tskey-auth-...): " TAILSCALE_AUTHKEY
	echo

	# SSH key
	if [ -f ~/.ssh/id_rsa.pub ]; then
		SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
		print_success "Using existing SSH key from ~/.ssh/id_rsa.pub"
	elif [ -f ~/.ssh/id_ed25519.pub ]; then
		SSH_KEY=$(cat ~/.ssh/id_ed25519.pub)
		print_success "Using existing SSH key from ~/.ssh/id_ed25519.pub"
	else
		print_error "No SSH key found. Please generate one with: ssh-keygen"
		exit 1
	fi

	# Confirm settings
	echo
	print_status "Configuration Summary:"
	echo "  App Name: $FLY_APP_NAME"
	echo "  Region: $FLY_REGION"
	echo "  Tailscale Key: tskey-auth-****${TAILSCALE_AUTHKEY: -4}"
	echo
	read -p "Continue with these settings? (y/N): " confirm

	if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
		print_warning "Setup cancelled"
		exit 0
	fi
}

# Create project structure
create_project() {
	print_status "Creating project structure..."

	PROJECT_DIR="fly-dev-env"
	mkdir -p "$PROJECT_DIR"
	cd "$PROJECT_DIR"

	# Create Dockerfile
	cat >Dockerfile <<'EOF'
FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

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
    ripgrep \
    fd-find \
    zsh \
    locales \
    && rm -rf /var/lib/apt/lists/*

# Generate locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Install Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Install Zellij
RUN curl -L https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz | tar xz -C /usr/local/bin

# Install code-server
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Create non-root user
RUN useradd -m -s /bin/bash developer && \
    echo "developer:developer" | chpasswd && \
    usermod -aG sudo developer && \
    echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Setup SSH
RUN mkdir /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Switch to developer user for remaining setup
USER developer
WORKDIR /home/developer

# Create necessary directories
RUN mkdir -p ~/.ssh ~/.config/zellij ~/.config/code-server

# Copy configuration files
COPY --chown=developer:developer authorized_keys /home/developer/.ssh/authorized_keys
COPY --chown=developer:developer zellij-config.kdl /home/developer/.config/zellij/config.kdl
COPY --chown=developer:developer start.sh /home/developer/start.sh

# Set permissions
RUN chmod 700 ~/.ssh && \
    chmod 600 ~/.ssh/authorized_keys && \
    chmod +x ~/start.sh

# Expose ports
EXPOSE 22 8080

CMD ["/home/developer/start.sh"]
EOF

	# Create start.sh
	cat >start.sh <<'EOF'
#!/bin/bash

# Function to check if a process is running
is_running() {
    pgrep -x "$1" > /dev/null
}

# Start Tailscale
echo "Starting Tailscale..."
sudo tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &
sleep 5

# Authenticate Tailscale
if [ -n "${TAILSCALE_AUTHKEY}" ]; then
    echo "Authenticating with Tailscale..."
    sudo tailscale up --authkey="${TAILSCALE_AUTHKEY}" --hostname="fly-dev-${FLY_REGION}" --accept-routes
fi

# Start SSH server
echo "Starting SSH server..."
sudo service ssh start

# Start code-server with config
echo "Starting code-server..."
cat > ~/.config/code-server/config.yaml << EOL
bind-addr: 0.0.0.0:8080
auth: none
cert: false
EOL

code-server &

# Create initial Zellij session
echo "Starting Zellij..."
zellij --session main detach &

# Create a welcome script
cat > ~/welcome.sh << 'WELCOME'
#!/bin/bash
clear
echo "========================================="
echo "   Welcome to your Fly.io Dev Environment"
echo "========================================="
echo ""
echo "Services running:"
echo "  - SSH: Port 22"
echo "  - Code Server: Port 8080"
echo "  - Zellij: 'zellij attach main'"
echo ""
echo "Tailscale hostname: fly-dev-${FLY_REGION}"
echo ""
echo "Happy coding! 🚀"
echo "========================================="
WELCOME
chmod +x ~/welcome.sh

# Monitor and restart services
while true; do
    # Check code-server
    if ! is_running "code-server"; then
        echo "Restarting code-server..."
        code-server &
    fi
    
    # Check if Zellij session exists
    if ! zellij list-sessions 2>/dev/null | grep -q "main"; then
        echo "Recreating Zellij session..."
        zellij --session main detach &
    fi
    
    # Check SSH
    if ! sudo service ssh status > /dev/null 2>&1; then
        echo "Restarting SSH..."
        sudo service ssh start
    fi
    
    sleep 30
done
EOF

	# Create zellij-config.kdl
	cat >zellij-config.kdl <<'EOF'
default_shell "bash"
pane_frames false
theme "tokyo-night"

keybinds {
    normal {
        bind "Ctrl a" { SwitchToMode "tmux"; }
    }
    
    tmux {
        bind "d" { Detach; }
        bind "c" { NewTab; SwitchToMode "normal"; }
        bind "n" { GoToNextTab; SwitchToMode "normal"; }
        bind "p" { GoToPreviousTab; SwitchToMode "normal"; }
        bind "x" { CloseFocus; SwitchToMode "normal"; }
        bind "s" { SwitchToMode "scroll"; }
        bind "Ctrl a" { SwitchToMode "normal"; }
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

	# Create authorized_keys
	echo "$SSH_KEY" >authorized_keys

	# Create fly.toml
	cat >fly.toml <<EOF
app = "$FLY_APP_NAME"
primary_region = "$FLY_REGION"

[build]
  dockerfile = "Dockerfile"

[env]
  PORT = "8080"
  FLY_REGION = "$FLY_REGION"

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
EOF

	# Create .gitignore
	cat >.gitignore <<'EOF'
authorized_keys
.env
*.log
EOF

	# Create helper scripts in parent directory
	cd ..

	# Create connect script
	cat >connect-fly-dev.sh <<'EOF'
#!/bin/bash
# Get Tailscale IP of the Fly dev instance
TAILSCALE_IP=$(tailscale status | grep "fly-dev-" | awk '{print $1}')

if [ -z "$TAILSCALE_IP" ]; then
    echo "Error: Could not find Fly dev instance in Tailscale"
    echo "Make sure Tailscale is running and connected"
    exit 1
fi

echo "Connecting to $TAILSCALE_IP..."

# Connect with Zellij attach
ssh -t developer@$TAILSCALE_IP "zellij attach main || zellij --session main"
EOF
	chmod +x connect-fly-dev.sh

	# Create code-server connect script
	cat >connect-fly-code.sh <<'EOF'
#!/bin/bash
TAILSCALE_IP=$(tailscale status | grep "fly-dev-" | awk '{print $1}')

if [ -z "$TAILSCALE_IP" ]; then
    echo "Error: Could not find Fly dev instance in Tailscale"
    exit 1
fi

echo "Code server available at: http://$TAILSCALE_IP:8080"
echo "Opening in browser..."

# Try to open in browser
if command -v open &> /dev/null; then
    open "http://$TAILSCALE_IP:8080"
elif command -v xdg-open &> /dev/null; then
    xdg-open "http://$TAILSCALE_IP:8080"
else
    echo "Please open manually: http://$TAILSCALE_IP:8080"
fi
EOF
	chmod +x connect-fly-code.sh

	print_success "Project structure created"
}

# Deploy to Fly.io
deploy_to_fly() {
	cd "$PROJECT_DIR"

	# Check if logged in to Fly
	if ! fly auth whoami &>/dev/null; then
		print_warning "Not logged in to Fly.io"
		fly auth login
	fi

	print_status "Creating Fly.io app..."
	fly apps create "$FLY_APP_NAME" --org personal || {
		print_warning "App might already exist, continuing..."
	}

	print_status "Creating persistent volume..."
	fly volumes create dev_data --app "$FLY_APP_NAME" --region "$FLY_REGION" --size 50 -y || {
		print_warning "Volume might already exist, continuing..."
	}

	print_status "Setting Tailscale auth key..."
	fly secrets set TAILSCALE_AUTHKEY="$TAILSCALE_AUTHKEY" --app "$FLY_APP_NAME"

	print_status "Deploying to Fly.io (this may take a few minutes)..."
	fly deploy --app "$FLY_APP_NAME" --region "$FLY_REGION"

	print_status "Scaling instance..."
	fly scale count 1 --app "$FLY_APP_NAME"
	fly scale vm shared-cpu-1x --memory 2048 --app "$FLY_APP_NAME"

	cd ..
}

# Create shell aliases
create_aliases() {
	print_status "Creating shell aliases..."

	ALIAS_FILE=""
	if [ -f ~/.zshrc ]; then
		ALIAS_FILE=~/.zshrc
	elif [ -f ~/.bashrc ]; then
		ALIAS_FILE=~/.bashrc
	fi

	if [ -n "$ALIAS_FILE" ]; then
		cat >>"$ALIAS_FILE" <<EOF

# Fly.io dev environment aliases
alias fly-dev='~/dotfiles/connect-fly-dev.sh'
alias fly-code='~/dotfiles/connect-fly-code.sh'
alias fly-ssh='ssh developer@\$(tailscale status | grep "fly-dev-" | awk "{print \\\$1}")'
alias fly-logs='fly logs --app $FLY_APP_NAME'
alias fly-restart='fly apps restart $FLY_APP_NAME'
EOF
		print_success "Aliases added to $ALIAS_FILE"
		print_warning "Run 'source $ALIAS_FILE' to use aliases in current session"
	fi
}

# Main execution
main() {
	print_status "Starting Fly.io dev environment setup..."

	check_prerequisites
	get_user_inputs
	create_project
	deploy_to_fly
	create_aliases

	echo
	print_success "Setup complete! 🎉"
	echo
	print_status "Connection instructions:"
	echo "  1. Make sure Tailscale is running: tailscale status"
	echo "  2. Connect to terminal: ./connect-fly-dev.sh or 'fly-dev' (after sourcing shell)"
	echo "  3. Connect to code-server: ./connect-fly-code.sh or 'fly-code'"
	echo "  4. Direct SSH: ssh developer@<tailscale-ip>"
	echo
	print_status "Useful commands:"
	echo "  - View logs: fly logs --app $FLY_APP_NAME"
	echo "  - Restart: fly apps restart $FLY_APP_NAME"
	echo "  - SSH via Fly: fly ssh console --app $FLY_APP_NAME"
	echo "  - Scale down: fly scale count 0 --app $FLY_APP_NAME"
	echo "  - Scale up: fly scale count 1 --app $FLY_APP_NAME"
	echo
	print_warning "Note: It may take 1-2 minutes for Tailscale to connect after deployment"
}

# Run main function
main
