# vulpforth

a forth with some rather odd design decisions:

- no hidden behavior
  - no special treatment of variables, requires manually retrieving
    values from memory, ie `' here @` instead of `here`
- takes inspiration from:
  - [miniforth](https://github.com/meithecatte/miniforth)
    (dtc using `lods`, dedicating a register to the value at the top
    of the working stack)
  - [duskos](https://duskos.org/)
    (not following ans forth, outputting hex numbers)
  - someone cool on irc who enjoys being anonymous
    (the fancy technique to check for many bytes at once via
    multiplication and a bitmask)
- not an operating system
  - i like being able to run other applications
  - targets x86 linux
- no words for messing with the return stack
  - it is more dangerous than useful in my opinion
  - needlessly avoiding global variables is bad, actually
- operates on words, not lines
  - no line length limit, but can cause weird behavior
  - mostly because it was simpler to implement, i might change my mind
    about this one
- being fast is not a goal
  - it *is* decently fast because modern computers are fast, but
    will choose the simple/small/slow way over a faster but more
    complex way

## building

after installing `nasm`, build with

```sh
make vulpforth
```

or the (comparatively gigantic due to needing c) zipapp
debug binary with

```sh
git submodule update --init # if you have not already
make vulpforth.zip
```

note that zip includes modification times. if you care about
reproducible builds, run `files.zip` through something like
[strip-nondeterminism]. if you wish to squeeze out a smaller binary,
use musl libc and sstrip `vulpforthzip`. both of these should be done
*before* `vulpforthzip` and `files.zip` get concatenated into
`vulpforth.zip`. these steps are automatically done by the included
flake's `zip` output.

[strip-nondeterminism]: https://salsa.debian.org/reproducible-builds/strip-nondeterminism
