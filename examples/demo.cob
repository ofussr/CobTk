identification division.
program-id. COBTK-DEMO.

data division.

working-storage section.

copy "cobtk.cpy".

01 LABEL-ID          pic s9(9) comp-5 value 0.
01 BUTTON-ID         pic s9(9) comp-5 value 0.

01 BUTTON-EVENT      pic s9(9) comp-5 value 1001.

01 TITLE-TEXT        pic x(18)
    value "CobTk first window".
01 TITLE-LENGTH      pic s9(9) comp-5 value 18.

01 LABEL-TEXT        pic x(21)
    value "Hello from COBOL + Tk".
01 LABEL-LENGTH      pic s9(9) comp-5 value 21.

01 BUTTON-TEXT       pic x(8)
    value "Click me".
01 BUTTON-LENGTH     pic s9(9) comp-5 value 8.

01 CLICKED-TEXT      pic x(29)
    value "The click came back to COBOL.".
01 CLICKED-LENGTH    pic s9(9) comp-5 value 29.


procedure division.

main-procedure.

    call "CTK-INIT"
        using
            by reference CTK-STATUS
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

                    call "CTK-SET-TEXT"
                        using
                            by value     LABEL-ID
                            by reference CLICKED-TEXT
                            by value     CLICKED-LENGTH
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

end program COBTK-DEMO.
