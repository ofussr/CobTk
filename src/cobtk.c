#include <stdio.h>
#include <string.h>
#include <tcl.h>
#include <tk.h>

#define CTK_MAX_WIDGETS 4096
#define CTK_OK 0
#define CTK_ERROR 1
#define CTK_BUFFER_TOO_SMALL 2

typedef enum {
    CTK_WIDGET_NONE = 0,
    CTK_WIDGET_LABEL,
    CTK_WIDGET_BUTTON,
    CTK_WIDGET_ENTRY,
    CTK_WIDGET_CHECKBUTTON
} CtkWidgetType;

static Tcl_Interp *ctk_interp = NULL;
static int ctk_next_widget_id = 1;
static int ctk_pending_event = 0;
static int ctk_has_pending_event = 0;
static CtkWidgetType ctk_widget_types[CTK_MAX_WIDGETS];


/* ---------------------------------------------------------
   Internal helpers
   --------------------------------------------------------- */

static int
ctk_eval_objv(int objc, Tcl_Obj **objv)
{
    int i;
    int result;

    if (ctk_interp == NULL) {
        return TCL_ERROR;
    }

    for (i = 0; i < objc; ++i) {
        Tcl_IncrRefCount(objv[i]);
    }

    result = Tcl_EvalObjv(
        ctk_interp,
        objc,
        objv,
        TCL_EVAL_DIRECT
    );

    for (i = 0; i < objc; ++i) {
        Tcl_DecrRefCount(objv[i]);
    }

    return result;
}


static void
ctk_widget_path(int widget_id, char *buffer, size_t buffer_size)
{
    snprintf(
        buffer,
        buffer_size,
        ".ctk%d",
        widget_id
    );
}


static int
ctk_allocate_widget(CtkWidgetType type)
{
    int widget_id;

    if (ctk_next_widget_id >= CTK_MAX_WIDGETS) {
        return -1;
    }

    widget_id = ctk_next_widget_id++;
    ctk_widget_types[widget_id] = type;

    return widget_id;
}


static int
ctk_valid_widget(int widget_id)
{
    return (
        widget_id > 0 &&
        widget_id < CTK_MAX_WIDGETS &&
        ctk_widget_types[widget_id] != CTK_WIDGET_NONE
    );
}


static int
ctk_copy_bytes(
    const char *source,
    int source_length,
    char *buffer,
    int buffer_capacity,
    int *output_length
)
{
    if (output_length != NULL) {
        *output_length = source_length;
    }

    if (buffer_capacity < source_length) {
        return CTK_BUFFER_TOO_SMALL;
    }

    if (source_length > 0 && buffer != NULL) {
        memcpy(buffer, source, (size_t) source_length);
    }

    return CTK_OK;
}


/* Called by Tk when a COBOL-facing event occurs. */
static int
ctk_emit_command(
    ClientData client_data,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *const objv[]
)
{
    int event_id;

    (void) client_data;

    if (objc != 2) {
        Tcl_WrongNumArgs(
            interp,
            1,
            objv,
            "eventId"
        );
        return TCL_ERROR;
    }

    if (Tcl_GetIntFromObj(
            interp,
            objv[1],
            &event_id
        ) != TCL_OK) {
        return TCL_ERROR;
    }

    ctk_pending_event = event_id;
    ctk_has_pending_event = 1;

    return TCL_OK;
}


static Tcl_Obj *
ctk_event_callback(int event_id)
{
    Tcl_Obj *callback;

    callback = Tcl_NewListObj(0, NULL);

    Tcl_ListObjAppendElement(
        ctk_interp,
        callback,
        Tcl_NewStringObj("cobtk_emit", -1)
    );

    Tcl_ListObjAppendElement(
        ctk_interp,
        callback,
        Tcl_NewIntObj(event_id)
    );

    return callback;
}


/* ---------------------------------------------------------
   Public CobTk API
   --------------------------------------------------------- */

