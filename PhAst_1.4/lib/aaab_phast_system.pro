;-------------------------------------------------------------------

pro phastslicer_event, event

  ; event handler for data cube slice selector widgets

  common phast_state
  common phast_images
  
  if (n_elements(event) EQ 0) then begin
    event_name = 'sliceslider'
    state.slice = 0
  endif else begin
    widget_control, event.id, get_uvalue = event_name
    if ((event_name EQ 'sliceslider') OR (event_name EQ 'sliceselect')) then $
      state.slice = event.value
  endelse
  
  
  if (event_name EQ 'sliceslider') then begin
    widget_control, state.sliceselect_id, set_value = state.slice
  endif
  
  if (event_name EQ 'sliceselect') then begin
    state.slice = 0 > event.value < (state.nslices-1)
    widget_control, state.sliceselect_id, set_value = state.slice
    widget_control, state.slicer_id, set_value = state.slice
  endif
  
  if (event_name EQ 'allslice') then begin
    state.slicecombine = state.nslices
    widget_control, state.slicecombine_id, set_value = state.slicecombine
  endif
  
  if (event_name EQ 'noslice') then begin
    state.slicecombine = 1
    widget_control, state.slicecombine_id, set_value = state.slicecombine
  endif
  
  
  if (event_name EQ 'average') then begin
    case event.value of
      'average': state.slicecombine_method = 0
      'median': state.slicecombine_method = 1
    endcase
  endif
  
  if (event_name EQ 'slicecombine') then begin
    state.slicecombine = 1 > event.value < state.nslices
    widget_control, state.slicecombine_id, set_value = state.slicecombine
  endif
  
  ; get the new main image from the cube
  if state.slicecombine EQ 1 then begin
  
    main_image = reform(main_image_cube[*, *, state.slice])
    
  endif else begin
  
    firstslice = 0 > round(state.slice - state.slicecombine/2)
    lastslice = (firstslice + state.slicecombine - 1) < (state.nslices - 1)
    
    if ((lastslice - firstslice) LT state.slicecombine) then $
      firstslice = lastslice - state.slicecombine + 1
      
    case state.slicecombine_method of
    
      0: begin
        main_image = total(main_image_cube[*, *, firstslice:lastslice], 3) $
          / float(state.slicecombine)
      end
      1: begin
        main_image = median(main_image_cube[*, *, firstslice:lastslice], $
          dimension=3)
      end
    endcase
    
  endelse
  
  
  ; if new slice selected from slider, display it
  if (n_elements(event) NE 0) then begin
    phast_settitle
    phast_displayall
  endif
end

;----------------------------------------------------------------------

function phast_get_image_offset, index = index, ref_index = ref,round=round
  
;function to return the x,y offset between an image and the reference
;image
  
  common phast_images
  common phast_state
  
  if not keyword_set(index) then index = state.current_image_index
  if not keyword_set(ref_index) then ref = 0
  if state.num_images gt 0 then begin
     xyxy,image_archive[index]->get_header(/string),image_archive[ref]->get_header(/string),0,0,x,y
     offset = [x,y]
     if keyword_set(round) then offset = round(offset)
     return, offset
  endif else return, [0,0]
end

;----------------------------------------------------------------------

pro phast_2mass_read, fitsfile, head, cancelled

  ; Fits reader for 3-plane 2MASS Extended Source J/H/Ks data cube.
  
  common phast_state
  common phast_images
  
  droptext = strcompress('0, droplist,J|H|Ks,' + $
    'label_left = Select 2MASS Band:, set_value=0')
    
  formdesc = [droptext, $
    '0, button, Read 2MASS Image, quit', $
    '0, button, Cancel, quit']
    
  textform = cw_form(formdesc, /column, title = '2MASS Band Selector')
  
  if (textform.tag2 EQ 1) then begin ; cancelled
    cancelled = 1
    return
  endif
  
  main_image=0
  main_image = mrdfits(fitsfile, 0, head);, /silent, /fscale)
  
  band = long(textform.tag0)
  main_image = main_image[*,*,band]    ; fixed 11/28/2000
  
  case textform.tag0 of
    0: state.title_extras = 'J Band'
    1: state.title_extras = 'H Band'
    2: state.title_extras = 'Ks Band'
    else: state.title_extras = ''
  endcase
  
  ; fix ctype2 in header to prevent crashes when running xy2ad routine:
  if (strcompress(sxpar(head, 'CTYPE2'), /remove_all) EQ 'DEC---SIN') then $
    sxaddpar, head, 'CTYPE2', 'DEC--SIN' 
end

;-------------------------------------------------------------------
      
pro phast_activate
  
; This routine is a workaround to use when you hit an error message or
; a "stop" command in another program while running phast.  If you want
; phast to become active again without typing "retall" and losing your
; current session variables, type "phast_activate" to temporarily
; activate phast again.  This will de-activate the command line but
; allow phast to be used until you hit "q" in phast or kill the phast
; window.
      
; Also, if you need to call phast from a command-line idl program and
; have that program wait until you're done looking at an image in phast
; before moving on to its next step, you can call phast_activate after
; sending your image to phast.  This will make your external program
; stop until you quit out of phast_activate mode.
      
  common phast_state
  
  if (not(xregistered('phast', /noshow))) then begin
     print, 'No PHAST window currently exists.'
     return
  endif
  
  state.activator = 1
  activator = 1
  
  while (activator EQ 1) do begin
     
     wait, 0.01
     void = widget_event(/nowait)
     
     ; If phast is killed by the window manager, then by the time we get here
     ; the state structure has already been destroyed by phast_shutdown.
     if (size(state, /type) NE 8) then begin
        activator = 0
     endif else begin
        activator = state.activator
     endelse
     
  endwhile
  
  widget_control, /hourglass
end

;-------------------------------------------------------------------

pro phast_add_image, new_image, filename, head, refresh_index = refresh, refresh_toggle=refresh_toggle, newimage = newimage, dir_add=dir_add,dir_num=dir_num
      
;outine to add a newly-loaded image to the image archive.  If this is
;the first image, the archive is initiallized before the image is added.
  
  common phast_state
  common phast_images
  if not keyword_set(refresh_toggle) then begin ;normal image adding
     new_image_size = size(new_image)
     if not keyword_set(dir_add) then begin
        if state.num_images gt 0 then begin ;check not first image
           state.num_images++
           if state.num_images gt state.archive_size then phast_expand_archive
           image_archive[state.num_images-1] = obj_new('phast_image') ;create new image object
           image_archive[state.num_images-1]->set_image, new_image
           image_archive[state.num_images-1]->set_name, filename
           image_archive[state.num_images-1]->set_header, head, /string
           image_archive[state.num_images-1]->set_rotation,0.0
           phast_setheader,head
           newimage = 1
           state.current_image_index = state.num_images-1
        endif else begin        ;handle first image add
           state.num_images++
           image_archive[0] = obj_new('phast_image') ;create new image object
           image_archive[0]->set_image, new_image
           image_archive[0]->set_name, filename
           image_archive[0]->set_header, head, /string
           image_archive[0]->set_rotation,0.0
           newimage = 1
        endelse
     endif else begin           ;handle directory add
        if keyword_set(dir_num) then begin
           ;; if state.num_images gt 0 then begin
              phast_expand_archive, num=dir_num
              image_archive[state.num_images] = obj_new('phast_image') ;create new image object
              image_archive[state.num_images]->set_image, new_image
              image_archive[state.num_images]->set_name, filename
              image_archive[state.num_images]->set_header, head, /string
              image_archive[state.num_images]->set_rotation,0.0
              state.num_images++
              newimage = 1
           ;; endif else begin     ;handle first image add
           ;;    state.num_images++
           ;;    image_archive[0] = obj_new('phast_image') ;create new image object
           ;;    image_archive[0]->set_image, new_image
           ;;    image_archive[0]->set_name, filename
           ;;    image_archive[0]->set_header, head
           ;;    image_archive[0]->set_rotation,0.0
           ;;    newimage = 1
           ;; endelse
        endif else begin
           image_archive[state.num_images] = obj_new('phast_image') ;create new image object
           image_archive[state.num_images]->set_image, new_image
           image_archive[state.num_images]->set_name, filename
           image_archive[state.num_images]->set_header, head, /string
           image_archive[state.num_images]->set_rotation,0.0
           state.num_images++
        endelse
        state.current_image_index = state.num_images-1
     endelse
     
  endif else begin              ;handle image refresh
     image_archive[refresh]->set_image, new_image
     image_archive[refresh]->set_name, filename
     image_archive[refresh]->set_header, head, /string
     image_archive[refresh]->set_rotation,0.0
     newimage = 1
  endelse
        
  ;update widgets
  if not keyword_set(refresh_toggle) then widget_control,state.image_counter_id,set_value='Cycle images: '+ strtrim(string(state.current_image_index+1),1) + ' of ' + strtrim(string(state.num_images),1)
  
  ;format filenames for dropdown box
  short_names = strarr(state.num_images)
  for i=0, state.num_images-1 do begin
     temp = strsplit(image_archive[i]->get_name(),'/\.',count=count,/extract)
     short_names[i] = temp[count-2]
  end
  widget_control,state.image_select_id,set_value=short_names
end

;-------------------------------------------------------------------
      
pro phast_changemode
      
; Use 'm' keypress to cycle through mouse modes
      
  common phast_state
  
  case state.mousemode of
     'color': begin
        state.mousemode = 'zoom'
        widget_control, state.mode_droplist_id, set_droplist_select=1
     end
     'zoom': begin
        state.mousemode = 'blink'
        widget_control, state.mode_droplist_id, set_droplist_select=2
     end
     'blink': begin
        state.mousemode = 'imexam'
        widget_control, state.mode_droplist_id, set_droplist_select=3
     end
     'imexam': begin
        state.mousemode = 'vector'
        widget_control, state.mode_droplist_id, set_droplist_select=4
     end
     'vector': begin
        state.mousemode = 'label'
        widget_control, state.mode_droplist_id, set_droplist_select=5
     end
     'label': begin
        state.mousemode = 'color'
        widget_control, state.mode_droplist_id, set_droplist_select=0
     end
  endcase      
end

;---------------------------------------------------------------------

pro phast_check_updates,silent=silent

  ;routine to check for updates to PhAst.  Set keyword /silent to
  ;suppress popup if PhAst is up to date.

  common phast_state
  
  error = 0
  catch, error_status
  if error_status ne 0 then begin
     print, 'No internet connection: updates not checked'
     catch, /cancel
     error = 1
  endif

  if error eq 0 then begin
     new_version = webget('http://noao.edu/staff/mighell/phast/version.html')
     if float(new_version.text[0]) gt float(state.version) then begin
        changes = webget('http://noao.edu/staff/mighell/phast/changelog.html')
        
        if (!D.NAME eq 'WIN') then newline = string([13B, 10B]) else newline = string(10B) ; create newline
    
        message = 'PhAst '+new_version.text[0]+' is now available!'+newline+newline+'Changes include:'
        for i=0, n_elements(changes.text)-1 do message += newline+changes.text[i]
        message += newline+newline+'Download PhAst '+new_version.text[0]+' at http://www.noao.edu/staff/mighell/phast/'
        
        result = dialog_message(message,/info,/center)
     endif else begin
        if not keyword_set(silent) then result = dialog_message('          PhAst is up to date!          ',/info,/center)
     endelse
  endif
end

;----------------------------------------------------------------------

pro phast_cycle_images, direction,animate=animate

