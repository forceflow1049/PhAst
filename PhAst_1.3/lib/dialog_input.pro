; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
;+
; NAME:
;     DIALOG_INPUT
;
; PURPOSE:
;     A modal (blocking) dialog widget to input a line of text.
;     The dialog must be dismissed, by entering text and pressing the
;     Return key, or by clicking on the 'Ok' or 'Cancel' button before
;     execution of the calling program can continue.
;
; TYPE:
;     FUNCTION
;
; CATEGORY:
;     WIDGETS
;
; CALLING SEQUENCE:
;     result = DIALOG_INPUT ()
;
; INPUTS:
;     NONE
;
; KEYWORD PARAMETERS:
;
;     PROMPT: Optional STRING or STRARR displayed on the widget.
;         If the keyword NFIELDS is set, then PROMPT must be a
;         STRARR of length NFIELDS.  If NFIELDS is not set, and PROMPT is
;         a STRARR, each element of the array will appear on a separate line.
;
;         If not supplied, default = 'Enter Text'
;
;     TITLE: Window title [default = 'dialog_input']
;
;     INITIAL: Initial value to show in the input area.  If PROMPT is 
;         supplied, this must be a array of length FIELDS.
;
;     XSIZE, YSIZE: The width and height of the dialog
;
;     WIDTH: Set the width of the input field IN CHARACTERS.  
;
;     NFIELDS: Show multiple input fields.  If PROMPT and/or INITIAL are
;         supplied, they must be STRARR of length FIELDS.  
; 
;     DIALOG_PARENT: Set this keyword to the widget ID of a widget over
;         which the message dialog should be positioned. When displayed,
;         the DIALOG_INPUT dialog will be positioned over the specified
;         widget. Dialogs are often related to a non-dialog widget tree.
;         The ID of the widget in that tree to which the dialog is most
;         closely related should be specified.
;
;     OK: STRING label for the 'Ok' button (default = 'Ok')
;     CANCEL: STRING label for the 'Cancel' button (default = 'Cancel')
;
; OUTPUTS:
;     result: STRING or STRARR of input text, or '' if dialog is cancelled
;
; COMMON BLOCKS:
;     NONE
;
; SIDE EFFECTS:
;     Creates a modal widget
;
; RESTRICTIONS:
;     NONE
;
; DEPENDENCIES:
;     NONE
;
; MODIFICATION HISTORY:
;
;     v1.03: RSM, Aug 1998, Added WIDTH keyword to set the width of the 
;            input field IN CHARACTERS.  Fixed layout bug when using NFIELDS.
;
;     v1.02: RSM, May 1998, Non-backward compatible changes to allow multiple
;            input fields.
;
;     v1.01: RSM, Mar 1998, fixed error when used with a modal toplevel base.
;
;     v1.0:  Written, Robert.Mallozzi@msfc.nasa.gov, July 1997.
;
;-
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 

FUNCTION DIALOG_INPUT, PROMPT = prompt, TITLE = title, INITIAL = initial, $
    XSIZE = xsize, YSIZE = ysize, WIDTH = width, $
    NFIELDS = nfields, DIALOG_PARENT = dialog_parent, $
    OK = ok, CANCEL = cancel


numFields = 1
IF (N_ELEMENTS (nfields) NE 0) THEN $
   numFields = nfields
   
IF (N_ELEMENTS (prompt) EQ 0) THEN BEGIN
   prompt = REPLICATE ('Enter Text', numFields)
ENDIF ELSE BEGIN
   IF (numFields GT 1) THEN $
      IF (N_ELEMENTS (prompt) NE numFields) THEN $
         MESSAGE, 'PROMPT must be array of length NFIELDS.'
ENDELSE

IF (N_ELEMENTS (initial) EQ 0) THEN BEGIN
   value = REPLICATE ('', numFields)
ENDIF ELSE BEGIN
   IF (N_ELEMENTS (initial) NE numFields) THEN $
      MESSAGE, 'INITIAL must be array of length NFIELDS.'
   ; Trim non-string datatypes
   ;
   s = SIZE (initial)
   IF (s[s[0]+1] NE 7) THEN BEGIN
      value = STRTRIM (initial, 2)
   ENDIF ELSE BEGIN
      value = initial
   ENDELSE   
ENDELSE

IF (N_ELEMENTS (title) EQ 0) THEN $
   title = 'dialog_input'

IF (N_ELEMENTS (ok) EQ 0) THEN $
   ok = 'Ok'

IF (N_ELEMENTS (cancel) EQ 0) THEN $
   cancel = 'Cancel'


