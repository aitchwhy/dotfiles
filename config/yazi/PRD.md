# Yazi Configuration Requirements

This document captures the requirements, preferences, and design principles for the Yazi file manager configuration.

## Core Requirements

### 1. Appearance and UI

- **Tokyo Night Theme**: Consistent Tokyo Night theming
- **Rounded Borders**: Use full-border plugin with rounded corners
- **Icons**: File type icons with proper rendering
- **Layout**: Three-pane layout (1 parent, 4 current, 3 preview)
- **Status Bar**: Informative status bar with path and file info
- **Color Coding**: Visual distinction for different file types
- **Preview Area**: Rich preview area with syntax highlighting

### 2. Performance

- **Fast Navigation**: Responsive file navigation
- **Quick Preview**: Fast file preview loading
- **Optimized Workers**: Configure workers for Apple Silicon (micro: 12, macro: 16)
- **Memory Efficiency**: Reasonable memory usage
- **Preview Limits**: Set file size limits for previews (5MB default)
- **Caching**: Effective use of caching for repeated operations

### 3. File Management

- **Operations**: Copy, move, delete, rename operations
- **Bulk Operations**: Support for bulk file operations
- **Archive Handling**: View and extract archives
- **Tag Support**: macOS tag integration with colors
- **Selection**: Multiple file selection with visual indicators
- **Sorting**: Multiple sort options (name, size, type, modified)
- **Filtering**: Quick filtering capabilities
- **Hidden Files**: Toggle for hidden files

### 4. Navigation

- **Directory Jumping**: Quick navigation to common directories
- **Vim-style**: Vim-inspired key bindings
- **Bookmarks**: Support for directory bookmarks
- **History**: Navigation history with forward/back
- **Jump to Char**: Fast navigation with character jumps
- **Project Management**: Project-based navigation

### 5. Integration

- **Neovim**: Seamless integration with Neovim for editing
- **Terminal**: Integration with Ghostty terminal
- **Git**: Git status information in file listings
- **Finder**: Integration with macOS Finder
- **VS Code**: Open files in VS Code when appropriate
- **macOS Tags**: Support for macOS file tagging

### 6. Preview

- **Code**: Syntax highlighting for code files
- **Images**: Image preview with scaling
- **Markdown**: Rendered markdown with glow
- **PDF**: PDF preview capabilities
- **Archives**: Preview archive contents
- **Rich Text**: Formatted preview for rich text
- **Binary**: Hexdump view for binary files

## Feature Requirements

### Essential Features

- **File Operations**: Basic file management operations
- **Navigation**: Intuitive directory navigation
- **Preview**: File content preview
- **Selection**: File selection mechanisms
- **Sorting**: Multiple sorting options
- **Filtering**: Quick file filtering
- **Search**: File search capabilities
- **Bookmarks**: Bookmark management

### Enhanced Features

- **macOS Tags**: Color-coded file tag support
- **Git Integration**: Show git status in file listings
- **Archive Management**: View and extract archives
- **Custom Openers**: Configurable file openers
- **Folder Rules**: Context-specific folder settings
- **Smart Jumping**: Intelligent directory jumping
- **Quick Copy**: Copy file contents without opening
- **Smart Paste**: Intelligent paste operations
- **File Stats**: Detailed file information

### Workflow Features

- **Projects**: Project management
- **Sessions**: Session persistence
- **History**: Navigation history
- **Batch Operations**: Bulk file operations
- **Command Mode**: Command-line interface within Yazi
- **Keyboard Shortcuts**: Comprehensive key bindings
- **Context Menus**: Right-click context menus

## Plugin Categories

1. **UI**: Visual enhancements (full-border)
2. **Navigation**: Movement aids (bunny, jump-to-char)
3. **Integration**: Tool integrations (starship, lazygit)
4. **Preview**: File preview enhancements (rich-preview)
5. **Management**: File management (smart-paste, copy-file-contents)
6. **Metadata**: File metadata (mactag, mime-ext)
7. **Organization**: File organization (folder-rules, projects)

## Key Mappings

- **Navigation**: hjkl (vim-style)
- **Open/Enter**: Enter
- **Back**: q
- **Select**: Space
- **Copy**: c
- **Cut**: x
- **Paste**: p
- **Delete**: d
- **Rename**: r
- **Create File**: a
- **Create Directory**: A
- **Search/Filter**: /
- **Sort**: z
- **Toggle Hidden**: .
- **Help**: ?

## Configuration Principles

1. **Defaults**: Good defaults that work out of the box
2. **Performance**: Optimize for responsiveness
3. **Consistency**: Consistent behavior with other tools
4. **Aesthetics**: Visual appeal with Tokyo Night theme
5. **Integration**: Seamless integration with the workflow
6. **Discoverability**: Easy to discover features
7. **Customization**: Easy to customize behavior

## Customization Areas

1. **Theme**: Visual appearance
2. **Layout**: Pane arrangement
3. **Keymaps**: Keyboard shortcuts
4. **Openers**: File opening behavior
5. **Previews**: Preview behavior
6. **Folder Rules**: Directory-specific settings