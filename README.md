# CobTk

CobTk is an experimental Tcl/Tk GUI binding for GnuCOBOL. It exposes a small
COBOL-facing API for creating native Tk widgets, arranging them, reading and
changing their values, and receiving GUI events without requiring application
code to contain Tcl scripts.

CobTk is currently an early-stage library. The existing implementation has been
tested on Windows with MSYS2 UCRT64, GnuCOBOL, GCC, and Tk. The public API is
still expected to change while more widgets, layout options, and event types are
added.

## How it works

CobTk is deliberately split into layers:

```text
GnuCOBOL application
        |
        v
CobTk COBOL API
(src/cobtk-api.cob + copybooks/cobtk.cpy)
        |
        v
C bridge
(src/cobtk.c)
        |
        v
Tcl interpreter + Tk / ttk
        |
        v
Native window system
```

Application code calls COBOL entry points such as `CTK-BUTTON`, `CTK-GRID`, and
`CTK-NEXT-EVENT`. The COBOL facade forwards those requests to a small C bridge,
which embeds Tcl/Tk and translates between COBOL data and Tk commands.

The application therefore does not need to construct Tcl commands itself. GUI
events travel in the opposite direction: Tk invokes the bridge, the bridge
returns an application-defined event ID, and the COBOL program handles that ID
with ordinary COBOL control flow.

## Current features

The current implementation provides:

- root-window title, size, and resizability;
- `ttk::label`;
- `ttk::button` with application-defined event IDs;
- `ttk::entry`;
- `ttk::checkbutton` with application-defined event IDs;
- `pack` layout with default padding;
- `grid` layout with row and column selection;
- reading and changing widget text;
- reading and changing checkbutton state;
- enabling and disabling widgets;
- assigning keyboard focus;
- destroying individual widgets;
- blocking event retrieval from COBOL;
- retrieval of the current Tcl/Tk error result;
- explicit shutdown of the embedded interpreter.

See [`API.md`](API.md) for the current call signatures and status codes.

## Requirements

The tested development environment is:

- Windows 10 or Windows 11;
- MSYS2 using the **UCRT64** environment;
- GnuCOBOL;
- GCC;
- Tcl/Tk;
- `pkg-config` / `pkgconf`.

The bridge itself uses standard Tcl/Tk APIs, but the supplied build script is
currently written specifically for MSYS2 UCRT64. Other platforms have not yet
been validated.

## Installation on Windows

