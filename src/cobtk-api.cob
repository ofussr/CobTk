identification division.
program-id. COBTK-API.

data division.

linkage section.

01 LK-STATUS          pic s9(9) comp-5.
01 LK-WIDGET-ID       pic s9(9) comp-5.
01 LK-EVENT-ID        pic s9(9) comp-5.
01 LK-LENGTH          pic s9(9) comp-5.
01 LK-CAPACITY        pic s9(9) comp-5.
01 LK-OUT-LENGTH      pic s9(9) comp-5.
01 LK-RUNNING         pic s9(9) comp-5.
01 LK-WIDTH           pic s9(9) comp-5.
01 LK-HEIGHT          pic s9(9) comp-5.
01 LK-HORIZONTAL      pic s9(9) comp-5.
01 LK-VERTICAL        pic s9(9) comp-5.
01 LK-ROW             pic s9(9) comp-5.
01 LK-COLUMN          pic s9(9) comp-5.
01 LK-VALUE           pic s9(9) comp-5.

01 LK-TEXT            pic x(4096).


procedure division.

main-entry.
    goback.


*> ================================================================
*> Initialise CobTk
*> ================================================================

entry "CTK-INIT"
    using
        by reference LK-STATUS.

    call "ctk_init"
        returning LK-STATUS
    end-call

    goback.


*> ================================================================
*> Root-window properties
*> ================================================================

entry "CTK-TITLE"
    using
        by reference LK-TEXT
        by value     LK-LENGTH
        by reference LK-STATUS.

    call "ctk_set_title"
        using
            by reference LK-TEXT
            by value     LK-LENGTH
        returning LK-STATUS
    end-call

    goback.


entry "CTK-WINDOW-SIZE"
    using
        by value     LK-WIDTH
        by value     LK-HEIGHT
        by reference LK-STATUS.

    call "ctk_set_window_size"
        using
            by value LK-WIDTH
            by value LK-HEIGHT
        returning LK-STATUS
    end-call

    goback.


entry "CTK-RESIZABLE"
    using
        by value     LK-HORIZONTAL
        by value     LK-VERTICAL
        by reference LK-STATUS.

    call "ctk_set_resizable"
        using
            by value LK-HORIZONTAL
            by value LK-VERTICAL
        returning LK-STATUS
    end-call

    goback.


*> ================================================================
*> Widget creation
*> ================================================================

entry "CTK-LABEL"
    using
        by reference LK-TEXT
        by value     LK-LENGTH
        by reference LK-WIDGET-ID
        by reference LK-STATUS.

    call "ctk_create_label"
        using
            by reference LK-TEXT
            by value     LK-LENGTH
        returning LK-WIDGET-ID
    end-call

    if LK-WIDGET-ID < 0
        move 1 to LK-STATUS
    else
        move 0 to LK-STATUS
    end-if

    goback.


entry "CTK-BUTTON"
    using
        by reference LK-TEXT
        by value     LK-LENGTH
        by value     LK-EVENT-ID
        by reference LK-WIDGET-ID
        by reference LK-STATUS.

    call "ctk_create_button"
        using
            by reference LK-TEXT
            by value     LK-LENGTH
            by value     LK-EVENT-ID
        returning LK-WIDGET-ID
    end-call

    if LK-WIDGET-ID < 0
        move 1 to LK-STATUS
    else
        move 0 to LK-STATUS
    end-if

    goback.


entry "CTK-ENTRY"
    using
        by reference LK-TEXT
        by value     LK-LENGTH
        by reference LK-WIDGET-ID
        by reference LK-STATUS.

    call "ctk_create_entry"
        using
            by reference LK-TEXT
            by value     LK-LENGTH
        returning LK-WIDGET-ID
    end-call

    if LK-WIDGET-ID < 0
        move 1 to LK-STATUS
    else
        move 0 to LK-STATUS
    end-if

    goback.


entry "CTK-CHECKBUTTON"
    using
        by reference LK-TEXT
        by value     LK-LENGTH
        by value     LK-EVENT-ID
        by reference LK-WIDGET-ID
        by reference LK-STATUS.

    call "ctk_create_checkbutton"
        using
            by reference LK-TEXT
            by value     LK-LENGTH
            by value     LK-EVENT-ID
        returning LK-WIDGET-ID
    end-call

    if LK-WIDGET-ID < 0
        move 1 to LK-STATUS
    else
        move 0 to LK-STATUS
    end-if

    goback.