;routine to switch between images in the image archive.  When an image
;is switched, its contents are copied into the main_image array, which
;legacy phast uses.  The filename and header info are also transfered.

  common phast_state
  common phast_images
  
  if state.num_images gt 1 then begin
    if not keyword_set(animate) then begin
      if direction eq -1 and  state.current_image_index ne 0 then state.current_image_index--
      if direction eq 1 and state.current_image_index ne state.num_images-1 then state.current_image_index++
    endif else begin ;deal with animation type
      case state.animate_type of
        'forward': begin
        
          if direction eq -1 then begin
            if state.current_image_index ne 0 then begin
              state.current_image_index--
            endif else state.current_image_index = state.num_images-1
          endif
          if direction eq 1 then begin
            if state.current_image_index ne state.num_images-1 then begin
              state.current_image_index++
            endif else state.current_image_index = 0
          endif
        end
        
        'backward': begin
        
          if direction eq 1 then begin
            if state.current_image_index ne 0 then begin
              state.current_image_index--
            endif else state.current_image_index = state.num_images-1
          endif
          if direction eq -1 then begin
            if state.current_image_index ne state.num_images-1 then begin
              state.current_image_index++
            endif else state.current_image_index = 0
          endif
        end
        
        'bounce': begin
          if state.bounce_direction eq 1 then begin
            if state.current_image_index ne state.num_images-1 then begin
              state.current_image_index++
            endif else state.bounce_direction = -1
          endif
          if state.bounce_direction eq -1 then begin
            if state.current_image_index ne 0 then begin
              state.current_image_index--
            endif else begin
              state.current_image_index++
              state.bounce_direction = 1
            endelse
          endif
          
          
        end
        
      end
    end
    
    
    main_image = image_archive[state.current_image_index]->get_image()
    state.imagename  = image_archive[state.current_image_index]->get_name()
    phast_setheader, image_archive[state.current_image_index]->get_header(/string)
    counter_string = 'Cycle images: ' + strtrim(string(state.current_image_index+1),1) + ' of ' + strtrim(string(state.num_images),1)
    temp = strsplit(image_archive[state.current_image_index]->get_name(),'/\',count=count,/extract)
    state.sex_catalog_path = ""
    for i=0,count-2 do begin
      state.sex_catalog_path += '/'
      state.sex_catalog_path += temp[i]
    end
    state.sex_catalog_path +='/'
    ;update widgets
    widget_control,state.image_counter_id,set_value= counter_string
    widget_control,state.image_select_id,set_droplist_select=state.current_image_index
    phast_getstats,/align,/noerase                ;update stats based on new image
    phast_settitle                                ;update title bar with object name
    phast_displayall              ;redraw screen
  ; phast_refresh
  end
end

;----------------------------------------------------------------------
      
pro phast_drawdepth, event
      
; draw the box showing the region selected for a depth plot
      
  common phast_state
  
  
  ; button press: create initial pixmap and start drawing vector
  if (event.type EQ 0) then begin
     window, /free, xsize = state.draw_window_size[0], $
             ysize = state.draw_window_size[1], /pixmap
     state.vector_pixmap_id = !d.window
     device, copy=[0, 0, state.draw_window_size[0], $
                   state.draw_window_size[1], 0, 0, state.draw_window_id]
     phast_resetwindow
  endif
  
  ; button release: redisplay initial image
  if (event.type EQ 1) then begin
     phast_setwindow, state.draw_window_id
     device, copy=[0, 0, state.draw_window_size[0], $
                   state.draw_window_size[1], 0, 0, state.vector_pixmap_id]
     phast_resetwindow
     wdelete, state.vector_pixmap_id
  endif
  
  ; motion event: redraw with new vector
  if (event.type EQ 2) then begin
     
     phast_setwindow, state.draw_window_id
     
     device, copy=[0, 0, state.draw_window_size[0], $
                   state.draw_window_size[1], 0, 0, state.vector_pixmap_id]
     xvector = [state.vectorstart[0], state.vectorstart[0], $
                event.x, event.x, state.vectorstart[0]]
     yvector = [state.vectorstart[1], event.y, event.y, $
                state.vectorstart[1], state.vectorstart[1]]
     
     plots, xvector, yvector, /device, color = state.box_color
     
     phast_resetwindow
  endif
end

;----------------------------------------------------------------------

pro phast_debug_info

;routine to print some basic debugging info to the screen

common phast_state
common phast_images

help, image_archive, main_image
help, state, /structure
end

;----------------------------------------------------------------------
      
pro phast_drawvector, event
  
  common phast_state
  
  ; button press: create initial pixmap and start drawing vector
  if (event.type EQ 0) then begin
     window, /free, xsize = state.draw_window_size[0], $
             ysize = state.draw_window_size[1], /pixmap
     state.vector_pixmap_id = !d.window
     device, copy=[0, 0, state.draw_window_size[0], $
                   state.draw_window_size[1], 0, 0, state.draw_window_id]
     phast_resetwindow
  endif
  
  ; button release: redisplay initial image
  if (event.type EQ 1) then begin
     phast_setwindow, state.draw_window_id
     device, copy=[0, 0, state.draw_window_size[0], $
                   state.draw_window_size[1], 0, 0, state.vector_pixmap_id]
     phast_resetwindow
     wdelete, state.vector_pixmap_id
  endif
  
  ; motion event: redraw with new vector
  if (event.type EQ 2) then begin
     phast_setwindow, state.draw_window_id
     
     device, copy=[0, 0, state.draw_window_size[0], $
                   state.draw_window_size[1], 0, 0, state.vector_pixmap_id]
     xvector = [state.vectorstart[0], event.x]
     yvector = [state.vectorstart[1], event.y]
     
     plots, xvector, yvector, /device, color = state.box_color
     
     phast_resetwindow
  endif      
end

 ;---------------------------------------------------------------------
      
pro phast_draw_blink_event, event
      
; Event handler for blink mode. This is the legacy blink mode from ATV.
      
  common phast_state
  common phast_images
        
  if (!d.name NE state.graphicsdevice) then return
  if (state.bitdepth EQ 24) then true = 1 else true = 0
  case event.type of
     0: begin                   ; button press
        if state.animate_toggle eq 1 then begin
           phast_animate
        endif else begin
           phast_setwindow, state.draw_window_id
           ;define the unblink image if needed
           if ((state.newrefresh EQ 1) AND (state.blinks EQ 0)) then begin
              unblink_image = tvrd(true = true)
              state.newrefresh = 0
           endif
           
           case event.press of
              1: if n_elements(blink_image1) GT 1 then $
                 tv, blink_image1, true = true
              2: if n_elements(blink_image2) GT 1 then $
                 tv, blink_image2, true = true
              4: if n_elements(blink_image3) GT 1 then $
                 tv, blink_image3, true = true
              else: event.press = 0 ; in case of errors
           endcase
           state.blinks = (state.blinks + event.press) < 7
        end
     end
     1: begin                   ; button release
        if state.animate_toggle eq 1 then begin
        endif else begin
           if (n_elements(unblink_image) EQ 0) then return ; just in case
           phast_setwindow, state.draw_window_id
           state.blinks = (state.blinks - event.release) > 0
           case state.blinks of
              0: tv, unblink_image, true = true
              1: if n_elements(blink_image1) GT 1 then $
                 tv, blink_image1, true = true else $
                    tv, unblink_image, true = true
              2: if n_elements(blink_image2) GT 1 then $
                 tv, blink_image2, true = true else $
                    tv, unblink_image, true = true
              3: if n_elements(blink_image1) GT 1 then begin
                 tv, blink_image1, true = true
              endif else if n_elements(blink_image2) GT 1 then begin
                 tv, blink_image2, true = true
              endif else begin
                 tv, unblink_image, true = true
              endelse
              4: if n_elements(blink_image3) GT 1 then $
                 tv, blink_image3, true = true $
              else tv, unblink_image, true = true
              5: if n_elements(blink_image1) GT 1 then begin
                 tv, blink_image1, true = true
              endif else if n_elements(blink_image3) GT 1 then begin
                 tv, blink_image3, true = true
              endif else begin
                 tv, unblink_image, true = true
              endelse
              6: if n_elements(blink_image2) GT 1 then begin
                 tv, blink_image2, true = true
              endif else if n_elements(blink_image4) GT 1 then begin
                 tv, blink_image4, true = true
              endif else begin
                 tv, unblink_image, true = true
              endelse
              else: begin       ; check for errors
                 state.blinks = 0
                 tv, unblink_image, true = true
              end
           endcase
        end
     end
     2: phast_draw_motion_event, event ; motion event
  endcase
        
  widget_control, state.draw_widget_id, /sensitive ;, /input_focus
  phast_resetwindow
end

;--------------------------------------------------------------------

pro phast_draw_color_event, event
      
; Event handler for color mode
      
  common phast_state
  common phast_images
       
  case event.type of
     0: begin                   ; button press
        if (event.press EQ 1) then begin
           state.cstretch = 1
           phast_stretchct, event.x, event.y, /getcursor
           phast_resetwindow
           phast_colorbar
        endif else begin
           phast_zoom, 'none', /recenter
        endelse
     end
     1: begin
        state.cstretch = 0      ; button release
        if (state.bitdepth EQ 24) then phast_refresh
        phast_draw_motion_event, event
     end
     2: begin                   ; motion event
        if (state.cstretch EQ 1) then begin
           phast_stretchct, event.x, event.y, /getcursor
           phast_resetwindow
           if (state.bitdepth EQ 24) then phast_refresh, /fast
        endif else begin
           phast_draw_motion_event, event
        endelse
     end
  endcase
  
  widget_control, state.draw_widget_id, /sensitive ;, /input_focus  
end

;--------------------------------------------------------------------
      
pro phast_draw_event, event
      
; top-level event handler for draw widget events
      
  common phast_state
  
  if (!d.name NE state.graphicsdevice) then return
  
  if (event.type EQ 0 or event.type EQ 1 or event.type EQ 2) then begin
     case state.mousemode of
        'color':  phast_draw_color_event, event
        'zoom':   phast_draw_zoom_event, event
        'blink':  phast_draw_blink_event, event
        'imexam': begin ;prevent photometry errors on start screen
           if state.num_images gt 0 then phast_draw_phot_event, event
        end
        'vector': phast_draw_vector_event, event
        'label':  phast_draw_label_event, event
     endcase
  endif
  
  if (event.type EQ 5 or event.type EQ 6) then $
     phast_draw_keyboard_event, event
  
  if (xregistered('phast', /noshow)) then $
     widget_control, state.draw_widget_id, /sensitive ;, /input_focus
          
end

 ;--------------------------------------------------------------------
      
pro phast_draw_keyboard_event, event
 
;event handler for keyboard presses 
  
  common phast_state
  common phast_images
  common phast_color
        
 ; Only want to look for key presses, not key releases.
  if (event.release EQ 1) then return
  
  if (event.type EQ 5) then begin
     
     eventchar = string(event.ch)
     
     if (!d.name NE state.graphicsdevice and eventchar NE 'q') then return
     if (state.bitdepth EQ 24) then true = 1 else true = 0
     case eventchar of
        '1': phast_move_cursor, eventchar
        '2': phast_move_cursor, eventchar
        '3': phast_move_cursor, eventchar
        '4': phast_move_cursor, eventchar
        '6': phast_move_cursor, eventchar
        '7': phast_move_cursor, eventchar
        '8': phast_move_cursor, eventchar
        '9': phast_move_cursor, eventchar
        'r': phast_rowplot, /newcoord
        'c': phast_colplot, /newcoord
        's': phast_surfplot, /newcoord
        't': phast_contourplot, /newcoord
        'h': phast_histplot, /newcoord
        'p': phast_apphot
        'i': phast_showstats
        'm': phast_changemode
        'w': print, state.coord
        'x': phastextract, /newcoord
        'e': phasterase
        '!': begin
           phast_setwindow, state.draw_window_id
           blink_image1 = tvrd(true = true)
           phast_resetwindow
        end
        '@': begin
           phast_setwindow, state.draw_window_id
           blink_image2 = tvrd(true = true)
           phast_resetwindow
        end
        '#': begin
           phast_setwindow, state.draw_window_id
           blink_image3 = tvrd(true = true)
           phast_resetwindow
        end
        'q': if (state.activator EQ 0) then phast_shutdown $
        else state.activator = 0
        'Q': if (state.activator EQ 0) then phast_shutdown $
        else state.activator = 0
        
       ; osiris cleaning routines:
       ;        'd': osirisclean_depthplot, state.coord
       ;        'f': osirisclean_cleanpix, state.coord
            
        else:                   ;any other key press does nothing
     endcase
  endif
  
  ; Starting with IDL 6.0, can generate events on arrow keys:
  if (event.type EQ 6) then begin
     case event.key of
        5: phast_move_cursor, '4'
        6: phast_move_cursor, '6'
        7: phast_move_cursor, '8'
        8: phast_move_cursor, '2'
        9: phast_cycle_images,1 ;Page Up
        10: phast_cycle_images, -1 ;Page Down
        11: phast_image_switch, 0 ;Home
        12: phast_image_switch, state.num_images-1 ;end
        else:
     endcase
  endif 
  
  if (xregistered('phast', /noshow)) then $
     widget_control, state.draw_widget_id, /sensitive ;, /input_focus
  
end

;--------------------------------------------------------------------

pro phast_draw_label_event, event
      
;Event handler for label mode
      
  common phast_state
  
  if (event.type EQ 2) then phast_draw_motion_event, event
  
  case event.press of
     1: begin                   ;left mouse button
        state.circ_coord[0] = event.x
        state.circ_coord[1] = event.y
     end
                                ;2: print,state.offset
     4: begin                   ;right mouse button
        text = dialog_input()
        phastxyouts,event.x+state.offset[0],event.y+state.offset[1],text,charsize=2.0
     end
     else:                      ;other buttons do nothing
  endcase
  
  case event.release of
     1: begin
        rad = sqrt((state.circ_coord[0]-event.x)^2+(state.circ_coord[1]-event.y)^2)
        x = state.offset[0]+state.circ_coord[0]/state.zoom_factor
        y = state.offset[1]+state.circ_coord[1]/state.zoom_factor
        phast_setregion,x=x,y=y,radius=rad
     end
     else:
  endcase  
end

;--------------------------------------------------------------------
      
pro phast_draw_motion_event, event
      
; Event handler for motion events in draw window
      
  common phast_state
  
  if (!d.name NE state.graphicsdevice) then return
  
  tmp_event = [event.x, event.y]
  state.coord = $
     round( (0.5 >  ((tmp_event / state.zoom_factor) + state.offset) $
             < (state.image_size - 0.5) ) - 0.5)
  phast_gettrack
  
  widget_control, state.draw_widget_id, /sensitive ;, /input_focus
        
  ;if phast_pixtable on, then create a 5x5 array of pixel values and the
  ;X & Y location strings that are fed to the pixel table
        
  if (xregistered('phast_pixtable', /noshow)) then phast_pixtable_update
end

;-------------------------------------------------------------------

pro phast_draw_phot_event, event
      
; Event handler for ImExam mode
      
  common phast_state
  common phast_images
  
  if (!d.name NE state.graphicsdevice) then return
  
  if (event.type EQ 0) then begin
     case event.press of
        1: phast_apphot
        2: phast_zoom, 'none', /recenter
        4: phast_showstats
        else:
     endcase
  endif
  
  if (event.type EQ 2) then phast_draw_motion_event, event
  
  widget_control, state.draw_widget_id, /sensitive ;, /input_focus
end

;----------------------------------------------------------------------
      
pro phast_draw_vector_event, event
      
; Check for left button press/depress, then get coords at point 1 and
; point 2.  Call phast_lineplot.  Calculate vector distance between
; endpoints and plot Vector Distance vs. Pixel Value with phast_vectorplot
      
  common phast_state
  common phast_images
  
  if (!d.name NE state.graphicsdevice) then return
  
  ;phast_setwindow, state.draw_window_id
        
  case event.type of
     0: begin; button press
        if ((event.press EQ 1) AND (state.vectorpress EQ 0)) then begin
           ; left button press
           state.vector_coord1[0] = state.coord[0]
           state.vector_coord1[1] = state.coord[1]
           state.vectorstart = [event.x, event.y]
           phast_drawvector, event
           state.vectorpress = 1
        endif
        if ((event.press EQ 2) AND (state.vectorpress EQ 0)) then begin
        ; left button press
           state.vector_coord1[0] = state.coord[0]
           state.vector_coord1[1] = state.coord[1]
           state.vectorstart = [event.x, event.y]
           phast_drawvector, event
           state.vectorpress = 2
        endif
        if ((event.press EQ 4) AND (state.vectorpress EQ 0)) then begin
        ; right button press
           state.vector_coord1[0] = state.coord[0]
           state.vector_coord1[1] = state.coord[1]
           state.vectorstart = [event.x, event.y]
           phast_drawdepth, event
           state.vectorpress = 4
        endif
     end
     1: begin  ; button release
        if ((event.release EQ 1) AND (state.vectorpress EQ 1)) then begin
        ; left button release
           state.vectorpress = 0
           state.vector_coord2[0] = state.coord[0]
           state.vector_coord2[1] = state.coord[1]
           phast_drawvector, event
           phast_vectorplot, /newcoord
        endif
        if ((event.release EQ 2) AND (state.vectorpress EQ 2)) then begin
        ; left button release
           state.vectorpress = 0
           state.vector_coord2[0] = state.coord[0]
           state.vector_coord2[1] = state.coord[1]
           phast_drawvector, event
           phast_gaussfit, /newcoord
        endif
        if ((event.release EQ 4) AND (state.vectorpress EQ 4)) then begin
        ; right button release
           state.vectorpress = 0
           state.vector_coord2[0] = state.coord[0]
           state.vector_coord2[1] = state.coord[1]
           phast_drawdepth, event
           phast_depthplot, /newcoord
        endif
        
     end
     2: begin                   ; motion event
        phast_draw_motion_event, event
        if (state.vectorpress EQ 1) then phast_drawvector, event
        if (state.vectorpress EQ 2) then phast_drawvector, event
        if (state.vectorpress EQ 4) then phast_drawdepth, event
     end
     
     else:
  endcase
  
  widget_control, state.draw_widget_id, /sensitive ;, /input_focus
end

;------------------------------------------------------------------
      
pro phast_draw_zoom_event, event
  
; Event handler for zoom mode
      
  common phast_state
  
  if (!d.name NE state.graphicsdevice) then return
  
  if (event.type EQ 0) then begin
     case event.press of
        1: phast_zoom, 'in', /recenter
        2: phast_zoom, 'none', /recenter
        4: phast_zoom, 'out', /recenter
     endcase
  endif
  
  if (event.type EQ 2) then phast_draw_motion_event, event
  
  if (xregistered('phast', /noshow)) then $
     widget_control, state.draw_widget_id, /sensitive ;, /input_focus
end

;--------------------------------------------------------------------
      
pro phast_event, event
      
; Main event loop for phast top-level base, and for all the buttons.
      
  common phast_state
  common phast_images
  common phast_color
  common phast_pdata
  common phast_images
        
  widget_control, event.id, get_uvalue = uvalue
  
  if (!d.name NE state.graphicsdevice and uvalue NE 'done') then return
  
  ; Get currently active window
  phast_getwindow
        
  case uvalue of
     
     'phast_base': begin
        c = where(tag_names(event) EQ 'ENTER', count)
        if (count EQ 0) then begin ; resize event
           phast_resize
           phast_refresh
        endif
     end
     
      ;cycle image buttons
     'left_button': phast_cycle_images, -1
     
     'right_button': phast_cycle_images, 1
     
     'image_select_box': if state.num_images gt 0 then phast_image_switch, event.index
     
     'mode': begin
        case event.index of
           0: state.mousemode = 'color'
           1: state.mousemode = 'zoom'
           2: state.mousemode = 'blink'
           3: state.mousemode = 'imexam'
           4: state.mousemode = 'vector'
           5: state.mousemode = 'label'
           else: print, 'Unknown mouse mode!'
        endcase
     end
     
     'invert': begin            ; invert the color table
        state.invert_colormap = abs(state.invert_colormap - 1)
        
        r_vector = reverse(r_vector)
        g_vector = reverse(g_vector)
        b_vector = reverse(b_vector)
        
        phast_setwindow, state.draw_window_id
        phast_stretchct
        phast_resetwindow
            
        ; For 24-bit color, need to refresh display after stretching color
        ; map.  Can refresh in /fast mode if there are no overplots
        if (state.bitdepth EQ 24) then begin
           if ptr_valid(plot_ptr[1]) then begin
              phast_refresh
           endif else begin
              phast_refresh, /fast
           endelse
        endif
     end
     
     'restretch_button': phast_restretch
     
     'min_text': begin          ; text entry in 'min = ' box
        phast_get_minmax, uvalue, event.value
        phast_displayall
     end
     
     'max_text': begin          ; text entry in 'max = ' box
        phast_get_minmax, uvalue, event.value
        phast_displayall
     end
     
     'autoscale_button': begin  ; autoscale the image
        phast_autoscale
        phast_displayall
     end
     
     'full_range': begin        ; display the full intensity range
        state.min_value = state.image_min
        state.max_value = state.image_max
        if state.min_value GE state.max_value then begin
           state.min_value = state.max_value - 1
           state.max_value = state.max_value + 1
        endif
        phast_set_minmax
        phast_displayall
     end
     
     'zoom_in':  phast_zoom, 'in' ; zoom buttons
     'zoom_out': phast_zoom, 'out'
     'zoom_one': phast_zoom, 'one'
     
     'center': begin            ; center image and preserve current zoom level
        state.centerpix = round(state.image_size / 2.)
        phast_refresh
     end
     
     'fullview': phast_fullview
      
     ;blink controls
     'blink_base_toggle':begin
        if state.tb_blink_toggle eq 1 then begin
           widget_control,state.blink_base_id,ysize=1
           state.tb_blink_toggle = 0
        endif else begin
           widget_control,state.blink_base_id,ysize=130
           state.tb_blink_toggle =1
        endelse
     end
     'blink_first': phast_image_switch,0
     'blink_last': phast_image_switch,state.num_images-1
     'blink_forward': phast_cycle_images,1
     'blink_back': phast_cycle_images,-1
     'blink_pause': state.pause_state = 1
     'blink_animate': begin
        phast_cycle_images,1,/animate
        widget_control,state.blink_base_label_id,timer=state.animate_speed
        state.pause_state = 0
     end
     'blink_base_label': begin  ;NOTE: USED FOR ANIMATIONS ONLY
        if state.pause_state eq 0 then begin
           phast_cycle_images,1,/animate
           widget_control, state.blink_base_label_id, timer=state.animate_speed
        end
     end
     'speed_slider': begin
        speed = 10/float(event.value)
        state.animate_speed = speed ;since speed is really a wait param (ie, a time)
        widget_control,state.speed_label_id, set_value=$
                       'Animate speed: ' + strmid(strtrim(string(1/speed),1),0,4)+ ' image/sec'
     end
     'type_forward': state.animate_type = 'forward'
     'type_backward': state.animate_type = 'backward'
     'type_bounce': state.animate_type = 'bounce'
     
     ;star overlay
     'overlay_toggle':begin
        if state.tb_overlay_toggle eq 0 then begin
           widget_control,state.overlay_stars_box_id,ysize=150
           state.tb_overlay_toggle = 1
        endif else begin
           widget_control,state.overlay_stars_box_id,ysize=1
           state.tb_overlay_toggle = 0
        endelse
     end
     'overlay_catalog': state.overlay_catalog = widget_info(state.overlay_catalog_id, /droplist_select)
     'mag_select':      begin & widget_control,state.mag_select_id,get_value=str
        state.mag_limit = float(str) ;convert from string
     end
     'display_stars':   phast_display_stars
     'display_char':    state.display_char = event.value
     'search_field':
     'search_button':   phast_search_stars
     'erase_button':    phasterase
     
     ;SPICE controls
     'spice_toggle': begin
        if state.tb_spice_toggle eq 0 then begin
           widget_control,state.spice_box_id,ysize=35
           state.tb_spice_toggle = 1
        endif else begin
           widget_control,state.spice_box_id,ysize=1
           state.tb_spice_toggle = 0
        endelse
     end
     'check_moons': phast_check_moons
     
     ;align
     'align_toggle': begin
        if state.align_toggle eq 0 then begin
           offset = state.zoom_factor*phast_get_image_offset()
           if not finite(offset[0]) then begin
              result = dialog_message('Error: Offset distance larger than image size. PhAst does not currently support aligning images which do not overlap.', /error,/center)
              widget_control, state.align_toggle_button, set_button=0
           endif else  state.align_toggle = 1
        endif else state.align_toggle = 0
     end
     
     else:  print, 'No match for uvalue....' ; bad news if this happens
  endcase
  widget_control, state.draw_base_id, /input_focus
end

;---------------------------------------------------------------

pro phast_expand_archive, num=num

;expand archive by the amount specified by num.  If num is not
;specified, use state.archive_chunk_size

common phast_state
common phast_images

if not keyword_set(num) then num = state.archive_chunk_size


state.archive_size += num
temp_arr = image_archive

image_archive = objarr(state.archive_size)
image_archive[0] = temporary(temp_arr)
end

;---------------------------------------------------------------

pro phast_fitsext_read, fitsfile, numext, head, cancelled, newimage=newimage

  ; Fits reader for fits extension files

  common phast_state
  common phast_images
  
  numlist = ''
  for i = 1, numext do begin
    numlist = strcompress(numlist + string(i) + '|', /remove_all)
  endfor
  
  numlist = strmid(numlist, 0, strlen(numlist)-1)
  
  droptext = strcompress('0, droplist, ' + numlist + $
    ', label_left=Select Extension:, set_value=0')
    
  formdesc = ['0, button, Read Primary Image, quit', $
    '0, label, OR:', $
    droptext, $
    '0, button, Read Fits Extension, quit', $
    '0, button, Cancel, quit']
    
  textform = cw_form(formdesc, /column, $
    title = 'Fits Extension Selector')
    
  if (textform.tag4 EQ 1) then begin  ; cancelled
    cancelled = 1
    return
  endif
  
  if (textform.tag3 EQ 1) then begin   ;extension selected
    extension = long(textform.tag2) + 1
  endif else begin
    extension = 0               ; primary image selected
  endelse
  
  ; Make sure it's not a fits table: this would make mrdfits crash
  head = headfits(fitsfile);, exten=extension)
  xten = strcompress(sxpar(head, 'XTENSION'), /remove_all)
  if (xten EQ 'BINTABLE') then begin
    phast_message, 'File appears to be a FITS table, not an image.', $
      msgtype='error', /window
    cancelled = 1
    return
  endif
  
  if (extension GE 1) then begin
    state.title_extras = strcompress('Extension ' + string(extension))
  endif else begin
    state.title_extras = 'Primary Image'
  endelse
  
  
  ; Read in the image
  main_image=0
  
  ; use fits_read so that extension headers will inherit primary header
  ; keywords.   Set /pdu to always inherit the primary header.
  fits_read, fitsfile, main_image, head, exten_no = extension, /pdu
  phast_add_image, main_image, fitsfile, head, newimage=newimage
