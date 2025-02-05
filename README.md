# vulpforth

a forth with some rather odd design decisions:

- 3926 bytes (hehe funny number)
- fully explicit
  - no special treatment of variables, requires manually retrieving
    values from memory, ie `' here @` instead of `here`
  - words that step on your toes (if/then/else, begin/until) are
    kept out of the core words (those are in [extra.vf](./extra.vf))
  - no doer/does>
- takes inspiration from:
  - [breadbox's teensy elf files](https://www.muppetlabs.com/~breadbox/software/tiny/teensy.html)
    (squishing the elf header together like that)
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
- being fast is not a goal
  - it *is* decently fast because modern computers are fast, but
    will choose the simple/small/slow way over a faster but more
    complex way

## building

after installing `nasm`, build the release binary with

```sh
make vulpforth.bin
```

or the (much larger) linked debug binary with

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
[strip-nondeterminism]. there is also no release counterpart for the
zipapp since the debug symbols are inconsequential compared to the
size of statically including libc. however, if you wish to squeeze out
a smaller binary, use musl libc and sstrip `vulpforthzip`. both of
these should be done *before* `vulpforthzip` and `files.zip` get
concatenated into `vulpforth.zip`. these steps are automatically done
by the included flake.

[strip-nondeterminism]: https://salsa.debian.org/reproducible-builds/strip-nondeterminism
