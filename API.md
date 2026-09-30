# CobTk API reference

This document describes the current experimental COBOL-facing API implemented
by `src/cobtk-api.cob`.

The interface is not yet frozen. All integer values shown below use the same
representation as the public implementation:

```cobol
PIC S9(9) COMP-5
```

String arguments are passed by reference together with an explicit byte length.
Unless noted otherwise, `STATUS` is returned by reference and should be compared
with the constants from `copybooks/cobtk.cpy`.

## Public constants

```cobol
78 CTK-OK                 VALUE 0.
78 CTK-ERROR              VALUE 1.
78 CTK-BUFFER-TOO-SMALL   VALUE 2.

78 CTK-FALSE              VALUE 0.
78 CTK-TRUE               VALUE 1.
```

The copybook also declares the common event-loop variables:

```cobol
01 CTK-STATUS   PIC S9(9) COMP-5 VALUE 0.
01 CTK-RUNNING  PIC S9(9) COMP-5 VALUE 1.
01 CTK-EVENT    PIC S9(9) COMP-5 VALUE 0.
```

## Runtime

### `CTK-INIT`

Initializes the embedded Tcl interpreter, initializes Tk, registers the internal
CobTk event command, and resets the widget registry.

```cobol
call "CTK-INIT"
    using
        by reference CTK-STATUS
end-call
```

Call this before every other CobTk operation.

### `CTK-SHUTDOWN`

Deletes the embedded Tcl interpreter and resets CobTk runtime state.

```cobol
call "CTK-SHUTDOWN"
end-call
```

## Root-window operations

### `CTK-TITLE`

Sets the title of the Tk root window.

Parameters:

1. text buffer — `BY REFERENCE`;
2. text length in bytes — `BY VALUE`;
3. status — `BY REFERENCE`.

```cobol
call "CTK-TITLE"
    using
        by reference TITLE-TEXT
        by value     TITLE-LENGTH
        by reference CTK-STATUS
end-call
```

### `CTK-WINDOW-SIZE`

Sets the root-window client geometry to `WIDTH x HEIGHT`.

Parameters:

1. width — `BY VALUE`;
2. height — `BY VALUE`;
3. status — `BY REFERENCE`.

Both dimensions must be positive.

```cobol
call "CTK-WINDOW-SIZE"
    using
        by value     WINDOW-WIDTH
        by value     WINDOW-HEIGHT
        by reference CTK-STATUS
end-call
```

### `CTK-RESIZABLE`

Controls whether the root window can be resized horizontally and vertically.
Any non-zero value is treated as true.

Parameters:

1. horizontal flag — `BY VALUE`;
2. vertical flag — `BY VALUE`;
3. status — `BY REFERENCE`.

```cobol
call "CTK-RESIZABLE"
    using
        by value     CTK-TRUE
        by value     CTK-FALSE
        by reference CTK-STATUS
end-call
```

## Widget creation

Widget creation calls return an integer widget ID through a caller-provided
variable. A valid ID is greater than zero.

### `CTK-LABEL`

Creates a `ttk::label`.

Parameters:

1. initial text — `BY REFERENCE`;
2. text length — `BY VALUE`;
3. output widget ID — `BY REFERENCE`;
4. status — `BY REFERENCE`.

```cobol
call "CTK-LABEL"
    using
        by reference LABEL-TEXT
        by value     LABEL-LENGTH
        by reference LABEL-ID
        by reference CTK-STATUS
end-call
```

### `CTK-BUTTON`

Creates a `ttk::button`. Pressing the button emits the supplied event ID.

Parameters:

1. button text — `BY REFERENCE`;
2. text length — `BY VALUE`;
3. event ID — `BY VALUE`;
4. output widget ID — `BY REFERENCE`;
5. status — `BY REFERENCE`.

```cobol
call "CTK-BUTTON"
    using
        by reference BUTTON-TEXT
        by value     BUTTON-LENGTH
        by value     BUTTON-EVENT
        by reference BUTTON-ID
        by reference CTK-STATUS
end-call
```

The event ID is application-defined. `0` is valid.

### `CTK-ENTRY`

Creates a `ttk::entry` and optionally inserts initial text.

Parameters:

1. initial text — `BY REFERENCE`;
2. text length — `BY VALUE`;
3. output widget ID — `BY REFERENCE`;
4. status — `BY REFERENCE`.

```cobol
call "CTK-ENTRY"
    using
        by reference ENTRY-TEXT
        by value     ENTRY-LENGTH
        by reference ENTRY-ID
        by reference CTK-STATUS
end-call
```

A length of zero creates an empty entry.

### `CTK-CHECKBUTTON`

Creates a `ttk::checkbutton`. Changing it emits the supplied event ID.

Parameters:

1. widget text — `BY REFERENCE`;
2. text length — `BY VALUE`;
3. event ID — `BY VALUE`;
4. output widget ID — `BY REFERENCE`;
5. status — `BY REFERENCE`.

```cobol
call "CTK-CHECKBUTTON"
    using
        by reference CHECK-TEXT
        by value     CHECK-LENGTH
        by value     CHECK-EVENT
        by reference CHECK-ID
        by reference CTK-STATUS
end-call
```

## Layout

### `CTK-PACK`

Places an existing widget with Tk `pack` using CobTk's current default padding.

Parameters:

1. widget ID — `BY VALUE`;
2. status — `BY REFERENCE`.

```cobol
call "CTK-PACK"
    using
        by value     BUTTON-ID
        by reference CTK-STATUS
end-call
```

Current padding is fixed at 12 horizontal and 8 vertical pixels.

### `CTK-GRID`

Places an existing widget with Tk `grid`.

Parameters:

1. widget ID — `BY VALUE`;
2. zero-based row — `BY VALUE`;
3. zero-based column — `BY VALUE`;
4. status — `BY REFERENCE`.

