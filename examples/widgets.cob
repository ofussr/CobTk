identification division.
program-id. COBTK-WIDGETS.

data division.

working-storage section.

copy "cobtk.cpy".

01 PROMPT-ID          pic s9(9) comp-5 value 0.
01 ENTRY-ID           pic s9(9) comp-5 value 0.
01 CHECK-ID           pic s9(9) comp-5 value 0.
01 COPY-BUTTON-ID     pic s9(9) comp-5 value 0.
01 CLEAR-BUTTON-ID    pic s9(9) comp-5 value 0.
01 RESULT-TITLE-ID    pic s9(9) comp-5 value 0.
01 RESULT-ID          pic s9(9) comp-5 value 0.

01 COPY-EVENT         pic s9(9) comp-5 value 1001.
01 CLEAR-EVENT        pic s9(9) comp-5 value 1002.
01 CHECK-EVENT        pic s9(9) comp-5 value 1003.

01 WINDOW-WIDTH       pic s9(9) comp-5 value 520.
01 WINDOW-HEIGHT      pic s9(9) comp-5 value 240.
01 ROW-NUMBER         pic s9(9) comp-5 value 0.
01 COLUMN-NUMBER      pic s9(9) comp-5 value 0.
01 CHECKED-VALUE      pic s9(9) comp-5 value 1.

01 TITLE-TEXT         pic x(17)
    value "CobTk widget demo".
01 TITLE-LENGTH       pic s9(9) comp-5 value 17.

01 PROMPT-TEXT        pic x(5)
    value "Text:".
01 PROMPT-LENGTH      pic s9(9) comp-5 value 5.

01 ENTRY-TEXT         pic x(16)
    value "Hello from COBOL".
01 ENTRY-LENGTH       pic s9(9) comp-5 value 16.

01 CHECK-TEXT         pic x(18)
    value "Enable Copy button".
01 CHECK-LENGTH       pic s9(9) comp-5 value 18.

01 COPY-TEXT          pic x(4)
    value "Copy".
01 COPY-LENGTH        pic s9(9) comp-5 value 4.

01 CLEAR-TEXT         pic x(5)
    value "Clear".
01 CLEAR-LENGTH       pic s9(9) comp-5 value 5.

01 RESULT-TITLE-TEXT  pic x(7)
    value "Result:".
01 RESULT-TITLE-LENGTH pic s9(9) comp-5 value 7.

01 WAITING-TEXT       pic x(10)
    value "Waiting...".
01 WAITING-LENGTH     pic s9(9) comp-5 value 10.

01 EMPTY-TEXT         pic x(1) value space.
01 EMPTY-LENGTH       pic s9(9) comp-5 value 0.

01 CLEARED-TEXT       pic x(7)
    value "Cleared".
01 CLEARED-LENGTH     pic s9(9) comp-5 value 7.

01 ENTRY-BUFFER       pic x(256) value spaces.
01 ENTRY-CAPACITY     pic s9(9) comp-5 value 256.
01 ENTRY-OUT-LENGTH   pic s9(9) comp-5 value 0.


procedure division.

