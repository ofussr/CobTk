# CobTk architecture

CobTk is a thin interoperability layer rather than a GUI renderer of its own.
Tk remains responsible for windows, native events, widget drawing, layout, and
theme integration.

## Layers

### 1. Application code

A GnuCOBOL application uses public entry points such as:

```text
CTK-INIT
CTK-LABEL
CTK-BUTTON
CTK-GRID
CTK-GET-TEXT
CTK-NEXT-EVENT
```

The application includes `copybooks/cobtk.cpy` for status constants and common
event-loop fields.

### 2. COBOL facade

`src/cobtk-api.cob` defines the public `ENTRY` points. It has two jobs:

- present COBOL-friendly call signatures;
- forward arguments to the C bridge using an explicit and predictable ABI.

The facade deliberately prevents application code from depending on the
internal C function names.

### 3. C bridge

`src/cobtk.c` embeds Tcl and Tk and translates public operations into Tcl object
commands.

The bridge owns:

- the `Tcl_Interp` instance;
- the current widget-ID allocator;
- the widget-type registry;
- the pending command event;
- conversion between explicit COBOL string lengths and Tcl objects.

Tk commands are constructed with `Tcl_Obj` values rather than concatenated Tcl
source strings. This avoids ordinary Tcl quoting problems for widget text.

### 4. Tcl/Tk

Tk and ttk create and manage the actual interface. The current bridge uses ttk
widgets for labels, buttons, entries, and checkbuttons, while root-window and
layout operations use normal Tk commands.

## Widget IDs

Application code never manipulates Tk path names directly. CobTk allocates an
integer ID and maps it to an internal path of the form:

```text
.ctk1
.ctk2
.ctk3
...
```

The C bridge keeps the widget type for each ID so operations such as
`CTK-GET-TEXT` can choose the correct Tk command for an `Entry` versus a widget
with a `-text` option.

The current registry contains 4096 slots and reserves ID `0`, giving a maximum
of 4095 allocated IDs during one runtime session. Destroyed IDs are invalidated
but are not yet recycled.

## Event flow

Buttons and checkbuttons receive an application-defined integer event ID during
creation.

For example:

```text
1. COBOL calls CTK-BUTTON with event ID 1001
2. the facade calls ctk_create_button
3. the C bridge creates a ttk::button
4. its Tk -command invokes the internal cobtk_emit command
5. the user clicks the button
6. Tk executes cobtk_emit 1001
7. the bridge stores event ID 1001
8. CTK-NEXT-EVENT returns to COBOL
9. the application handles 1001 in EVALUATE or other COBOL logic
```

This keeps application behavior in COBOL rather than requiring Tcl callback
scripts.

## Event loop

`ctk_next_event` repeatedly calls `Tcl_DoOneEvent(TCL_ALL_EVENTS)` until a CobTk
command event is emitted or no Tk windows remain.

The public API therefore exposes an event-polling model that fits ordinary
COBOL control flow:

```cobol
perform until CTK-RUNNING = CTK-FALSE
    call "CTK-NEXT-EVENT" ...
    evaluate CTK-EVENT
        ...
    end-evaluate
end-perform
```

This is intentionally different from attempting to reproduce callback objects,
closures, or language-specific constructs from Python GUI libraries.

## String boundary

COBOL fixed-width strings are not assumed to be NUL-terminated. CobTk therefore
passes every string as:

```text
address + explicit byte length
```

The C bridge creates Tcl string objects with that exact length. Text read back
from Tk is copied into a caller-supplied COBOL buffer, and the actual byte
length is returned separately.

The current public facade uses a 4096-byte linkage buffer and does not perform
code-page conversion. UTF-8 is therefore the intended text representation at
the Tcl boundary.

## Build model

The current Windows/MSYS2 build is intentionally minimal:

```text
src/cobtk.c
    -> GCC
    -> build/cobtk.o

application.cob + src/cobtk-api.cob + build/cobtk.o
    -> GnuCOBOL / GCC linker
    -> application.exe
```

Tcl/Tk include and linker flags come from:

```bash
pkg-config --cflags tk
pkg-config --libs tk
```

The bridge is currently linked directly into each executable. A future release
may provide a reusable shared library once the public ABI is stable enough to
make that worthwhile.

## Design direction

CobTk is not intended to duplicate Tk internally. The project should stay a
small COBOL-oriented layer over Tcl/Tk and expose additional Tk functionality
only where it can be represented cleanly in COBOL.

Likely future areas include:

- additional ttk widgets;
- richer `grid` and `pack` options;
- multiple top-level windows;
- keyboard and mouse bindings;
- timers;
- dialogs and menus;
- ttk styling and themes;
- a richer event structure than a single integer command ID;
- portable build support outside MSYS2 UCRT64.