HAVE_PARENT = N_ELEMENTS(dialog_parent) NE 0

min_width = 100


; Top level base
;
IF (HAVE_PARENT) THEN BEGIN

   ; Check for a valid widget id
   ;
   HAVE_PARENT = WIDGET_INFO (dialog_parent, /VALID_ID)

ENDIF   

IF (HAVE_PARENT) THEN BEGIN
   topBase = WIDGET_BASE (TITLE = title, /COLUMN, /BASE_ALIGN_CENTER, $
       /FLOATING, /MODAL, GROUP_LEADER = dialog_parent, $
       XSIZE = xsize, YSIZE = ysize)
ENDIF ELSE BEGIN
   topBase = WIDGET_BASE (TITLE = title, /COLUMN, /BASE_ALIGN_CENTER, MAP = 0, $
       XSIZE = xsize, YSIZE = ysize)   
ENDELSE


IF (numFields EQ 1) THEN BEGIN

   base = WIDGET_BASE (topBase, /COLUMN)
   FOR i = 0,  N_ELEMENTS (prompt) - 1 DO $
       w = WIDGET_LABEL (base, VALUE = prompt[i])
   textID = LONARR (numFields)
   FOR i = 0,  numFields - 1 DO $
       textID[i] = WIDGET_TEXT (base, VALUE = value[i], /EDIT, XSIZE = width)

ENDIF ELSE BEGIN

   base = WIDGET_BASE (topBase, ROW = numFields, /GRID_LAYOUT)
   textID = LONARR (numFields)
   FOR i = 0,  N_ELEMENTS (prompt) - 1 DO BEGIN
       textID[i] = CW_FIELD (base, VALUE = value[i], XSIZE = width, $
           TITLE = prompt[i])
   ENDFOR
   
ENDELSE

; Ok, Cancel buttons
;
rowBase = WIDGET_BASE (topBase, /ROW, /GRID_LAYOUT)
    w = WIDGET_BUTTON (rowBase, VALUE = ok)
    w = WIDGET_BUTTON (rowBase, VALUE = cancel)


; Map to screen
;
WIDGET_CONTROL, topBase, /REALIZE


; Place the dialog: window manager dependent
;
IF (NOT HAVE_PARENT) THEN BEGIN

   CURRENT_SCREEN = GET_SCREEN_SIZE()
   WIDGET_CONTROL, topBase, TLB_GET_SIZE = DIALOG_SIZE

   DIALOG_PT = [(CURRENT_SCREEN[0] / 2.0) - (DIALOG_SIZE[0] / 2.0), $ 
                (CURRENT_SCREEN[1] / 2.0) - (DIALOG_SIZE[1] / 2.0)] 

   WIDGET_CONTROL, topBase, $
                   TLB_SET_XOFFSET = DIALOG_PT[0], $
                   TLB_SET_YOFFSET = DIALOG_PT[1]
   WIDGET_CONTROL, topBase, MAP = 1

ENDIF

value = ''
REPEAT BEGIN


    ; Get the event, without using XMANAGER
    ;
    event = WIDGET_EVENT (topBase)


    ; Get widget value
    ;
    WIDGET_CONTROL, event.id, GET_VALUE = value


    ; Process the event
    ;
    type = TAG_NAMES (event, /STRUCTURE)

    CASE (type) OF

         ; Button widget events
         ;
         'WIDGET_BUTTON': BEGIN

             IF (value[0] EQ cancel) THEN BEGIN
                WIDGET_CONTROL, topBase, /DESTROY
                RETURN, ''
             ENDIF

             END

         ; Text widget events
         ;
         'WIDGET_TEXT_CH': BEGIN
             IF (numFields EQ 1) THEN BEGIN
                WIDGET_CONTROL, textID[0], GET_VALUE = retVal
                WIDGET_CONTROL, topBase, /DESTROY
                RETURN, retVal[0]
             ENDIF                   
             END

         ELSE: BEGIN
             PRINT, 'DIALOG_INPUT: Internal Error: Event not handled: ', TYPE
             retVal = ''
             END
    
    ENDCASE ; for type


ENDREP UNTIL (value[0] EQ ok)

; Retrieve the text values
;
retVal = STRARR (numFields)
FOR i = 0, numFields - 1 DO BEGIN
    WIDGET_CONTROL, textID[i], GET_VALUE = v
    retVal[i] = v
ENDFOR


WIDGET_CONTROL, topBase, /DESTROY

IF (numFields EQ 1) THEN BEGIN
   RETURN, retVal[0]
ENDIF ELSE BEGIN                   
   RETURN, retval
ENDELSE


END