```cobol
call "CTK-GRID"
    using
        by value     ENTRY-ID
        by value     ROW-NUMBER
        by value     COLUMN-NUMBER
        by reference CTK-STATUS
end-call
```

Negative row or column values are rejected. Current padding is fixed at 8
horizontal and 6 vertical pixels.

## Text and values

### `CTK-SET-TEXT`

Changes a widget's text. For an `Entry`, the current contents are deleted and
replaced. For the other implemented widget types, the Tk `-text` option is
updated.

Parameters:

1. widget ID — `BY VALUE`;
2. text buffer — `BY REFERENCE`;
3. text length — `BY VALUE`;
4. status — `BY REFERENCE`.

```cobol
call "CTK-SET-TEXT"
    using
        by value     LABEL-ID
        by reference NEW-TEXT
        by value     NEW-TEXT-LENGTH
        by reference CTK-STATUS
end-call
```

A text length of zero clears an `Entry` and supplies an empty string to other
widget types.

### `CTK-GET-TEXT`

Reads a widget's current text into a caller-provided buffer.

Parameters:

1. widget ID — `BY VALUE`;
2. output buffer — `BY REFERENCE`;
3. buffer capacity in bytes — `BY VALUE`;
4. output text length — `BY REFERENCE`;
5. status — `BY REFERENCE`.

```cobol
call "CTK-GET-TEXT"
    using
        by value     ENTRY-ID
        by reference TEXT-BUFFER
        by value     TEXT-CAPACITY
        by reference TEXT-LENGTH
        by reference CTK-STATUS
end-call
```

For an `Entry`, CobTk uses the widget's `get` command. For the other current
widget types, it reads the `-text` option.

If the output buffer is too small, status is `CTK-BUFFER-TOO-SMALL` and
`TEXT-LENGTH` still receives the required byte length.

### `CTK-SET-CHECKED`

Sets the selected state of a checkbutton.

Parameters:

1. checkbutton widget ID — `BY VALUE`;
2. selected flag — `BY VALUE`;
3. status — `BY REFERENCE`.

Any non-zero value selects the checkbutton.

```cobol
call "CTK-SET-CHECKED"
    using
        by value     CHECK-ID
        by value     CTK-TRUE
        by reference CTK-STATUS
end-call
```

### `CTK-GET-CHECKED`

Reads the selected state of a checkbutton.

Parameters:

1. checkbutton widget ID — `BY VALUE`;
2. output selected flag — `BY REFERENCE`;
3. status — `BY REFERENCE`.

```cobol
call "CTK-GET-CHECKED"
    using
        by value     CHECK-ID
        by reference CHECKED-VALUE
        by reference CTK-STATUS
end-call
```

The returned value is `0` or `1`.

## Widget state and lifetime

### `CTK-SET-ENABLED`

Enables or disables a widget using ttk state.

Parameters:

1. widget ID — `BY VALUE`;
2. enabled flag — `BY VALUE`;
3. status — `BY REFERENCE`.

```cobol
call "CTK-SET-ENABLED"
    using
        by value     BUTTON-ID
        by value     CTK-FALSE
        by reference CTK-STATUS
end-call
```

### `CTK-FOCUS`

Moves keyboard focus to a widget.

Parameters:

1. widget ID — `BY VALUE`;
2. status — `BY REFERENCE`.

```cobol
call "CTK-FOCUS"
    using
        by value     ENTRY-ID
        by reference CTK-STATUS
end-call
```

### `CTK-DESTROY`

Destroys a widget and invalidates its CobTk widget ID.

Parameters:

1. widget ID — `BY VALUE`;
2. status — `BY REFERENCE`.

```cobol
call "CTK-DESTROY"
    using
        by value     LABEL-ID
        by reference CTK-STATUS
end-call
```

Destroyed IDs are not currently reused during the same CobTk runtime session.

## Events

### `CTK-NEXT-EVENT`

Blocks while Tk processes its native event loop. It returns when either a
CobTk command event is emitted or no Tk windows remain.

Parameters:

1. output event ID — `BY REFERENCE`;
2. running flag — `BY REFERENCE`.

```cobol
call "CTK-NEXT-EVENT"
    using
        by reference CTK-EVENT
        by reference CTK-RUNNING
end-call
```

After the call:

- `CTK-RUNNING = CTK-TRUE` means `CTK-EVENT` contains an event ID;
- `CTK-RUNNING = CTK-FALSE` means the event loop has ended because the Tk
  windows have been closed or the runtime is unavailable.

## Diagnostics

### `CTK-LAST-ERROR`

Copies the current Tcl interpreter result into a caller-provided buffer.

Parameters:

1. output buffer — `BY REFERENCE`;
2. buffer capacity in bytes — `BY VALUE`;
3. output text length — `BY REFERENCE`;
4. status — `BY REFERENCE`.

```cobol
call "CTK-LAST-ERROR"
    using
        by reference ERROR-BUFFER
        by value     ERROR-CAPACITY
        by reference ERROR-LENGTH
        by reference CTK-STATUS
end-call
```

If CobTk has not been initialized, the function returns the text
`CobTk is not initialized` instead.

Not every validation failure currently replaces the Tcl result with a dedicated
CobTk error message, so the diagnostic text may be empty or may contain an
older Tcl result in some failure paths.

## String limits and encoding

The current COBOL facade declares its generic linkage string as:

```cobol
01 LK-TEXT PIC X(4096).
```

String inputs longer than 4096 bytes are therefore outside the supported public
interface at this stage.

CobTk passes byte sequences to Tcl with explicit lengths. Tcl interprets those
strings as UTF-8. CobTk currently performs no conversion between a COBOL runtime
code page and UTF-8.
