#!/usr/bin/env zsh

function code_uninstall() {
  # List of extension IDs to uninstall each one
  extensions=(
    "GitHub.github-vscode-theme"
    "GraphQL.vscode-graphql"
    "GraphQL.vscode-graphql-syntax"
    "johnpapa.vscode-peacock"
    "heybourn.headwind"
    "bradlc.vscode-tailwindcss"
    "ms-vscode.vscode-typescript-tslint-plugin"
    "dsznajder.es7-react-js-snippets"
    "ms-python.python"
    "ms-python.vscode-pylance"
    "ritwickdey.LiveServer"
    "esbenp.prettier-vscode"
    "dbaeumer.vscode-eslint"
    "formulahendry.code-runner"
    "PKief.material-icon-theme"
    "dracula-theme.theme-dracula"
    "ms-vscode-remote.remote-wsl"
    "ms-azuretools.vscode-docker"
    "eamodio.gitlens"
    "vscodevim.vim"
  )

  for ext in "${extensions[@]}"; do
    echo "Uninstalling $ext"
    void --uninstall-extension "$ext"
  done
}


code_uninstall