end

;----------------------------------------------------------------

pro phast_fpack_read, fitsfile, numext, head, cancelled

  ; fits reader for fpack-compressed .fz images with no extensions.   Note: uses
  ; readfits.pro to handle .fz format, but this does not handle header
  ; inheritance for extensions.  This is why we still use fits_read for
  ; normal, non-fz format images with extensions.

  common phast_state
  common phast_images
  
  main_image = 0
  
  if (numext LE 1) then begin
    main_image = readfits(fitsfile, head)
  endif else begin
    numlist = ''
    for i = 1, numext do begin
      numlist = strcompress(numlist + string(i) + '|', /remove_all)
    endfor
    
    numlist = strmid(numlist, 0, strlen(numlist)-1)
    
    droptext = strcompress('0, droplist, ' + numlist + $
      ', label_left=Select Extension:, set_value=0')
      
    formdesc = ['0, button, Read Primary Image, quit', $
      '0, label, OR:', $
      droptext, $
      '0, button, Read Fits Extension, quit', $
      '0, button, Cancel, quit']
      
    textform = cw_form(formdesc, /column, $
      title = 'Fits Extension Selector')
      
    if (textform.tag4 EQ 1) then begin ; cancelled
      cancelled = 1
      return
    endif
    
    if (textform.tag3 EQ 1) then begin ;extension selected
      extension = long(textform.tag2) + 1
    endif else begin
      extension = 0             ; primary image selected
    endelse
    
    if (extension GE 1) then begin
      state.title_extras = strcompress('Extension ' + string(extension))
    endif else begin
      state.title_extras = 'Primary Image'
    endelse
    
    main_image = readfits(fitsfile, head);, exten_no = extension)
    
  endelse
end

;----------------------------------------------------------------------

pro phast_getdss

  common phast_state
  common phast_images
  
  formdesc = ['0, text, , label_left=Object Name: , width=15, tag=objname', $
    '0, button, NED|SIMBAD, set_value=1, label_left=Object Lookup:, exclusive, tag=lookupsource', $
    '0, label, Or enter J2000 Coordinates:, CENTER', $
    '0, text, , label_left=RA   (hh:mm:ss.ss): , width=15, tag=ra', $
    '0, text, , label_left=Dec (+dd:mm:ss.ss): , width=15, tag=dec', $
    '0, droplist, 1st Generation|2nd Generation Blue|2nd Generation Red|2nd Generation Near-IR, label_left=Band:, set_value=0,tag=band ', $
    '0, float, 10.0, label_left=Image Size (arcmin; max=60): ,tag=imsize', $
  '1, base, , row', $
    '0, button, GetImage, tag=getimage, quit', $
    '0, button, Cancel, tag=cancel, quit']
    
  archiveform = cw_form(formdesc, /column, title = 'phast: Get DSS Image')
  
  if (archiveform.cancel EQ 1) then return
  
  if (archiveform.imsize LE 0.0 OR archiveform.imsize GT 60.0) then begin
    phast_message, 'Image size must be between 0 and 60 arcmin.', $
      msgtype='error', /window
    return
  endif
  
  case archiveform.band of
    0: band = '1'
    1: band = '2b'
    2: band = '2r'
    3: band = '2i'
    else: print, 'error in phast_getdss!'
  endcase
  
  ;case archiveform.lookupsource of
  ;    0: ned = 1
  ;    1: ned = 0  ; simbad lookup
  ;endcase
  
  ; Temporary fix: ned lookups don't work due to change in ned
  ; query format.  Use SIMBAD always now, regardless of user choice.
  ned = 0
  
  widget_control, /hourglass
  if (archiveform.objname NE '') then begin
    ; user entered object name
    querysimbad, archiveform.objname, ra, dec, found=found, ned=ned, $
      errmsg=errmsg
    if (found EQ 0) then begin
      phast_message, errmsg, msgtype='error', /window
      return
    endif
  endif else begin
    ;  user entered ra, dec
    rastring = archiveform.ra
    decstring = archiveform.dec
    phast_getradec, rastring, decstring, ra, dec
  endelse
  
  ; as of nov 2006, stsci server doesn't seem to recognize '2i'
  ; band in the way it used to.  Use eso server for 2i.
  if (band NE '2i') then begin
    querydss, [ra, dec], tmpimg, tmphdr, imsize=archiveform.imsize, $
      survey=band
  endif else begin
    querydss, [ra, dec], tmpimg, tmphdr, imsize=archiveform.imsize, $
      survey=band, /eso
  endelse
  
  phast, temporary(tmpimg), header=temporary(tmphdr)
end

;----------------------------------------------------------------------

pro phast_image_switch, index

  ;routine to jump to a give image in the image archive.  Image,
  ;filename, and header info are copied into the appropriate places for
  ;access by legacy phast

  common phast_state
  common phast_images
  if state.num_images gt 0 then begin
    state.current_image_index = index
    main_image = image_archive[state.current_image_index]->get_image()
    state.imagename  = image_archive[state.current_image_index]->get_name()
    phast_setheader, image_archive[state.current_image_index]->get_header(/string)
    counter_string = 'Cycle images: ' + strtrim(string(state.current_image_index+1),1) + ' of ' + strtrim(string(state.num_images),1)
    ;update widgets
    widget_control,state.image_counter_id,set_value= counter_string
    phast_getstats,/align,/noerase                ;update stats based on new image
    phast_settitle                                ;update title bar with object name
    phast_displayall            ;redraw screen
  end
end

;----------------------------------------------------------------------

pro phast_image__define
  
;class definition for image class
  
  struct = {phast_image,$
            catalog: ptr_new(), $ ;holds downloaded astrometric catalog
            catalog_type: ptr_new(), $ ;what type of catalog is stored
            image: ptr_new(),$  ;array which holds the image data
            header_string: ptr_new(),$  ;holds the image header in string format
            header_struct: ptr_new(), $ ;holds the image header as a structure
            name:ptr_new(),$    ;holds the file path to the image
            size:ptr_new(),$    ;contains the size of the image: [x,y]
            astr:ptr_new(),$    ;holds astrometry data, if available
            rotation:ptr_new()$ ;holds rotation state of image in deg
           }
end

;----------------------------------------------------------------------

function phast_image::astr_valid
  
;routine to check if astrometry data present
  
  if ptr_valid(self.astr) then begin
     return, 1
  endif else return, 0
end

;----------------------------------------------------------------------

function phast_image::catalog_valid
  
;routine to check if catalog data present
  
  if ptr_valid(self.catalog) then begin
     return, 1
  endif else return, 0
end

;----------------------------------------------------------------------
 
pro phast_image::Cleanup
  
;Routine called by IDL destructor to free memory claimed by object
  
  ptr_free,self.catalog
  ptr_free, self.catalog_type
  ptr_free,self.image
  ptr_free,self.header_string
  ptr_free,self.header_struct
  ptr_free,self.name
  ptr_free,self.size
  ptr_free,self.rotation
  ptr_free,self.astr
end

;----------------------------------------------------------------------

function phast_image::get_astr
  
;routine to return astrometry data for the image
  
  return,*(self.astr)
end

;----------------------------------------------------------------------

function phast_image::get_catalog

;routine to return a catalog 

  return, *(self.catalog)
end

;----------------------------------------------------------------------

function phast_image::get_catalog_type

;routine to return a catalog type

  return, *(self.catalog_type)
end

;----------------------------------------------------------------------
 
function phast_image::get_header, struct=struct, string=string
  
;routine to get header from image object
  
  if keyword_set(struct) then return, *(self.header_struct)
  if keyword_set(string) then return, *(self.header_string)
  print, 'Error: Header not returned: no type specified'
end

 ;----------------------------------------------------------------------
 
function phast_image::get_image
  
;routine to get image from image object
  
  return, *(self.image)
end

;----------------------------------------------------------------------

function phast_image::get_rotation
  
;routine to get image rotation state in degrees
  
  return, *(self.rotation)
end

;----------------------------------------------------------------------

function phast_image::get_size,x=x,y=y
  
;routine to return size of image
  
  if not keyword_set(x) and not keyword_set(y) then return, *(self.size)
  if keyword_set(x) and keyword_set(y) then return, *(self.size)
  if keyword_set(x) then return, *(self.size)[0]
  if keyword_set(y) then return, *(self.size)[1]
end

;----------------------------------------------------------------------

function phast_image::get_name
  
;routine to get image name from image object
  
  return, *(self.name)
end

;----------------------------------------------------------------------

function phast_image::init
  
;constructor for image class
  
  self.catalog = ptr_new() ;this will be allocated when catalog is downloaded
  self.catalog_type = ptr_new('')
  self.image = ptr_new(/allocate)
  self.header_string = ptr_new(/allocate)
  self.header_struct = ptr_new(/allocate)
  self.name = ptr_new(/allocate)
  self.size = ptr_new(/allocate)
  self.rotation = ptr_new(/allocate)
  self.astr = ptr_new()  ;this will be allocated when astrometry data is present
  return,1
end

;----------------------------------------------------------------------

pro phast_image::set_astr,new_astr
  
;routine to set the astrometry info for the image
  
  self.astr = ptr_new(new_astr)
end

;----------------------------------------------------------------------

pro phast_image::set_catalog,new_catalog, type
  
;routine to set the astrometry info for the image
  
  ptr_free, self.catalog
  ptr_free, self.catalog_type
  self.catalog = ptr_new(new_catalog)
  self.catalog_type = ptr_new(type)
end

;----------------------------------------------------------------------
 
pro phast_image::set_header, header, struct=struct, string=string
  
;routine to set header of image object

  while 1 eq 1 do begin ;choose obly one
     if keyword_set(struct) then begin
        *(self.header_struct) = header
        break
     endif
     if keyword_set(string) then begin
        *(self.header_string) = header
        break
     endif
     print, 'Error: Header not set: no type specified'
     break
  endwhile
end

;----------------------------------------------------------------------

pro phast_image::set_image, image
  
;routine to set image of image object
  
  *(self.image) = image
  image_size= size(image)
  *(self.size) = [image_size[2],image_size[3]]
end

;----------------------------------------------------------------------
pro phast_image::set_name, name
  
;routine to set image name for image object
  
  *(self.name) = name
end

;----------------------------------------------------------------------

pro phast_image::set_rotation,deg,add=add
  
;routine to set the rotation state of the image in degrees
  
  common phast_state
  
  if not keyword_set(add) then begin
     *(self.rotation) = deg mod 360
  endif else begin
     *(self.rotation) = (*(self.rotation) + deg) mod 360
  endelse
end

;-----------------------------------------------------------------------------------------

function phast_ndxBand, band

;function to convert character band to numeric index

  case strlowcase(band) of
    'u': index=0
    'b': index=1
    'v': index=2
    'r': index=3
    'i': index=4
    else: index=-1
  endcase
  return, index
end

;----------------------------------------------------------------------
      
pro phast_pan_event, event
      
; event procedure for moving the box around in the pan window
      
  common phast_state
  
  if (!d.name NE state.graphicsdevice) then return
  
  case event.type of
     0: begin                   ; button press
        widget_control, state.pan_widget_id, draw_motion_events = 1
        phast_pantrack, event
     end
     1: begin                   ; button release
        widget_control, state.pan_widget_id, draw_motion_events = 0
        widget_control, state.pan_widget_id, /clear_events
        phast_pantrack, event
        phast_refresh
     end
     2: begin
        phast_pantrack, event   ; motion event
        widget_control, state.pan_widget_id, /clear_events
     end
     else:
  endcase
end

;---------------------------------------------------------------