int
ctk_init(void)
{
    if (ctk_interp != NULL) {
        return CTK_OK;
    }

    Tcl_FindExecutable("cobtk");

    ctk_interp = Tcl_CreateInterp();

    if (ctk_interp == NULL) {
        return CTK_ERROR;
    }

    if (Tcl_Init(ctk_interp) != TCL_OK) {
        Tcl_DeleteInterp(ctk_interp);
        ctk_interp = NULL;
        return CTK_ERROR;
    }

    if (Tk_Init(ctk_interp) != TCL_OK) {
        Tcl_DeleteInterp(ctk_interp);
        ctk_interp = NULL;
        return CTK_ERROR;
    }

    Tcl_CreateObjCommand(
        ctk_interp,
        "cobtk_emit",
        ctk_emit_command,
        NULL,
        NULL
    );

    memset(ctk_widget_types, 0, sizeof(ctk_widget_types));
    ctk_next_widget_id = 1;
    ctk_pending_event = 0;
    ctk_has_pending_event = 0;

    return CTK_OK;
}


int
ctk_set_title(
    const char *text,
    int text_length
)
{
    Tcl_Obj *command[4];

    command[0] = Tcl_NewStringObj("wm", -1);
    command[1] = Tcl_NewStringObj("title", -1);
    command[2] = Tcl_NewStringObj(".", -1);
    command[3] = Tcl_NewStringObj(text, text_length);

    return ctk_eval_objv(4, command);
}


int
ctk_set_window_size(int width, int height)
{
    Tcl_Obj *command[4];

    if (width <= 0 || height <= 0) {
        return CTK_ERROR;
    }

    command[0] = Tcl_NewStringObj("wm", -1);
    command[1] = Tcl_NewStringObj("geometry", -1);
    command[2] = Tcl_NewStringObj(".", -1);
    command[3] = Tcl_ObjPrintf("%dx%d", width, height);

    return ctk_eval_objv(4, command);
}


int
ctk_set_resizable(int horizontal, int vertical)
{
    Tcl_Obj *command[5];

    command[0] = Tcl_NewStringObj("wm", -1);
    command[1] = Tcl_NewStringObj("resizable", -1);
    command[2] = Tcl_NewStringObj(".", -1);
    command[3] = Tcl_NewBooleanObj(horizontal != 0);
    command[4] = Tcl_NewBooleanObj(vertical != 0);

    return ctk_eval_objv(5, command);
}


int
ctk_create_label(
    const char *text,
    int text_length
)
{
    int widget_id;
    char path[32];
    Tcl_Obj *command[4];

    widget_id = ctk_allocate_widget(CTK_WIDGET_LABEL);
    if (widget_id < 0) {
        return -1;
    }

    ctk_widget_path(widget_id, path, sizeof(path));

    command[0] = Tcl_NewStringObj("ttk::label", -1);
    command[1] = Tcl_NewStringObj(path, -1);
    command[2] = Tcl_NewStringObj("-text", -1);
    command[3] = Tcl_NewStringObj(text, text_length);

    if (ctk_eval_objv(4, command) != TCL_OK) {
        ctk_widget_types[widget_id] = CTK_WIDGET_NONE;
        return -1;
    }

    return widget_id;
}


int
ctk_create_button(
    const char *text,
    int text_length,
    int event_id
)
{
    int widget_id;
    char path[32];
    Tcl_Obj *command[6];

    widget_id = ctk_allocate_widget(CTK_WIDGET_BUTTON);
    if (widget_id < 0) {
        return -1;
    }

    ctk_widget_path(widget_id, path, sizeof(path));

    command[0] = Tcl_NewStringObj("ttk::button", -1);
    command[1] = Tcl_NewStringObj(path, -1);
    command[2] = Tcl_NewStringObj("-text", -1);
    command[3] = Tcl_NewStringObj(text, text_length);
    command[4] = Tcl_NewStringObj("-command", -1);
    command[5] = ctk_event_callback(event_id);

    if (ctk_eval_objv(6, command) != TCL_OK) {
        ctk_widget_types[widget_id] = CTK_WIDGET_NONE;
        return -1;
    }

    return widget_id;
}