main-procedure.

    call "CTK-INIT"
        using by reference CTK-STATUS
    end-call

    if CTK-STATUS not = CTK-OK
        display "CobTk initialization failed."
        stop run
    end-if

    call "CTK-TITLE"
        using
            by reference TITLE-TEXT
            by value     TITLE-LENGTH
            by reference CTK-STATUS
    end-call

    call "CTK-WINDOW-SIZE"
        using
            by value     WINDOW-WIDTH
            by value     WINDOW-HEIGHT
            by reference CTK-STATUS
    end-call

    call "CTK-RESIZABLE"
        using
            by value     CTK-TRUE
            by value     CTK-TRUE
            by reference CTK-STATUS
    end-call

    call "CTK-LABEL"
        using
            by reference PROMPT-TEXT
            by value     PROMPT-LENGTH
            by reference PROMPT-ID
            by reference CTK-STATUS
    end-call

    move 0 to ROW-NUMBER
    move 0 to COLUMN-NUMBER
    call "CTK-GRID"
        using
            by value     PROMPT-ID
            by value     ROW-NUMBER
            by value     COLUMN-NUMBER
            by reference CTK-STATUS
    end-call

    call "CTK-ENTRY"
        using
            by reference ENTRY-TEXT
            by value     ENTRY-LENGTH
            by reference ENTRY-ID
            by reference CTK-STATUS
    end-call

    move 0 to ROW-NUMBER
    move 1 to COLUMN-NUMBER
    call "CTK-GRID"
        using
            by value     ENTRY-ID
            by value     ROW-NUMBER
            by value     COLUMN-NUMBER
            by reference CTK-STATUS
    end-call

    call "CTK-CHECKBUTTON"
        using
            by reference CHECK-TEXT
            by value     CHECK-LENGTH
            by value     CHECK-EVENT
            by reference CHECK-ID
            by reference CTK-STATUS
    end-call

    call "CTK-SET-CHECKED"
        using
            by value     CHECK-ID
            by value     CTK-TRUE
            by reference CTK-STATUS
    end-call

    move 1 to ROW-NUMBER
    move 1 to COLUMN-NUMBER
    call "CTK-GRID"
        using
            by value     CHECK-ID
            by value     ROW-NUMBER
            by value     COLUMN-NUMBER
            by reference CTK-STATUS
    end-call

    call "CTK-BUTTON"
        using
            by reference COPY-TEXT
            by value     COPY-LENGTH
            by value     COPY-EVENT
            by reference COPY-BUTTON-ID
            by reference CTK-STATUS
    end-call

    move 2 to ROW-NUMBER
    move 0 to COLUMN-NUMBER
    call "CTK-GRID"
        using
            by value     COPY-BUTTON-ID
            by value     ROW-NUMBER
            by value     COLUMN-NUMBER
            by reference CTK-STATUS
    end-call

    call "CTK-BUTTON"
        using
            by reference CLEAR-TEXT
            by value     CLEAR-LENGTH
            by value     CLEAR-EVENT
            by reference CLEAR-BUTTON-ID
            by reference CTK-STATUS
    end-call

    move 2 to ROW-NUMBER
    move 1 to COLUMN-NUMBER
    call "CTK-GRID"
        using
            by value     CLEAR-BUTTON-ID
            by value     ROW-NUMBER
            by value     COLUMN-NUMBER
            by reference CTK-STATUS
    end-call

    call "CTK-LABEL"
        using
            by reference RESULT-TITLE-TEXT
            by value     RESULT-TITLE-LENGTH
            by reference RESULT-TITLE-ID
            by reference CTK-STATUS
    end-call

    move 3 to ROW-NUMBER
    move 0 to COLUMN-NUMBER
    call "CTK-GRID"
        using
            by value     RESULT-TITLE-ID
            by value     ROW-NUMBER
            by value     COLUMN-NUMBER
            by reference CTK-STATUS
    end-call

    call "CTK-LABEL"
        using
            by reference WAITING-TEXT
            by value     WAITING-LENGTH
            by reference RESULT-ID
            by reference CTK-STATUS
    end-call

    move 3 to ROW-NUMBER
    move 1 to COLUMN-NUMBER
    call "CTK-GRID"
        using
            by value     RESULT-ID
            by value     ROW-NUMBER
            by value     COLUMN-NUMBER
            by reference CTK-STATUS
    end-call

    call "CTK-FOCUS"
        using
            by value     ENTRY-ID
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
                    move spaces to ENTRY-BUFFER
                    move 0 to ENTRY-OUT-LENGTH

                    call "CTK-GET-TEXT"
                        using
                            by value     ENTRY-ID
                            by reference ENTRY-BUFFER
                            by value     ENTRY-CAPACITY
                            by reference ENTRY-OUT-LENGTH
                            by reference CTK-STATUS
                    end-call

                    if CTK-STATUS = CTK-OK
                        call "CTK-SET-TEXT"
                            using
                                by value     RESULT-ID
                                by reference ENTRY-BUFFER
                                by value     ENTRY-OUT-LENGTH
                                by reference CTK-STATUS
                        end-call
                    end-if

                when 1002
                    call "CTK-SET-TEXT"
                        using
                            by value     ENTRY-ID
                            by reference EMPTY-TEXT
                            by value     EMPTY-LENGTH
                            by reference CTK-STATUS
                    end-call

                    call "CTK-SET-TEXT"
                        using
                            by value     RESULT-ID
                            by reference CLEARED-TEXT
                            by value     CLEARED-LENGTH
                            by reference CTK-STATUS
                    end-call

                    call "CTK-FOCUS"
                        using
                            by value     ENTRY-ID
                            by reference CTK-STATUS
                    end-call

                when 1003
                    call "CTK-GET-CHECKED"
                        using
                            by value     CHECK-ID
                            by reference CHECKED-VALUE
                            by reference CTK-STATUS
                    end-call

                    call "CTK-SET-ENABLED"
                        using
                            by value     COPY-BUTTON-ID
                            by value     CHECKED-VALUE
                            by reference CTK-STATUS
                    end-call

                when other
                    continue

            end-evaluate

        end-if

    end-perform

    call "CTK-SHUTDOWN"
    end-call

    stop run.

end program COBTK-WIDGETS.