pro phast_initcube

  ; routine to initialize the data cube slice selector

  common phast_state
  common phast_images
  
  ; First: if data cube is in OSIRIS IFU (lambda,x,y) format, re-form it
  ; into (x,y,lambda).  If it's a normal image stack (x,y,n), don't
  ; modify it.  This way, we can treat both kinds of cubes identically
  ; later on.
  
  if (ptr_valid(state.head_ptr)) then head = *(state.head_ptr) $
  else head = strarr(1)
  
  ; Test for whether this is an OSIRIS cube.
  currinst = strcompress(string(sxpar(head, 'CURRINST')), /remove_all)
  instr = strcompress(string(sxpar(head, 'INSTR')), /remove_all)
  
  if ((currinst EQ 'OSIRIS') AND (instr EQ 'spec')) then begin
    ;   print, 'Re-forming OSIRIS data cube to (x,y,lambda)...'
    nl = (size(main_image_cube))[1]
    ny = (size(main_image_cube))[2]
    nx = (size(main_image_cube))[3]
    
    tmpcube = fltarr(nx, ny, nl)
    
    for i = 0, nl-1 do begin
      tmpcube[*,*,i] = transpose(reform(main_image_cube[i,*,*]))
    endfor
    
    main_image_cube = tmpcube
    tmpcube = 0.0
    state.osiriscube = 1
  endif else begin
    state.osiriscube = 0
  endelse
  
  state.nslices = (size(main_image_cube))[3]
  
  ; Create the slicer widgets if not already there
  if (not(xregistered('phastslicer', /noshow))) then begin
  
    wtitle = 'phast data cube slicer'
    
    slicebase = widget_base(group_leader = state.base_id, $
      title = wtitle, /column)
    state.slicebase_id = slicebase
    
    sliceselect = cw_field(slicebase, $
      uvalue = 'sliceselect', $
      /integer,  $
      title = 'Select Slice:', $
      value = state.slice,  $
      /return_events, $
      xsize = 7)
    state.sliceselect_id = sliceselect
    
    slicer = widget_slider(slicebase, /drag, scroll = 1, $
      scr_xsize = 250, frame = 5, $
      minimum = 0, $
      maximum = state.nslices - 1, $
      uvalue = 'sliceslider')
    state.slicer_id = slicer
    
    combinebase = widget_base(slicebase, /row)
    
    state.slicecombine_id = cw_field(combinebase, $
      uvalue = 'slicecombine', $
      /integer, $
      title = '# Slices to combine: ', $
      value = state.slicecombine, $
      /return_events, $
      xsize = 7)
      
    allslice = widget_button(combinebase, $
      uvalue = 'allslice', $
      value = 'All')
      
    noslice = widget_button(combinebase, uvalue = 'noslice', $
      value = 'None')
      
    averagebase = cw_bgroup(slicebase, ['average', 'median'], $\
    uvalue = 'average', $
      button_uvalue = ['average', 'median'], $
      /exclusive, set_value = state.slicecombine_method, $
      label_left = 'Combine with: ', $
      /no_release, $
      /row)
      
    widget_control, slicebase, /realize
    xmanager, 'phastslicer', state.slicebase_id, /no_block
    
  endif
  
  state.slice = 0
  widget_control, state.slicer_id, set_value = 0
  widget_control, state.sliceselect_id, set_value = 0
  widget_control, state.slicer_id, set_slider_max = state.nslices-1
  
  if (state.slicecombine GT state.nslices) then begin
    state.slicecombine = state.nslices
    widget_control, state.slicecombine_id, set_value = state.slicecombine
  endif
  
  phastslicer_event
end

;-------------------------------------------------------------------

pro phast_killcube

  ; kill data cube slicer widget and go back to non-cube 2d image mode

  common phast_state
  common phast_images
  
  if (xregistered('phastslicer', /noshow)) then begin
    widget_control, state.slicebase_id, /destroy
  endif
  
  state.cube = 0
  state.slice = 0
  state.osiriscube = 0
  state.slicecombine = 1
  main_image_cube = 0
end

;----------------------------------------------------------------------

pro phast_makergb

  ; Makes an RGB truecolor png image from the 3 blink channels.
  ; Can be saved using file->writeimage.
  ; Note- untested for 8-bit displays.  May not work there.

  common phast_state
  common phast_images
  
  if (n_elements(blink_image1) EQ 1 OR $
    n_elements(blink_image2) EQ 1 OR $
    n_elements(blink_image3) EQ 1) then begin
    
    phast_message, $
      'You need to set the 3 blink channels first to make an RGB image.', $
      msgtype = 'error', /window
    return
  endif
  
  phast_getwindow
  
  window, /free, xsize = state.draw_window_size[0], $
    ysize = state.draw_window_size[1], /pixmap
  tempwindow = !d.window
  
  tv, blink_image1, /true
  rimage = tvrd()
  tv, blink_image2, /true
  gimage = tvrd()
  tv, blink_image3, /true
  bimage = tvrd()
  
  tcimage = [[[rimage]], [[gimage]], [[bimage]]]
  
  tv, tcimage, true=3
  
  tvlct, rmap, gmap, bmap, /get
  image = tvrd(/true)
  
  wdelete, tempwindow
  
  phast_setwindow, state.draw_window_id
  tv, image, /true
  phast_resetwindow
end

;----------------------------------------------------------------------

pro phast_message, msg_txt, msgtype=msgtype, window=window

  ; Routine to display an error or warning message.  Message can be
  ; displayed either to the IDL command line or to a popup window,
  ; depending on whether /window is set.
  ; msgtype must be 'warning', 'error', or 'information'.

  common phast_state
  
  if (n_elements(window) EQ 0) then window = 0
  
  if (window EQ 1) then begin  ; print message to popup window
    case msgtype of
      'warning': t = dialog_message(msg_txt, dialog_parent = state.base_id)
      'error': t = $
        dialog_message(msg_txt,/error,dialog_parent=state.base_id)
      'information': t = $
        dialog_message(msg_txt,/information,dialog_parent=state.base_id)
      else:
    endcase
  endif else begin           ;  print message to IDL console
    message = strcompress(strupcase(msgtype) + ': ' + msg_txt)
    print, message
  endelse
end

;----------------------------------------------------------------------

pro phast_move_cursor, direction

  ; Use keypad arrow keys to step cursor one pixel at a time.
  ; Get the new track image, and update the cursor position.

  common phast_state
  
  i = 1L
  
  case direction of
    '2': state.coord[1] = max([state.coord[1] - i, 0])
    '4': state.coord[0] = max([state.coord[0] - i, 0])
    '8': state.coord[1] = min([state.coord[1] + i, state.image_size[1] - i])
    '6': state.coord[0] = min([state.coord[0] + i, state.image_size[0] - i])
    '7': begin
      state.coord[1] = min([state.coord[1] + i, state.image_size[1] - i])
      state.coord[0] = max([state.coord[0] - i, 0])
    end
    '9': begin
      state.coord[1] = min([state.coord[1] + i, state.image_size[1] - i])
      state.coord[0] = min([state.coord[0] + i, state.image_size[0] - i])
    end
    '3': begin
      state.coord[1] = max([state.coord[1] - i, 0])
      state.coord[0] = min([state.coord[0] + i, state.image_size[0] - i])
    end
    '1': begin
      state.coord[1] = max([state.coord[1] - i, 0])
      state.coord[0] = max([state.coord[0] - i, 0])
    end
    
  endcase
  
  newpos = (state.coord - state.offset + 0.5) * state.zoom_factor
  
  phast_setwindow,  state.draw_window_id
  tvcrs, newpos[0], newpos[1], /device
  phast_resetwindow
  
  phast_gettrack
  
  ; If pixel table widget is open, update pixel values and cursor position
  if (xregistered('phast_pixtable', /noshow)) then phast_pixtable_update
  
  
  ; Prevent the cursor move from causing a mouse event in the draw window
  widget_control, state.draw_widget_id, /clear_events
  
  phast_resetwindow
end

;------------------------------------------------------------------
pro phast_plainfits_read, fitsloc, head, cancelled,dir=dir,refresh_index=index,refresh_toggle=refresh, newimage = newimage

  ; Fits reader for plain fits files, no extensions.

  common phast_images
  
  ;main_image=0
  if keyword_set(dir) then begin
    fitsfile = findfile(fitsloc+'*.fits')
    if fitsfile[0] ne '' then begin ;check folder actually contains any images
      ;read first image and set up directory add
      fits_read, fitsfile[0],main_image,head
      head = headfits(fitsfile[0])
      phast_add_image,main_image,fitsfile[0],head, newimage = newimage, /dir_add, dir_num = n_elements(fitsfile)
      progress_bar = obj_new('cgprogressbar',title='Opening images')
      progress_bar->start
      file_count = n_elements(fitsfile)
      for i=1, file_count-1 do begin
         fits_read, fitsfile[i],main_image,head
         head = headfits(fitsfile[i])
         phast_add_image,main_image,fitsfile[i],head, newimage = newimage,/dir_add
         progress_bar->update,float(i)/file_count*100
      endfor
      progress_bar->destroy
    endif else begin
      newimage = 0 ;if empty, no new image
      result = dialog_message('Directory contains no FITS images!',/center,/error)
    endelse
  endif else begin
    fits_read, fitsloc, main_image, head
    if not keyword_set(refresh) then begin
      phast_add_image,main_image,fitsloc,head, newimage = newimage
    endif else phast_add_image,main_image,fitsloc,head,refresh_index=index,/refresh_toggle, newimage =newimage
  endelse
end

;------------------------------------------------------------------

pro phast_readfits, fitsfilename=fitsfilename, newimage=newimage, dir=dir,refresh_index = index,refresh_toggle=refresh_toggle

  ; Read in a new image when user goes to the File->ReadFits menu.
  ; Do a reasonable amount of error-checking first, to prevent unwanted
  ; crashes.

  common phast_state
  common phast_images
  
  newimage = 0
  cancelled = 0
  if (n_elements(fitsfilename) EQ 0) then window = 1 else window = 0
  
  filterlist = ['*.fit*;*.FIT*;*.ftz*;*.FTZ*;*.fts*;*.ccd;*.fz']
  
  ; If fitsfilename hasn't been passed to this routine, get filename
  ; from dialog_pickfile.
  if (n_elements(fitsfilename) EQ 0) then begin
    if keyword_set(dir) then begin
      fitsfile = dialog_pickfile(/read,/directory)
      if fitsfile ne '' then phast_plainfits_read, fitsfile, head, cancelled, /dir,newimage=newimage ;check for cancel
    endif else begin
      fitsfile = $
        dialog_pickfile( $
        filter = filterlist, $
        group = state.base_id, $
        /must_exist, $
        /read, $
        path = state.current_dir, $
        get_path = tmp_dir, $
        title = 'Select FITS Image')
      if (tmp_dir NE '') then state.current_dir = tmp_dir
      if (fitsfile EQ '') then return ; 'cancel' button returns empty string
    endelse
  endif else begin
    fitsfile = fitsfilename
  endelse
  
  
  if not keyword_set(dir) then begin
  
    ; Get fits header so we know what kind of image this is.
    head = headfits(fitsfile)   ;, errmsg = errmsg)
    
    ; Check validity of fits file header
    if (n_elements(strcompress(head, /remove_all)) LT 2) then begin
      phast_message, 'File does not appear to be a valid FITS image!', $
        window = window, msgtype = 'error'
      return
    endif
    if (!ERR EQ -1) then begin
      phast_message, $
        'Selected file does not appear to be a valid FITS image!', $
        msgtype = 'error', window = window
      return
    endif
    
    ; Find out if this is a fits extension file, and how many extensions
    ; New: use fits_open rather than fits_info
    fits_open, fitsfile, fcb, message = message
    if (message NE '') then begin
      phast_message, message, msgtype='error', /window
      return
    end
    numext = fcb.nextend
    fits_close, fcb
    
       instrume = strcompress(string(sxpar(head, 'INSTRUME')), /remove_all)
    origin = strcompress(sxpar(head, 'ORIGIN'), /remove_all)
    naxis = sxpar(head, 'NAXIS')
    
    ; Make sure it's not a 1-d spectrum
    if (numext EQ 0 AND naxis LT 2) then begin
      phast_message, 'Selected file is not a 2-d FITS image!', $
        window = window, msgtype = 'error'
      return
    endif

    state.title_extras = ''
    
    ; Now call the subroutine that knows how to read in this particular
    ; data format:
    
    checkfz = strmid(fitsfile, 2, /reverse_offset)
  

    if ((checkfz EQ '.fz')) then begin
      phast_fpack_read, fitsfile, numext, head, cancelled
    endif else if ((numext GT 0) AND (instrume NE 'WFPC2')) then begin
      phast_fitsext_read, fitsfile, numext, head, cancelled, newimage=newimage
    endif else if ((instrume EQ 'WFPC2') AND (naxis EQ 3)) then begin
      phast_wfpc2_read, fitsfile, head, cancelled
    endif else if ((naxis EQ 3) AND (origin EQ '2MASS')) then begin
      phast_2mass_read, fitsfile, head, cancelled
    endif else begin
      if not keyword_set(refresh_toggle) then begin
        phast_plainfits_read, fitsfile, head, cancelled, newimage = newimage
      endif else phast_plainfits_read, fitsfile, head, cancelled, /refresh_toggle, refresh_index = index, newimage=newimage
    endelse
    
    if (cancelled EQ 1) then begin
      newimage = 0
      return
    endif
    
    ; check for 2d image or 3d cube, and store the header if all is well:
    s = (size(main_image))[0]
    case s of
      2: begin
        phast_setheader, head
        main_image_cube = 0
        state.cube = 0
        state.nslices = 0
        phast_killcube
      end
      3: begin
        main_image_cube = main_image
        main_image = 0
        state.cube = 1
        phast_setheader, head
        phast_initcube
      end
      else: begin
        phast_message, 'Selected file is not a 2-D fits image!', $
          msgtype = 'error', window = window
        main_image_cube = 0
        main_image = fltarr(512, 512)
        newimage = 1
        state.cube = 0
        state.nslices = 0
        phast_killcube
        head = ''
        phast_setheader, head
        fitsfile = ''
      end
    endcase
    widget_control, /hourglass
    
    state.imagename = fitsfile
  ;newimage = 1
    
  endif
end

;---------------------------------------------------------------------

pro phast_read_config

  ;routine to read a user-supplied configuration file and make the
  ;appropriate changes to state variables.

  common phast_state
  common phast_mpc_data
  common phast_images

  if file_test(state.phast_dir+'phast.conf') eq 1 then begin
    readcol,state.phast_dir+'phast.conf',var,val,FORMAT='A,A',/silent,delim=string(9b),comment='#'
    for i=0, n_elements(var)-1 do begin
      case strlowcase(strtrim(var[i])) of
        ;calibration
        'bias_file': begin
          state.bias_filename = val[i]
          fits_read,state.bias_filename,cal_bias,cal_flat_head
          state.bias_toggle = 1
        end
        'dark_file': begin
          state.dark_filename = val[i]
          fits_read,state.dark_filename,cal_dark,cal_dark_head
          state.dark_toggle = 1
        end
        'flat_file': begin
          state.flat_filename = val[i]
          fits_read,state.flat_filename,cal_flat,cal_flat_head
          state.flat_toggle = 1
        end
        'overscan': begin
          state.over_toggle = fix(val[i])
       end
        'compute_astrometry': begin
           state.astrometry_toggle = fix(val[i])
        end
        ;sextractor
        'sex_catalog_path': state.sex_catalog_path = val[i]
        'sex_flags': state.sex_flags = val[i]
        ;scamp
        'scamp_flags': state.scamp_flags = val[i]
        ;missfits
        'missfits_flags': state.missfits_flags = val[i]
        ;blink control
        'animate_speed': state.animate_speed = float(val[i])
        'tb_blink_toggle': state.tb_blink_toggle = fix(val[i])
        'tb_blink_visible': state.tb_blink_visible = fix(val[i])
        'animate_type': state.animate_type = val[i]
        ;star overlay
        'tb_overlay_toggle': state.tb_overlay_toggle = fix(val[i])
        'tb_overlay_visible': state.tb_overlay_visible = fix(val[i])
        ;SPICE control
        'tb_spice_toggle': state.tb_spice_toggle = fix(val[i])
        'tb_spice_visible': state.tb_spice_visible = fix(val[i])
        'kernel_list': state.kernel_list = val[i]
        ;calibration
        'cal_file_name': state.cal_file_name = val[i]
        ;photometery
        'photfilename': state.photfilename = val[i]
        'aprad': state.aprad = float(val[i])
        'innersky': state.innersky = float(val[i])
        'outersky': state.outersky = float(val[i])
        'seeing': state.objfwhm = float(val[i])
        'pixelscale': state.pixelscale = float(val[i])
        'ccdgain': state.ccdgain = float(val[i])
        'ccdrn': state.ccdrn = float(val[i])
        'photerrors': state.photerrors = fix(val[i])
        'skytype': state.skytype = fix(val[i])
        'magunits': state.magunits = fix(val[i])
        'phot_rad_plot_open': state.phot_rad_plot_open = fix(val[i])
        'ccdrotangle': begin
          state.fits_crota1 = float(val[i])
          state.fits_crota2 = float(val[i])
          state.fits_cdelt1 = -(state.pixelscale/3600.0)*sin(float(val[i])*!pi/180.0)
          state.fits_cdelt2 = -state.fits_cdelt1
        end
        ;MPC reporting
        'mpc_net': mpc.net = val[i]
        'mpc_com': mpc.com = val[i]
        'mpc_ack': mpc.ack = val[i]
        'mpc_note1': mpc.note1 = val[i]
        'mpc_note2': mpc.note2 = val[i]
        'mpc_code': mpc.code = val[i]
        'mpc_contact_address': mpc.contact_address = val[i]
        'mpc_contact_email': mpc.contact_email = val[i]
        'mpc_contact_name': mpc.contact_name = val[i]
        'mpc_height': mpc.height = float(val[i])
        'mpc_lat': mpc.lat = float(val[i])
        'mpc_lat_dir': mpc.lat_dir = val[i]
        'mpc_lon': mpc.lon = float(val[i])
        'mpc_lon_dir': mpc.lon_dir = val[i]
        'mpc_observers': mpc.observers = val[i]
        'mpc_measurer': mpc.measurer = val[i]
        'mpc_site_code': mpc.site_code = fix(val[i])
        'mpc_telescope': mpc.telescope = val[i]
        ;other
        'align_toggle': state.align_toggle = fix(val[i])
        'check_updates':state.check_updates = fix(val[i])
        'invert_colormap': state.invert_colormap = fix(val[i])
        
        
        else: print, 'Parameter '+var[i]+' not found in phast_state!'
      endcase
   endfor
 endif
    ;
    ;now, process any state defaults based on inputs
  if state.pixelscale le 0 then begin
       print, 'Warning: CCD pixel scale has not been set.  Defaulting to 1.0" per pixel.'
       state.pixelscale = 1.0
       state.magunits = 0
    endif
    if state.objfwhm le 0 then begin
       print, 'Warning: Nominal seeing has not been set.  Defaulting to 2 x pixel scale.'
       state.objfwhm = 2.0 * state.pixelscale 
    endif
    if state.fits_crota1 lt -999.0 or state.fits_crota2 lt -999.0 then begin
       print, 'Warning: CCD rotation angle has not been set.  Defaulting to 90 degrees.'
       state.fits_crota1 = 90.0
       state.fits_crota2 = 90.0
       state.fits_cdelt1 = -(state.pixelscale/3600.0)*sin(state.fits_crota1*!pi/180.0)
       state.fits_cdelt2 = -state.fits_cdelt1
    endif
    ;
    ; set photometric apertures based on typical object fwhm to be consistent with sextractor apertures
    if finite(state.objfwhm) then begin
        state.objfwhm = state.objfwhm / state.pixelScale
        phast_setAps, state.objfwhm, 0
    endif  