int
ctk_create_entry(
    const char *text,
    int text_length
)
{
    int widget_id;
    char path[32];
    Tcl_Obj *create_command[2];
    Tcl_Obj *insert_command[4];

    widget_id = ctk_allocate_widget(CTK_WIDGET_ENTRY);
    if (widget_id < 0) {
        return -1;
    }

    ctk_widget_path(widget_id, path, sizeof(path));

    create_command[0] = Tcl_NewStringObj("ttk::entry", -1);
    create_command[1] = Tcl_NewStringObj(path, -1);

    if (ctk_eval_objv(2, create_command) != TCL_OK) {
        ctk_widget_types[widget_id] = CTK_WIDGET_NONE;
        return -1;
    }

    if (text_length > 0) {
        insert_command[0] = Tcl_NewStringObj(path, -1);
        insert_command[1] = Tcl_NewStringObj("insert", -1);
        insert_command[2] = Tcl_NewIntObj(0);
        insert_command[3] = Tcl_NewStringObj(text, text_length);

        if (ctk_eval_objv(4, insert_command) != TCL_OK) {
            return -1;
        }
    }

    return widget_id;
}


int
ctk_create_checkbutton(
    const char *text,
    int text_length,
    int event_id
)
{
    int widget_id;
    char path[32];
    Tcl_Obj *command[6];

    widget_id = ctk_allocate_widget(CTK_WIDGET_CHECKBUTTON);
    if (widget_id < 0) {
        return -1;
    }

    ctk_widget_path(widget_id, path, sizeof(path));

    command[0] = Tcl_NewStringObj("ttk::checkbutton", -1);
    command[1] = Tcl_NewStringObj(path, -1);
    command[2] = Tcl_NewStringObj("-text", -1);
    command[3] = Tcl_NewStringObj(text, text_length);
    command[4] = Tcl_NewStringObj("-command", -1);
    command[5] = ctk_event_callback(event_id);

    if (ctk_eval_objv(6, command) != TCL_OK) {
        ctk_widget_types[widget_id] = CTK_WIDGET_NONE;
        return -1;
    }

    return widget_id;
}


int
ctk_pack(int widget_id)
{
    char path[32];
    Tcl_Obj *command[6];

    if (!ctk_valid_widget(widget_id)) {
        return CTK_ERROR;
    }

    ctk_widget_path(widget_id, path, sizeof(path));

    command[0] = Tcl_NewStringObj("pack", -1);
    command[1] = Tcl_NewStringObj(path, -1);
    command[2] = Tcl_NewStringObj("-padx", -1);
    command[3] = Tcl_NewIntObj(12);
    command[4] = Tcl_NewStringObj("-pady", -1);
    command[5] = Tcl_NewIntObj(8);

    return ctk_eval_objv(6, command);
}


int
ctk_grid(int widget_id, int row, int column)
{
    char path[32];
    Tcl_Obj *command[10];

    if (!ctk_valid_widget(widget_id) || row < 0 || column < 0) {
        return CTK_ERROR;
    }

    ctk_widget_path(widget_id, path, sizeof(path));

    command[0] = Tcl_NewStringObj("grid", -1);
    command[1] = Tcl_NewStringObj(path, -1);
    command[2] = Tcl_NewStringObj("-row", -1);
    command[3] = Tcl_NewIntObj(row);
    command[4] = Tcl_NewStringObj("-column", -1);
    command[5] = Tcl_NewIntObj(column);
    command[6] = Tcl_NewStringObj("-padx", -1);
    command[7] = Tcl_NewIntObj(8);
    command[8] = Tcl_NewStringObj("-pady", -1);
    command[9] = Tcl_NewIntObj(6);

    return ctk_eval_objv(10, command);
}


