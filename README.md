# dotfiles

Run `init.bash` to run all commands for all sections inside the [dots](./dots) folder.

## Sections

> A group of files or directories and commands to patch them into the user's `$HOME`.

To add a new section, create a new folder inside [./dots](./dots):

```sh
mkdir dots/bash
```

Now, all of the commands added to this section will be run by the repo's `init.bash` script.

## Command Execution

Commands are executed in the following order:

1. For all sections...
    1. dir
    2. link

## Commands

### `dir`

> Ensure the specified directory exists in `$HOME`.

|||
|-|-|
| **File extension** | dir |
| **File contents** | `dirname` |

To create a `dir` command for some section `foo` to create `~/.config/foo`:

```sh
mkdir -p dots/foo
echo "~/.config/foo" > dots/foo/conf.dir
```

### `link`

> Link the target somewhere in `$HOME`.

|||
|-|-|
| **File extension** | link |
| **File contents** | `target->linkname` |

To create a `link` command for some section `bash` to create a symlink for `.bashrc`:

```sh
mkdir -p dots/bash
touch dots/bash/bashrc
echo "bashrc->~/.bashrc" > dots/bash/conf.link
```
