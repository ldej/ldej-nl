---
title: "EditorConfig helps maintain consistent coding styles"
date: 2020-07-22T12:00:39+05:30
source: "https://editorconfig.org/"
tags:
- IDE
---

You can configure the end-of-line and indentation styles for different file type in a `.editorconfig` file. Example:
```ini
root = true

[*.go]
indent_style = tab
indent_size = 4

[Makefile]
indent_style = tab
```
Works automatically in IntelliJ Idea, requires a plugin for Atom, Sublime and VS Code.