int
ctk_set_text(
    int widget_id,
    const char *text,
    int text_length
)
{
    char path[32];

    if (!ctk_valid_widget(widget_id) || text_length < 0) {
        return CTK_ERROR;
    }

    ctk_widget_path(widget_id, path, sizeof(path));

    if (ctk_widget_types[widget_id] == CTK_WIDGET_ENTRY) {
        Tcl_Obj *delete_command[4];
        Tcl_Obj *insert_command[4];

        delete_command[0] = Tcl_NewStringObj(path, -1);
        delete_command[1] = Tcl_NewStringObj("delete", -1);
        delete_command[2] = Tcl_NewIntObj(0);
        delete_command[3] = Tcl_NewStringObj("end", -1);

        if (ctk_eval_objv(4, delete_command) != TCL_OK) {
            return CTK_ERROR;
        }

        if (text_length == 0) {
            return CTK_OK;
        }

        insert_command[0] = Tcl_NewStringObj(path, -1);
        insert_command[1] = Tcl_NewStringObj("insert", -1);
        insert_command[2] = Tcl_NewIntObj(0);
        insert_command[3] = Tcl_NewStringObj(text, text_length);

        return ctk_eval_objv(4, insert_command);
    }

    {
        Tcl_Obj *command[4];

        command[0] = Tcl_NewStringObj(path, -1);
        command[1] = Tcl_NewStringObj("configure", -1);
        command[2] = Tcl_NewStringObj("-text", -1);
        command[3] = Tcl_NewStringObj(text, text_length);

        return ctk_eval_objv(4, command);
    }
}


int
ctk_get_text(
    int widget_id,
    char *buffer,
    int buffer_capacity,
    int *text_length
)
{
    char path[32];
    Tcl_Obj *command[3];
    const char *result_text;
    int result_length;

    if (!ctk_valid_widget(widget_id) || buffer_capacity < 0) {
        return CTK_ERROR;
    }

    ctk_widget_path(widget_id, path, sizeof(path));

    command[0] = Tcl_NewStringObj(path, -1);

    if (ctk_widget_types[widget_id] == CTK_WIDGET_ENTRY) {
        command[1] = Tcl_NewStringObj("get", -1);

        if (ctk_eval_objv(2, command) != TCL_OK) {
            return CTK_ERROR;
        }
    } else {
        command[1] = Tcl_NewStringObj("cget", -1);
        command[2] = Tcl_NewStringObj("-text", -1);

        if (ctk_eval_objv(3, command) != TCL_OK) {
            return CTK_ERROR;
        }
    }

    result_text = Tcl_GetStringFromObj(
        Tcl_GetObjResult(ctk_interp),
        &result_length
    );

    return ctk_copy_bytes(
        result_text,
        result_length,
        buffer,
        buffer_capacity,
        text_length
    );
}


int
ctk_set_checked(int widget_id, int checked)
{
    char path[32];
    Tcl_Obj *command[3];

    if (
        !ctk_valid_widget(widget_id) ||
        ctk_widget_types[widget_id] != CTK_WIDGET_CHECKBUTTON
    ) {
        return CTK_ERROR;
    }

    ctk_widget_path(widget_id, path, sizeof(path));

    command[0] = Tcl_NewStringObj(path, -1);
    command[1] = Tcl_NewStringObj("state", -1);
    command[2] = Tcl_NewStringObj(
        checked ? "selected" : "!selected",
        -1
    );

    return ctk_eval_objv(3, command);
}


