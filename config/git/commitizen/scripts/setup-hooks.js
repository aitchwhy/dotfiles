// setup-hooks.js
const fs = require('fs');
const path = require('path');
const {execSync} = require('child_process');

/**
 * Setup husky hooks and copy commitlint config to root
 */
function setupHooks() {
  console.log('Setting up git hooks and commitlint configuration...');
  
  try {
    // Create husky directory if it doesn't exist
    const huskyDir = path.resolve(__dirname, '..', '..', '..', '..', '.husky');
    if (!fs.existsSync(huskyDir)) {
      fs.mkdirSync(huskyDir, {recursive: true});
      console.log(`Created directory: ${huskyDir}`);
    }
    
    // Create commit-msg hook for commitlint
    const commitMsgHookPath = path.join(huskyDir, 'commit-msg');
    const commitMsgContent = `#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

npx --no-install commitlint --edit $1
`;
    fs.writeFileSync(commitMsgHookPath, commitMsgContent);
    fs.chmodSync(commitMsgHookPath, 0o755);
    console.log(`Created commit-msg hook at ${commitMsgHookPath}`);
    
    // Create pre-commit hook for lint-staged
    const preCommitHookPath = path.join(huskyDir, 'pre-commit');
    const preCommitContent = `#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

npx --no-install lint-staged
`;
    fs.writeFileSync(preCommitHookPath, preCommitContent);
    fs.chmodSync(preCommitHookPath, 0o755);
    console.log(`Created pre-commit hook at ${preCommitHookPath}`);
    
    // Copy commitlint.config.js to dotfiles root
    const commitlintConfig = path.resolve(__dirname, '..', 'commitlint.config.js');
    const rootCommitlintConfig = path.resolve(__dirname, '..', '..', '..', '..', 'commitlint.config.js');
    fs.copyFileSync(commitlintConfig, rootCommitlintConfig);
    console.log(`Copied commitlint config to ${rootCommitlintConfig}`);
    
    // Update git config to use hooks
    execSync('git config --global core.hooksPath .husky');
    console.log('Updated git config to use .husky hooks directory');
    
    console.log('Hooks setup complete! 🎉');
  } catch (error) {
    console.error('Error setting up hooks:', error);
    process.exit(1);
  }
}

setupHooks();