end

;-----------------------------------------------------------------------------------------

pro phast_read_filters 

;read the phast.filters file containing filter passband characteristics used in photometry

  common phast_state
  common phast_filters, filters  

  filename = 'phast.filters'
  
  error = 0
  if not file_test(filename) then begin
    print, 'Passband configuration file phast.filters not found'
    state.filters_loaded = 0
    filters = { fitsKey:'AnY FILTERS', N:'1', nameFilter:'R', transCoeff:0.0, transTerm:'N/A', $
                zeroPoint:99.9,   errZeroPt:0.0, atmExtinct:0.0, atmColorVI:0.0,             $
                doZeroPt:1,      magBand:'R',   fitColor:0,      fitTerm:'N/A'     }
    
  endif else begin
     state.filters_loaded = 1
    comment = '#'
    line = ''
    OPENR, lun, filename, /GET_LUN
    WHILE NOT EOF(lun) DO BEGIN
      READF, lun, line
      vals = STRSPLIT(line, string(9b), /EXTRACT)
      if strmid(strtrim(line),0,1) NE comment then begin
        case strlowcase(vals[0]) of
          'fitskeyword' : fitsKeyword = vals[1]
          'nfilters'    : nFilters = vals[1]
          'posfilter'   : begin
                          posFilter = make_array(1+nFilters,/integer)
                          posFilter[1:nFilters] = vals[1:(n_elements(vals)-1)]                         & end
          'namefilter'  : begin
                          nameFilter = make_array(1+nFilters,/string)
                          nameFilter[posFilter[1:nFilters]] = vals[1:(n_elements(vals)-1)]             & end
          'transcoeff'  : begin
                          transCoeff = make_array(1+nFilters,/float)
                          transCoeff[posFilter[1:nFilters]] = vals[1:(n_elements(vals)-1)]             & end
          'transterm'   : begin
                          transTerm = make_array(1+nFilters,/string)
                          transTerm[posFilter[1:nFilters]] = strupcase(vals[1:(n_elements(vals)-1)])   & end
          'zeropoint'   : begin
                          zeroPoint = make_array(1+nFilters,/float)
                          zeroPoint[posFilter[1:nFilters]] = vals[1:(n_elements(vals)-1)]              & end
          'errzeropt'   : begin
                          errZeroPt = make_array(1+nFilters,/float)
                          errZeroPt[posFilter[1:nFilters]] = vals[1:(n_elements(vals)-1)]              & end
          'extinct k1'  : begin
                          atmExtinct = make_array(1+nFilters,/float)
                          atmExtinct[posFilter[1:nFilters]] = vals[1:(n_elements(vals)-1)]             & end
          'extinct k2'  : begin
                          atmColorVI = make_array(1+nFilters,/float)
                          atmColorVI[posFilter[1:nFilters]] = vals[1:(n_elements(vals)-1)]             & end
          'magcatalog'  : begin
                          magFilter = make_array(1+nFilters,/string)
                          magFilter[posFilter[1:nFilters]] = vals[1:(n_elements(vals)-1)]              & end
          'fitcolor'    : begin
                          fitTerm = make_array(1+nFilters,/string)
                          fitTerm[posFilter[1:nFilters]] = strupcase(vals[1:(n_elements(vals)-1)])     & end
                    else: print, 'Unexpected parameter found in phast_read_filters: ' + vals[0]
        endcase
      endif
   ENDWHILE  &  FREE_LUN, lun
                        
   posFilter = posFilter[posFilter[1:nFilters]]
   fitTerm   = strupcase( strmid(strcompress(fitTerm)+replicate('   ',1+nFilters),0,3) ) ; nominally B-R, etc, but guarantee length 3
   fitColor  = (fitTerm NE 'N/A') And (fitTerm NE ' ') And (fitTerm NE '')
                        
   ; how will zeropoint be determined?
   doZeroPt = make_array(1+nFilters,/Long)
   ; rely on users zeropoint specification when given
   select = where(zeropoint LT 99.0, count)
   if count GT 0 then begin
      doZeroPt[select] = 0
      fitColor[select] = 0
       fitTerm[select] = '   '
   endif
   ; rely on catalog when user requests catalog or standard magnitudes
   select = where(zeropoint GE 99.0, count)
   if count GT 0 then begin
       doZeroPt[select] = 1
      zeropoint[select] = !values.F_NaN
      errZeroPt[select] = !values.F_NaN
   endif
                        
   state.nFilters = nFilters
                        

   filters = { fitsKey:fitsKeyword, N:nFilters, nameFilter:nameFilter, transCoeff:transCoeff, transTerm:transTerm, $
             zeroPoint:zeroPoint,   errZeroPt:errZeroPt, atmExtinct:atmExtinct, atmColorVI:atmColorVI,             $
              doZeroPt:doZeroPt,      magBand:magFilter,   fitColor:fitColor,      fitTerm:fitTerm     }
                          
   ; Now, test user's specs against availability of photometric bands in catalog
   case state.photcatalog_name of
     'USNO-B1.0': begin
                  state.photcatalog_UBVRI = 0
                  state.photcatalog_Bands = [ 0L, 1L, 0L, 1L, 0L ]
                  end
     'GSC-2.3'  : begin
                  state.photcatalog_UBVRI = 0
                  state.photcatalog_Bands = [ 0L, 1L, 1L, 1L, 1L ]
                  end
     'Landolt'  : begin
                  state.photcatalog_UBVRI = 1
                  state.photcatalog_Bands = [ 1L, 1L, 1L, 1L, 1L ]
                  end
      endcase
                        
    ; determine if catalog supports the requested magnitude band
    for pos = 1, nFilters do begin
        if filters.doZeroPt[pos] then begin
           magBand = strlowcase(filters.magBand[pos])
           filters.doZeroPt[pos]=1
           case magBand of
            'x': begin & zeroPoint[pos] = 0.00
                         errZeroPt[pos] = 0.00
                          doZeroPt[pos] = 0
                         magFilter[pos] = 'Instr'
                          fitColor[pos] = 0
                           fitTerm[pos] = '   '
                 end
            'u': begin & if not state.photcatalog_Bands[phast_ndxBand(magBand)] then begin
                            filters.doZeroPt[pos]=0
                            print, 'error: ' + filters.magBand[pos] + ' zeropoint can not be determined for filter ' + filters.nameFilter[pos] $
                                 + ' because ' + state.photcatalog_name + ' is missing ' + filters.magBand[pos]
                            error = 1
                          endif
                 end
            'b': begin & if not state.photcatalog_Bands[phast_ndxBand(magBand)] then begin
                            filters.doZeroPt[pos]=0
                            print, 'error: ' + filters.magBand[pos] + ' zeropoint can not be determined for filter ' + filters.nameFilter[pos] $
                                 + ' because ' + state.photcatalog_name + ' is missing ' + filters.magBand[pos]
                            error = 1
                         endif
                 end
            'v': begin & if not state.photcatalog_Bands[phast_ndxBand(magBand)] then begin
                            filters.doZeroPt[pos]=0
                            print, 'error: ' + filters.magBand[pos] + ' zeropoint can not be determined for filter ' + filters.nameFilter[pos] $
                                 + ' because ' + state.photcatalog_name + ' is missing ' + filters.magBand[pos]
                            error = 1
                         endif
                 end
            'r': begin & if not state.photcatalog_Bands[phast_ndxBand(magBand)] then begin
                            filters.doZeroPt[pos]=0
                            print, 'error: ' + filters.magBand[pos] + ' zeropoint can not be determined for filter ' + filters.nameFilter[pos] $
                                 + ' because ' + state.photcatalog_name + ' is missing ' + filters.magBand[pos]
                            error = 1
                         endif
                 end
            'i': begin & if not state.photcatalog_Bands[phast_ndxBand(magBand)] then begin
                            filters.doZeroPt[pos]=0
                            print, 'error: ' + filters.magBand[pos] + ' zeropoint can not be determined for filter ' + filters.nameFilter[pos] $
                                 + ' because ' + state.photcatalog_name + ' is missing ' + filters.magBand[pos]
                            error = 1
                         endif
                 end
           else: begin & msgarr = strarr(2)
                         filters.doZeroPt[pos]=0
                         print, 'error: ' + filters.magBand[pos] + ' zeropoint can not be determined for filter ' + filters.nameFilter[pos] $
                              + ' because ' + state.photcatalog_name + ' is missing ' + filters.magBand[pos]
                         error = 1
                 end
           endcase
              
           if filters.fitColor[pos] NE 0 then begin
              if not (state.photcatalog_Bands[phast_ndxBand(strmid(filters.fitTerm[pos],0,1))]   And $
                 state.photcatalog_Bands[phast_ndxBand(strmid(filters.fitTerm[pos],2,1))]) then begin
                 doZeroPt[pos]=0
                 print, 'error: ' + filters.magBand[pos] + ' zeropoint can not be determined for filter ' + filters.nameFilter[pos] $
                     + ' because ' + state.photcatalog_name + ' is missing ' + filters.fitTerm[pos]
                 error = 1
              endif
           endif
              
       endif
    endfor
          
 endelse        
    
    if error then begin
        ; patch should terminate program here
    endif   
 end

;-------------------------------------------------------------------
pro phast_read_vicar,  newimage=newimage, dir=dir
      
;routine to read a VICAR image file and store it in the archive
  
  common phast_state
  common phast_images
  
  widget_control,/hourglass
  
  if not keyword_set(dir) then begin
     file = dialog_pickfile(filter='*.IMG,*.img')
     if file ne '' then begin                                 ;check for cancel
        image = read_vicar(file,label)                        ;read the image
        phast_add_image,image,file, '', newimage=newimage     ;omit label for now
        main_image = image_archive[state.current_image_index]->get_image()
        phast_getstats
     endif
  endif else begin
     fileloc = dialog_pickfile(/directory)
     vicarfile = findfile(fileloc+'*.IMG')
     if vicarfile[0] ne '' then begin              ;check the directory actually contains images
        image = read_vicar(vicarfile[0],label)     ;read the image
        phast_add_image,image,vicarfile[0],'',newimage=newimage, /dir_add, dir_num = n_elements(vicarfile)
        for i=1, n_elements(vicarfile)-1 do begin
           image = read_vicar(vicarfile[i],label) ;read the image
           phast_add_image,image,vicarfile[i],'',newimage=newimage, /dir_add
        endfor
     endif else begin
        newimage = 0
        result = dialog_message('Directory contains no VICAR images!',/center,/error)
     endelse
  endelse
end

;----------------------------------------------------------------------

pro phast_refresh_image,index,filename

  ;routine to refresh an image already in the archive with an updated
  ;version

  common phast_state
  
  phast_readfits,fitsfilename=filename,/refresh_toggle,refresh_index=index
  
end

;-------------------------------------------------------------------

pro phast_remove_image,index=index,all=all
      
;routine to remove an image from the image archive, as well as it's
;data from related archives
       
  common phast_state
  common phast_images
  if not keyword_set(all) then begin
     obj_destroy, image_archive[index]
     if state.num_images gt 1 then begin
        temp_image = objarr(state.num_images-1)
        j=0
        for i=0, state.num_images-1 do begin
           if i ne index then begin
              temp_image[j] = image_archive[i]
              j++
           endif
        endfor
        image_archive[0] = temp_image
        while 1 eq 1 do begin   ;choose only one
           if index eq 0 then begin
              state.num_images--
              phast_image_switch,state.current_image_index
              break
           endif
           if index eq state.num_images-1 then begin
              state.current_image_index--
              state.num_images--
              phast_image_switch,state.current_image_index
              break
           endif
           if index ne 0 and index ne state.num_images-1 then begin
              state.num_images--
              state.current_image_index--
              phast_image_switch,state.current_image_index
              break
           endif
        endwhile
     endif else begin
        state.num_images = 0
        state.current_image_index = 0
        state.catalog_loaded = 0
        state.firstimage = 1
        widget_control,state.image_counter_id,set_value='Cycle images: no image loaded'
        widget_control,state.image_select_id,set_value='no image'
        phast_settitle, /reset
        phast_base_image
     endelse
  endif else begin
     for i=0,state.num_images-1 do obj_destroy,image_archive[i]
     state.num_images = 0
     state.current_image_index = 0
     state.catalog_loaded = 0
     state.firstimage = 1
     widget_control,state.image_counter_id,set_value='Cycle images: no image loaded'
     widget_control,state.image_select_id,set_value='no image'
     phast_settitle, /reset
     phast_base_image
  endelse  
end

;----------------------------------------------------------------------