int
ctk_get_checked(int widget_id, int *checked)
{
    char path[32];
    Tcl_Obj *command[3];
    int value;

    if (
        !ctk_valid_widget(widget_id) ||
        ctk_widget_types[widget_id] != CTK_WIDGET_CHECKBUTTON ||
        checked == NULL
    ) {
        return CTK_ERROR;
    }

    ctk_widget_path(widget_id, path, sizeof(path));

    command[0] = Tcl_NewStringObj(path, -1);
    command[1] = Tcl_NewStringObj("instate", -1);
    command[2] = Tcl_NewStringObj("selected", -1);

    if (ctk_eval_objv(3, command) != TCL_OK) {
        return CTK_ERROR;
    }

    if (Tcl_GetBooleanFromObj(
            ctk_interp,
            Tcl_GetObjResult(ctk_interp),
            &value
        ) != TCL_OK) {
        return CTK_ERROR;
    }

    *checked = value;
    return CTK_OK;
}


int
ctk_set_enabled(int widget_id, int enabled)
{
    char path[32];
    Tcl_Obj *command[3];

    if (!ctk_valid_widget(widget_id)) {
        return CTK_ERROR;
    }

    ctk_widget_path(widget_id, path, sizeof(path));

    command[0] = Tcl_NewStringObj(path, -1);
    command[1] = Tcl_NewStringObj("state", -1);
    command[2] = Tcl_NewStringObj(
        enabled ? "!disabled" : "disabled",
        -1
    );

    return ctk_eval_objv(3, command);
}


int
ctk_focus(int widget_id)
{
    char path[32];
    Tcl_Obj *command[2];

    if (!ctk_valid_widget(widget_id)) {
        return CTK_ERROR;
    }

    ctk_widget_path(widget_id, path, sizeof(path));

    command[0] = Tcl_NewStringObj("focus", -1);
    command[1] = Tcl_NewStringObj(path, -1);

    return ctk_eval_objv(2, command);
}


int
ctk_destroy(int widget_id)
{
    char path[32];
    Tcl_Obj *command[2];
    int result;

    if (!ctk_valid_widget(widget_id)) {
        return CTK_ERROR;
    }

    ctk_widget_path(widget_id, path, sizeof(path));

    command[0] = Tcl_NewStringObj("destroy", -1);
    command[1] = Tcl_NewStringObj(path, -1);

    result = ctk_eval_objv(2, command);

    if (result == TCL_OK) {
        ctk_widget_types[widget_id] = CTK_WIDGET_NONE;
    }

    return result;
}


int
ctk_get_last_error(
    char *buffer,
    int buffer_capacity,
    int *text_length
)
{
    const char *result_text;
    int result_length;

    if (ctk_interp == NULL) {
        static const char message[] = "CobTk is not initialized";
        return ctk_copy_bytes(
            message,
            (int) (sizeof(message) - 1),
            buffer,
            buffer_capacity,
            text_length
        );
    }

    result_text = Tcl_GetStringFromObj(
        Tcl_GetObjResult(ctk_interp),
        &result_length
    );

    return ctk_copy_bytes(
        result_text,
        result_length,
        buffer,
        buffer_capacity,
        text_length
    );
}


/*
   Blocks until CobTk receives an event.

   Returns:
       1 -> event received
       0 -> all windows were closed
*/
int
ctk_next_event(int *event_id)
{
    if (ctk_interp == NULL || event_id == NULL) {
        return 0;
    }

    while (
        !ctk_has_pending_event &&
        Tk_GetNumMainWindows() > 0
    ) {
        Tcl_DoOneEvent(TCL_ALL_EVENTS);
    }

    if (Tk_GetNumMainWindows() == 0) {
        return 0;
    }

    *event_id = ctk_pending_event;
    ctk_pending_event = 0;
    ctk_has_pending_event = 0;

    return 1;
}


void
ctk_shutdown(void)
{
    if (ctk_interp != NULL) {
        Tcl_DeleteInterp(ctk_interp);
        ctk_interp = NULL;
    }

    memset(ctk_widget_types, 0, sizeof(ctk_widget_types));
    ctk_pending_event = 0;
    ctk_has_pending_event = 0;
    ctk_next_widget_id = 1;
}
