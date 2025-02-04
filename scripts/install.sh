
#####################
# uv (python) - https://docs.astral.sh/uv/getting-started/installation/#standalone-installer
#####################
curl -LsSf https://astral.sh/uv/install.sh | sh


#####################
# ruff (python linter) - https://docs.astral.sh/ruff/
#####################

# Install Ruff globally.
uv tool install ruff@latest

# Or add Ruff to your project.
# uv add --dev ruff