pro phast_setheader, head

  ; Routine to keep the image header using a pointer to a
  ; heap variable.  If there is no header (i.e. if phast has just been
  ; passed a data array rather than a filename), then make the
  ; header pointer a null pointer.  Get astrometry info from the
  ; header if available.  If there's no astrometry information, set
  ; state.astr_ptr to be a null pointer.

  common phast_state
  common phast_images
  
  ; Kill the header info window when a new image is read in
  
  if (xregistered('phast_headinfo')) then begin
    widget_control, state.headinfo_base_id, /destroy
  endif
  
  if (xregistered('phast_stats')) then begin
    widget_control, state.stats_base_id, /destroy
  endif
  
  state.cunit = ''
  
  if (n_elements(head) LE 1) then begin
    ; If there's no image header...
    state.wcstype = 'none'
    ptr_free, state.head_ptr
    state.head_ptr = ptr_new()
    ptr_free, state.astr_ptr
    state.astr_ptr = ptr_new()
    widget_control, state.wcs_bar_id, set_value = '---No WCS Info---'
    return
  endif
  
  ptr_free, state.head_ptr
  state.head_ptr = ptr_new(head)
  
  ; get exposure time for photometry, if present, otherwise set to 1s
  state.exptime = float(sxpar(head, 'EXPTIME'))
  if (state.exptime LE 0.0) then state.exptime = 1.0
  
  ; try to get gain and readnoise from header?
  ;state.ccdgain = float(sxpar(head, 'GAIN'))
  ;if (state.ccdgain LE 0.0) then state.ccdgain = 1.0
  ;state.ccdrn = float(sxpar(head, 'RDNOISE'))
  ;if (state.ccdrn LE 0.0) then state.ccdrn = 0.0
  
  ; Get astrometry information from header, if it exists
  ptr_free, state.astr_ptr        ; kill previous astrometry info
  state.astr_ptr = ptr_new()
  
  ; Keck OSIRIS data cube headers have CRVAL2 and CRVAL3 as strings
  ; rather than floats.  This causes extast.pro to return an error.  To
  ; fix, change these keywords to floats.  Do this before running
  ; extast, to avoid getting the error message.
  if ( (strcompress(sxpar(head, 'INSTRUME'), /remove_all) EQ 'OSIRIS') and $
    (strcompress(sxpar(head, 'INSTR'), /remove_all) EQ 'spec') ) then begin
    crval2 = double(sxpar(head, 'CRVAL2'))
    crval3 = double(sxpar(head, 'CRVAL3'))
    sxaddpar, head, 'CRVAL2', crval2
    sxaddpar, head, 'CRVAL3', crval3
  ;   print, 'OSIRIS header keywords CRVAL2, CRVAL3 fixed.'
  endif
  
  extast, head, astr, noparams
  
  ; No valid astrometry in header
  if (noparams EQ -1) then begin
    widget_control, state.wcs_bar_id, set_value = '---No WCS Info---'
    state.wcstype = 'none'
    return
  endif
  
  ; Here: add escape clauses for any WCS types that cause crashes.  Add
  ; more as needed
  checkastr = strcompress(string(astr.ctype[0]), /remove_all)
  if ( (checkastr EQ 'PIXEL') OR $
    (checkastr EQ '') OR $
    (checkastr EQ 'COLUMN#') ) then begin
    widget_control, state.wcs_bar_id, set_value = '---No WCS Info---'
    state.wcstype = 'none'
    return
  endif
  
  if (checkastr EQ 'RA---TNX') then begin
    widget_control, state.wcs_bar_id, set_value = '---No WCS Info---'
    state.wcstype = 'none'
    print
    print, 'WARNING- WCS info is in unsupported TNX format.'
    return
  endif
  
  ; Image is a 2-d calibrated spectrum:
  ; (these keywords work for HST STIS 2-d spectral images)
  if (astr.ctype[0] EQ 'LAMBDA' OR astr.ctype[0] EQ 'WAVE') then begin
    state.wcstype = 'lambda'
    state.astr_ptr = ptr_new(astr)
    widget_control, state.wcs_bar_id, set_value = '                 '
    
    state.cunit = sxpar(*state.head_ptr, 'cunit1')
    state.cunit = strcompress(string(state.cunit), /remove_all)
    if (state.cunit NE '0') then begin
      state.cunit = strcompress((strmid(state.cunit,0,1)) + $
        strmid(state.cunit,1), $
        /remove_all)
    endif else begin
      state.cunit = ''
    endelse
    return
  endif
  
  ; 2-D wavelength calibrated spectrum from iraf gemini reductions:
  if (string(sxpar(head, 'WAT1_001')) EQ $
    'wtype=linear label=Wavelength units=angstroms') then begin
    state.wcstype = 'lambda'
    state.astr_ptr = ptr_new(astr)
    widget_control, state.wcs_bar_id, set_value = '                 '
    state.cunit = 'Angstrom'
    return
  endif
  
  
  ; final error check on WCS, in case it's in a format that can't be
  ; understood by the idlastro routines.
  catch, error_status
  
  if (error_status NE 0) then begin
    print
    print, 'Warning: WCS information could not be understood.'
    wcsstring = '---No WCS Info---'
    state.wcstype='none'
    return
  endif
  
  ; see if coordinates can be extracted without an error
  xy2ad, 0, 0, astr, lon, lat
  
  catch, /cancel
  
  
  ; Good astrometry info in header:
  state.wcstype = 'angle'
  widget_control, state.wcs_bar_id, set_value = '                 '
  
  ; Check for GSS type header
  if strmid( astr.ctype[0], 5, 3) EQ 'GSS' then begin
    hdr1 = head
    gsss_STDAST, hdr1
    extast, hdr1, astr, noparams
  endif
  
  ; Create a pointer to the header info
  state.astr_ptr = ptr_new(astr)
  image_archive[state.current_image_index]->set_astr,astr ; add astrometry to image object
  
  ; Get the equinox of the coordinate system
  equ = get_equinox(head, code)
  
  if (code NE -1) then begin
    if (equ EQ 2000.0) then state.equinox = 'J2000'
    if (equ EQ 1950.0) then state.equinox = 'B1950'
    if (equ NE 2000.0 and equ NE 1950.0) then $
      state.equinox = string(equ, format = '(f6.1)')
  endif else begin
    IF (strmid(astr.ctype[0], 0, 4) EQ 'GLON') THEN BEGIN
      state.equinox = 'J2000' ; (just so it is set)
    ENDIF ELSE BEGIN
      ; If no valid equinox, then ignore the WCS info.
      print, 'Warning: WCS equinox not given in image header.  Ignoring WCS info.'
      ptr_free, state.astr_ptr    ; clear pointer
      state.astr_ptr = ptr_new()
      state.equinox = 'J2000'
      state.wcstype = 'none'
      widget_control, state.wcs_bar_id, set_value = '---No WCS Info---'
    ENDELSE
  endelse
  
  ; Set default display to native system in header
  state.display_equinox = state.equinox
  state.display_coord_sys = strmid(astr.ctype[0], 0, 4)
end

;--------------------------------------------------------------------

pro phast_shutdown, windowid

  ; routine to kill the phast window(s) and clear variables to conserve
  ; memory when quitting phast.  The windowid parameter is used when
  ; phast_shutdown is called automatically by the xmanager, if phast is
  ; killed by the window manager.

  common phast_images
  common phast_state
  common phast_color
  common phast_pdata
  common phast_spectrum
  
  if (state.photprint EQ 1) then begin
    free_lun, state.photfile
 endif

  ; destroy the image archive and release all pointers
  for i=0, state.archive_size-1 do obj_destroy, image_archive[i]
  
  ; reset color table and pmulti to user values
  tvlct, user_r, user_g, user_b
  !p.multi = state.active_window_pmulti
  
  ; Kill top-level base if it still exists
  if (xregistered ('phast')) then widget_control, state.base_id, /destroy
  
  ; Destroy all pointers to plots and their heap variables: this runs
  ; ptr_free on any existing plot pointers
  if (nplot GT 0) then begin
    phasterase, /norefresh
  endif
  
  if (size(state, /tname) EQ 'STRUCT') then begin
    if (!d.name EQ state.graphicsdevice) then wdelete, state.pan_pixmap
    if (ptr_valid(state.head_ptr)) then ptr_free, state.head_ptr
    if (ptr_valid(state.astr_ptr)) then ptr_free, state.astr_ptr
  endif
  
  ; Clean up saved variables in common blocks to conserve memory.
  ; Previously this was done using delvarx, but since delvarx uses an
  ; execute function, it's incompatible with IDL virtual machine.  So,
  ; just set these variables to zero.
  
  plot_ptr=0
  maxplot=0
  main_image=0
  main_image_cube=0
  display_image=0
  scaled_image=0
  blink_image1=0
  blink_image2=0
  blink_image3=0
  unlink_image=0
  pan_image=0
  r_vector=0
  g_vector=0
  b_vector=0
  user_r=0
  user_g=0
  user_b=0
  state=0
  traceinit=0
  tracecenters=0
  tracepoints=0
  xspec=0
  fulltrace=0
  spectrum=0
  
  return
end

;---------------------------------------------------------------------

pro phast_startup, phast_dir, launch_dir

