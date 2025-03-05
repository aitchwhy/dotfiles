# Development Cheatsheets

Quick reference sheets for common tools, languages, and workflows.

## Terminal Commands

### File Operations

| Command | Description |
|---------|-------------|
| `ls -la` | List all files with details |
| `find . -name "pattern"` | Find files matching pattern |
| `rg "pattern" --type=js` | Search for text in JavaScript files |
| `fd -e md` | Find all markdown files |
| `cp -r source/ dest/` | Copy directory recursively |
| `chmod +x filename` | Make file executable |
| `chown user:group file` | Change file ownership |

### Process Management

| Command | Description |
|---------|-------------|
| `ps aux` | List all running processes |
| `kill -9 PID` | Force kill process by ID |
| `pkill -f "pattern"` | Kill processes matching pattern |
| `lsof -i :3000` | Show process using port 3000 |
| `nohup command &` | Run command immune to hangups |
| `command &` | Run command in background |
| `jobs` | List background jobs |
| `fg %1` | Bring job 1 to foreground |

### Disk & Performance

| Command | Description |
|---------|-------------|
| `df -h` | Show disk usage |
| `du -sh *` | Show size of files/directories |
| `ncdu` | Interactive disk usage analyzer |
| `htop` | Interactive process viewer |
| `iostat` | CPU and disk I/O stats |
| `vmstat` | Virtual memory statistics |
| `free -h` | Display memory usage |

## Git Quick Reference

### Common Operations

| Command | Description |
|---------|-------------|
| `git init` | Initialize new repository |
| `git clone URL` | Clone repository |
| `git add .` | Stage all changes |
| `git commit -m "message"` | Commit staged changes |
| `git push origin branch` | Push to remote |
| `git pull origin branch` | Pull from remote |
| `git checkout -b newbranch` | Create and switch to new branch |
| `git merge branch` | Merge branch into current branch |
| `git stash` | Stash changes |
| `git stash pop` | Apply stashed changes |

### Advanced Operations

| Command | Description |
|---------|-------------|
| `git rebase -i HEAD~3` | Interactive rebase of last 3 commits |
| `git cherry-pick SHA` | Apply commit from another branch |
| `git reset --soft HEAD~1` | Undo last commit, keep changes staged |
| `git reset --hard HEAD~1` | Undo last commit, discard changes |
| `git reflog` | Show history of HEAD changes |
| `git bisect start/good/bad` | Binary search for bug introduction |
| `git worktree add ../path branch` | Create linked working tree |

## Homebrew Quick Reference

| Command | Description |
|---------|-------------|
| `brew install package` | Install package |
| `brew uninstall package` | Uninstall package |
| `brew update` | Update Homebrew |
| `brew upgrade` | Upgrade all packages |
| `brew upgrade package` | Upgrade specific package |
| `brew list` | List installed packages |
| `brew info package` | Show package info |
| `brew doctor` | Check system for issues |
| `brew cleanup` | Remove old versions |

## Nix Quick Reference

| Command | Description |
|---------|-------------|
| `nix-env -i package` | Install package |
| `nix-env -e package` | Uninstall package |
| `nix-env -q` | List installed packages |
| `nix-env -u` | Upgrade packages |
| `nix-channel --update` | Update channels |
| `nix-shell -p package` | Start shell with package |
| `nix-collect-garbage -d` | Delete old generations |
| `nix-store --gc` | Garbage collection |
| `nix flake update` | Update flake inputs |

## Python Quick Reference

### Virtual Environments (uv)

| Command | Description |
|---------|-------------|
| `uv venv .venv` | Create virtual environment |
| `source .venv/bin/activate` | Activate environment |
| `deactivate` | Deactivate environment |
| `uv pip install -r requirements.txt` | Install requirements |
| `uv pip freeze > requirements.txt` | Save requirements |
| `uv pip install -e .` | Install package in development mode |
| `uv pip list` | List installed packages |

### Common Libraries

| Library | Use Case |
|---------|----------|
| `requests` | HTTP requests |
| `pandas` | Data analysis |
| `numpy` | Numerical computing |
| `matplotlib` | Data visualization |
| `pytest` | Testing |
| `pydantic` | Data validation |
| `black` | Code formatting |
| `ruff` | Fast linting |

## TypeScript/Node.js Quick Reference

### NPM/Yarn Commands

| Command | Description |
|---------|-------------|
| `npm init` | Initialize new project |
| `npm install` | Install dependencies |
| `npm install package` | Install package |
| `npm install -D package` | Install dev dependency |
| `npm run script` | Run script from package.json |
| `npm update` | Update packages |
| `npm list` | List installed packages |
| `npm outdated` | Check for outdated packages |

### Common Libraries

| Library | Use Case |
|---------|----------|
| `express` | Web server |
| `react` | UI library |
| `next.js` | React framework |
| `lodash` | Utility functions |
| `axios` | HTTP client |
| `jest` | Testing |
| `typescript` | Type checking |
| `eslint` | Linting |
| `prettier` | Code formatting |

## Rust Quick Reference

### Cargo Commands

| Command | Description |
|---------|-------------|
| `cargo new project` | Create new project |
| `cargo build` | Build project |
| `cargo run` | Build and run project |
| `cargo test` | Run tests |
| `cargo check` | Check for errors without building |
| `cargo update` | Update dependencies |
| `cargo doc --open` | Generate and open documentation |
| `cargo add crate` | Add dependency |
| `cargo fmt` | Format code |
| `cargo clippy` | Advanced linting |

### Common Crates

| Crate | Use Case |
|-------|----------|
| `serde` | Serialization/deserialization |
| `tokio` | Async runtime |
| `reqwest` | HTTP client |
| `clap` | Command line parsing |
| `rocket` | Web framework |
| `diesel` | ORM and query builder |
| `rayon` | Parallel computing |
| `anyhow` | Error handling |

## Regular Expressions

### Common Patterns

| Pattern | Matches |
|---------|---------|
| `^` | Start of line |
| `$` | End of line |
| `.` | Any single character |
| `\d` | Any digit |
| `\w` | Any word character (letter, number, underscore) |
| `\s` | Any whitespace character |
| `[abc]` | Any character in the set |
| `[^abc]` | Any character not in the set |
| `a*` | Zero or more occurrences of a |
| `a+` | One or more occurrences of a |
| `a?` | Zero or one occurrence of a |
| `a{n}` | Exactly n occurrences of a |
| `a{n,}` | n or more occurrences of a |
| `a{n,m}` | Between n and m occurrences of a |

### Useful Examples

| Expression | Purpose |
|------------|---------|
| `^\d{3}-\d{3}-\d{4}$` | US phone number (123-456-7890) |
| `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$` | Email address |
| `^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$` | URL |
| `^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$` | Password (min 8 chars, one letter, one number) |
| `<!--.*?-->` | HTML comment |
| `\/\*[\s\S]*?\*\/` | C-style comment |