Install [MSYS2](https://www.msys2.org/) and open the **MSYS2 UCRT64** terminal.
Do not use the plain MSYS shell or the MINGW64 shell for the commands below.

Update the package database and installed packages:

```bash
pacman -Syu
```

If MSYS2 asks you to close the terminal during the update, reopen **MSYS2
UCRT64** and run the same command again.

Install the required packages:

```bash
pacman -S \
    mingw-w64-ucrt-x86_64-gcc \
    mingw-w64-ucrt-x86_64-gnucobol \
    mingw-w64-ucrt-x86_64-tk \
    mingw-w64-ucrt-x86_64-pkgconf
```

You can verify the toolchain with:

```bash
cobc -V
gcc --version
pkg-config --modversion tk
```

To verify Tk independently, run:

```bash
wish
```

A small Tk window should open.

## Building CobTk and the examples

Clone or download the repository, then enter its root directory from the
**MSYS2 UCRT64** terminal.

The supplied script builds the C bridge and both example applications:

```bash
./build.sh
```

The script also sets the GnuCOBOL paths required by the current MSYS2 package,
so no manual `cobenv.sh` step is required.

A successful build produces:

```text
build/demo.exe
build/widgets.exe
```

Run the minimal example with:

```bash
./build/demo.exe
```

Run the extended widget example with:

```bash
./build/widgets.exe
```

## Quick start

A CobTk program normally includes the public copybook, initializes the runtime,
creates widgets, places them, and then waits for events.

The following shortened example shows the basic pattern:

```cobol
identification division.
program-id. HELLO-COBTK.

data division.
working-storage section.

copy "cobtk.cpy".

01 LABEL-ID       pic s9(9) comp-5 value 0.
01 BUTTON-ID      pic s9(9) comp-5 value 0.
01 BUTTON-EVENT   pic s9(9) comp-5 value 1001.

01 LABEL-TEXT     pic x(21) value "Hello from COBOL + Tk".
01 LABEL-LENGTH   pic s9(9) comp-5 value 21.
01 BUTTON-TEXT    pic x(8) value "Click me".
01 BUTTON-LENGTH  pic s9(9) comp-5 value 8.

procedure division.

    call "CTK-INIT"
        using by reference CTK-STATUS
    end-call

    call "CTK-LABEL"
        using
            by reference LABEL-TEXT
            by value     LABEL-LENGTH
            by reference LABEL-ID
            by reference CTK-STATUS
    end-call

    call "CTK-PACK"
        using
            by value     LABEL-ID
            by reference CTK-STATUS
    end-call

    call "CTK-BUTTON"
        using
            by reference BUTTON-TEXT
            by value     BUTTON-LENGTH
            by value     BUTTON-EVENT
            by reference BUTTON-ID
            by reference CTK-STATUS
    end-call

    call "CTK-PACK"
        using
            by value     BUTTON-ID
            by reference CTK-STATUS
    end-call

    perform until CTK-RUNNING = CTK-FALSE
        call "CTK-NEXT-EVENT"
            using
                by reference CTK-EVENT
                by reference CTK-RUNNING
        end-call

        if CTK-RUNNING = CTK-TRUE
            evaluate CTK-EVENT
                when 1001
                    display "The button was clicked."
                when other
                    continue
            end-evaluate
        end-if
    end-perform

    call "CTK-SHUTDOWN"
    end-call

    stop run.
```

The complete working version is in [`examples/demo.cob`](examples/demo.cob).

## Event model

CobTk does not attempt to imitate Python callbacks or closures. Widgets that
produce command events receive an integer event ID when they are created.
`CTK-NEXT-EVENT` blocks until either an event is available or the last Tk window
has been closed.

A typical COBOL event loop is therefore:

```cobol
perform until CTK-RUNNING = CTK-FALSE

    call "CTK-NEXT-EVENT"
        using
            by reference CTK-EVENT
            by reference CTK-RUNNING
    end-call

    if CTK-RUNNING = CTK-TRUE
        evaluate CTK-EVENT
            when 1001
                perform COPY-TEXT
            when 1002
                perform CLEAR-TEXT
            when 1003
                perform UPDATE-STATE
            when other
                continue
        end-evaluate
    end-if

end-perform
```

The event number is application-defined. `0` is also a valid event ID.

## Text handling

CobTk passes text together with an explicit byte length instead of relying on
NUL-terminated strings. This is important because fixed-width COBOL strings are
not C strings.

For example:

```cobol
01 TITLE-TEXT    pic x(12) value "CobTk window".
01 TITLE-LENGTH  pic s9(9) comp-5 value 12.

call "CTK-TITLE"
    using
        by reference TITLE-TEXT
        by value     TITLE-LENGTH
        by reference CTK-STATUS
end-call
```

When reading text, the caller supplies a buffer capacity and receives the
actual byte length:

```cobol
01 TEXT-BUFFER      pic x(256) value spaces.
01 TEXT-CAPACITY    pic s9(9) comp-5 value 256.
01 TEXT-LENGTH      pic s9(9) comp-5 value 0.

call "CTK-GET-TEXT"
    using
        by value     ENTRY-ID
        by reference TEXT-BUFFER
        by value     TEXT-CAPACITY
        by reference TEXT-LENGTH
        by reference CTK-STATUS
end-call
```

If the buffer is too small, `CTK-STATUS` is set to
`CTK-BUFFER-TOO-SMALL` and the required length is still returned.

Text passed to Tcl/Tk is expected to be UTF-8. CobTk does not currently perform
character-set conversion for COBOL source or runtime code pages.

## Layout

CobTk currently exposes two simple layout operations.

`CTK-PACK` uses fixed default padding and is convenient for small linear
interfaces:

```cobol
call "CTK-PACK"
    using
        by value     BUTTON-ID
        by reference CTK-STATUS
end-call
```

`CTK-GRID` places a widget at a zero-based row and column, also with fixed
default padding:

```cobol
call "CTK-GRID"
    using
        by value     ENTRY-ID
        by value     ROW-NUMBER
        by value     COLUMN-NUMBER
        by reference CTK-STATUS
end-call
```

Fine-grained `pack` and `grid` options are not exposed yet.

## Building your own application

`build.sh` is intentionally simple and currently builds the two examples. A
separate application can be linked against the same source files with the same
pattern.

First build the bridge:

```bash
gcc \
    -Wall \
    -Wextra \
    -O2 \
    -c src/cobtk.c \
    -o build/cobtk.o \
    $(pkg-config --cflags tk)
```

Then compile your COBOL program together with the CobTk COBOL facade and C
object:

```bash
cobc \
    -x \
    -free \
    -I copybooks \
    path/to/your-program.cob \
    src/cobtk-api.cob \
    build/cobtk.o \
    $(pkg-config --libs tk) \
    -o build/your-program.exe
```

Under MSYS2, use the same GnuCOBOL environment variables as `build.sh` before
running the manual `cobc` command.

## Examples

### `examples/demo.cob`

The smallest end-to-end example. It creates a label and a button. Pressing the
button generates an event that returns to COBOL, where the label text is
changed through CobTk.

This demonstrates the full round trip:

```text
COBOL -> CobTk -> Tk -> user input -> CobTk -> COBOL -> CobTk -> Tk
```

### `examples/widgets.cob`

A larger demonstration containing:

- a text entry;
- a checkbutton;
- two buttons;
- labels;
- grid layout;
- text retrieval and modification;
- widget enable/disable state;
- focus control;
- multiple event IDs.

## Project structure

```text
cobtk/
|-- build.sh
|-- copybooks/
|   `-- cobtk.cpy
|-- examples/
|   |-- demo.cob
|   `-- widgets.cob
|-- src/
|   |-- cobtk-api.cob
|   `-- cobtk.c
|-- API.md
|-- ARCHITECTURE.md
|-- LICENSE
`-- README.md
```

`copybooks/cobtk.cpy` contains public constants and common state variables.
`src/cobtk-api.cob` is the public COBOL-facing facade. `src/cobtk.c` owns the
embedded Tcl interpreter, widget registry, and translation to Tk commands.

## Error handling

Most public operations receive `CTK-STATUS` by reference.

Current status constants are:

| Constant | Value | Meaning |
| --- | ---: | --- |
| `CTK-OK` | 0 | Operation succeeded |
| `CTK-ERROR` | 1 | Generic error |
| `CTK-BUFFER-TOO-SMALL` | 2 | Caller-provided output buffer is too small |

`CTK-LAST-ERROR` copies the current Tcl interpreter result into a caller-provided
buffer. At this stage, not every CobTk-side validation failure sets a dedicated
human-readable Tcl error message, so this function should be treated as a
diagnostic aid rather than a complete exception system.

## Current limitations

CobTk is still experimental. Important current limitations include:

- only one root window is exposed;
- only `Label`, `Button`, `Entry`, and `Checkbutton` are implemented;
- `pack` and `grid` expose only a small subset of Tk layout options;
- there are no menus, dialogs, list widgets, text areas, canvases, images,
  notebooks, tree views, scrollbars, or additional top-level windows yet;
- keyboard, mouse, focus, timer, and arbitrary Tk bindings are not yet exposed;
- styling and ttk themes are not yet exposed;
- widget IDs are allocated monotonically and are not reused after destruction;
- the current registry can represent at most 4095 allocated widget IDs during
  one runtime session;
- public text arguments pass through a 4096-byte COBOL linkage buffer;
- text is expected to be UTF-8 and no code-page conversion is performed;
- the supplied build script is currently Windows/MSYS2 UCRT64-specific;
- Linux and macOS builds have not yet been validated;
- the API should be considered unstable until the widget and event model has
  matured.

## Documentation

- [`API.md`](API.md) — public calls, parameters, and status codes;
- [`ARCHITECTURE.md`](ARCHITECTURE.md) — implementation layers and event flow;
- [`examples/demo.cob`](examples/demo.cob) — minimal example;
- [`examples/widgets.cob`](examples/widgets.cob) — extended widget example.

## License

CobTk is distributed under the MIT License. See [`LICENSE`](LICENSE) for the
full license text.

Copyright (c) 2026 Mikhail Mirushchenko.