; This routine initializes the phast internal variables, and creates and
; realizes the window widgets.  It is only called by the phast main
; program level, when there is no previously existing phast window.
      
  common phast_state
  common phast_color
        
  ; save the user color table and pmulti first
  tvlct, user_r, user_g, user_b, /get
        
  ; Read in a color table to initialize !d.table_size
  ; As a bare minimum, we need the 8 basic colors used by PHAST_ICOLOR(),
  ; plus 2 more for a color map.
        
  ;loadct, 0, /silent
  if (!d.table_size LT 12) then begin
     message, 'Too few colors available for color table'
     tvlct, user_r, user_g, user_b
     phast_shutdown
  endif
        
  ; Initialize the common blocks
  phast_initcommon, phast_dir, launch_dir
        
  state.active_window_pmulti = !p.multi
  !p.multi = 0
        
  osfamily = strupcase(!version.os_family)
  case osfamily of
     'UNIX': state.delimiter = '/'
     'WINDOWS': state.delimiter = '\'
     else:
  endcase
        
  state.ncolors = !d.table_size - 9
        
  ; If compiling phast to make a sav file for the phast virtual machine,
  ; always do it for 24-bit color with retain & decomposed set.
  ; Uncomment this block to compile phast for idl vm.  For some reason,
  ; idl vm gets !d.n_colors=256 even on a 24-bit display, so we need
  ; this to work around it to force 24-bit mode.
  ;device, true_color=24
  device, decomposed=0
  device, retain=2
  state.bitdepth=24
        
  ; For normal idl operation, use the following.  Comment this block out
  ; if compiling phast for idl vm.
  ;; if (!d.n_colors LE 256) then begin
  ;;     state.bitdepth = 8
  ;; endif else begin
  ;;     state.bitdepth = 24
  ;;     device, decomposed=0
  ;; endelse
        
        
  state.graphicsdevice = !d.name
  
  state.screen_xsize = (get_screen_size())[0]
  state.screen_ysize = (get_screen_size())[1]
        
        
  ; Get the current window id and color table
  phast_getwindow
        
        
  ; Define the widgets.  For the widgets that need to be modified later
  ; on, save their widget ids in state variables
  
  base = widget_base(title = 'PhAst', $
                     /row, /base_align_top, $
                     app_mbar = top_menu, $
                     uvalue = 'phast_base', $
                     /tlb_size_events,bitmap='icon.bmp')
  state.base_id = base
        
  tmp_struct = {cw_pdmenu_s, flags:0, name:''}
        
  top_menu_desc = [ $
                  {cw_pdmenu_s, 1, 'File'}, $ ; file menu
                  {cw_pdmenu_s, 1, 'Read'},$
                  {cw_pdmenu_s, 0, 'Read FITS file'}, $
                  {cw_pdmenu_s, 0, 'Read FITS directory'},$
                  {cw_pdmenu_s, 0, '--------------'}, $
                  {cw_pdmenu_s, 0 ,'Read VICAR file'}, $
                  {cw_pdmenu_s, 2 ,'Read VICAR directory'}, $
                  {cw_pdmenu_s, 1, 'Write'},$
                  {cw_pdmenu_s, 0, 'Write FITS file'}, $
                  {cw_pdmenu_s, 1, 'Write image file'}, $
                  {cw_pdmenu_s, 0, 'PNG'}, $
                  {cw_pdmenu_s, 0, 'JPEG'}, $
                  {cw_pdmenu_s, 2, 'TIFF'}, $
                  {cw_pdmenu_s, 2, 'Write postscript file'},  $
                  ;{cw_pdmenu_s, 0, 'WriteMPEG'}, $
                  ;{cw_pdmenu_s, 1, 'Get'}, $
                  ;{cw_pdmenu_s, 2, ' DSS'}, $
                  ;{cw_pdmenu_s, 2, ' FIRST'},
                  {cw_pdmenu_s, 1, 'Remove'},$
                  {cw_pdmenu_s, 0, 'Remove current image'},$
                  {cw_pdmenu_s, 0, 'Remove all images'},$
                  {cw_pdmenu_s, 0, '--------------'}, $
                  {cw_pdmenu_s, 2, 'Clear output directory'},$
                  {cw_pdmenu_s, 1, 'Refresh'},$
                  {cw_pdmenu_s, 0, 'Refresh current image'},$
                  {cw_pdmenu_s, 2, 'Refresh all images'},$
                  {cw_pdmenu_s, 0, '--------------'}, $
                  {cw_pdmenu_s, 2, 'Quit'}, $
                  {cw_pdmenu_s, 1, 'ColorMap'}, $ ; color menu
                  {cw_pdmenu_s, 0, 'Grayscale'}, $
                  {cw_pdmenu_s, 0, 'Blue-White'}, $
                  {cw_pdmenu_s, 0, 'Red-Orange'}, $
                  {cw_pdmenu_s, 0, 'Green-White'}, $
                  {cw_pdmenu_s, 0, 'Rainbow'}, $
                  {cw_pdmenu_s, 0, 'BGRY'}, $
                  {cw_pdmenu_s, 0, 'Stern Special'}, $
                  {cw_pdmenu_s, 0, 'PHAST Special'}, $
                  {cw_pdmenu_s, 0, 'Velocity1'}, $
                  {cw_pdmenu_s, 2, 'Velocity2'}, $
                  {cw_pdmenu_s, 1, 'Scaling'}, $ ; scaling menu
                  {cw_pdmenu_s, 0, 'Asinh'}, $
                  {cw_pdmenu_s, 0, 'Log'}, $
                  {cw_pdmenu_s, 0, 'Linear'}, $
                  {cw_pdmenu_s, 0, 'HistEq'}, $
                  {cw_pdmenu_s, 0, '--------------'}, $
                  {cw_pdmenu_s, 0, 'Asinh Settings'}, $
                  ;{cw_pdmenu_s, 0, '--------------'}, $
                  ;{cw_pdmenu_s, 0, 'Stretch vertically'}, $
                  {cw_pdmenu_s, 2, '--------------'}, $
                  {cw_pdmenu_s, 1, 'Labels'}, $ ; labels menu
                  {cw_pdmenu_s, 0, 'TextLabel'}, $
                  {cw_pdmenu_s, 0, 'Arrow'}, $
                  {cw_pdmenu_s, 0, 'Contour'}, $
                  {cw_pdmenu_s, 0, 'Compass'}, $
                  {cw_pdmenu_s, 0, 'ScaleBar'}, $
                  {cw_pdmenu_s, 0, 'Region'}, $
                  {cw_pdmenu_s, 0, '--------------'}, $
                  {cw_pdmenu_s, 0, 'EraseLast'}, $
                  {cw_pdmenu_s, 0, 'EraseAll'}, $
                  {cw_pdmenu_s, 0, '--------------'}, $
                  {cw_pdmenu_s, 0, 'LoadRegions'}, $
                  {cw_pdmenu_s, 2, 'SaveRegions'}, $
                  {cw_pdmenu_s, 1, 'Blink'}, $
                  {cw_pdmenu_s, 0, 'SetBlink1'}, $
                  {cw_pdmenu_s, 0, 'SetBlink2'}, $
                  {cw_pdmenu_s, 0, 'SetBlink3'}, $
                  {cw_pdmenu_s, 0, '--------------'}, $
                  {cw_pdmenu_s, 2, 'MakeRGB'}, $
                  {cw_pdmenu_s, 1, 'Rotate/Zoom'}, $
                 ; {cw_pdmenu_s, 0, 'Rotate'}, $
                  {cw_pdmenu_s, 0, '90 deg'}, $
                  {cw_pdmenu_s, 0, '180 deg'}, $
                  {cw_pdmenu_s, 0, '270 deg'}, $
                  {cw_pdmenu_s, 0, '--------------'}, $
                  {cw_pdmenu_s, 0, 'Invert X'}, $
                  {cw_pdmenu_s, 0, 'Invert Y'}, $
                  {cw_pdmenu_s, 0, 'Invert XY'}, $
                  {cw_pdmenu_s, 0, '--------------'}, $
                  {cw_pdmenu_s, 1, 'Zoom'},$
                  {cw_pdmenu_s, 0, '1/16x'}, $
                  {cw_pdmenu_s, 0, '1/8x'}, $
                  {cw_pdmenu_s, 0, '1/4x'}, $
                  {cw_pdmenu_s, 0, '1/2x'}, $
                  {cw_pdmenu_s, 0, '1x'}, $
                  {cw_pdmenu_s, 0, '2x'}, $
                  {cw_pdmenu_s, 0, '4x'}, $
                  {cw_pdmenu_s, 0, '8x'}, $
                  {cw_pdmenu_s, 2, '16x'}, $
                  {cw_pdmenu_s, 2, '--------------'}, $
                  {cw_pdmenu_s, 1, 'ImageInfo'}, $ ;info menu
                  {cw_pdmenu_s, 0, 'Image header'}, $
                  {cw_pdmenu_s, 0, 'Photometry'}, $
                  {cw_pdmenu_s, 0, 'Statistics'}, $
                  {cw_pdmenu_s, 0, 'Pixel table'}, $
                  {cw_pdmenu_s, 1, 'Coordinates'}, $
                  {cw_pdmenu_s, 0, 'RA,dec (J2000)'}, $
                  {cw_pdmenu_s, 0, 'RA,dec (B1950)'}, $
                  {cw_pdmenu_s, 0, '--------------'}, $
                  {cw_pdmenu_s, 0, 'RA,dec (J2000) deg'}, $
                  {cw_pdmenu_s, 0, 'Galactic'}, $
                  {cw_pdmenu_s, 0, 'Ecliptic (J2000)'}, $
                  {cw_pdmenu_s, 2, 'Native'}, $
                  {cw_pdmenu_s, 1, 'Select catalog'},$
                  {cw_pdmenu_s, 0, 'USNO-B1.0 (online)'}, $
                  {cw_pdmenu_s, 2, 'GSC 2.3 (online)'}, $
                  ;{cw_pdmenu_s, 0, 'USNOA2'},$
                  ;{cw_pdmenu_s, 2, 'UCAC2'},$
                  {cw_pdmenu_s, 1, 'Select filter'},$
                  {cw_pdmenu_s, 0, 'Blue'},$
                  {cw_pdmenu_s, 0, 'Visible'},$
                  {cw_pdmenu_s, 2, 'Red'},$
                  {cw_pdmenu_s, 0, '--------------'},$
                  {cw_pdmenu_s, 2, 'MPC report'},$
                  {cw_pdmenu_s, 1, 'Pipeline'}, $
                  {cw_pdmenu_s, 0, 'Combine images'},$
                  {cw_pdmenu_s, 0, 'Process images'}, $
                  {cw_pdmenu_s, 2, 'Photometric zero-point'},$
                  {cw_pdmenu_s, 1, 'Help'}, $ ; help menu
                  {cw_pdmenu_s, 0, 'PHAST Help'},$
                  {cw_pdmenu_s, 0, 'Debug info'},$                  
                  {cw_pdmenu_s, 2, 'Check for updates'}$
                  ]
          
  top_menu = cw_pdmenu(top_menu, top_menu_desc, $
                       ids = state.menu_ids, $
                       /mbar, $
                       /help, $
                       /return_name, $
                       uvalue = 'top_menu')
          
          
  left_pane = widget_base(base,/column,/base_align_center,xsize=270)
  track_base = widget_base(left_pane, /row)
  state.colorbar_base_id = widget_base(left_pane, $
                                       uvalue = 'colorbar_base', $
                                       /column, /base_align_center, $
                                       frame = 2,xsize=250)
  
          
  image_switch_base = widget_base(left_pane,/column,xsize=250,frame=4,/base_align_center)
  image_switch_row1 = widget_base(image_switch_base,/row)
  cycle_image_label = widget_label(image_switch_row1,value="Cycle images: no image loaded",/align_left)
  image_switch_sub = widget_base(image_switch_base,/row)
  left_button = widget_button(image_switch_sub,value='<---',uvalue='left_button',$
                              tooltip='Previous image')
  right_button = widget_button(image_switch_sub,value='--->', uvalue='right_button',$
                               tooltip='Next image')
  image_select_box = widget_droplist(image_switch_sub,value='no image',/dynamic_resize,uvalue='image_select_box')
  
  toggle_buttonbox = widget_base(image_switch_row1,/row,/nonexclusive)
  
  state.align_toggle_button = widget_button(toggle_buttonbox,value='Align',uvalue='align_toggle',$
                               tooltip='Align images using WCS coordinates')
  
  state.image_counter_id = cycle_image_label
  state.image_select_id = image_select_box
  
  state.info_base_id = widget_base(left_pane, /column,frame=4,xsize=250,/base_align_center)
  buttonbar_base = widget_base(left_pane, column=3,xsize=250,frame=4,/base_align_center)
  
        
  state.draw_base_id = widget_base(base, $
                                   /column, /base_align_center, $
                                   uvalue = 'draw_base', $
                                   frame = 2)
  
  minmax_base = widget_base(state.info_base_id,/row,/base_align_center)
  
  state.min_text_id = cw_field(minmax_base, $
                               uvalue = 'min_text', $
                               /floating,  $
                               title = 'Min=', $
                               value = state.min_value,  $
                               /return_events, $
                               xsize = 11)
          
  state.max_text_id = cw_field(minmax_base, $
                               uvalue = 'max_text', $
                               /floating,  $
                               title = 'Max=', $
                               value = state.max_value, $
                               /return_events, $
                               xsize = 11)
  
  tmp_string = string(1000, 1000, 1.0e-10, $
                      format = '("(",i5,",",i5,") ",g12.5)' )
  
  state.location_bar_id = widget_label (state.info_base_id, $
                                        value = tmp_string,  $
                                        uvalue = 'location_bar')
  
  tmp_string = string(12, 12, 12.001, -60, 60, 60.01, ' J2000', $
                      format = '(i2,":",i2,":",f6.3,"  ",i3,":",i2,":",f5.2," ",a6)' )
  
  state.wcs_bar_id = widget_label (state.info_base_id, $
                                   value = tmp_string,  $
                                   uvalue = 'wcs_bar')
  
  state.pan_widget_id = widget_draw(track_base, $
                                    xsize = state.pan_window_size, $
                                    ysize = state.pan_window_size, $
                                    frame = 2, uvalue = 'pan_window', $
                                    /button_events, /motion_events)
  
  track_window = widget_draw(track_base, $
                             xsize=state.track_window_size, $
                             ysize=state.track_window_size, $
                             frame=2, uvalue='track_window')
  
  modebase = widget_base(buttonbar_base, /column, /base_align_center)
  mode_label = widget_label(modebase,value='Mouse Mode')
  modelist = ['Color', 'Zoom', 'Blink', 'ImExam', 'Vector','Label']
  mode_droplist_id = widget_droplist(modebase, $
                                     uvalue = 'mode', $
                                     value = modelist)
  widget_control,mode_droplist_id,set_droplist_select=3
  
  state.mode_droplist_id = mode_droplist_id
  
  
  button_base1 = widget_base(buttonbar_base, /column,/base_align_center)
  button_base2 = widget_base(buttonbar_base, /column,/base_align_center)
  
  
  invert_button = widget_button(button_base1, $
                                value = 'Invert', $
                                uvalue = 'invert',xsize=72)
  
  restretch_button = widget_button(button_base1, $
                                   value = 'Restretch', $
                                   uvalue = 'restretch_button',xsize=72)
  
  autoscale_button = widget_button(button_base1, $
                                   uvalue = 'autoscale_button', $
                                   value = 'AutoScale',xsize=72)
  
  fullrange_button = widget_button(button_base1, $
                                   uvalue = 'full_range', $
                                   value = 'FullRange',xsize=72)
          
  ;dummy_spacing_widget = widget_label(button_base,value='')
          
  zoomin_button = widget_button(button_base2, $
                                value = 'ZoomIn', $
                                uvalue = 'zoom_in',xsize=72)
  
  zoomout_button = widget_button(button_base2, $
                                 value = 'ZoomOut', $
                                 uvalue = 'zoom_out',xsize=72)
  
  zoomone_button = widget_button(button_base2, $
                                 value = 'Zoom1', $
                                 uvalue = 'zoom_one',xsize=72)
  
  ;fullview_button = widget_button(button_base2, $
  ;                                value = 'FullView', $
  ;                                uvalue = 'fullview')
          
  center_button = widget_button(button_base2, $
                                value = 'Center', $
                                uvalue = 'center',xsize=72)

  ;blink control
  if state.tb_blink_visible eq 1 then begin
     blink_base_toggle = widget_button(left_pane,value='Blink Control',uvalue='blink_base_toggle')
     blink_base = widget_base(left_pane,/column,frame=4,/base_align_center,xsize=250)
     
     ; NOTE: EVENTS RETURNED BY THE BLINK BASE LABEL ARE TIMER EVENTS FOR ANIMATION
     blink_base_label = widget_label(blink_base,value=' ',uvalue='blink_base_label',ysize=1,xsize=1)
     
     blink_nav_base = widget_base(blink_base,/row,/align_center)
     blink_first = widget_button(blink_nav_base,value='<--|',uvalue='blink_first',$
                                 tooltip='First image')
     blink_back = widget_button(blink_nav_base,value='<---',uvalue='blink_back',$
                                tooltip='Previous image')
     blink_pause = widget_button(blink_nav_base,value='||',uvalue='blink_pause',$
                                 tooltip='Pause animation')
     blink_animate = widget_button(blink_nav_base,value='|>',uvalue='blink_animate',$
                                   tooltip='Start animation')
     
     blink_forward = widget_button(blink_nav_base,value='--->',uvalue='blink_forward',$
                                   tooltip='Next image')
     blink_last = widget_button(blink_nav_base,value='|-->',uvalue='blink_last',$
                                tooltip='Last image')
     speed_label = widget_label(blink_base,value='Animate speed: '+strmid(strtrim(string(1/state.animate_speed),1),0,4)+' image/sec')
     speed_slider = widget_slider(blink_base,value=10/state.animate_speed,/drag,uvalue='speed_slider',$
                                  min=10,/suppress_value,xsize=244)
     animate_type_label = widget_label(blink_base,value='Select animation type')
     animate_type_box = widget_base(blink_base,/row,/exclusive)
     type_forward = widget_button(animate_type_box,value='Forward',uvalue='type_forward')
     type_backward = widget_button(animate_type_box,value='Backward',uvalue='type_backward')
     type_bounce = widget_button(animate_type_box, value='Bounce',uvalue='type_bounce')
     
     state.speed_label_id = speed_label
     state.blink_base_label_id = blink_base_label
     state.blink_base_id = blink_base
  endif
  
  ;star overlay
  if state.tb_overlay_visible eq 1 then begin
     overlay_toggle    = widget_button(left_pane,value='Overlay stars',uvalue='overlay_toggle')
     
     overlay_stars_box = widget_base(left_pane,/column,frame=4,xsize=250, /align_center)
     
     overlay_sub_box   = widget_base(overlay_stars_box, /row)
     
     overlay_catalog_id = widget_droplist(overlay_sub_box,value=state.overlay_catList,uvalue='overlay_catalog')
     ;mag_select_label   = widget_label(overlay_sub_box,value='<=')
     mag_select_value   = widget_text(overlay_sub_box,value=string(state.mag_limit,'(F4.1)'),uvalue='mag_select', $
                                      xsize=4, /editable, /all_events, /align_bottom)
     mag_select_label   = widget_label(overlay_sub_box,value='R')          
     display_stars      = widget_button(overlay_sub_box,value='Display',uvalue='display_stars',$
                                        tooltip='Overlay stars from selected catalog')
     
     stars_button_box = widget_base(overlay_stars_box, /row, /align_center)
     overlay_char     = CW_BGROUP(stars_button_box, ['Circle', 'Name', 'R Mag', 'B-R'], uvalue = 'display_char', $
                                  button_uvalue = [0, 1, 2, 3], set_value = 0, label_left = '', $
                                  ypad=0, /exclusive, /no_release, /row)
     
     star_search_box  = widget_base(overlay_stars_box, /row, /align_center)
     search_button    = widget_button(star_search_box,value='Search',uvalue='search_button')
     search_field     = widget_text(star_search_box,value='Search for a star...',uvalue='search_field',/editable)
     erase_button     = widget_button(star_search_box,value='Erase',uvalue='erase_button')
     search_notify    = widget_label(overlay_stars_box,value='---------------',/dynamic_resize)
     
     state.overlay_catalog_id = overlay_catalog_id
     state.mag_select_id = mag_select_value
     state.overlay_char_id = overlay_char
     state.star_search_widget_id = search_field
     state.overlay_stars_box_id = overlay_stars_box
     state.search_msg_id = search_notify
  endif
        
  ;SPICE controls
  if state.tb_spice_visible eq 1 then begin
     spice_toggle = widget_button(left_pane,value='SPICE Control',uvalue='spice_toggle')
     state.spice_box_id = widget_base(left_pane,/column,frame=4,xsize=250)
     spice_sub_box = widget_base(state.spice_box_id,/row)
     check_moons = widget_button(spice_sub_box,value='Check Moons', uvalue='check_moons')
     
  endif
  
  ; Set widget y size for small screens
  state.draw_window_size[1] = state.draw_window_size[1] < $
                              (state.screen_ysize - 300)
  
  state.draw_widget_id = widget_draw(state.draw_base_id, $
                                     uvalue = 'draw_window', $
                                     /motion_events,  /button_events, $
                                     keyboard_events=2, $
                                     scr_xsize = state.draw_window_size[0], $
                                     scr_ysize = state.draw_window_size[1])
  
  state.colorbar_widget_id = widget_draw(state.colorbar_base_id, $
                                         uvalue = 'colorbar', $
                                         xsize=243,/align_left,$
                                         scr_ysize = state.colorbar_height)
  
  ; Create the widgets on screen
  
  widget_control, base, /realize
  widget_control, state.pan_widget_id, draw_motion_events = 0

  ;set initial collapse states
  if state.tb_overlay_toggle eq 0 and state.tb_overlay_visible eq 1 then widget_control,state.overlay_stars_box_id,ysize=1
  if state.tb_blink_toggle eq 0 and state.tb_blink_visible eq 1 then widget_control,state.blink_base_id,ysize=1
  if state.tb_spice_toggle eq 0 and state.tb_spice_visible eq 1 then widget_control,state.spice_box_id,ysize=1
  
  
  ; get the window ids for the draw widgets
        
  widget_control, track_window, get_value = tmp_value
  state.track_window_id = tmp_value
  widget_control, state.draw_widget_id, get_value = tmp_value
  state.draw_window_id = tmp_value
  widget_control, state.pan_widget_id, get_value = tmp_value
  state.pan_window_id = tmp_value
  widget_control, state.colorbar_widget_id, get_value = tmp_value
  state.colorbar_window_id = tmp_value
  
  ; set the event handlers
  
  widget_control, top_menu, event_pro = 'phast_topmenu_event'
  widget_control, state.draw_widget_id, event_pro = 'phast_draw_event'
  widget_control, state.pan_widget_id, event_pro = 'phast_pan_event'
        
  ; Find window padding sizes needed for resizing routines.
  ; Add extra padding for menu bar, since this isn't included in
  ; the geometry returned by widget_info.
  ; Also add extra padding for margin (frame) in draw base.
  
  basegeom = widget_info(state.base_id, /geometry)
  drawbasegeom = widget_info(state.draw_base_id, /geometry)
  
        
  ; Initialize the vectors that hold the current color table.
  ; See the routine phast_stretchct to see why we do it this way.
        
  r_vector = bytarr(state.ncolors)
  g_vector = bytarr(state.ncolors)
  b_vector = bytarr(state.ncolors)
  
  phast_getct, 0
  state.invert_colormap = 0
        
  ; Create a pixmap window to hold the pan image
  window, /free, xsize=state.pan_window_size, ysize=state.pan_window_size, $
          /pixmap
  state.pan_pixmap = !d.window
  phast_resetwindow
  
  phast_colorbar
  
  widget_control, state.base_id, tlb_get_size=tmp_event
  state.base_pad = tmp_event - state.draw_window_size
  state.base_pad[1] = 20        ;set y pad staticlly
        
  ;check for output directories

  if not (file_test(phast_dir+'output',/directory) and file_test(phast_dir+'output/images',/directory) and file_test(phast_dir+'output/catalogs',/directory)) then begin
     result = dialog_message('Output directories not found.  Create them?',/question,/center)
     if result eq 'Yes' then begin
        file_mkdir,phast_dir+'output/images'
        file_mkdir,phast_dir+'output/catalogs'
     endif else begin
        result = dialog_message('PHAST will not function correctly without the appropriate output directories.',/center)
     endelse
  endif  
end

;--------------------------------------------------------------------

