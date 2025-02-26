# Ghostty

- <https://ghostty.org/docs/config#macos-specific-path-(macos-only)>:

```
Offline Reference Documentation

There are multiple places to find documentation on the configuration options besides the website. All locations are identical (they're all generated from the same source).

    Tip

    The online reference documentation is available here.

    There are HTML and Markdown formatted docs in the $prefix/share/ghostty/docs directory. This directory is created when you build or install Ghostty. The $prefix is zig-out if you're building from source (or the specified --prefix flag). On macOS, $prefix is the Contents/Resources subdirectory of the .app bundle.

    There are man pages in the $prefix/share/man directory. This directory is created when you build or install Ghostty.

    In the CLI, you can run ghostty +show-config --default --docs. Note that this will output the full default configuration with docs to stdout, so you may want to pipe that through a pager, an editor, etc.

    In the source code, you can find the configuration structure in the Config structure. The available keys are the keys verbatim, and their possible values are typically documented in the comments.

    Not documentation per se, but you can search for the public config files of many Ghostty users for examples and inspiration.

```