*> ================================================================
*> Layout
*> ================================================================

entry "CTK-PACK"
    using
        by value     LK-WIDGET-ID
        by reference LK-STATUS.

    call "ctk_pack"
        using
            by value LK-WIDGET-ID
        returning LK-STATUS
    end-call

    goback.


entry "CTK-GRID"
    using
        by value     LK-WIDGET-ID
        by value     LK-ROW
        by value     LK-COLUMN
        by reference LK-STATUS.

    call "ctk_grid"
        using
            by value LK-WIDGET-ID
            by value LK-ROW
            by value LK-COLUMN
        returning LK-STATUS
    end-call

    goback.


*> ================================================================
*> Widget values and state
*> ================================================================

entry "CTK-SET-TEXT"
    using
        by value     LK-WIDGET-ID
        by reference LK-TEXT
        by value     LK-LENGTH
        by reference LK-STATUS.

    call "ctk_set_text"
        using
            by value     LK-WIDGET-ID
            by reference LK-TEXT
            by value     LK-LENGTH
        returning LK-STATUS
    end-call

    goback.


entry "CTK-GET-TEXT"
    using
        by value     LK-WIDGET-ID
        by reference LK-TEXT
        by value     LK-CAPACITY
        by reference LK-OUT-LENGTH
        by reference LK-STATUS.

    call "ctk_get_text"
        using
            by value     LK-WIDGET-ID
            by reference LK-TEXT
            by value     LK-CAPACITY
            by reference LK-OUT-LENGTH
        returning LK-STATUS
    end-call

    goback.


entry "CTK-SET-CHECKED"
    using
        by value     LK-WIDGET-ID
        by value     LK-VALUE
        by reference LK-STATUS.

    call "ctk_set_checked"
        using
            by value LK-WIDGET-ID
            by value LK-VALUE
        returning LK-STATUS
    end-call

    goback.


entry "CTK-GET-CHECKED"
    using
        by value     LK-WIDGET-ID
        by reference LK-VALUE
        by reference LK-STATUS.

    call "ctk_get_checked"
        using
            by value     LK-WIDGET-ID
            by reference LK-VALUE
        returning LK-STATUS
    end-call

    goback.


entry "CTK-SET-ENABLED"
    using
        by value     LK-WIDGET-ID
        by value     LK-VALUE
        by reference LK-STATUS.

    call "ctk_set_enabled"
        using
            by value LK-WIDGET-ID
            by value LK-VALUE
        returning LK-STATUS
    end-call

    goback.


entry "CTK-FOCUS"
    using
        by value     LK-WIDGET-ID
        by reference LK-STATUS.

    call "ctk_focus"
        using
            by value LK-WIDGET-ID
        returning LK-STATUS
    end-call

    goback.


entry "CTK-DESTROY"
    using
        by value     LK-WIDGET-ID
        by reference LK-STATUS.

    call "ctk_destroy"
        using
            by value LK-WIDGET-ID
        returning LK-STATUS
    end-call

    goback.


*> ================================================================
*> Error information
*> ================================================================

entry "CTK-LAST-ERROR"
    using
        by reference LK-TEXT
        by value     LK-CAPACITY
        by reference LK-OUT-LENGTH
        by reference LK-STATUS.

    call "ctk_get_last_error"
        using
            by reference LK-TEXT
            by value     LK-CAPACITY
            by reference LK-OUT-LENGTH
        returning LK-STATUS
    end-call

    goback.


*> ================================================================
*> Events and shutdown
*> ================================================================

entry "CTK-NEXT-EVENT"
    using
        by reference LK-EVENT-ID
        by reference LK-RUNNING.

    call "ctk_next_event"
        using
            by reference LK-EVENT-ID
        returning LK-RUNNING
    end-call

    goback.


entry "CTK-SHUTDOWN".

    call "ctk_shutdown"
    end-call

    goback.

end program COBTK-API.