pro phast_topmenu_event, event
      
        ; Event handler for top menu
      
  common phast_state
  common phast_images
  
  widget_control, event.id, get_uvalue = event_name
  
  if (!d.name NE state.graphicsdevice and event_name NE 'Quit') then return
  if (state.bitdepth EQ 24) then true = 1 else true = 0
        
  ; Need to get active window here in case mouse goes to menu from top
  ; of phast window without entering the main base
  phast_getwindow
        
        
  case event_name of
        
  ; File menu options:
     'Read FITS file': begin
        phast_readfits, newimage=newimage
        if (newimage EQ 1) then begin
           phast_getstats, align=state.default_align
           if (state.default_align EQ 0) then begin
              state.zoom_level =  0
              state.zoom_factor = 1.0
           endif
           if (state.default_stretch EQ 0 AND $
               state.default_autoscale EQ 1) then phast_autoscale
           if (state.firstimage EQ 1) then phast_autoscale
           phast_set_minmax
           if state.align_toggle eq 1 then begin
              offset = phast_get_image_offset()
              if not finite(offset[0]) then begin
                 result = dialog_message('Image alignment disabled: PhAst does not currently support aligning images which do not overlap.', /error,/center)
                 state.align_toggle = 0
                 widget_control, state.align_toggle_button, set_button=0
              endif
           endif
           phast_displayall
           phast_settitle
           state.firstimage = 0
        endif
     end
     'Read FITS directory': begin
        widget_control,/hourglass
        phast_readfits, /dir, newimage=newimage
        if (newimage EQ 1) then begin
           phast_getstats, align=state.default_align
           if (state.default_align EQ 0) then begin
              state.zoom_level =  0
              state.zoom_factor = 1.0
           endif
           if (state.default_stretch EQ 0 AND $
               state.default_autoscale EQ 1) then phast_autoscale
           if (state.firstimage EQ 1) then phast_autoscale
           
           phast_set_minmax
           phast_image_switch,0
           phast_settitle
           state.firstimage = 0
        endif
     end
          
     'Read VICAR file': begin
        newimage=0
        phast_read_vicar,  newimage=newimage
        if newimage eq 1 then begin
           phast_getstats, align=state.default_align
           if (state.default_align EQ 0) then begin
              state.zoom_level =  0
              state.zoom_factor = 1.0
           endif
           if (state.default_stretch EQ 0 AND $
               state.default_autoscale EQ 1) then phast_autoscale
           if (state.firstimage EQ 1) then phast_autoscale
           phast_set_minmax
           phast_displayall
           phast_settitle
           state.firstimage = 0
           state.image_type = 'VICAR'
        endif
     end
     
     'Read VICAR directory': begin
        newimage=0
        phast_read_vicar, /dir, newimage=newimage
        if newimage eq 1 then begin
           phast_getstats, align=state.default_align
           if (state.default_align EQ 0) then begin
              state.zoom_level =  0
              state.zoom_factor = 1.0
           endif
           if (state.default_stretch EQ 0 AND $
               state.default_autoscale EQ 1) then phast_autoscale
           if (state.firstimage EQ 1) then phast_autoscale
           phast_set_minmax
           phast_image_switch,0
           phast_displayall
           phast_settitle
           state.firstimage = 0
           state.image_type = 'VICAR'
        endif
     end
     
          
     'Write FITS file': phast_writefits
     'Write postscript file' : phast_writeps
     'PNG': phast_writeimage, 'png'
     'JPEG': phast_writeimage, 'jpg'
     'TIFF': phast_writeimage, 'tiff'
     ;'WriteMPEG': phast_write_mpeg
     'GetImage':
     ' DSS': phast_getdss
     ;' FIRST': phast_getfirst
     'LoadRegions': phast_loadregion
     'SaveRegions': phast_saveregion
     'Remove current image': phast_remove_image,index=state.current_image_index
     'Remove all images': begin
        widget_control,/hourglass
        state.current_image_index = 0
        phast_remove_image,/all
     end
     'Clear output directory': begin
        result = dialog_message('Empty ./output/images/ ?  This will remove all files from this directory',/question,/center)
        if result eq 'Yes' then spawn, 'rm ./output/images/*'
     end
     'Refresh current image': phast_refresh_image,state.current_image_index,state.imagename
     'Refresh all images': for i=0, state.num_images-1 do phast_refresh_image,i,image_archive[i]->get_name()
     'Quit':     if (state.activator EQ 0) then phast_shutdown $
     else state.activator = 0
     ;ColorMap menu options:
     'Grayscale': phast_getct, 0
     'Blue-White': phast_getct, 1
     'Red-Orange': phast_getct, 3
     'BGRY': phast_getct, 4
     'Rainbow': phast_getct, 13
     'Stern Special': phast_getct, 15
     'Green-White': phast_getct, 8
     'PHAST Special': phast_makect, event_name
     'Velocity1': phast_makect, event_name
     'Velocity2': phast_makect, event_name
     ; Scaling options:
     'Linear': begin
        state.scaling = 0
        phast_displayall
     end
     'Log': begin
        state.scaling = 1
        phast_displayall
     end
     
     'HistEq': begin
        state.scaling = 2
        phast_displayall
     end
     
     'Asinh': begin
        state.scaling = 3
        phast_displayall
     end
     
     'Asinh Settings': begin
        phast_setasinh
     end
     ;'Stretch vertically':  phast_stretch_image
     
     ; Label options:
     'TextLabel': phast_textlabel
     'Arrow': phast_setarrow
     'Contour': phast_oplotcontour
     'Compass': phast_setcompass
     'ScaleBar': phast_setscalebar
     'Region': phast_setregion
     'EraseLast': phasterase, 1
     'EraseAll': phasterase
     
     ; Blink options:
     'SetBlink1': begin
        phast_setwindow, state.draw_window_id
        blink_image1 = tvrd(true = true)
     end
     'SetBlink2': begin
        phast_setwindow, state.draw_window_id
        blink_image2 = tvrd(true = true)
     end
     'SetBlink3': begin
        phast_setwindow, state.draw_window_id
        blink_image3 = tvrd(true = true)
     end
     
     'MakeRGB' : phast_makergb
     
     ; Zoom/Rotate options
     '1/16x': phast_zoom, 'onesixteenth'
     '1/8x': phast_zoom, 'oneeighth'
     '1/4x': phast_zoom, 'onefourth'
     '1/2x': phast_zoom, 'onehalf'
     '1x': phast_zoom, 'one'
     '2x': phast_zoom, 'two'
     '4x': phast_zoom, 'four'
     '8x': phast_zoom, 'eight'
     '16x': phast_zoom, 'sixteen'
     'Invert X': phast_invert, 'x'
     'Invert Y': phast_invert, 'y'
     'Invert XY': phast_invert, 'xy'
     'Rotate': phast_rotate, '0', /get_angle
     '0 deg': phast_rotate, '0'
     '90 deg': phast_rotate, '90'
     '180 deg': phast_rotate, '180'
     '270 deg': phast_rotate, '270'
     
     ; Info options:
     'Photometry': phast_apphot
     'Image header': phast_headinfo
     'Statistics': phast_showstats
     'Pixel table': phast_pixtable
     
     ; Coordinate system options:
     '--------------':
     'RA,dec (J2000)': BEGIN
        state.display_coord_sys = 'RA--'
        state.display_equinox = 'J2000'
        state.display_base60 = 1B
        phast_gettrack          ; refresh coordinate window
     END
     'RA,dec (B1950)': BEGIN
        state.display_coord_sys = 'RA--'
        state.display_equinox = 'B1950'
        state.display_base60 = 1B
        phast_gettrack          ; refresh coordinate window
     END
     'RA,dec (J2000) deg': BEGIN
        state.display_coord_sys = 'RA--'
        state.display_equinox = 'J2000'
        state.display_base60 = 0B
        phast_gettrack          ; refresh coordinate window
     END
     'Galactic': BEGIN
        state.display_coord_sys = 'GLON'
        phast_gettrack          ; refresh coordinate window
     END
     'Ecliptic (J2000)': BEGIN
        state.display_coord_sys = 'ELON'
        state.display_equinox = 'J2000'
        phast_gettrack          ; refresh coordinate window
     END
     'Native': BEGIN
        IF (state.wcstype EQ 'angle') THEN BEGIN
           state.display_coord_sys = strmid((*state.astr_ptr).ctype[0], 0, 4)
           state.display_equinox = state.equinox
           phast_gettrack       ; refresh coordinate window
        ENDIF
     END
     ;Catalog options
     'USNO-B1.0 (online)': state.catalog_name = 'USNO-B1.0'
     'GSC 2.3 (online)': state.catalog_name = 'GSC 2.3'
     'USNOA2': state.catalog_name = 'USNOA2'
     'UCAC2': state.catalog_name = 'UCAC2'
     'MPC report': phast_mpc_report
     ;Filter options
     'Blue': state.filter_color = 'Blue'
     'Visible': state.filter_color = 'Visible'
     'Red': state.filter_color = 'Red'
     ;Pipeline options
     'Combine images': phast_combine_gui
     'Calibration': phast_calibrate_image
     'SExtractor': phast_sextractor
     'SCAMP': phast_scamp
     'missFITS': phast_missfits
     'Photometric zero-point': begin
        if file_test('zeropoint.param') eq 1 then begin
           phast_zeropoint
        endif else result = dialog_message('The file zeropoint.param is required for this action.  Download it from the PhAst website.',/error,/center)
     end
     'Do all': phast_do_all
     'Process images': phast_batch
     
     
     ; Help options:
     'PHAST Help': phast_help
     'Debug info': phast_debug_info
     'Check for updates': phast_check_updates
     
     else: print, 'Unknown event in file menu!'
  endcase
  
  ; Need to test whether phast is still alive, since the quit option
  ; might have been selected.
  if (xregistered('phast', /noshow)) then phast_resetwindow   
end

;------------------------------------------------------------------
pro phast_wfpc2_read, fitsfile, head, cancelled

  ; Fits reader for 4-panel HST WFPC2 images

  common phast_state
  common phast_images
  
  droptext = strcompress('0, droplist,PC|WF2|WF3|WF4|Mosaic,' + $
    'label_left = Select WFPC2 CCD:, set_value=0')
    
  formdesc = [droptext, $
    '0, button, Read WFPC2 Image, quit', $
    '0, button, Cancel, quit']
    
  textform = cw_form(formdesc, /column, title = 'WFPC2 CCD Selector')
  
  if (textform.tag2 EQ 1) then begin ; cancelled
    cancelled = 1
    return
  endif
  
  ccd = long(textform.tag0) + 1
  
  widget_control, /hourglass
  if (ccd LE 4) then begin
    main_image=0
    wfpc2_read, fitsfile, main_image, head, num_chip = ccd
  endif
  
  if (ccd EQ 5) then begin
    main_image=0
    wfpc2_read, fitsfile, main_image, head, /batwing
  endif
  
  case ccd of
    1: state.title_extras = 'PC1'
    2: state.title_extras = 'WF2'
    3: state.title_extras = 'WF3'
    4: state.title_extras = 'WF4'
    5: state.title_extras = 'Mosaic'
    else: state.title_extras = ''
  endcase
end

pro phast_writefits

  ; Writes image to a FITS file

  common phast_state
  common phast_images
  
  ; Get filename to save image
  
  filename = dialog_pickfile(filter = '*.fits', $
    file = 'phast.fits', $
    default_extension = '.fits', $
    dialog_parent =  state.base_id, $
    path = state.current_dir, $
    get_path = tmp_dir, $
    /write, /overwrite_prompt)
    
  if (tmp_dir NE '') then state.current_dir = tmp_dir
  
  if (strcompress(filename, /remove_all) EQ '') then return   ; cancel
  
  if (filename EQ state.current_dir) then begin
    phast_message, 'Must indicate filename to save.', msgtype = 'error', /window
    return
  endif
  
  if (ptr_valid(state.head_ptr)) then begin
    writefits, filename, main_image, (*state.head_ptr)
  endif else begin
    writefits, filename, main_image
  endelse
end

;-----------------------------------------------------------------------

pro phast_writeimage, imgtype

  common phast_state
  common phast_images
  
  
  tmpfilename = strcompress('phast.' + strlowcase(imgtype), /remove_all)
  filename = dialog_pickfile(file = tmpfilename, $
    dialog_parent = state.base_id, $
    path = state.current_dir, $
    get_path = tmp_dir, $
    /write, /overwrite_prompt)
  if (tmp_dir NE '') then state.current_dir = tmp_dir
  if (strcompress(filename, /remove_all) EQ '') then return   ; cancel
  if (filename EQ state.current_dir) then begin
    phast_message, 'Must indicate filename to save.', msgtype = 'error', /window
    return
  endif
  
  ; From here down this routine is based on Liam E. Gumley's SAVEIMAGE
  ; program, modified for use with PHAST.
  
  quality = 75 ; for jpeg output
  
  ;- Check for TVRD capable device
  if ((!d.flags and 128)) eq 0 then begin
    phast_message, 'Unsupported graphics device- cannot create image.', $
      msgtype='error', /window
    return
  endif
  
  depth = state.bitdepth
  
  ;- Handle window devices (other than the Z buffer)
  if (!d.flags and 256) ne 0 then begin
  
    ;- Copy the contents of the current display to a pixmap
    current_window = state.draw_window_id
    xsize =  state.draw_window_size[0]
    ysize = state.draw_window_size[1]
    window, /free, /pixmap, xsize=xsize, ysize=ysize, retain=2
    device, copy=[0, 0, xsize, ysize, 0, 0, current_window]
    
    ;- Set decomposed color mode for 24-bit displays
    if (depth gt 8) then device, get_decomposed=entry_decomposed
    device, decomposed=1
  endif
  
  ;- Read the pixmap contents into an array
  if (depth gt 8) then begin
    image = tvrd(order=0, true=1)
  endif else begin
    image = tvrd(order=0)
  endelse
  
  ;- Handle window devices (other than the Z buffer)
  if (!d.flags and 256) ne 0 then begin
  
    ;- Restore decomposed color mode for 24-bit displays
    if (depth gt 8) then begin
      device, decomposed=entry_decomposed
    endif
    
    ;- Delete the pixmap
    wdelete, !d.window
    wset, current_window
    
  endif
  
  ;- Get the current color table
  tvlct, r, g, b, /get
  
  ;- If an 8-bit image was read, reduce the number of colors
  if (depth le 8) then begin
    reduce_colors, image, index
    r = r[index]
    g = g[index]
    b = b[index]
  endif
  
  ; write output file
  
  if (imgtype eq 'png') then begin
    write_png, filename, image, r, g, b
  endif
  
  if (imgtype eq 'jpg') or (imgtype eq 'tiff') then begin
  
    ;- Convert 8-bit image to 24-bit
    if (depth le 8) then begin
      info = size(image)
      nx = info[1]
      ny = info[2]
      true = bytarr(3, nx, ny)
      true[0, *, *] = r[image]
      true[1, *, *] = g[image]
      true[2, *, *] = b[image]
      image = temporary(true)
    endif
    
    ;- If TIFF format output, reverse image top to bottom
    if (imgtype eq 'tiff') then image = reverse(temporary(image), 3)
    
    ;- Write the image
    case imgtype of
      'jpg' : write_jpeg, filename, image, true=1, quality=quality
      'tiff' : write_tiff, filename, image, 1
    else  :
  endcase
endif


phast_resetwindow
end

;----------------------------------------------------------------------

pro phast_writeps

  ; Writes an encapsulated postscript file of the current display.
  ; Calls cmps_form to get postscript file parameters.

  ; Note. cmps_form blocks the command line but doesn't block phast
  ; menus.  If we have one cmps_form active and invoke another one, it
  ; would crash.  Use state.ispsformon to keep track of whether we have
  ; one active already or not.

  common phast_state
  common phast_images
  common phast_color
  
  if (state.ispsformon EQ 1) then return
  
  ; cmps_form.pro crashes if phast is in blocking mode.
  if (state.block EQ 1) then begin
    phast_message, 'PS output is disabled in blocking mode.', $
      msgtype = 'warning', /window
    return
  endif
  
  widget_control, /hourglass
  
  view_min = round(state.centerpix - $
    (0.5 * state.draw_window_size / state.zoom_factor))
  ; bug fix from N. Cunningham here- modified 4/14/06 to fix centering
  ; of overplots on the image by subtracting 1 from the max size
  view_max = round(view_min + state.draw_window_size $
    / state.zoom_factor - 1)
    
  xsize = (state.draw_window_size[0] / state.zoom_factor) > $
    (view_max[0] - view_min[0] + 1)
  ysize = (state.draw_window_size[1] / state.zoom_factor) > $
    (view_max[1] - view_min[1] + 1)
    
  aspect = float(ysize) / float(xsize)
  fname = strcompress(state.current_dir + 'phast.ps', /remove_all)
  
  phast_setwindow, state.draw_window_id
  tvlct, rr, gg, bb, 8, /get
  phast_resetwindow
  
  ; make sure that we don't keep the cmps_form window as the active window
  external_window_id = !d.window
  
  state.ispsformon = 1
  psforminfo = cmps_form(cancel = canceled, create = create, $
    aspect = aspect, parent = state.base_id, $
    /preserve_aspect, $
    xsize = 6.0, ysize = 6.0 * aspect, $
    /color, /encapsulated, $
    /nocommon, papersize='Letter', $
    bits_per_pixel=8, $
    filename = fname, $
    button_names = ['Create PS File'])
  phast_setwindow, external_window_id
  
  state.ispsformon = 0
  if (canceled) then return
  if (psforminfo.filename EQ '') then return
  tvlct, rr, gg, bb, 8
  
  
  tmp_result = findfile(psforminfo.filename, count = nfiles)
  
  result = ''
  if (nfiles GT 0) then begin
    mesg = strarr(2)
    mesg[0] = 'Overwrite existing file:'
    tmp_string = $
      strmid(psforminfo.filename, $
      strpos(psforminfo.filename, state.delimiter, /reverse_search) + 1)
    mesg[1] = strcompress(tmp_string + '?', /remove_all)
    result =  dialog_message(mesg, $
      /default_no, $
      dialog_parent = state.base_id, $
      /question)
  endif
  
  if (strupcase(result) EQ 'NO') then return
  
  widget_control, /hourglass
  
  screen_device = !d.name
  
  ; In 8-bit mode, the screen color table will have fewer than 256
  ; colors.  Stretch out the existing color table to 256 colors for the
  ; postscript plot.
  
  set_plot, 'ps'
  
  device, _extra = psforminfo
  
  tvlct, rr, gg, bb, 8, /get
  
  rn = congrid(rr, 248)
  gn = congrid(gg, 248)
  bn = congrid(bb, 248)
  
  tvlct, temporary(rn), temporary(gn), temporary(bn), 8
  
  ; Make a full-resolution version of the display image, accounting for
  ; scalable pixels in the postscript output
  
  newdisplay = bytarr(xsize, ysize)
  
  startpos = abs(round(state.offset) < 0)
  
  view_min = (0 > view_min < (state.image_size - 1))
  view_max = (0 > view_max < (state.image_size - 1))
  
  dimage = bytscl(scaled_image[view_min[0]:view_max[0], $
    view_min[1]:view_max[1]], $
    top = 247, min=8, max=(!d.table_size-1)) + 8
    
    
  newdisplay[startpos[0], startpos[1]] = temporary(dimage)
  
  ; if there's blank space around the image border, keep it black
  
  tv, newdisplay
  phast_plotall
  
  
  if (state.frame EQ 1) then begin    ; put frame around image
    plot, [0], [0], /nodata, position=[0,0,1,1], $
      xrange=[0,1], yrange=[0,1], xstyle=5, ystyle=5, /noerase
    boxx = [0,0,1,1,0,0]
    boxy = [0,1,1,0,0,1]
    oplot, boxx, boxy, color=0, thick=state.framethick
  endif
  
  tvlct, temporary(rr), temporary(gg), temporary(bb), 8
  
  
  device, /close
  set_plot, screen_device
end

;----------------------------------------------------------------------

pro aaab_phast_system

;for compilation purposes only

end
