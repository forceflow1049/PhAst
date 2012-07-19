;----------------------------------------------------------------------

pro phastarrow, x1, y1, x2, y2, _extra = options

  ; Routine to read in arrow overplot options, store in a heap
  ; variable structure, and overplot the arrow

  common phast_pdata
  common phast_state
  
  if (not(xregistered('phast', /noshow))) then begin
    print, 'You need to start PHAST first!'
    return
  endif
  
  if (N_params() LT 4) then begin
    print, 'Too few parameters for PHASTARROW'
    return
  endif
  
  if (n_elements(options) EQ 0) then options = {color: 'red'}
  
  if (nplot LT maxplot) then begin
    nplot = nplot + 1
    
    ;  convert color names to index numbers, and set default=red
    c = where(tag_names(options) EQ 'COLOR', count)
    if (count EQ 0) then options = create_struct(options, 'color', 'red')
    options.color = phast_icolor(options.color)
    
    pstruct = {type: 'arrow',   $       ; type of plot
      x1: x1,             $     ; x1 coordinate
      y1: y1,             $     ; y1 coordinate
      x2: x2,             $     ; x2 coordinate
      y2: y2,             $     ; y2 coordinate
      options: options  $     ; plot keyword options
      }
      
    plot_ptr[nplot] = ptr_new(pstruct)
    
    phast_plotwindow
    phast_plot1arrow, nplot
    
  endif else begin
    print, 'Too many calls to PHASTPLOT.'
  endelse
end

;-------------------------------------------------------------------
      
pro phastclear
      
; displays a small blank image, useful for clearing memory if phast is
; displaying a huge image.
      
  phast, fltarr(10,10)
end

;---------------------------------------------------------------------

pro phastcontour, z, x, y, _extra = options

  ; Routine to read in contour plot data and options, store in a heap
  ; variable structure, and overplot the contours.  Data to be contoured
  ; need not be the same dataset displayed in the phast window, but it
  ; should have the same x and y dimensions in order to align the
  ; overplot correctly.

  common phast_pdata
  common phast_state
  
  if (not(xregistered('phast', /noshow))) then begin
    print, 'You need to start PHAST first!'
    return
  endif
  
  if (N_params() LT 1) then begin
    print, 'Too few parameters for PHASTCONTOUR.'
    return
  endif
  
  if (n_params() EQ 1 OR n_params() EQ 2) then begin
    x = 0
    y = 0
  endif
  
  if (n_elements(options) EQ 0) then options = {c_color: 'red'}
  
  if (nplot LT maxplot) then begin
    nplot = nplot + 1
    
    ;  convert color names to index numbers, and set default=red
    c = where(tag_names(options) EQ 'C_COLOR', count)
    if (count EQ 0) then options = create_struct(options, 'c_color', 'red')
    options.c_color = phast_icolor(options.c_color)
    
    pstruct = {type: 'contour',  $     ; type of plot
      z: z,             $     ; z values
      x: x,             $     ; x coordinate
      y: y,             $     ; y coordinate
      options: options  $     ; plot keyword options
      }
      
    plot_ptr[nplot] = ptr_new(pstruct)
    
    phast_plotwindow
    phast_plot1contour, nplot
    
  endif else begin
    print, 'Too many calls to PHASTCONTOUR.'
  endelse
end

;----------------------------------------------------------------------

pro phasterase, nerase, norefresh = norefresh

  ; Routine to erase line plots from PHASTPLOT, text from PHASTXYOUTS, and
  ; contours from PHASTCONTOUR.

  common phast_pdata
    
  if (n_params() LT 1) then begin
    nerase = nplot
  endif else begin
    if (nerase GT nplot) then nerase = nplot
  endelse
  
  for iplot = nplot - nerase + 1, nplot do begin
    ptr_free, plot_ptr[iplot]
    plot_ptr[iplot] = ptr_new()
  endfor
  
  nplot = nplot - nerase
  
  if (NOT keyword_set(norefresh)) then phast_refresh
end

;----------------------------------------------------------------------

pro phastplot, x, y, _extra = options

  ; Routine to read in line plot data and options, store in a heap
  ; variable structure, and plot the line plot

  common phast_pdata
  common phast_state
 
  if (not(xregistered('phast', /noshow))) then begin
    print, 'You need to start PHAST first!'
    return
  endif
  
  if (N_params() LT 1) then begin
    print, 'Too few parameters for PHASTPLOT.'
    return
  endif
  
  if (n_elements(options) EQ 0) then options = {color: 'red'}
  
  if (nplot LT maxplot) then begin
    nplot = nplot + 1
    
    ;  convert color names to index numbers, and set default=red
    c = where(tag_names(options) EQ 'COLOR', count)
    if (count EQ 0) then options = create_struct(options, 'color', 'red')
    options.color = phast_icolor(options.color)
    
    pstruct = {type: 'points',   $     ; points
      x: x,             $     ; x coordinate
      y: y,             $     ; y coordinate
      options: options  $     ; plot keyword options
      }
      
    plot_ptr[nplot] = ptr_new(pstruct)
    
    phast_plotwindow
    phast_plot1plot, nplot
    
  endif else begin
    print, 'Too many calls to PHASTPLOT.'
  endelse
end

;----------------------------------------------------------------------

pro phastxyouts, x, y, text, _extra = options

  ; Routine to read in text overplot string and options, store in a heap
  ; variable structure, and overplot the text

  common phast_pdata
  common phast_state
  
  if (not(xregistered('phast', /noshow))) then begin
    print, 'You need to start PHAST first!'
    return
  endif
  
  if (N_params() LT 3) then begin
    print, 'Too few parameters for PHASTXYOUTS'
    return
  endif
  
  if (n_elements(options) EQ 0) then options = {color: 'red'}
  
  if (nplot LT maxplot) then begin
    nplot = nplot + 1
    
    ;  convert color names to index numbers, and set default=red
    c = where(tag_names(options) EQ 'COLOR', count)
    if (count EQ 0) then options = create_struct(options, 'color', 'red')
    options.color = phast_icolor(options.color)
    
    ;  set default font to 1
    c = where(tag_names(options) EQ 'FONT', count)
    if (count EQ 0) then options = create_struct(options, 'font', 1)
    
    pstruct = {type: 'text',   $       ; type of plot
      x: x,             $     ; x coordinate
      y: y,             $     ; y coordinate
      text: text,       $     ; text to plot
      options: options  $     ; plot keyword options
      }
      
    plot_ptr[nplot] = ptr_new(pstruct)
    
    phast_plotwindow
    phast_plot1text, nplot
    
  endif else begin
    print, 'Too many calls to PHASTPLOT.'
  endelse
end

;-------------------------------------------------------------------

pro phast_animate
      
  ;legacy code for animation.  I don't think this is used anymore

  common phast_state
  common phast_images
  
  remember_main = main_image    ;remember current image to redraw at end
  
  duration = state.animate_duration
  for j=0,duration do begin
     for i=0,state.num_images-1 do begin
        wait,state.animate_speed
        main_image = image_archive[i]->get_image()
        phast_displayall
     endfor
  endfor
  main_image = remember_main
  phast_displayall
end

;----------------------------------------------------------------------

pro phast_arcbar, hdr, arclen, LABEL = label, SIZE = size, THICK = thick, $
    DATA =data, COLOR = color, POSITION = position, $
    NORMAL = normal, SECONDS=SECONDS
    
  ; This is a copy of the IDL Astronomy User's Library routine 'arcbar',
  ; abbreviated for phast and modified to work with zoomed images.  For
  ; the revision history of the original arcbar routine, look at
  ; arcbar.pro in the pro/astro subdirectory of the IDL Astronomy User's
  ; Library.
  
  ; Modifications for phast:
  ; Modified to work with zoomed PHAST images, AJB Jan. 2000
  ; Moved text label upwards a bit for better results, AJB Jan. 2000

  common phast_state
  
  On_error,2                      ;Return to caller
  
  extast, hdr, bastr, noparams    ;extract astrom params in deg.
  
  if N_params() LT 2 then arclen = 1 ;default size = 1 arcmin
  
  if not keyword_set( SIZE ) then size = 1.0
  if not keyword_set( THICK ) then thick = !P.THICK
  if not keyword_set( COLOR ) then color = !P.COLOR
  
  a = bastr.crval[0]
  d = bastr.crval[1]
  if keyword_set(seconds) then factor = 3600.0d else factor = 60.0
  d1 = d + (1/factor)             ;compute x,y of crval + 1 arcmin
  
  proj = strmid(bastr.ctype[0],5,3)
  
  case proj of
    'GSS': gsssadxy, bastr, [a,a], [d,d1], x, y
    else:  ad2xy, [a,a], [d,d1], bastr, x, y
  endcase
  
  dmin = sqrt( (x[1]-x[0])^2 + (y[1]-y[0])^2 ) ;det. size in pixels of 1 arcmin
  
  if (!D.FLAGS AND 1) EQ 1 then begin ;Device have scalable pixels?
    if !X.s[1] NE 0 then begin
      dmin = convert_coord( dmin, 0, /DATA, /TO_DEVICE) - $
        convert_coord(    0, 0, /DATA, /TO_DEVICE) ;Fixed Apr 97
      dmin = dmin[0]
    endif else dmin = dmin/sxpar(hdr, 'NAXIS1' ) ;Fixed Oct. 96
  endif else  dmin = dmin * state.zoom_factor    ; added by AJB Jan. '00
  
  dmini2 = round(dmin * arclen)
  
  if keyword_set(NORMAL) then begin
    posn = convert_coord(position,/NORMAL, /TO_DEVICE)
    xi = posn[0] & yi = posn[1]
  endif else if keyword_set(DATA) then begin
    posn = convert_coord(position,/DATA, /TO_DEVICE)
    xi = posn[0] & yi = posn[1]
  endif else begin
    xi = position[0]   & yi = position[1]
  endelse
  
  
  xf = xi + dmini2
  dmini3 = dmini2/10       ;Height of vertical end bars = total length/10.
  
  plots,[xi,xf],[yi,yi], COLOR=color, /DEV, THICK=thick
  plots,[xf,xf],[ yi+dmini3, yi-dmini3 ], COLOR=color, /DEV, THICK=thick
  plots,[xi,xi],[ yi+dmini3, yi-dmini3 ], COLOR=color, /DEV, THICK=thick
  
  if not keyword_set(Seconds) then begin
    if (!D.NAME EQ 'PS') and (!P.FONT EQ 0) then $ ;Postscript Font?
      arcsym='!9'+string(162B)+'!X' else arcsym = "'"
  endif else begin
    if (!D.NAME EQ 'PS') and (!P.FONT EQ 0) then $ ;Postscript Font?
      arcsym = '!9'+string(178B)+'!X' else arcsym = "''"
  endelse
  if not keyword_set( LABEL) then begin
    if (arclen LT 1) then arcstr = string(arclen,format='(f4.2)') $
    else arcstr = string(arclen)
    label = strtrim(arcstr,2) + arcsym
  endif
  
  ; AJB modified this to move the numerical label upward a bit: 5/8/2000
  xyouts,(xi+xf)/2, (yi+(dmini2/10)), label, SIZE = size, COLOR=color,$
    /DEV, alignment=.5, CHARTHICK=thick
    
  return
end
    
;------------------------------------------------------------------

pro phast_autoscale

  ; Routine to auto-scale the image.

  common phast_state
  common phast_images
  
  widget_control, /hourglass
  
  state.min_value = state.skymode - (2.0*state.skysig) > state.image_min
  if (state.scaling LE 1) then begin
    case state.scaling of
      0: highval = 2.0
      1: highval = 4.0
    endcase
    state.max_value = state.skymode + (highval*stddev(main_image)) $
      < state.image_max
  endif else begin
    state.max_value = state.image_max
  endelse
  
  if (finite(state.min_value) EQ 0) then state.min_value = state.image_min
  if (finite(state.max_value) EQ 0) then state.max_value = state.image_max
  
  if (state.min_value GE state.max_value) then begin
    state.min_value = state.min_value - 1
    state.max_value = state.max_value + 1
  endif
  
  state.asinh_beta = state.skysig
  
  phast_set_minmax
end

;--------------------------------------------------------------------
pro phast_base_image

  ;routine to display the starup image again

  common phast_state
  common phast_images
  
  ;gridsize = 512
  gridsize=state.draw_window_size[0]
  ;    centerpix = 256
  centerpix = round(state.draw_window_size[0]/2)
  x = ((findgen(gridsize) # replicate(1, gridsize)) - centerpix + 0.001)*0.05
  y = ((replicate(1, gridsize) # findgen(gridsize)) - centerpix + 0.001)*0.05
  main_image = abs((sin(x*x*y)/(sqrt(x^2 + y^2))) * $
    (sin(x*y*y)/(sqrt(x^2 + y^2))))
  startup_image = main_image
  state.min_value = 0.0
  state.max_value = 1.0
  stretch = 1
  autoscale = 0
  imagename = ''
  newimage = 1                    ; flag for startup image
  phast_setheader, ''
  ;state.title_extras = 'firstimage'
  
  phast_getstats
  phast_autoscale
  phast_displayall
end

;-------------------------------------------------------------------

pro phast_colorbar
      
  ; Routine to tv the colorbar at the bottom of the phast window
      
  common phast_state
        
  phast_setwindow, state.colorbar_window_id
  
  xsize=250
  
  b = congrid( findgen(state.ncolors), xsize) + 8
  c = replicate(1, state.colorbar_height)
  a = b # c
  
  tv, a
  
  phast_resetwindow
end

;--------------------------------------------------------------------

pro phast_colplot, ps=ps, fullrange=fullrange, newcoord=newcoord

  common phast_state
  common phast_images
  
  if (keyword_set(ps)) then begin
    thick = 3
    color = 0
  endif else begin
    thick = 1
    color = 7
  endelse
  
  if (keyword_set(newcoord)) then state.plot_coord = state.coord
  
  if (not (keyword_set(ps))) then begin
    newplot = 0
    if (not (xregistered('phast_lineplot', /noshow))) then begin
      phast_lineplot_init
      newplot = 1
    endif
    
    widget_control, state.histbutton_base_id, map=0
    widget_control, state.holdrange_button_id, sensitive=1
    
    widget_control, state.lineplot_xmin_id, get_value=xmin
    widget_control, state.lineplot_xmax_id, get_value=xmax
    widget_control, state.lineplot_ymin_id, get_value=ymin
    widget_control, state.lineplot_ymax_id, get_value=ymax
    
    if (newplot EQ 1 OR state.plot_type NE 'colplot' OR $
      keyword_set(fullrange) OR $
      (state.holdrange_value EQ 0 AND keyword_set(newcoord))) then begin
      xmin = 0.0
      xmax = state.image_size[1]
      ymin = min(main_image[state.plot_coord[0],*])
      ymax = max(main_image[state.plot_coord[0],*])
    endif
    
    widget_control, state.lineplot_xmin_id, set_value=xmin
    widget_control, state.lineplot_xmax_id, set_value=xmax
    widget_control, state.lineplot_ymin_id, set_value=ymin
    widget_control, state.lineplot_ymax_id, set_value=ymax
    
    state.lineplot_xmin = xmin
    state.lineplot_xmax = xmax
    state.lineplot_ymin = ymin
    state.lineplot_ymax = ymax
    
    state.plot_type = 'colplot'
    phast_setwindow, state.lineplot_window_id
    erase
    
  endif
  
  
  plot, main_image[state.plot_coord[0], *], $
    xst = 3, yst = 3, psym = 10, $
    title = strcompress('Plot of column ' + $
    string(state.plot_coord[0])), $
    xtitle = 'Row', $
    ytitle = 'Pixel Value', $
    color = color, xmargin=[15,3], $
    xran = [state.lineplot_xmin, state.lineplot_xmax], $
    yran = [state.lineplot_ymin, state.lineplot_ymax], $
    thick = thick, xthick = thick, ythick = thick, charthick = thick, $
    charsize = state.plotcharsize
    
    
  if (not (keyword_set(ps))) then begin
    widget_control, state.lineplot_base_id, /clear_events
    phast_resetwindow
  endif
end

;--------------------------------------------------------------------

pro phast_contourplot, ps=ps, fullrange=fullrange, newcoord=newcoord

  common phast_state
  common phast_images

  if (keyword_set(ps)) then begin
     thick = 3
     color = 0
  endif else begin
     thick = 1
     color = 7
  endelse
  
  if (not (keyword_set(ps))) then begin
  
    newplot = 0
    if (not (xregistered('phast_lineplot', /noshow))) then begin
      phast_lineplot_init
      newplot = 1
    endif
    
    widget_control, state.histbutton_base_id, map=0
    widget_control, state.holdrange_button_id, sensitive=0
    
    if (keyword_set(newcoord)) then begin
    
      plotsize = $
        fix(min([50, state.image_size[0]/2., state.image_size[1]/2.]))
      center = plotsize > state.coord < (state.image_size[0:1] - plotsize)
      
      contour_image =  main_image[center[0]-plotsize:center[0]+plotsize-1, $
        center[1]-plotsize:center[1]+plotsize-1]
        
      state.lineplot_xmin = center[0]-plotsize
      state.lineplot_xmax = center[0]+plotsize-1
      state.lineplot_ymin = center[1]-plotsize
      state.lineplot_ymax = center[1]+plotsize-1
      
      state.plot_coord = state.coord
      
      widget_control,state.lineplot_xmin_id, $
        set_value=state.lineplot_xmin
      widget_control,state.lineplot_xmax_id, $
        set_value=state.lineplot_xmax
      widget_control,state.lineplot_ymin_id, $
        set_value=state.lineplot_ymin
      widget_control,state.lineplot_ymax_id, $
        set_value=state.lineplot_ymax
    endif
    
    if (keyword_set(fullrange)) then begin
      widget_control, state.lineplot_xmin_id, set_value = 0
      widget_control, state.lineplot_xmax_id, $
        set_value = state.image_size[0]-1
      widget_control, state.lineplot_ymin_id, set_value = 0
      widget_control, state.lineplot_ymax_id, $
        set_value = state.image_size[1]-1
    endif
    
    state.plot_type = 'contourplot'
    phast_setwindow, state.lineplot_window_id
    erase
    
    ; now get plot coords from the widget box
    widget_control,state.lineplot_xmin_id, get_value=xmin
    widget_control,state.lineplot_xmax_id, get_value=xmax
    widget_control,state.lineplot_ymin_id, get_value=ymin
    widget_control,state.lineplot_ymax_id, get_value=ymax
    
    state.lineplot_xmin = xmin
    state.lineplot_xmax = xmax
    state.lineplot_ymin = ymin
    state.lineplot_ymax = ymax
  endif
  
  contour_image =  main_image[state.lineplot_xmin:state.lineplot_xmax, $
    state.lineplot_ymin:state.lineplot_ymax]
    
  if (state.scaling EQ 1) then begin
    contour_image = alog10(contour_image)
    logflag = 'Log'
  endif else begin
    logflag = ''
  endelse
  
  plottitle =  $
    strcompress(logflag + $
    ' Contour plot of ' + $
    strcompress('['+string(round(state.lineplot_xmin))+ $
    ':'+string(round(state.lineplot_xmax))+ $
    ','+string(round(state.lineplot_ymin))+ $
    ':'+string(round(state.lineplot_ymax))+ $
    ']', /remove_all))
    
  xdim = state.lineplot_xmax - state.lineplot_xmin + 1
  ydim = state.lineplot_ymax - state.lineplot_ymin + 1
  
  xran = lindgen(xdim) + state.lineplot_xmin
  yran = lindgen(ydim) + state.lineplot_ymin
  
  contour, temporary(contour_image), xst=3, yst=3, $
    xran, yran, $
    nlevels = 10, $
    /follow, $
    title = plottitle, $
    xtitle = 'X', ytitle = 'Y', color = color, $
    thick = thick, xthick = thick, ythick = thick, charthick = thick, $
    charsize = state.plotcharsize
    
  if (not (keyword_set(ps))) then begin
    widget_control, state.lineplot_base_id, /clear_events
    phast_resetwindow
  endif
end

;--------------------------------------------------------------------

pro phast_depthplot, ps=ps, fullrange=fullrange, newcoord=newcoord

  common phast_state
  common phast_images
  
  if (state.cube NE 1) then return
  
  if (keyword_set(ps)) then begin
    thick = 3
    color = 0
  endif else begin
    thick = 1
    color = 7
  endelse
  
  if (ptr_valid(state.head_ptr)) then head = *(state.head_ptr) $
  else head = strarr(1)
  
  cd = float(sxpar(head,'CD1_1'));, /silent))
  if (cd EQ 0.0) then $
    cd = float(sxpar(head,'CDELT1'));, /silent))
  crpix = float(sxpar(head,'CRPIX1'));, /silent)) - 1
  crval = float(sxpar(head,'CRVAL1'));, /silent))
  shifta = float(sxpar(head, 'SHIFTA1'));, /silent))
  
  wave = (findgen(state.nslices) * cd) + crval
  if (max(wave) EQ min(wave)) then begin
    wave = findgen(state.nslices)
  endif
  
  x1 = min([state.vector_coord1[0],state.vector_coord2[0]])
  x2 = max([state.vector_coord1[0],state.vector_coord2[0]])
  y1 = min([state.vector_coord1[1],state.vector_coord2[1]])
  y2 = max([state.vector_coord1[1],state.vector_coord2[1]])
  
  pixval = main_image_cube[x1:x2, y1:y2, *]
  
  ; collapse to a 1d spectrum:
  pixval = total(total(pixval,1),1)
  
  if (not (keyword_set(ps))) then begin
  
    newplot = 0
    if (not (xregistered('phast_lineplot', /noshow))) then begin
      phast_lineplot_init
      newplot = 1
    endif
    
    widget_control, state.histbutton_base_id, map=0
    widget_control, state.holdrange_button_id, sensitive=1
    
    widget_control, state.lineplot_xmin_id, get_value=xmin
    widget_control, state.lineplot_xmax_id, get_value=xmax
    widget_control, state.lineplot_ymin_id, get_value=ymin
    widget_control, state.lineplot_ymax_id, get_value=ymax
    
    if (newplot EQ 1 OR state.plot_type NE 'depthplot' OR $
      keyword_set(fullrange) OR $
      (state.holdrange_value EQ 0 AND keyword_set(newcoord))) then begin
      xmin = min(wave)
      xmax = max(wave)
      ymin = min(pixval)
      ymax = max(pixval)
      
    endif
 
    widget_control, state.lineplot_xmin_id, set_value=xmin
    widget_control, state.lineplot_xmax_id, set_value=xmax
    widget_control, state.lineplot_ymin_id, set_value=ymin
    widget_control, state.lineplot_ymax_id, set_value=ymax
    
    state.lineplot_xmin = xmin
    state.lineplot_xmax = xmax
    state.lineplot_ymin = ymin
    state.lineplot_ymax = ymax
    
    state.plot_type = 'depthplot'
    phast_setwindow, state.lineplot_window_id
    erase
    
  endif
  
  
  plottitle = strcompress('Depth plot [' + $
    string(x1) + ':' + string(x2) + ',' + $
    string(y1) + ':' + string(y2) + ']')
    
  if (state.cunit NE '') then begin
    xunit = state.cunit
    xunittype = 'Wavelength'
  endif else begin
    xunit = 'pixel'
    xunittype = 'Slice'
  endelse
  
  plot, wave, pixval, $
    xst = 3, yst = 3, psym = 10, $
    title = plottitle, $
    xtitle = strcompress(xunittype + ' (' + xunit + ')') , $
    ytitle = 'Flux', $
    color = color, xmargin=[15,3], $
    xran = [state.lineplot_xmin, state.lineplot_xmax], $
    yran = [state.lineplot_ymin, state.lineplot_ymax], $
    thick = thick, xthick = thick, ythick = thick, charthick = thick, $
    charsize = state.plotcharsize
    
  if (not (keyword_set(ps))) then begin
    widget_control, state.lineplot_base_id, /clear_events
    phast_resetwindow
  endif
end

;-----------------------------------------------------------------------

pro phast_displayall

  ; Call the routines to scale the image, make the pan image, and
  ; re-display everything.  Use this if the scaling changes (log/
  ; linear/ histeq), or if min or max are changed, or if a new image is
  ; passed to phast.  If the display image has just been moved around or
  ; zoomed without a change in scaling, then just call phast_refresh
  ; rather than this routine.

  phast_scaleimage
  phast_makepan
  phast_refresh
end

;-----------------------------------------------------------------------

pro phast_displaymain

  ; Display the main image and overplots

  common phast_state
  common phast_images
  offset = [0,0]
  if state.align_toggle eq 1 then offset = state.zoon_factor*phast_get_image_offset()
  phast_setwindow, state.draw_window_id
  
  if state.align_toggle eq 1 then tv, display_image,offset[0],offset[1]
  if state.align_toggle ne 1 then tv, display_image
  phast_resetwindow
end

;----------------------------------------------------------------------

pro phast_display_stars

  ;routine to overlay catalog star postions/names based on WCS pointing info

  common phast_state
  common phast_images
  common phast_pdata
  
  if ptr_valid(state.astr_ptr) then begin
    phast_getFieldEpoch, a, d,radius, X, obsDate
    catalog_name = state.overlay_catList(state.overlay_catalog)
    star_catalog = phast_get_stars(a,d,radius,AsOf=obsDate,catalog_name=catalog_name)
    
    band    = 'R'    &  mag   = star_catalog.RMag ;choose R mag
    clrband = 'B-R'  &  color = star_catalog.BMag - star_catalog.RMag
    ra      = star_catalog.RA
    dec     = star_catalog.Dec
    name    = star_catalog.starID
    limit   = state.mag_limit

    ad2xy,ra,dec,*(state.astr_ptr),x,y
    select  = where(mag lt limit and x gt 0 and x lt state.image_size[0] and y gt 0 and y lt state.image_size[1])

    if select[0] ge 0 then begin
       phasterase
       colorcode = 'blue'
       circlesize = 7   &  circletext = strtrim(string(circlesize))
       fontsize = 1.75  &    fonttext = strtrim(string(fontsize))
       offset = circlesize + 7 
       
       x1 = x[select]
       y1 = y[select]
       for i = 0, n_elements(x1)-1 do begin
           if nplot lt maxplot then begin
              nplot++
              region_str = 'circle('+strtrim(string(x1[i]),2)+', '+strtrim(string(y1[i]),2)+', ' $
                         + circletext + ') # color=' + colorcode
              options = {color:colorcode,thick:fonttext}
              options.color = phast_icolor(options.color)
              pstruct = {type:'region',reg_array:[region_str],options:options}
              plot_ptr[nplot] =ptr_new(pstruct)
              phast_plotwindow
              phast_plot1region,nplot
           endif
       endfor
        
       case  state.display_char of
         0 : ; do nothing
         1 : begin & labelVal = name[select]
                     phastxyouts,x1+offset,y1,labelVal,charsize=fontsize,color=colorcode
             end
         2 : begin & if catalog_name eq 'Landolt' then fmttext='(F6.3,1H )' $
                                                  else fmttext='(F5.2,1H )'
                     labelVal = string(mag[select],format=fmttext) + band
                     blank = where(~finite(mag[select]), count)
                     if count gt 0 then labelVal[blank] = ' '
                     phastxyouts,x1+offset,y1,labelVal,charsize=fontsize,color=colorcode
             end
         3 : begin & if catalog_name eq 'Landolt' then fmttext='(F7.3,1H )' $
                                                  else fmttext='(F6.2,1H )'
                     labelVal = string(abs(color[select]),format=fmttext) + clrband
                     colorsgn = replicate('-',n_elements(select))
                     colorneg = where(color[select] gt 0.0, count)
                     if count gt 0 then colorsgn[colorneg] = '+'
                     labelVal = strtrim(colorsgn,2) + strtrim(labelVal,2)
                     blank = where(~finite(color[select]), count)
                     if count gt 0 then labelVal[blank] = ' '
                     phastxyouts,x1+offset,y1,labelVal,charsize=fontsize,color=colorcode
             end
       else: ; do nothing        
     endcase
 
     widget_control,state.search_msg_id,set_value='Overlay successful!'
       
    endif else widget_control,state.search_msg_id,set_value='No stars to overlay!' 
  endif else widget_control,state.search_msg_id,set_value='WCS data not present'
end

;----------------------------------------------------------------------

pro phast_drawbox, norefresh=norefresh

  ; routine to draw the box on the pan window, given the current center
  ; of the display image.

  common phast_state
  common phast_images
  
  phast_setwindow, state.pan_window_id
  
  view_min = round(state.centerpix - $
    (0.5 * state.draw_window_size / state.zoom_factor))
  view_max = round(view_min + state.draw_window_size / state.zoom_factor) - 1
  
  ; Create the vectors which contain the box coordinates
  
  box_x = float((([view_min[0], $
    view_max[0], $
    view_max[0], $
    view_min[0], $
    view_min[0]]) * state.pan_scale) + state.pan_offset[0])
    
  box_y = float((([view_min[1], $
    view_min[1], $
    view_max[1], $
    view_max[1], $
    view_min[1]]) * state.pan_scale) + state.pan_offset[1])
    
  ; set limits on box to make sure all sides always appear
  box_x = 0 > box_x < (state.pan_window_size - 1)
  box_y = 0 > box_y < (state.pan_window_size - 1)
  
  ; Redraw the pan image and overplot the box
  if (not(keyword_set(norefresh))) then $
    device, copy=[0,0,state.pan_window_size, state.pan_window_size, 0, 0, $
    state.pan_pixmap]
    
  plots, box_x, box_y, /device, color = state.box_color, psym=0
  
  phast_resetwindow
end

;-----------------------------------------------------------------------

pro phast_fullview
  
  ; set the zoom level so that the full image fits in the display window
  
  common phast_state

  sizeratio = float(state.image_size) / float(state.draw_window_size)
  maxratio = (max(sizeratio))
  
  state.zoom_level = floor((alog(maxratio) / alog(2.0)) * (-1))
  state.zoom_factor = (2.0)^(state.zoom_level)
  
  ; recenter
  state.centerpix = round(state.image_size / 2.)
  
  phast_refresh
  
  phast_resetwindow
end

;--------------------------------------------------------------------

pro phast_getct, tablenum

  ; Read in a pre-defined color table, and invert if necessary.

  common phast_color
  common phast_state
  common phast_images
    
  phast_setwindow, state.draw_window_id
  loadct, tablenum, /silent, bottom=8
  tvlct, r, g, b, 8, /get
  
  phast_initcolors
  
  r = r[0:state.ncolors-2]
  g = g[0:state.ncolors-2]
  b = b[0:state.ncolors-2]
  
  if (state.invert_colormap EQ 1) then begin
    r = reverse(r)
    g = reverse(g)
    b = reverse(b)
  endif
  
  r_vector = r
  g_vector = g
  b_vector = b
  
  phast_stretchct
  
  ; need this to re-set to external color table
  phast_resetwindow
  
  if (state.bitdepth EQ 24 AND (n_elements(pan_image) GT 10) ) then $
    phast_refresh
end

;--------------------------------------------------------------------

pro phast_getdisplay

  ; make the display image from the scaled image by applying the zoom
  ; factor and matching to the size of the draw window, and display the
  ; image.

  common phast_state
  common phast_images
  
  ;widget_control, /hourglass
  
  display_image = bytarr(state.draw_window_size[0], state.draw_window_size[1])
  
  view_min = round(state.centerpix - $
    (0.5 * state.draw_window_size / state.zoom_factor))
  view_max = round(view_min + state.draw_window_size / state.zoom_factor)
  
  view_min = (0 > view_min < (state.image_size - 1))
  view_max = (0 > view_max < (state.image_size - 1))
  
  newsize = round( (view_max - view_min + 1) * state.zoom_factor) > 1
  startpos = abs( round(state.offset * state.zoom_factor) < 0)
  
  ; Use interp & center keywords to congrid for zoomfactor < 1 :
  ; improvement contributed by N. Cunningham, added 4/14/06
  if (state.zoom_factor LT 1.0) then begin
    tmp_image = congrid(scaled_image[view_min[0]:view_max[0], $
      view_min[1]:view_max[1]], $
      newsize[0], newsize[1], /center, /interp)
  endif else begin
    tmp_image = congrid(scaled_image[view_min[0]:view_max[0], $
      view_min[1]:view_max[1]], $
      newsize[0], newsize[1])
  endelse
  
  
  xmax = newsize[0] < (state.draw_window_size[0] - startpos[0])
  ymax = newsize[1] < (state.draw_window_size[1] - startpos[1])
  
  display_image[startpos[0], startpos[1]] = tmp_image[0:xmax-1, 0:ymax-1]
  tmp_image = 0
end

;--------------------------------------------------------------------

pro phast_gettrack

  ; Create the image to display in the track window that tracks
  ; cursor movements.  Also update the coordinate display and the
  ; (x,y) and pixel value.

  common phast_state
  common phast_images
  
  ;get image offset
  offset = [0,0]
  if state.align_toggle eq 1 then offset = phast_get_image_offset()
  if not finite(offset[0])  then begin
    result = dialog_message('Crash: offset distance larger than image size.  Are these images from the same region of sky?', /error,/center)
  endif
  ; Get x and y for center of track window, correcting for offset
  zcenter = (0 > state.coord < state.image_size) - offset
  
  
  track = bytarr(11,11)
  boxsize=5
  xmin = (0 > (zcenter[0] - boxsize)) < (state.image_size[0] - 1)    ; patch, morgan to review
  xmax =  0 > (zcenter[0] + boxsize)  < (state.image_size[0] - 1)
  ymin = (0 > (zcenter[1] - boxsize)) < (state.image_size[1] - 1)
  ymax =  0 > (zcenter[1] + boxsize)  < (state.image_size[1] - 1)
  
  startx = abs( (zcenter[0] - boxsize) < 0 )
  starty = abs( (zcenter[1] - boxsize) < 0 )
  
  track[startx,starty] = scaled_image[xmin:xmax,ymin:ymax]
  track_image = rebin(track, $
    state.track_window_size, state.track_window_size, $
    /sample)
    
  phast_setwindow, state.track_window_id
  tv, track_image
  
  ; Overplot an X on the central pixel in the track window, to show the
  ; current mouse position
  
  ; Changed central x to be green always
  plots, [0.46, 0.54], [0.46, 0.54], /normal, color = state.box_color, psym=0
  plots, [0.46, 0.54], [0.54, 0.46], /normal, color = state.box_color, psym=0
  
  ; update location bar with x, y, and pixel value
  loc_string = $
    string(state.coord[0], $
    state.coord[1], $
    main_image[state.coord[0], $
    state.coord[1]], $
    format = '("(",i5,",",i5,") ",g12.5)')
    
  widget_control, state.location_bar_id, set_value = loc_string
  
  ; Update coordinate display.
  
  if (state.wcstype EQ 'angle') then begin
    xy2ad, state.coord[0], state.coord[1], *(state.astr_ptr), lon, lat
    wcsstring = phast_wcsstring(lon, lat, (*state.astr_ptr).ctype,  $
      state.equinox, state.display_coord_sys, $
      state.display_equinox, state.display_base60)
      
    widget_control, state.wcs_bar_id, set_value = wcsstring
    
  endif
  
  if (state.wcstype EQ 'lambda') then begin
    wavestring = phast_wavestring()
    widget_control, state.wcs_bar_id, set_value = wavestring
  endif
  
  phast_resetwindow
end

;------------------------------------------------------------------

pro phast_getwindow

  ; get currently active window id

  common phast_state
  common phast_color
  
  if (!d.name NE 'PS') then begin
    state.active_window_id = !d.window
  endif
  
  ; use for debugging
  ; print, 'phast_getwindow', state.active_window_id
  
  
  ; get current external window color table
  tvlct, user_r, user_g, user_b, /get
  
end

;----------------------------------------------------------------------

pro phast_get_minmax, uvalue, newvalue

  ; Change the min and max state variables when user inputs new numbers
  ; in the text boxes.

  common phast_state
  
  case uvalue of
  
    'min_text': begin
      if (newvalue LT state.max_value) then begin
        state.min_value = newvalue
      endif
    end
    
    'max_text': begin
      if (newvalue GT state.min_value) then begin
        state.max_value = newvalue
      endif
    end
    
  endcase
  
  phast_set_minmax
end

;---------------------------------------------------------------------

pro phast_headinfo

  ; routine to display popup with header info

  common phast_state
  
  ; If there's no header, kill the headinfo window and exit this
  ; routine.
  if (not(ptr_valid(state.head_ptr))) then begin
    if (xregistered('phast_headinfo')) then begin
      widget_control, state.headinfo_base_id, /destroy
    endif
    
    phast_message, 'No header information available for this image!', $
      msgtype = 'error', /window
    return
  endif
  
  
  ; If there is header information but not headinfo window,
  ; create the headinfo window.
  if (not(xregistered('phast_headinfo', /noshow))) then begin
  
    headinfo_base = $
      widget_base(/base_align_right, $
      group_leader = state.base_id, $
      /column, $
      title = 'phast image header information', $
      uvalue = 'headinfo_base')
    state.headinfo_base_id = headinfo_base
    
    h = *(state.head_ptr)
    
    headinfo_text = widget_text(headinfo_base, $
      /scroll, $
      value = h, $
      xsize = 85, $
      ysize = 24)
      
    headinfo_done = widget_button(headinfo_base, $
      value = 'Done', $
      uvalue = 'headinfo_done')
      
    widget_control, headinfo_base, /realize
    xmanager, 'phast_headinfo', headinfo_base, /no_block
    
  endif
end

;---------------------------------------------------------------------

pro phast_headinfo_event, event

  ;event handler for header popup

  common phast_state
  
  widget_control, event.id, get_uvalue = uvalue
  
  case uvalue of
    'headinfo_done': widget_control, event.top, /destroy
    else:
  endcase
  
end

;----------------------------------------------------------------------

pro phast_histplot, ps=ps, fullrange=fullrange, newcoord=newcoord

  common phast_state
  common phast_images
   
  if (keyword_set(ps)) then begin
    thick = 3
    color = 0
  endif else begin
    thick = 1
    color = 7
  endelse
  
  if (not (keyword_set(ps))) then begin
  
    newplot = 0
    if (not (xregistered('phast_lineplot', /noshow))) then begin
      phast_lineplot_init
      newplot = 1
    endif
    
    widget_control, state.histbutton_base_id, map=1
    widget_control, state.holdrange_button_id, sensitive=0
    
    if (keyword_set(newcoord)) then begin
    
      state.plot_coord = state.coord
      plotsize_x = $
        fix(min([20, state.image_size[0]/2.]))
      plotsize_y = $
        fix(min([20, state.image_size[1]/2.]))
        
      ; Establish pixel boundaries to histogram
      x1 = (state.plot_coord[0]-plotsize_x) > 0.
      x2 = (state.plot_coord[0]+plotsize_x) < (state.image_size[0]-1)
      y1 = (state.plot_coord[1]-plotsize_y) > 0.
      y2 = (state.plot_coord[1]+plotsize_y) < (state.image_size[1]-1)
      
      widget_control, state.x1_pix_id, set_value=x1
      widget_control, state.x2_pix_id, set_value=x2
      widget_control, state.y1_pix_id, set_value=y1
      widget_control, state.y2_pix_id, set_value=y2
    endif
    
    state.plot_type = 'histplot'
    phast_setwindow, state.lineplot_window_id
    erase
  endif
  
  ; get histogram region
  widget_control, state.x1_pix_id, get_value=x1
  widget_control, state.x2_pix_id, get_value=x2
  widget_control, state.y1_pix_id, get_value=y1
  widget_control, state.y2_pix_id, get_value=y2
  hist_image = main_image[x1:x2, y1:y2]
  
  ; initialize the binsize if necessary
  if (state.binsize EQ 0 OR keyword_set(newcoord)) then begin
    nbins = 50.
    state.binsize = (float(max(hist_image)) - float(min(hist_image)) ) / nbins
    if (abs(state.binsize) GT 10) then $
      state.binsize = fix(state.binsize)
    widget_control, state.histplot_binsize_id, set_value=state.binsize
  endif
  
  ; Call plothist to create histogram arrays
  plothist, hist_image, xhist, yhist, bin=state.binsize, /NaN, /noplot
  
  ; Only initialize plot window and plot ranges to the min/max ranges
  ; when histplot window is not already present or plot window is present
  ; but last plot was not a histplot.  Otherwise, use the values
  ; currently in the min/max boxes
  
  if (keyword_set(newcoord) OR keyword_set(fullrange)) then begin
    state.lineplot_xmin = min(hist_image)
    state.lineplot_xmax = max(hist_image)
    state.lineplot_ymin = 0.
    state.lineplot_ymax = round(max(yhist) * 1.1)
    widget_control, state.lineplot_xmin_id, set_value = state.lineplot_xmin
    widget_control, state.lineplot_xmax_id, set_value = state.lineplot_xmax
    widget_control, state.lineplot_ymin_id, set_value = state.lineplot_ymin
    widget_control, state.lineplot_ymax_id, set_value = state.lineplot_ymax
  endif
  
  widget_control, state.histplot_binsize_id, get_value=binsize
  widget_control, state.lineplot_xmin_id, get_value=xmin
  widget_control, state.lineplot_xmax_id, get_value=xmax
  widget_control, state.lineplot_ymin_id, get_value=ymin
  widget_control, state.lineplot_ymax_id, get_value=ymax
  
  state.binsize = binsize
  state.lineplot_xmin = xmin
  state.lineplot_xmax = xmax
  state.lineplot_ymin = ymin
  state.lineplot_ymax = ymax
  
  plottitle = $
    strcompress('Histogram plot of ' + $
    strcompress('['+string(round(x1))+ $
    ':'+string(round(x2))+ $
    ','+string(round(y1))+ $
    ':'+string(round(y2))+ $
    ']', /remove_all))
    
  ;Plot histogram with proper ranges
  plothist, hist_image, xhist, yhist, bin=state.binsize, /NaN, $
    xtitle='Pixel Value', ytitle='Number', title=plottitle, $
    xran=[state.lineplot_xmin,state.lineplot_xmax], $
    yran=[state.lineplot_ymin,state.lineplot_ymax], $
    xstyle=1, ystyle=1, color=color, $
    thick = thick, xthick = thick, ythick = thick, charthick = thick, $
    charsize = state.plotcharsize
    
  if (not (keyword_set(ps))) then begin
    widget_control, state.lineplot_base_id, /clear_events
    phast_resetwindow
  endif
  
end

;----------------------------------------------------------------------

function phast_icolor, color

  ; Routine to reserve the bottom 8 colors of the color table
  ; for plot overlays and line plots.

  if (n_elements(color) EQ 0) then return, 1
  
  ncolor = N_elements(color)
  
  ; If COLOR is a string or array of strings, then convert color names
  ; to integer values
  if (size(color,/tname) EQ 'STRING') then begin ; Test if COLOR is a string
  
    ; Detemine the default color for the current device
    if (!d.name EQ 'X') then defcolor = 7 $ ; white for X-windows
    else defcolor = 0           ; black otherwise
    
    icolor = 0 * (color EQ 'black') $
      + 1 * (color EQ 'red') $
      + 2 * (color EQ 'green') $
      + 3 * (color EQ 'blue') $
      + 4 * (color EQ 'cyan') $
      + 5 * (color EQ 'magenta') $
      + 6 * (color EQ 'yellow') $
      + 7 * (color EQ 'white') $
      + defcolor * (color EQ 'default')
      
  endif else begin
    icolor = long(color)
  endelse
  
  return, icolor
end

;------------------------------------------------------------------

pro phast_initcolors

  ; Load a simple color table with the basic 8 colors in the lowest
  ; 8 entries of the color table.  Also set top color to white.

  common phast_state
  
  rtiny   = [0, 1, 0, 0, 0, 1, 1, 1]
  gtiny = [0, 0, 1, 0, 1, 0, 1, 1]
  btiny  = [0, 0, 0, 1, 1, 1, 0, 1]
  tvlct, 255*rtiny, 255*gtiny, 255*btiny
  
  tvlct, [255],[255],[255], !d.table_size-1
end

;----------------------------------------------------------------------

pro phast_invert, ichange

  ; Routine to do image axis-inversion (X,Y,X&Y)

  common phast_state
  common phast_images
  
  case ichange of
    'x': begin
      if ptr_valid(state.astr_ptr) then begin
        hreverse, main_image, *(state.head_ptr), $
          main_image, *(state.head_ptr), 1, /silent
        head = *(state.head_ptr)
        phast_setheader, head
      endif else begin
        main_image = reverse(main_image,1)
      endelse
    end
    
    'y': begin
      if ptr_valid(state.astr_ptr) then begin
        hreverse, main_image, *(state.head_ptr), $
          main_image, *(state.head_ptr), 2, /silent
        head = *(state.head_ptr)
        phast_setheader, head
      endif else begin
        main_image = reverse(main_image,2)
      endelse
    end
    
    
    'xy': begin
    
      if ptr_valid(state.astr_ptr) then begin
        hreverse, main_image, *(state.head_ptr), $
          main_image, *(state.head_ptr), 1, /silent
        hreverse, main_image, *(state.head_ptr), $
          main_image, *(state.head_ptr), 2, /silent
        head = *(state.head_ptr)
        phast_setheader, head
      endif else begin
        main_image = reverse(main_image,1)
        main_image = reverse(main_image,2)
      endelse
    end
    
    else:  print,  'problem in phast_invert!'
  endcase
  
  phast_getstats, /align, /noerase
  
  ;Redisplay inverted image with current zoom, update pan, and refresh image
  phast_displayall
  
  ;make sure that the image arrays are updated for line/column plots, etc.
  phast_resetwindow
end

;----------------------------------------------------------------------

pro phast_lineplot_event, event

  common phast_state
  common phast_images
  
  widget_control, event.id, get_uvalue = uvalue
  
  case uvalue of
    'lineplot_done': begin
      widget_control, event.top, /destroy
      state.plot_type = ''
    end
    
    'lineplot_base': begin      ; Resize event
      state.lineplot_size = [event.x, event.y]- state.lineplot_pad
      widget_control, state.lineplot_widget_id, $
        xsize = (state.lineplot_size[0] > state.lineplot_min_size[0]), $
        ysize = (state.lineplot_size[1] > state.lineplot_min_size[1])
        
      case state.plot_type of
        'rowplot': phast_rowplot
        'colplot': phast_colplot
        'vectorplot': phast_vectorplot
        'gaussplot': phast_gaussfit
        'histplot': phast_histplot
        'surfplot': phast_surfplot
        'contourplot': phast_contourplot
        'specplot': phast_specplot
        'depthplot': phast_depthplot
      endcase
    end
    
    'lineplot_holdrange': begin
      if (state.holdrange_value eq 1) then state.holdrange_value = 0 $
      else state.holdrange_value = 1
    end
    
    'lineplot_fullrange': begin
      case state.plot_type of
        'rowplot': phast_rowplot, /fullrange
        'colplot': phast_colplot, /fullrange
        'vectorplot': phast_vectorplot, /fullrange
        'gaussplot': phast_gaussfit, /fullrange
        'histplot': phast_histplot, /fullrange
        'surfplot': phast_surfplot, /fullrange
        'contourplot': phast_contourplot, /fullrange
        'specplot': phast_specplot, /fullrange
        'depthplot': phast_depthplot, /fullrange
        else:
      endcase
    end
    
    'lineplot_ps': begin
    
      if (state.ispsformon EQ 1) then return
      fname = strcompress(state.current_dir + 'phast_plot.ps', /remove_all)
      state.ispsformon = 1
      lpforminfo = cmps_form(cancel = canceled, create = create, $
        parent = state.lineplot_base_id, $
        /preserve_aspect, $
        /color, $
        /nocommon, papersize='Letter', $
        filename = fname, $
        button_names = ['Create PS File'])
        
      state.ispsformon = 0
      if (canceled) then return
      if (lpforminfo.filename EQ '') then return
      
      tmp_result = findfile(lpforminfo.filename, count = nfiles)
      
      result = ''
      if (nfiles GT 0) then begin
        mesg = strarr(2)
        mesg[0] = 'Overwrite existing file:'
        tmp_string = strmid(lpforminfo.filename, strpos(lpforminfo.filename, $
          '/') + 1)
        mesg[1] = strcompress(tmp_string + '?', /remove_all)
        result =  dialog_message(mesg, $
          /default_no, $
          dialog_parent = state.base_id, $
          /question)
      endif
      
      if (strupcase(result) EQ 'NO') then return
      
      widget_control, /hourglass
      
      screen_device = !d.name
      set_plot, 'ps'
      device, _extra = lpforminfo
      
      case (state.plot_type) of
        'rowplot': phast_rowplot, /ps
        'colplot': phast_colplot, /ps
        'vectorplot': phast_vectorplot, /ps
        'gaussplot': phast_gaussfit, /ps
        'histplot': phast_histplot, /ps
        'surfplot': phast_surfplot, /ps
        'contourplot': phast_contourplot, /ps
        'specplot': phast_specplot, /ps
        'depthplot': phast_depthplot, /ps
        else:
      endcase
      
      device, /close
      set_plot, screen_device
      
    end
    
    'lineplot_charsize': begin
      widget_control, state.lineplot_charsize_id, get_value = newcharsize
      newcharsize = newcharsize > 0.2
      state.plotcharsize = newcharsize
      widget_control, state.lineplot_charsize_id, set_value = newcharsize
      case state.plot_type of
        'rowplot': phast_rowplot
        'colplot': phast_colplot
        'vectorplot': phast_vectorplot
        'gaussplot': phast_gaussfit
        'histplot': phast_histplot
        'surfplot': phast_surfplot
        'contourplot': phast_contourplot
        'specplot': phast_specplot
        'depthplot': phast_depthplot
      endcase
      
    end
    
    'lineplot_newrange': begin
    
      widget_control, state.lineplot_xmin_id, get_value = xmin
      widget_control, state.lineplot_xmax_id, get_value = xmax
      widget_control, state.lineplot_ymin_id, get_value = ymin
      widget_control, state.lineplot_ymax_id, get_value = ymax
      
      ; check plot ranges for validity
      if (state.plot_type EQ 'surfplot' OR $
        state.plot_type EQ 'contourplot') then begin
        
        xmin = fix(round(0 > xmin < (state.image_size[0] - 2)))
        xmax = fix(round(1 > xmax < (state.image_size[0] - 1)))
        ymin = fix(round(0 > ymin < (state.image_size[1] - 2)))
        ymax = fix(round(1 > ymax < (state.image_size[1] - 1)))
        
        if (event.id EQ state.lineplot_xmin_id) then $
          if (xmin GT xmax) then xmin = xmax-1
        if (event.id EQ state.lineplot_xmax_id) then $
          if (xmax LT xmin) then xmax = xmin+1
        if (event.id EQ state.lineplot_ymin_id) then $
          if (ymin GT ymax) then ymin = ymax-1
        if (event.id EQ state.lineplot_xmax_id) then $
          if (ymax LT ymin) then ymax = ymin+1
          
      endif
      
      state.lineplot_xmin = xmin
      state.lineplot_xmax = xmax
      state.lineplot_ymin = ymin
      state.lineplot_ymax = ymax
      
      widget_control, state.lineplot_xmin_id, set_value = xmin
      widget_control, state.lineplot_xmax_id, set_value = xmax
      widget_control, state.lineplot_ymin_id, set_value = ymin
      widget_control, state.lineplot_ymax_id, set_value = ymax
      
      case state.plot_type of
        'rowplot': phast_rowplot
        'colplot': phast_colplot
        'vectorplot': phast_vectorplot
        'gaussplot': phast_gaussfit
        'surfplot': phast_surfplot
        'contourplot': phast_contourplot
        'specplot': phast_specplot
        'depthplot': phast_depthplot
        
        'histplot': begin
        
          ; check requested plot ranges and bin size for validity
        
          if (event.id EQ state.x1_pix_id) then begin
            widget_control, state.x1_pix_id, get_value=x1
            widget_control, state.x2_pix_id, get_value=x2
            if (x1 GT x2) then x1 = x2 - 1
            if (x1 LT 0) then x1 = 0
            widget_control, state.x1_pix_id, set_value=x1
          endif
          
          if (event.id EQ state.x2_pix_id) then begin
            widget_control, state.x1_pix_id, get_value=x1
            widget_control, state.x2_pix_id, get_value=x2
            if (x1 GT x2) then x2 = x1 + 1
            if (x2 GT state.image_size[0]-1) then $
              x2 = state.image_size[0] - 1
            widget_control, state.x2_pix_id, set_value=x2
          endif
          
          if (event.id EQ state.y1_pix_id) then begin
            widget_control, state.y1_pix_id, get_value=y1
            widget_control, state.y2_pix_id, get_value=y2
            if (y1 GT y2) then y1 = y2 - 1
            if (y1 LT 0) then y1 = 0
            widget_control, state.y1_pix_id, set_value=y1
          endif
          
          if (event.id EQ state.y2_pix_id) then begin
            widget_control, state.y1_pix_id, get_value=y1
            widget_control, state.y2_pix_id, get_value=y2
            if (y1 GT y2) then y2 = y1 + 1
            if (y2 GT state.image_size[1]-1) then $
              y2 = state.image_size[1]-1
            widget_control, state.y2_pix_id, set_value=y2
          endif
          
          if (event.id EQ state.histplot_binsize_id) then begin
            b = event.value
            if (event.value LE 0) then begin
              phast_message, 'Bin size must be >0.', $
                msgtype='error', /window
              widget_control, state.histplot_binsize_id, $
                set_value = 1.0
            endif
          endif
          
          phast_histplot
        end
        
        else:
      endcase
    end
    
    else:
  endcase
end

;---------------------------------------------------------------------

pro phast_lineplot_init

  ; This routine creates the window for line plots

  common phast_state
  
  state.lineplot_base_id = $
    widget_base(group_leader = state.base_id, $
    /row, $
    /base_align_right, $
    title = 'phast plot', $
    /tlb_size_events, $
    uvalue = 'lineplot_base')
    
  state.lineplot_widget_id = $
    widget_draw(state.lineplot_base_id, $
    frame = 0, $
    scr_xsize = state.lineplot_size[0], $
    scr_ysize = state.lineplot_size[1], $
    uvalue = 'lineplot_window')
    
  lbutton_base = $
    widget_base(state.lineplot_base_id, $
    /base_align_bottom, $
    /column, frame=2)
    
  state.histbutton_base_id = $
    widget_base(lbutton_base, $
    /base_align_bottom, $
    /column, map=1)
    
  state.x1_pix_id = $
    cw_field(state.histbutton_base_id, $
    /return_events, $
    /floating, $
    title = 'X1:', $
    uvalue = 'lineplot_newrange', $
    xsize = 12)
    
  state.x2_pix_id = $
    cw_field(state.histbutton_base_id, $
    /return_events, $
    /floating, $
    title = 'X2:', $
    uvalue = 'lineplot_newrange', $
    xsize = 12)
    
  state.y1_pix_id = $
    cw_field(state.histbutton_base_id, $
    /return_events, $
    /floating, $
    title = 'Y1:', $
    uvalue = 'lineplot_newrange', $
    xsize = 12)
    
  state.y2_pix_id = $
    cw_field(state.histbutton_base_id, $
    /return_events, $
    /floating, $
    title = 'Y2:', $
    uvalue = 'lineplot_newrange', $
    xsize = 12)
    
  state.histplot_binsize_id = $
    cw_field(state.histbutton_base_id, $
    /return_events, $
    /floating, $
    title = 'Bin:', $
    uvalue = 'lineplot_newrange', $
    xsize = 12)
    
  state.lineplot_xmin_id = $
    cw_field(lbutton_base, $
    /return_events, $
    /floating, $
    title = 'XMin:', $
    uvalue = 'lineplot_newrange', $
    xsize = 12)
    
  state.lineplot_xmax_id = $
    cw_field(lbutton_base, $
    /return_events, $
    /floating, $
    title = 'XMax:', $
    uvalue = 'lineplot_newrange', $
    xsize = 12)
    
  state.lineplot_ymin_id = $
    cw_field(lbutton_base, $
    /return_events, $
    /floating, $
    title = 'YMin:', $
    uvalue = 'lineplot_newrange', $
    xsize = 12)
    
  state.lineplot_ymax_id = $
    cw_field(lbutton_base, $
    /return_events, $
    /floating, $
    title = 'YMax:', $
    uvalue = 'lineplot_newrange', $
    xsize = 12)
    
  state.lineplot_charsize_id = $
    cw_field(lbutton_base, $
    /return_events, $
    /floating, $
    title = 'Charsize:', $
    uvalue = 'lineplot_charsize', $
    value = state.plotcharsize, $
    xsize = 7)
    
  state.holdrange_base_id = $
    widget_base(lbutton_base, $
    row = 1, $
    /nonexclusive, frame=1)
    
  state.holdrange_button_id = $
    widget_button(state.holdrange_base_id, $
    value = 'Hold Ranges', $
    uvalue = 'lineplot_holdrange')
    
  lineplot_fullrange = $
    widget_button(lbutton_base, $
    value = 'FullRange', $
    uvalue = 'lineplot_fullrange')
    
  lineplot_ps = $
    widget_button(lbutton_base, $
    value = 'Create PS', $
    uvalue = 'lineplot_ps')
    
  lineplot_done = $
    widget_button(lbutton_base, $
    value = 'Done', $
    uvalue = 'lineplot_done')
    
  widget_control, state.lineplot_base_id, /realize
  widget_control, state.holdrange_button_id, set_button=state.holdrange_value
  
  widget_control, state.lineplot_widget_id, get_value = tmp_value
  state.lineplot_window_id = tmp_value
  
  lbuttgeom = widget_info(lbutton_base, /geometry)
  state.lineplot_min_size[1] = lbuttgeom.ysize
  
  basegeom = widget_info(state.lineplot_base_id, /geometry)
  drawgeom = widget_info(state.lineplot_widget_id, /geometry)
  
  state.lineplot_pad[0] = basegeom.xsize - drawgeom.xsize
  state.lineplot_pad[1] = basegeom.ysize - drawgeom.ysize
  
  xmanager, 'phast_lineplot', state.lineplot_base_id, /no_block
  
  phast_resetwindow
end

;--------------------------------------------------------------------

pro phast_makect, tablename

  ; Define new color tables here.  Invert if necessary.

  common phast_state
  common phast_color
  
  case tablename of
    'PHAST Special': begin
    
      w = findgen(256)
      
      sigma = 60.
      center = 140
      r = 255.* exp(-1.*(w - center)^2 / (2.*sigma^2))
      r[center:255] = 255.
      
      sigma = 60
      center = 255
      g = 255. * exp(-1.*(w - center)^2 / (2.*sigma^2))
      
      sigma = 60
      center = 40
      b = 255. * exp(-1.*(w - center)^2 / (2.*sigma^2))
      
      b[0:center-1] = findgen(center)^0.5 / center^0.5 * 255.
      center = 30
      b[(255-center+1):255] = findgen(center)^2 / center^2 *255.
      
    end
    
    'Velocity2': begin
      r = fltarr(256)
      r[0:127] = 128. - findgen(128)
      r[128:255] = 255
      
      g = fltarr(256)
      g[0:127] = findgen(128)^1.5
      g[128:255] = reverse(g[0:127])
      g = g / max(g) * 255.
      
      b = 255. - findgen(256)
      b[128:255] = findgen(128)^3 / 128.^2
      
    end
    
    'Velocity1': begin
      w = findgen(256)
      
      sigma = 25.
      center = 170
      r = 255.* exp(-1.*(w - center)^2 / (2.*sigma^2))
      r[center:255] = 255.
      sigma = 30.
      center = 0.
      r = r + 100.* exp(-1.*(w - center)^2 / (2.*sigma^2))
      
      sigma = 30.
      center1 = 100.
      g = fltarr(256)
      g[0:center1] = 255. * exp(-1.*(w[0:center1] - center1)^2 / (2.*sigma^2))
      sigma = 60.
      center2 = 140.
      g[center1:center2] = 255.
      g[center2:255] = $
        255. * exp(-1.*(w[center2:255] - center2)^2 / (2.*sigma^2))
        
      sigma = 40.
      center = 70
      b = 255.* exp(-1.*(w - center)^2 / (2.*sigma^2))
      b[0:center] = 255.
      
    end
    
    ; add more color table definitions here as needed...
    else: return
    
  endcase
  
  r = congrid(r, state.ncolors)
  g = congrid(g, state.ncolors)
  b = congrid(b, state.ncolors)
  
  
  if (state.invert_colormap EQ 1) then begin
    r = reverse(r)
    g = reverse(g)
    b = reverse(b)
  endif
  
  r_vector = temporary(r)
  g_vector = temporary(g)
  b_vector = temporary(b)
  
  phast_stretchct
  
  ; need this to preserve external color map
  phast_resetwindow
  
  if (state.bitdepth EQ 24) then phast_refresh
end

;----------------------------------------------------------------------

pro phast_makepan

  ; Make the 'pan' image that shows a miniature version of the full image.

  common phast_state
  common phast_images
  
  sizeratio = state.image_size[1] / state.image_size[0]
  
  if (sizeratio GE 1) then begin
    state.pan_scale = float(state.pan_window_size) / float(state.image_size[1])
  endif else begin
    state.pan_scale = float(state.pan_window_size) / float(state.image_size[0])
  endelse
  
  tmp_image = $
    scaled_image[0:state.image_size[0]-1, 0:state.image_size[1]-1]
    
  if (max(state.image_size) LT state.pan_window_size) then $
    i = 0 else i = 1
    
  pan_image = $
    congrid(tmp_image, round(state.pan_scale * state.image_size[0])>1, $
    round(state.pan_scale * state.image_size[1])>1, $
    /center, interp=i)
    
  state.pan_offset[0] = round((state.pan_window_size - (size(pan_image))[1]) / 2)
  state.pan_offset[1] = round((state.pan_window_size - (size(pan_image))[2]) / 2)
end

;--------------------------------------------------------------------

pro phast_oplotcontour

  ; widget front end for phastcontour

  common phast_state
  common phast_images
  
  minvalstring = strcompress('0, float, ' + string(state.min_value) + $
    ', label_left=MinValue: , width=15 ')
  maxvalstring = strcompress('0, float, ' + string(state.max_value) + $
    ', label_left=MaxValue: , width=15')
    
  formdesc = ['0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Color:, set_value=0 ', $
    ;            '0, float, 1.0, label_left=Charsize: ', $
    ;            '0, integer, 1, label_left=Charthick: ', $
    '0, droplist, solid|dotted|dashed|dashdot|dashdotdotdot|longdash, label_left=Linestyle: , set_value=0', $
    '0, integer, 1, label_left=LineThickness: ', $
    minvalstring, $
    maxvalstring, $
    '0, integer, 6, label_left=NLevels: ', $
    '1, base, , row,', $
    '0, button, Cancel, quit', $
    '0, button, DrawContour, quit']
    
  cform = cw_form(formdesc, /column, $
    title = 'phast text label')
    
    
  if (cform.tag8 EQ 1) then begin
    ; switch red and black indices
    case cform.tag0 of
      0: labelcolor = 1
      1: labelcolor = 0
      else: labelcolor = cform.tag0
    endcase
    
    phastcontour, main_image, c_color = labelcolor, $
      ;      c_charsize = cform.tag1, c_charthick = cform.tag2, $
      c_linestyle = cform.tag1, $
      c_thick = cform.tag2, $
      min_value = cform.tag3, max_value = cform.tag4, $,
    nlevels = cform.tag5
  endif
end

;----------------------------------------------------------------------

pro phast_pantrack, event

  ; routine to track the view box in the pan window during cursor motion

  common phast_state
  
  ; get the new box coords and draw the new box
  tmp_event = [event.x, event.y]
  
  newpos = state.pan_offset > tmp_event < $
    (state.pan_offset + (state.image_size * state.pan_scale))
    
  state.centerpix = round( (newpos - state.pan_offset ) / state.pan_scale)
  
  phast_drawbox
  phast_getoffset
end

;-------------------------------------------------------------------

pro phast_pixtable

  ; Create a table widget that will show a 5x5 array of pixel values
  ; around the current cursor position

  if (not(xregistered('phast_pixtable', /noshow))) then begin
  
    common phast_state
    common phast_images
    
    state.pixtable_base_id = $
      widget_base(/base_align_right, $
      group_leader = state.base_id, $
      /column, $
      title = 'phast pixel table')
      
    state.pixtable_tbl_id = $
      widget_table(state.pixtable_base_id,   $
      value=[0,0], xsize=5, ysize=5, row_labels='', $
      column_labels='', alignment=2, /resizeable_columns, $
      column_widths = 3, units=2)
      
    pixtable_done = widget_button(state.pixtable_base_id, $
      value = 'Done', $
      uvalue = 'pixtable_done')
      
    widget_control, state.pixtable_base_id, /realize
    xmanager, 'phast_pixtable', state.pixtable_base_id, /no_block
    
  endif
end

;---------------------------------------------------------------------

pro phast_pixtable_event, event

  ;event handler for pixtable widget

  common phast_state
  
  widget_control, event.id, get_uvalue = uvalue
  
  case uvalue of
    'pixtable_done': widget_control, event.top, /destroy
    else:
  endcase
end

;--------------------------------------------------------------------

pro phast_pixtable_update
  
  ; routine to update pixtable as mouse moves

  common phast_state
  common phast_images
  
  zcenter = (0 > state.coord < state.image_size[0:1])
  
  ; Check and adjust the zcenter if the cursor is near the edges of the image
  
  if (zcenter[0] le 2) then zcenter[0] = 2
  if (zcenter[0] gt (state.image_size[0]-3)) then $
    zcenter[0] =  state.image_size[0] - 3
    
  if (zcenter[1] le 2) then zcenter[1] = 2
  if (zcenter[1] gt (state.image_size[1]-3)) then $
    zcenter[1] = state.image_size[1] - 3
    
  ;pix_values = dblarr(5,5)
  row_labels = strarr(5)
  column_labels = strarr(5)
  boxsize=2
  
  xmin = 0 > (zcenter[0] - boxsize)
  xmax = (zcenter[0] + boxsize) < (state.image_size[0] - 1)
  ymin = 0 > (zcenter[1] - boxsize)
  ymax = (zcenter[1] + boxsize) < (state.image_size[1] - 1)
  
  row_labels = [strcompress(string(ymax),/remove_all),   $
    strcompress(string(ymin+3),/remove_all), $
    strcompress(string(ymin+2),/remove_all), $
    strcompress(string(ymin+1),/remove_all), $
    strcompress(string(ymin),/remove_all)]
    
  column_labels = [strcompress(string(xmin),/remove_all),   $
    strcompress(string(xmin+1),/remove_all), $
    strcompress(string(xmin+2),/remove_all), $
    strcompress(string(xmin+3),/remove_all), $
    strcompress(string(xmax),/remove_all)]
    
  pix_values = main_image[xmin:xmax, ymin:ymax]
  pix_values = reverse(pix_values, 2, /overwrite)
  
  widget_control, state.pixtable_tbl_id, set_value = pix_values, $
    column_labels=column_labels, row_labels=row_labels
    
  ; highlight the current image cursor position in the table
  wx = where(long(column_labels) EQ state.coord[0], count)
  wy = where(long(row_labels) EQ state.coord[1], count)
  
  widget_control, state.pixtable_tbl_id, set_table_select = [wx,wy,wx,wy] 
end

;----------------------------------------------------------------------

pro phast_plot1arrow, iplot

 ; Plot a arrow overlay on the image

  common phast_pdata
  common phast_state
   
  phast_setwindow, state.draw_window_id
  
  widget_control, /hourglass
  
  arrow, (*(plot_ptr[iplot])).x1, (*(plot_ptr[iplot])).y1, $
    (*(plot_ptr[iplot])).x2, (*(plot_ptr[iplot])).y2, $
    _extra = (*(plot_ptr[iplot])).options, /data
    
  phast_resetwindow
  state.newrefresh=1
end

;---------------------------------------------------------------------

pro phast_plot1compass, iplot

  ; Uses idlastro routine arrows to plot compass arrows.

  common phast_pdata
  common phast_state
  
  phast_setwindow, state.draw_window_id
  
  widget_control, /hourglass
  
  arrows, *(state.head_ptr), $
    (*(plot_ptr[iplot])).x, $
    (*(plot_ptr[iplot])).y, $
    thick = (*(plot_ptr[iplot])).thick, $
    charsize = (*(plot_ptr[iplot])).charsize, $
    arrowlen = (*(plot_ptr[iplot])).arrowlen, $
    color = (*(plot_ptr[iplot])).color, $
    notvertex = (*(plot_ptr[iplot])).notvertex, $
    /data
    
  phast_resetwindow
  state.newrefresh=1
end

;----------------------------------------------------------------------

pro phast_plot1contour, iplot

  ; Overplot contours on the image

  common phast_pdata
  common phast_state
  
  phast_setwindow, state.draw_window_id
  widget_control, /hourglass
  
  xrange = !x.crange
  yrange = !y.crange
  
  ; The following allows for 2 conditions, depending upon whether X and Y
  ; are set
  
  dims = size( (*(plot_ptr[iplot])).z,/dim )
  
  if (size( (*(plot_ptr[iplot])).x,/N_elements ) EQ dims[0] $
    AND size( (*(plot_ptr[iplot])).y,/N_elements) EQ dims[1] ) then begin
    
    contour, (*(plot_ptr[iplot])).z, (*(plot_ptr[iplot])).x, $
      (*(plot_ptr[iplot])).y, $
      position=[0,0,1,1], xrange=xrange, yrange=yrange, $
      xstyle=5, ystyle=5, /noerase, $
      _extra = (*(plot_ptr[iplot])).options
      
  endif else begin
  
    contour, (*(plot_ptr[iplot])).z, $
      position=[0,0,1,1], xrange=xrange, yrange=yrange, $
      xstyle=5, ystyle=5, /noerase, $
      _extra = (*(plot_ptr[iplot])).options
      
  endelse
  
  phast_resetwindow
  state.newrefresh=1
end

;----------------------------------------------------------------------

pro phast_plot1ellipse, rmax, rmin, xc, yc, pos_ang, _extra = _extra

  ; This is a modified version of Wayne Landsman's tvellipse, changed so
  ; that it won't ask for interactive input under any circumstances.

  if N_params() LT 5 then pos_ang = 0. ;Default position angle
  
  npoints = 500                   ;Number of points to connect
  phi = 2*!pi*(findgen(npoints)/(npoints-1)) ;Divide circle into Npoints
  ang = pos_ang/!RADEG            ;Position angle in radians
  cosang = cos(ang)
  sinang = sin(ang)
  
  x =  rmax*cos(phi)              ;Parameterized equation of ellipse
  y =  rmin*sin(phi)
  
  xprime = xc + x*cosang - y*sinang ;Rotate to desired position angle
  yprime = yc + x*sinang + y*cosang
  
  plots, round(xprime), round(yprime), color=color, /device,  $
    _STRICT_Extra = _extra
end

;----------------------------------------------------------------------

pro phast_plot1plot, iplot

  ; Plot a point or line overplot on the image

  common phast_pdata
  common phast_state
  
  phast_setwindow, state.draw_window_id
  
  widget_control, /hourglass
  
  oplot, [(*(plot_ptr[iplot])).x], [(*(plot_ptr[iplot])).y], $
    _extra = (*(plot_ptr[iplot])).options
    
  phast_resetwindow
  state.newrefresh=1
end

;----------------------------------------------------------------------

pro phast_plot1region, iplot

  ; Plot a region overlay on the image

  common phast_pdata
  common phast_state
  
  phast_setwindow, state.draw_window_id
  
  widget_control, /hourglass
  
  reg_array = (*(plot_ptr[iplot])).reg_array
  n_reg = n_elements(reg_array)
  
  for i=0, n_reg-1 do begin
    open_parenth_pos = strpos(reg_array[i],'(')
    close_parenth_pos = strpos(reg_array[i],')')
    reg_type = strcompress(strmid(reg_array[i],0,open_parenth_pos),/remove_all)
    length = close_parenth_pos - open_parenth_pos
    coords_str = strcompress(strmid(reg_array[i], open_parenth_pos+1, $
      length-1),/remove_all)
    coords_arr = strsplit(coords_str,',',/extract)
    n_coords = n_elements(coords_arr)
    color_begin_pos = strpos(strlowcase(reg_array[i]), 'color')
    text_pos = strpos(strlowcase(reg_array[i]), 'text')
    
    if (color_begin_pos ne -1) then begin
      color_equal_pos = strpos(reg_array[i], '=', color_begin_pos)
    endif
    
    text_begin_pos = strpos(reg_array[i], '{')
    
    ; Text for region
    if (text_begin_pos ne -1) then begin
      text_end_pos = strpos(reg_array[i], '}')
      text_len = (text_end_pos-1) - (text_begin_pos)
      text_str = strmid(reg_array[i], text_begin_pos+1, text_len)
      color_str = ''
      
      ; Color & Text for region
      if (color_begin_pos ne -1) then begin
        ; Compare color_begin_pos to text_begin_pos to tell which is first
      
        case (color_begin_pos lt text_begin_pos) of
          0: begin
            ;text before color
            color_str = $
              strcompress(strmid(reg_array[i], color_equal_pos+1, $
              strlen(reg_array[i])), /remove_all)
          end
          1: begin
            ;color before text
            len_color = (text_pos-1) - color_equal_pos
            color_str = $
              strcompress(strmid(reg_array[i], color_equal_pos+1, $
              len_color), /remove_all)
          end
          else:
        endcase
      endif
      
    endif else begin
    
      ; Color but no text for region
      if (color_begin_pos ne -1) then begin
        color_str = strcompress(strmid(reg_array[i], color_equal_pos+1, $
          strlen(reg_array[i])), /remove_all)
          
      ; Neither color nor text for region
      endif else begin
        color_str = ''
      endelse
      
      text_str = ''
      
    endelse
    
    index_j2000 = where(strlowcase(coords_arr) eq 'j2000')
    index_b1950 = where(strlowcase(coords_arr) eq 'b1950')
    index_galactic = where(strlowcase(coords_arr) eq 'galactic')
    index_ecliptic = where(strlowcase(coords_arr) eq 'ecliptic')
    
    index_coord_system = where(strlowcase(coords_arr) eq 'j2000') AND $
      where(strlowcase(coords_arr) eq 'b1950') AND $
      where(strlowcase(coords_arr) eq 'galactic') AND $
      where(strlowcase(coords_arr) eq 'ecliptic')
      
    index_coord_system = index_coord_system[0]
    
    if (index_coord_system ne -1) then begin
    
      ; Check that a WCS region is not overplotted on image with no WCS
      if (NOT ptr_valid(state.astr_ptr)) then begin
        phast_message, $
          'WCS Regions cannot be displayed on image without WCS information in header.', $
          msgtype='error', /window
        ; Erase pstruct that was formed for this region.
        phasterase, 1
        return
      endif
      
      case strlowcase(coords_arr[index_coord_system]) of
        'j2000': begin
          if (strlowcase(reg_type) ne 'line') then $
            coords_arr = phast_wcs2pix(coords_arr, coord_sys='j2000') $
          else $
            coords_arr = $
            phast_wcs2pix(coords_arr, coord_sys='j2000', /line)
        end
        'b1950': begin
          if (strlowcase(reg_type) ne 'line') then $
            coords_arr = phast_wcs2pix(coords_arr, coord_sys='b1950') $
          else $
            coords_arr = $
            phast_wcs2pix(coords_arr, coord_sys='b1950', /line)
        end
        'galactic': begin
          if (strlowcase(reg_type) ne 'line') then $
            coords_arr = phast_wcs2pix(coords_arr, coord_sys='galactic') $
          else $
            coords_arr = $
            phast_wcs2pix(coords_arr, coord_sys='galactic', /line)
        end
        'ecliptic': begin
          if (strlowcase(reg_type) ne 'line') then $
            coords_arr = phast_wcs2pix(coords_arr, coord_sys='ecliptic') $
          else $
            coords_arr = $
            phast_wcs2pix(coords_arr, coord_sys='ecliptic', /line)
        end
        else:
      endcase
    endif else begin
    
      if (strpos(coords_arr[0], ':')) ne -1 then begin
      
        ; Check that a WCS region is not overplotted on image with no WCS
        if (NOT ptr_valid(state.astr_ptr)) then begin
          phast_message, $
            'WCS Regions cannot be displayed on image without WCS', $
            msgtype='error', /window
          return
        endif
        
        if (strlowcase(reg_type) ne 'line') then $
          coords_arr = phast_wcs2pix(coords_arr,coord_sys='current') $
        else $
          coords_arr = phast_wcs2pix(coords_arr,coord_sys='current', /line)
      endif else begin
        if (strlowcase(reg_type) ne 'line') then $
          coords_arr = phast_wcs2pix(coords_arr,coord_sys='pixel') $
        else $
          coords_arr = phast_wcs2pix(coords_arr,coord_sys='pixel', /line)
      endelse
      
    endelse
    
    CASE strlowcase(color_str) OF
    
      'red':     (*(plot_ptr[iplot])).options.color = '1'
      'black':   (*(plot_ptr[iplot])).options.color = '0'
      'green':   (*(plot_ptr[iplot])).options.color = '2'
      'blue':    (*(plot_ptr[iplot])).options.color = '3'
      'cyan':    (*(plot_ptr[iplot])).options.color = '4'
      'magenta': (*(plot_ptr[iplot])).options.color = '5'
      'yellow':  (*(plot_ptr[iplot])).options.color = '6'
      'white':   (*(plot_ptr[iplot])).options.color = '7'
      ELSE:      (*(plot_ptr[iplot])).options.color = '1'
      
    ENDCASE
    
    phast_setwindow,state.draw_window_id
    phast_plotwindow
    
    case strlowcase(reg_type) of
    
      'circle': begin
        xcenter = (float(coords_arr[0]) - state.offset[0] + 0.5) * $
          state.zoom_factor
        ycenter = (float(coords_arr[1]) - state.offset[1] + 0.5) * $
          state.zoom_factor
          
        radius = float(coords_arr[2]) * state.zoom_factor
        
        ; added by AJB: rescale for postscript output for each plot type
        if (!d.name EQ 'PS') then begin
          xcenter = xcenter / state.draw_window_size[0] * !d.x_size
          ycenter = ycenter / state.draw_window_size[1] * !d.y_size
          radius = radius / state.draw_window_size[0] * !d.x_size
        endif
        
        tvcircle, radius, xcenter, ycenter, $
          _extra = (*(plot_ptr[iplot])).options
          
        if (text_str ne '') then xyouts, xcenter, ycenter, text_str, $
          alignment=0.5, _extra = (*(plot_ptr[iplot])).options, /device
      end
      'box': begin
        angle = 0           ; initialize angle to 0
        if (n_coords ge 4) then begin
          xcenter = (float(coords_arr[0]) - state.offset[0] + 0.5) * $
            state.zoom_factor
          ycenter = (float(coords_arr[1]) - state.offset[1] + 0.5) * $
            state.zoom_factor
          xwidth = float(coords_arr[2]) * state.zoom_factor
          ywidth = float(coords_arr[3]) * state.zoom_factor
          if (n_coords ge 5) then angle = float(coords_arr[4])
        endif
        width_arr = [xwidth,ywidth]
        
        if (!d.name EQ 'PS') then begin
          xcenter = xcenter / state.draw_window_size[0] * !d.x_size
          ycenter = ycenter / state.draw_window_size[1] * !d.y_size
          width_arr = width_arr / state.draw_window_size[0] * !d.x_size
        endif
        
        ; angle = -angle because tvbox rotates clockwise
        tvbox, width_arr, xcenter, ycenter, angle=-angle, $
          _extra = (*(plot_ptr[iplot])).options
          
        if (text_str ne '') then xyouts, xcenter, ycenter, text_str, $
          alignment=0.5, _extra = (*(plot_ptr[iplot])).options, /device
      end
      
      'ellipse': begin
        angle = 0           ; initialize angle to 0
        if (n_coords ge 4) then begin
          xcenter = (float(coords_arr[0]) - state.offset[0] + 0.5) * $
            state.zoom_factor
          ycenter = (float(coords_arr[1]) - state.offset[1] + 0.5) * $
            state.zoom_factor
          xradius = float(coords_arr[2]) * state.zoom_factor
          yradius = float(coords_arr[3]) * state.zoom_factor
          if (n_coords ge 5) then angle = float(coords_arr[4])
        endif
        
        ; Correct angle for default orientation used by tvellipse
        angle=angle+180.
        
        if (!d.name EQ 'PS') then begin
          xcenter = xcenter / state.draw_window_size[0] * !d.x_size
          ycenter = ycenter / state.draw_window_size[1] * !d.y_size
          xradius = xradius / state.draw_window_size[0] * !d.x_size
          yradius = yradius / state.draw_window_size[1] * !d.y_size
        endif
        
        phast_plot1ellipse, xradius, yradius, xcenter, ycenter, angle, $
          _extra = (*(plot_ptr[iplot])).options
          
        if (text_str ne '') then xyouts, xcenter, ycenter, text_str, $
          alignment=0.5, _extra = (*(plot_ptr[iplot])).options, /device
      end
      'polygon': begin
        n_vert = n_elements(coords_arr) / 2
        xpoints = fltarr(n_vert)
        ypoints = fltarr(n_vert)
        for vert_i = 0, n_vert - 1 do begin
          xpoints[vert_i] = coords_arr[vert_i*2]
          ypoints[vert_i] = coords_arr[vert_i*2+1]
        endfor
        
        if (xpoints[0] ne xpoints[n_vert-1] OR $
          ypoints[0] ne ypoints[n_vert-1]) then begin
          xpoints1 = fltarr(n_vert+1)
          ypoints1 = fltarr(n_vert+1)
          xpoints1[0:n_vert-1] = xpoints
          ypoints1[0:n_vert-1] = ypoints
          xpoints1[n_vert] = xpoints[0]
          ypoints1[n_vert] = ypoints[0]
          xpoints = xpoints1
          ypoints = ypoints1
        endif
        
        xcenter = total(xpoints) / n_elements(xpoints)
        ycenter = total(ypoints) / n_elements(ypoints)
        
        plots, xpoints, ypoints,  $
          _extra = (*(plot_ptr[iplot])).options
          
        if (text_str ne '') then xyouts, xcenter, ycenter, text_str, $
          alignment=0.5, _extra = (*(plot_ptr[iplot])).options, /device
      end
      'line': begin
        x1 = (float(coords_arr[0]) - state.offset[0] + 0.5) * $
          state.zoom_factor
        y1 = (float(coords_arr[1]) - state.offset[1] + 0.5) * $
          state.zoom_factor
        x2 = (float(coords_arr[2]) - state.offset[0] + 0.5) * $
          state.zoom_factor
        y2 = (float(coords_arr[3]) - state.offset[1] + 0.5) * $
          state.zoom_factor
          
        xpoints = [x1,x2]
        ypoints = [y1,y2]
        xcenter = total(xpoints) / n_elements(xpoints)
        ycenter = total(ypoints) / n_elements(ypoints)
        
        if (!d.name EQ 'PS') then begin
          xpoints = xpoints / state.draw_window_size[0] * !d.x_size
          ypoints = ypoints / state.draw_window_size[1] * !d.y_size
        endif
        
        plots, xpoints, ypoints, /device, $
          _extra = (*(plot_ptr[iplot])).options
          
        if (text_str ne '') then xyouts, xcenter, ycenter, text_str, $
          alignment=0.5, _extra = (*(plot_ptr[iplot])).options, /device
      end
      
      ; these are all the region types we have defined so far.
      else: begin
      
      end
      
    endcase
    
  endfor
  
  phast_resetwindow
  state.newrefresh=1
end

;---------------------------------------------------------------------

pro phast_plot1scalebar, iplot

  ; uses modified version of idlastro routine arcbar to plot a scalebar

  common phast_pdata
  common phast_state
  
  phast_setwindow, state.draw_window_id
  widget_control, /hourglass
  
  ; routine arcbar doesn't recognize color=0, because it uses
  ; keyword_set to check the color.  So we need to set !p.color = 0
  ; to get black if the user wants color=0
  
  !p.color = 0
  
  phast_arcbar, *(state.head_ptr), $
    (*(plot_ptr[iplot])).arclen, $
    position = (*(plot_ptr[iplot])).position, $
    thick = (*(plot_ptr[iplot])).thick, $
    size = (*(plot_ptr[iplot])).size, $
    color = (*(plot_ptr[iplot])).color, $
    seconds = (*(plot_ptr[iplot])).seconds, $
    /data
    
  phast_resetwindow
  state.newrefresh=1
end

;----------------------------------------------------------------------

pro phast_plot1text, iplot
 
  ; Plot a text overlay on the image

  common phast_pdata
  common phast_state
   
  phast_setwindow, state.draw_window_id
  
  widget_control, /hourglass
  
  xyouts, (*(plot_ptr[iplot])).x, (*(plot_ptr[iplot])).y, $
    (*(plot_ptr[iplot])).text, _extra = (*(plot_ptr[iplot])).options
    
  phast_resetwindow
  state.newrefresh=1
end

;---------------------------------------------------------------------

pro phast_plotall

  ; Routine to overplot all line, text, and contour plots

  common phast_state
  common phast_pdata
  
  if (nplot EQ 0) then return
  
  phast_plotwindow
  
  for iplot = 1, nplot do begin
    case (*(plot_ptr[iplot])).type of
      'points'  : phast_plot1plot, iplot
      'text'    : phast_plot1text, iplot
      'arrow'   : phast_plot1arrow, iplot
      'contour' : phast_plot1contour, iplot
      'compass' : phast_plot1compass, iplot
      'scalebar': phast_plot1scalebar, iplot
      'region'  : phast_plot1region, iplot
    else      : print, 'Problem in phast_plotall!'
  endcase
endfor
end

;----------------------------------------------------------------------

pro phast_plotwindow

  ; Set plot window
  ; improved version by N. Cunningham- different scaling for postscript
  ; vs non-postscript output  -- added 4/14/06

  common phast_state
  
  phast_setwindow, state.draw_window_id
 
  if !d.name eq 'PS' then begin
    xrange=[state.offset[0], $
      state.offset[0] + state.draw_window_size[0] $
      / state.zoom_factor] - 0.5
    yrange=[state.offset[1], $
      state.offset[1] + state.draw_window_size[1] $
      / state.zoom_factor] - 0.5
  endif else begin
    xrange=[state.offset[0] + 0.5 / state.zoom_factor, $
      state.offset[0] + (state.draw_window_size[0] + 0.5) $
      / state.zoom_factor] - 0.5
    yrange=[state.offset[1] + 0.5 / state.zoom_factor, $
      state.offset[1] + (state.draw_window_size[1] + 0.5) $
      / state.zoom_factor] - 0.5
  endelse
  
  plot, [0], [0], /nodata, position=[0,0,1,1], $
    xrange=xrange, yrange=yrange, xstyle=5, ystyle=5, /noerase
    
  phast_resetwindow
end

;---------------------------------------------------------------------

pro phast_refresh, fast = fast

  ; Make the display image from the scaled_image, and redisplay the pan
  ; image and tracking image.
  ; The /fast option skips the steps where the display_image is
  ; recalculated from the main_image.  The /fast option is used in 24
  ; bit color mode, when the color map has been stretched but everything
  ; else stays the same.

  common phast_state
  common phast_images
  
  phast_getwindow
  if (not(keyword_set(fast))) then begin
    phast_getoffset
    phast_getdisplay
    phast_displaymain
    phast_plotall
  endif else begin
    phast_displaymain
  endelse
  
  ; redisplay the pan image and plot the boundary box
  phast_setwindow, state.pan_pixmap
  erase
  tv, pan_image, state.pan_offset[0], state.pan_offset[1]
  if ptr_valid(state.astr_ptr) then begin
    arrows,image_archive[state.current_image_index]->get_header(),60,60
  endif
  phast_resetwindow
  
  phast_setwindow, state.pan_window_id
  if (not(keyword_set(fast))) then erase
  tv, pan_image, state.pan_offset[0], state.pan_offset[1]
  if ptr_valid(state.astr_ptr) then begin    ;stop
    arrows,image_archive[state.current_image_index]->get_header(),60,60
  endif
  
  phast_resetwindow
  phast_drawbox, /norefresh
  
  if (state.bitdepth EQ 24) then phast_colorbar
  
  ; redisplay the tracking image
  if (not(keyword_set(fast))) then phast_gettrack
  
  phast_resetwindow
  
  state.newrefresh = 1
end

;---------------------------------------------------------------------

pro phast_resetwindow

  ; reset to current active window

  common phast_state
  common phast_color
  
  
  ; The empty command used below is put there to make sure that all
  ; graphics to the previous phast window actually get displayed to screen
  ; before we wset to a different window.  Without it, some line
  ; graphics would not actually appear on screen.
  ; Also reset to user's external color map and p.multi.
  
  ; use for debugging
  ; print, 'phast_resetwindow', state.active_window_id
  
  if (!d.name NE 'PS') then begin
    empty
    wset, state.active_window_id
    tvlct, user_r, user_g, user_b
  endif
  
  !p.multi = state.active_window_pmulti
end

;----------------------------------------------------------------------

pro phast_resize

  ; Routine to resize the draw window when a top-level resize event
  ; occurs.

  common phast_state
  
  widget_control, state.base_id, tlb_get_size=tmp_event
  
  window = (state.base_min_size > tmp_event)
  
  newbase = window - state.base_pad
  newxsize = (tmp_event[0] - state.base_pad[0]) ;> $
  ;  (state.base_min_size[0] - state.base_pad[0])
  newysize = (tmp_event[1] - state.base_pad[1]) ;> $
  ;  (state.base_min_size[1] - state.base_pad[1])
  
  
  widget_control, state.draw_widget_id, $
    scr_xsize = newxsize, scr_ysize = newysize
  ;widget_control, state.colorbar_widget_id, $
  ;  scr_xsize = newxsize, scr_ysize = state.colorbar_height
    
  state.draw_window_size = [newxsize, newysize]
  
  phast_colorbar
  
  widget_control, state.base_id, /clear_events
  widget_control, state.draw_base_id, /sensitive;, /input_focus
end

;--------------------------------------------------------------------

pro phast_restretch

  ; Routine to restretch the min and max to preserve the display
  ; visually but use the full color map linearly.  Written by DF, and
  ; tweaked and debugged by AJB.  It doesn't always work exactly the way
  ; you expect (especially in log-scaling mode), but mostly it works fine.

  common phast_state
  
  sx = state.brightness
  sy = state.contrast
  
  if (state.scaling EQ 2) then return ; do nothing for hist-eq mode
  
  if (state.scaling EQ 0) then begin
    sfac = (state.max_value-state.min_value)
    state.max_value = sfac*(sx+sy)+state.min_value
    state.min_value = sfac*(sx-sy)+state.min_value
  endif
  
  if (state.scaling EQ 1) then begin
  
    offset = state.min_value - $
      (state.max_value - state.min_value) * 0.01
      
    sfac = alog10((state.max_value - offset) / (state.min_value - offset))
    state.max_value = 10.^(sfac*(sx+sy)+alog10(state.min_value - offset)) $
      + offset
    state.min_value = 10.^(sfac*(sx-sy)+alog10(state.min_value - offset)) $
      + offset
      
  endif
  
  
  ; Try different behavior in asinh mode: usually want to keep the min
  ; value the same and just adjust the max value.  Seems to work ok.
  if (state.scaling EQ 3) then begin
    sfac = asinh(state.max_value / state.asinh_beta) - $
      asinh(state.min_value / state.asinh_beta)
      
    state.max_value = sinh(sfac*(sx+sy) + $
      asinh(state.min_value/state.asinh_beta))*state.asinh_beta
  endif
  
  ; do this differently for 8 or 24 bit color, to prevent flashing
  phast_setwindow, state.draw_window_id
  if (state.bitdepth EQ 8) then begin
    phast_set_minmax
    phast_displayall
    state.brightness = 0.5      ; reset these
    state.contrast = 0.5
    phast_stretchct
  endif else begin
    state.brightness = 0.5      ; reset these
    state.contrast = 0.5
    phast_stretchct
    phast_set_minmax
    phast_displayall
  endelse
  phast_resetwindow
end

;------------------------------------------------------------------

pro phast_rotate, rchange, get_angle=get_angle
  
  ; Routine to do image rotation
  ; If /get_angle set, create widget to enter rotation angle
  
  common phast_state
  common phast_images

  widget_control, /hourglass
  all = 0
  if (keyword_set(get_angle)) then begin
  
    formdesc = ['0, float,, label_left=Rotation Angle: ', $
      '1, base, , row', $
      '0, button, Cancel, quit', $
      '0, button, Rotate, quit', $
      '0, button, Rotate all, quit']
      
    textform = cw_form(formdesc, /column, title = 'Rotate')
    
    if (textform.tag2 EQ 1) then return
    if (textform.tag3 EQ 1) then rchange = textform.tag0
    if (textform.tag4 EQ 1) then begin
      rchange = textform.tag0
      all = 1
    endif
  endif
  
  if not keyword_set(get_angle)then begin
    case rchange of
      '0':                    ; do nothing
      
      '90': begin
        ;update rotation state in image object
        image_archive[state.current_image_index]->set_rotation,90.0,/add
        ;update current image and header
        main_image = image_archive[state.current_image_index]->get_image()
        phast_setheader, image_archive[state.current_image_index]->get_header()
      end
      '180': begin
        ;update rotation state in image object
        image_archive[state.current_image_index]->set_rotation,180.0,/add
        ;update current image and header
        main_image = image_archive[state.current_image_index]->get_image()
        phast_setheader, image_archive[state.current_image_index]->get_header()
      end
      '270': begin
        ;update rotation state in image object
        image_archive[state.current_image_index]->set_rotation,270.0,/add
        ;update current image and header
        main_image = image_archive[state.current_image_index]->get_image()
        phast_setheader, image_archive[state.current_image_index]->get_header()
      end
    endcase
    
  endif else begin
    ; arbitrary rotation angle
    rchange = float(rchange)
    if all eq 0 then begin        ;rotate current only
      ;update rotation state in image object
      image_archive[state.current_image_index]->set_rotation,rchange,/add
      ;update current image and header
      main_image = image_archive[state.current_image_index]->get_image()
      phast_setheader, image_archive[state.current_image_index]->get_header()
    endif else begin
      for i = 0, state.num_images-1 do begin
        image_archive[i]->set_rotation,rchange,/add
      endfor
      ;update current image and header
      main_image = image_archive[state.current_image_index]->get_image()
      phast_setheader,image_archive[state.current_image_index]->get_header()
    endelse
  endelse
  
  ;Update header information after rotation if header is present
  if ptr_valid(state.head_ptr) then begin
    ; head = *(state.head_ptr)
    phast_setheader, image_archive[state.current_image_index]->get_header()
  endif
  
  phast_getstats, /align, /noerase
  
  ;Redisplay image with current zoom, update pan, and refresh image
  phast_displayall
  
  ;make sure that the image arrays are updated for line/column plots, etc.
  phast_resetwindow
end

;--------------------------------------------------------------------

pro phast_rowplot, ps=ps, fullrange=fullrange, newcoord=newcoord

  ; draws a new row plot in the plot window or to postscript output

  common phast_state
  common phast_images
  
  if (keyword_set(ps)) then begin
    thick = 3
    color = 0
  endif else begin
    thick = 1
    color = 7
  endelse
  
  if (keyword_set(newcoord)) then state.plot_coord = state.coord
  
  if (not (keyword_set(ps))) then begin
    newplot = 0
    if (not (xregistered('phast_lineplot', /noshow))) then begin
      phast_lineplot_init
      newplot = 1
    endif
    
    widget_control, state.histbutton_base_id, map=0
    widget_control, state.holdrange_button_id, sensitive=1
    
    widget_control, state.lineplot_xmin_id, get_value=xmin
    widget_control, state.lineplot_xmax_id, get_value=xmax
    widget_control, state.lineplot_ymin_id, get_value=ymin
    widget_control, state.lineplot_ymax_id, get_value=ymax
    
    if (newplot EQ 1 OR state.plot_type NE 'rowplot' OR $
      keyword_set(fullrange) OR $
      (state.holdrange_value EQ 0 AND keyword_set(newcoord))) then begin
      xmin = 0.0
      xmax = state.image_size[0]
      ymin = min(main_image[*,state.plot_coord[1]])
      ymax = max(main_image[*,state.plot_coord[1]])
    endif
    
    widget_control, state.lineplot_xmin_id, set_value=xmin
    widget_control, state.lineplot_xmax_id, set_value=xmax
    widget_control, state.lineplot_ymin_id, set_value=ymin
    widget_control, state.lineplot_ymax_id, set_value=ymax
    
    state.lineplot_xmin = xmin
    state.lineplot_xmax = xmax
    state.lineplot_ymin = ymin
    state.lineplot_ymax = ymax
    
    state.plot_type = 'rowplot'
    phast_setwindow, state.lineplot_window_id
    erase
    
  endif
  
  plot, main_image[*, state.plot_coord[1]], $
    xst = 3, yst = 3, psym = 10, $
    title = strcompress('Plot of row ' + $
    string(state.plot_coord[1])), $
    
    xtitle = 'Column', $
    ytitle = 'Pixel Value', $
    color = color, xmargin=[15,3], $
    xran = [state.lineplot_xmin, state.lineplot_xmax], $
    yran = [state.lineplot_ymin, state.lineplot_ymax], $
    thick = thick, xthick = thick, ythick = thick, charthick = thick, $
    charsize = state.plotcharsize
    
  if (not (keyword_set(ps))) then begin
    widget_control, state.lineplot_base_id, /clear_events
    phast_resetwindow
  endif
end

;----------------------------------------------------------------------

pro phast_scaleimage

  ; Create a byte-scaled copy of the image, scaled according to
  ; the state.scaling parameter.

  common phast_state
  common phast_images
  
  ; Since this can take some time for a big image, set the cursor
  ; to an hourglass until control returns to the event loop.
  ;widget_control, /hourglass
  
  scaled_image=0
  
  case state.scaling of
    0: scaled_image = $                 ; linear stretch
      bytscl(main_image, $
      /nan, $
      min=state.min_value, $
      max=state.max_value, $
      top = state.ncolors - 1) + 8
      
    1: begin                            ; log stretch
      offset = state.min_value - $
        (state.max_value - state.min_value) * 0.01
        
      scaled_image = $
        bytscl( alog10(main_image - offset), $
        min=alog10(state.min_value - offset), /nan, $
        max=alog10(state.max_value - offset),  $
        top=state.ncolors - 1) + 8
    end
    
    
    2: scaled_image = $                 ; histogram equalization
      bytscl(hist_equal(main_image, $
      minv = state.min_value, $
      maxv = state.max_value), $
      /nan, top = state.ncolors - 1) + 8
      
    3:  begin                            ; asinh
      scaled_image = bytscl(asinh((main_image - state.min_value) $
        / state.asinh_beta), $
        min = 0, $
        max = asinh((state.max_value - state.min_value) / $
        state.asinh_beta), $
        /nan, top = state.ncolors - 1) + 8
    end    
  endcase
end

;---------------------------------------------------------------------

pro phast_setarrow

  ; widget front end for phastarrow

  formdesc = ['0, integer, , label_left=Tail x: ', $
    '0, integer, , label_left=Tail y: ', $
    '0, integer, , label_left=Head x: ', $
    '0, integer, , label_left=Head y: ', $
    '0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Color:, set_value=0 ', $
    '0, float, 1.0, label_left=LineThickness: ', $
    '0, float, 1.0, label_left=HeadThickness: ', $
    '1, base, , row', $
    '0, button, Cancel, quit', $
    '0, button, DrawArrow, quit']
    
  textform = cw_form(formdesc, /column, $
    title = 'phast arrow')
    
  if (textform.tag9 EQ 1) then begin
    ; switch red and black indices
    case textform.tag4 of
      0: labelcolor = 1
      1: labelcolor = 0
      else: labelcolor = textform.tag4
    endcase
    
    phastarrow, textform.tag0, textform.tag1, $
      textform.tag2, textform.tag3, $
      color = labelcolor, thick = textform.tag5, $
      hthick = textform.tag6
      
  endif
end

;---------------------------------------------------------------------

pro phast_setcompass

  ; Routine to prompt user for compass parameters

  common phast_state
  common phast_images
  common phast_pdata
  
  if (nplot GE maxplot) then begin
    phast_message, 'Total allowed number of overplots exceeded.', $
      msgtype = 'error', /window
    return
  endif
  
  
  if (state.wcstype NE 'angle') then begin
    phast_message, 'Cannot get coordinate info for this image!', $
      msgtype = 'error', /window
    return
  endif
  
  view_min = round(state.centerpix - $
    (0.5 * state.draw_window_size / state.zoom_factor))
  view_max = round(view_min + state.draw_window_size / state.zoom_factor) - 1
  
  xpos = string(round(view_min[0] + 0.15 * (view_max[0] - view_min[0])))
  ypos = string(round(view_min[1] + 0.15 * (view_max[1] - view_min[1])))
  
  xposstring = strcompress('0,integer,'+xpos+',label_left=XCenter: ')
  yposstring = strcompress('0,integer,'+ypos+',label_left=YCenter: ')
  
  formdesc = [ $
    xposstring, $
    yposstring, $
    '0, droplist, Vertex of Compass|Center of Compass, label_left = Coordinates Specify:, set_value=0', $
    '0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Color:, set_value=0 ', $
    '0, integer, 1, label_left=LineThickness: ', $
    '0, float, 1, label_left=Charsize: ', $
    '0, float, 3.5, label_left=ArrowLength: ', $
    '1, base, , row,', $
    '0, button, Cancel, quit', $
    '0, button, DrawCompass, quit']
    
  cform = cw_form(formdesc, /column, $
    title = 'phast compass properties')
    
  if (cform.tag8 EQ 1) then return
  
  cform.tag0 = 0 > cform.tag0 < (state.image_size[0] - 1)
  cform.tag1 = 0 > cform.tag1 < (state.image_size[1] - 1)
  
  ; switch red and black indices
  case cform.tag3 of
    0: labelcolor = 1
    1: labelcolor = 0
    else: labelcolor = cform.tag3
  endcase
  
  pstruct = {type: 'compass',  $  ; type of plot
    x: cform.tag0,         $
    y: cform.tag1,         $
    notvertex: cform.tag2, $
    color: labelcolor, $
    thick: cform.tag4, $
    charsize: cform.tag5, $
    arrowlen: cform.tag6 $
    }
    
  nplot = nplot + 1
  plot_ptr[nplot] = ptr_new(pstruct)
  
  phast_plotwindow
  phast_plot1compass, nplot
end

;----------------------------------------------------------------------

pro phast_setregion,x=x,y=y,radius=radius

  ; Widget front-end for plotting individual regions on image

  common phast_state
  common phast_images
  common phast_pdata
  
  if (not(xregistered('phast_setregion', /noshow))) then begin
  
    if not keyword_set(x) then x = 0
    if not keyword_set(y) then y = 0
    if not keyword_set(radius) then radius = 10
    
    regionbase = widget_base(/row, group_leader=state.base_id)
    
    formdesc = ['0, droplist, circle|box|ellipse|line,label_left=Region:, set_value=0, TAG=reg_opt ', $
      '0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Color:, set_value=0, TAG=color_opt ', $
      '0, droplist, Pixel|RA Dec (J2000)|RA Dec (B1950)|Galactic|Ecliptic|Native,label_left=Coords:, set_value=0, TAG=coord_opt ', $
      '0, text, '+string(x)+', label_left=xcenter: , width=15', $
      '0, text, '+string(y)+', label_left=ycenter: , width=15', $
      '0, text, '+string(radius)+', label_left=xwidth (Pix/ArcMin): , width=15', $
      '0, text, 0, label_left=ywidth (Pix/ArcMin): , width=15', $
      '0, text, 0, label_left=x1: , width=15', $
      '0, text, 0, label_left=y1: , width=15', $
      '0, text, 0, label_left=x2: , width=15', $
      '0, text, 0, label_left=y2: , width=15', $
      '0, text, 0.0, label_left=Angle: ', $
      '0, integer, 1, label_left=Thick: ', $
      '0, text,  , label_left=Text: ', $
      '1, base, , row', $
      '0, button, Done, quit, TAG=quit ', $
      '0, button, DrawRegion, quit, TAG=draw']
      
    regionform = cw_form(regionbase, formdesc, /column, title = 'phast region',$
      IDS=reg_ids_ptr)
    state.regionform_id = regionbase
    
    widget_control, regionbase, /REALIZE
    
    xmanager, 'phast_setregion', regionbase, /no_block
    
    reg_ids_ptr = reg_ids_ptr(where(widget_info(reg_ids_ptr,/type) eq 3 OR $
      widget_info(reg_ids_ptr,/type) eq 8))
      
    if ptr_valid(state.reg_ids_ptr) then ptr_free,state.reg_ids_ptr
    
    state.reg_ids_ptr = ptr_new(reg_ids_ptr)
    
    widget_control,(*state.reg_ids_ptr)[6],sensitive=0
    widget_control,(*state.reg_ids_ptr)[7],sensitive=0
    widget_control,(*state.reg_ids_ptr)[8],sensitive=0
    widget_control,(*state.reg_ids_ptr)[9],sensitive=0
    widget_control,(*state.reg_ids_ptr)[10],sensitive=0
    widget_control,(*state.reg_ids_ptr)[11],sensitive=0
    
    ; Check for WCS.  If WCS exists, then convert to display coordinates.
    ;if (ptr_valid(state.astr_ptr)) then begin
    ; Convert to display coordinates and change droplist selection.
    
    ;    if (state.wcstype EQ 'angle') then begin
    ;        xy2ad, state.coord[0], state.coord[1], *(state.astr_ptr), lon, lat
    ;
    ;        wcsstring = phast_wcsstring(lon, lat, (*state.astr_ptr).ctype,  $
    ;                                  state.equinox, state.display_coord_sys, $
    ;                                  state.display_equinox, state.display_base60)
    ;        ;;
    ;
    ;        if (strpos(wcsstring, 'J2000') ne -1) then coord_select = 1
    ;        if (strpos(wcsstring, 'B1950') ne -1) then coord_select = 2
    ;        if (strpos(wcsstring, 'Galactic') ne -1) then coord_select = 3
    ;        if (strpos(wcsstring, 'Ecliptic') ne -1) then coord_select = 4
    ;
    ;        if (strpos(wcsstring, 'J2000') eq -1 AND $
    ;            strpos(wcsstring, 'B1950') eq -1 AND $
    ;            strpos(wcsstring, 'Galactic') eq -1 AND $
    ;            strpos(wcsstring, 'Ecliptic') eq -1) then coord_select = 5
    ;
    ;        wcsstring = repstr(wcsstring,'J2000','')
    ;        wcsstring = repstr(wcsstring,'B1950','')
    ;        wcsstring = repstr(wcsstring,'Deg','')
    ;        wcsstring = repstr(wcsstring,'Galactic','')
    ;        wcsstring = repstr(wcsstring,'Ecliptic','')
    ;        wcsstring = repstr(wcsstring,'(','')
    ;        wcsstring = repstr(wcsstring,')','')
    ;
    ;        xcent = strcompress(gettok(wcsstring,','), /remove_all)
    ;        ycent = strcompress(wcsstring, /remove_all)
    ;
    ;        widget_control,(*state.reg_ids_ptr)[3], Set_Value = xcent
    ;        widget_control,(*state.reg_ids_ptr)[4], Set_Value = ycent
    ;        widget_control,(*state.reg_ids_ptr)[7], Set_Value = xcent
    ;        widget_control,(*state.reg_ids_ptr)[8], Set_Value = ycent
    ;        widget_control,(*state.reg_ids_ptr)[2], set_droplist_select=coord_select
    ;    endif
    ;
    ;endif else begin
    ;    widget_control,(*state.reg_ids_ptr)[3], Set_Value = $
    ;      strcompress(string(state.coord[0]), /remove_all)
    ;    widget_control,(*state.reg_ids_ptr)[4], Set_Value = $
    ;      strcompress(string(state.coord[1]), /remove_all)
    ;    widget_control,(*state.reg_ids_ptr)[7], Set_Value = $
    ;      strcompress(string(state.coord[0]), /remove_all)
    ;    widget_control,(*state.reg_ids_ptr)[8], Set_Value = $
    ;      strcompress(string(state.coord[1]), /remove_all)
    ;endelse
    
    xmanager, 'phast_setregion', regionbase
    
  endif else begin
  
    if (ptr_valid(state.astr_ptr)) then begin
      ; Convert to display coordinates and change droplist selection.
    
      if (state.wcstype EQ 'angle') then begin
        xy2ad, state.coord[0], state.coord[1], *(state.astr_ptr), lon, lat
        
        
        wcsstring = phast_wcsstring(lon, lat, (*state.astr_ptr).ctype,  $
          state.equinox, state.display_coord_sys, $
          state.display_equinox, state.display_base60)
          
        if (strpos(wcsstring, 'J2000') ne -1) then coord_select = 1
        if (strpos(wcsstring, 'B1950') ne -1) then coord_select = 2
        if (strpos(wcsstring, 'Galactic') ne -1) then coord_select = 3
        if (strpos(wcsstring, 'Ecliptic') ne -1) then coord_select = 4
        
        if (strpos(wcsstring, 'J2000') eq -1 AND $
          strpos(wcsstring, 'B1950') eq -1 AND $
          strpos(wcsstring, 'Galactic') eq -1 AND $
          strpos(wcsstring, 'Ecliptic') eq -1) then coord_select = 5
          
        wcsstring = repstr(wcsstring,'J2000','')
        wcsstring = repstr(wcsstring,'B1950','')
        wcsstring = repstr(wcsstring,'Deg','')
        wcsstring = repstr(wcsstring,'Galactic','')
        wcsstring = repstr(wcsstring,'Ecliptic','')
        wcsstring = repstr(wcsstring,'(','')
        wcsstring = repstr(wcsstring,')','')
        
        xcent = strcompress(gettok(wcsstring,','), /remove_all)
        ycent = strcompress(wcsstring, /remove_all)
        
        widget_control,(*state.reg_ids_ptr)[3], Set_Value = xcent
        widget_control,(*state.reg_ids_ptr)[4], Set_Value = ycent
        widget_control,(*state.reg_ids_ptr)[7], Set_Value = xcent
        widget_control,(*state.reg_ids_ptr)[8], Set_Value = ycent
        widget_control,(*state.reg_ids_ptr)[2], set_droplist_select=coord_select
      endif
      
    endif else begin
      widget_control,(*state.reg_ids_ptr)[3], Set_Value = $
        strcompress(string(state.coord[0]), /remove_all)
      widget_control,(*state.reg_ids_ptr)[4], Set_Value = $
        strcompress(string(state.coord[1]), /remove_all)
      widget_control,(*state.reg_ids_ptr)[7], Set_Value = $
        strcompress(string(state.coord[0]), /remove_all)
      widget_control,(*state.reg_ids_ptr)[8], Set_Value = $
        strcompress(string(state.coord[1]), /remove_all)
    endelse
    
  endelse
end

;--------------------------------------------------------------------

pro phast_setregion_event, event


  ; Event handler for phast_setregion.  Region plot structure created from
  ; information in form widget.  Plotting routine phast_plot1region is
  ; then called.

  common phast_state
  common phast_pdata
  
  CASE event.tag OF
  
    'REG_OPT' : BEGIN
      CASE event.value OF
        '0' : BEGIN
          widget_control,(*state.reg_ids_ptr)[3],Sensitive=1
          widget_control,(*state.reg_ids_ptr)[4],Sensitive=1
          widget_control,(*state.reg_ids_ptr)[5],Sensitive=1
          widget_control,(*state.reg_ids_ptr)[6],Sensitive=1
          widget_control,(*state.reg_ids_ptr)[7],Sensitive=0
          widget_control,(*state.reg_ids_ptr)[8],Sensitive=0
          widget_control,(*state.reg_ids_ptr)[9],Sensitive=0
          widget_control,(*state.reg_ids_ptr)[10],Sensitive=0
          widget_control,(*state.reg_ids_ptr)[11],Sensitive=0
        END
        '1' : BEGIN
          widget_control,(*state.reg_ids_ptr)[3],Sensitive=1
          widget_control,(*state.reg_ids_ptr)[4],Sensitive=1
          widget_control,(*state.reg_ids_ptr)[5],Sensitive=1
          widget_control,(*state.reg_ids_ptr)[6],Sensitive=1
          widget_control,(*state.reg_ids_ptr)[7],Sensitive=0
          widget_control,(*state.reg_ids_ptr)[8],Sensitive=0
          widget_control,(*state.reg_ids_ptr)[9],Sensitive=0
          widget_control,(*state.reg_ids_ptr)[10],Sensitive=0
          widget_control,(*state.reg_ids_ptr)[11],Sensitive=1
        END
        '2' : BEGIN
          widget_control,(*state.reg_ids_ptr)[3],Sensitive=1
          widget_control,(*state.reg_ids_ptr)[4],Sensitive=1
          widget_control,(*state.reg_ids_ptr)[5],Sensitive=1
          widget_control,(*state.reg_ids_ptr)[6],Sensitive=1
          widget_control,(*state.reg_ids_ptr)[7],Sensitive=0
          widget_control,(*state.reg_ids_ptr)[8],Sensitive=0
          widget_control,(*state.reg_ids_ptr)[9],Sensitive=0
          widget_control,(*state.reg_ids_ptr)[10],Sensitive=0
          widget_control,(*state.reg_ids_ptr)[11],Sensitive=1
        END
        '3' : BEGIN
          widget_control,(*state.reg_ids_ptr)[3],Sensitive=0
          widget_control,(*state.reg_ids_ptr)[4],Sensitive=0
          widget_control,(*state.reg_ids_ptr)[5],Sensitive=0
          widget_control,(*state.reg_ids_ptr)[6],Sensitive=0
          widget_control,(*state.reg_ids_ptr)[7],Sensitive=1
          widget_control,(*state.reg_ids_ptr)[8],Sensitive=1
          widget_control,(*state.reg_ids_ptr)[9],Sensitive=1
          widget_control,(*state.reg_ids_ptr)[10],Sensitive=1
          widget_control,(*state.reg_ids_ptr)[11],Sensitive=0
        END
        ELSE:
      ENDCASE
      
    END
    
    'QUIT': BEGIN
      if (ptr_valid(state.reg_ids_ptr)) then ptr_free, state.reg_ids_ptr
      widget_control, event.top, /destroy
    END
    
    'DRAW': BEGIN
      IF (nplot LT maxplot) then begin
      
        nplot = nplot + 1
        
        reg_type = ['circle','box','ellipse','line']
        reg_color = ['red','black','green','blue','cyan','magenta', $
          'yellow','white']
        coords_type = ['Pixel', 'J2000','B1950', $
          'Galactic','Ecliptic', 'Native']
        reg_index = widget_info((*state.reg_ids_ptr)[0], /droplist_select)
        color_index = $
          widget_info((*state.reg_ids_ptr)[1], /droplist_select)
        coords_index = $
          widget_info((*state.reg_ids_ptr)[2], /droplist_select)
        widget_control,(*state.reg_ids_ptr)[3],get_value=xcenter
        widget_control,(*state.reg_ids_ptr)[4],get_value=ycenter
        widget_control,(*state.reg_ids_ptr)[5],get_value=xwidth
        widget_control,(*state.reg_ids_ptr)[6],get_value=ywidth
        widget_control,(*state.reg_ids_ptr)[7],get_value=x1
        widget_control,(*state.reg_ids_ptr)[8],get_value=y1
        widget_control,(*state.reg_ids_ptr)[9],get_value=x2
        widget_control,(*state.reg_ids_ptr)[10],get_value=y2
        widget_control,(*state.reg_ids_ptr)[11],get_value=angle
        widget_control,(*state.reg_ids_ptr)[12],get_value=thick
        widget_control,(*state.reg_ids_ptr)[13],get_value=text_str
        text_str = strcompress(text_str[0],/remove_all)
        
        CASE reg_type[reg_index] OF
        
          'circle': BEGIN
            region_str = reg_type[reg_index] + '(' + xcenter + ', ' + $
              ycenter + ', ' + xwidth
            if (coords_index ne 0 and coords_index ne 5) then $
              region_str = $
              region_str + ', ' + coords_type[coords_index]
            region_str = $
              region_str + ') # color=' + reg_color[color_index]
          END
          
          'box': BEGIN
            region_str = reg_type[reg_index] + '(' + xcenter + ', ' + $
              ycenter + ', ' + xwidth + ', ' + ywidth + ', ' + angle
            if (coords_index ne 0 and coords_index ne 5) then $
              region_str = $
              region_str + ', ' + coords_type[coords_index]
            region_str = $
              region_str + ') # color=' + reg_color[color_index]
          END
          
          'ellipse': BEGIN
            region_str = reg_type[reg_index] + '(' + xcenter + ', ' + $
              ycenter + ', ' + xwidth + ', ' + ywidth + ', ' + angle
            if (coords_index ne 0 and coords_index ne 5) then $
              region_str = $
              region_str + ', ' + coords_type[coords_index]
            region_str = $
              region_str + ') # color=' + reg_color[color_index]
          END
          
          'line': BEGIN
            region_str = reg_type[reg_index] + '(' + x1 + ', ' + y1 + ', ' + $
              x2 + ', ' + y2
            if (coords_index ne 0 and coords_index ne 5) then $
              region_str = $
              region_str + ', ' + coords_type[coords_index]
            region_str = $
              region_str + ') # color=' + reg_color[color_index]
          END
          
          ELSE:
        ENDCASE
        
        if (text_str ne '') then region_str = region_str + $
          ' text={' + text_str + '}'
          
        options = {color: reg_color[color_index], $
          thick:thick}
        options.color = phast_icolor(options.color)
        
        pstruct = {type:'region', $ ;type of plot
          reg_array:[region_str], $ ;region array to plot
          options: options $
          }
          
        plot_ptr[nplot] = ptr_new(pstruct)
        
        phast_plotwindow
        phast_plot1region, nplot
        
      ENDIF ELSE BEGIN
        print, 'Too many calls to PHASTPLOT.'
      ENDELSE
      
      ;       if ptr_valid(state.reg_ids_ptr) then ptr_free, state.reg_ids_ptr
      ;       widget_control, event.top, /destroy
      if state.mousemode eq 'label' then begin
        if (ptr_valid(state.reg_ids_ptr)) then ptr_free, state.reg_ids_ptr
        widget_control, event.top, /destroy
      end
    END
    
    ELSE:
  ENDCASE
end

;---------------------------------------------------------------------

pro phast_setscalebar

  ; Routine to prompt user for scalebar parameters

  common phast_state
  common phast_images
  common phast_pdata
  
  if (nplot GE maxplot) then begin
    phast_message, 'Total allowed number of overplots exceeded.', $
      msgtype = 'error', /window
    return
  endif
  
  
  if (state.wcstype NE 'angle') then begin
    phast_message, 'Cannot get coordinate info for this image!', $
      msgtype = 'error', /window
    return
  endif
  
  view_min = round(state.centerpix - $
    (0.5 * state.draw_window_size / state.zoom_factor))
  view_max = round(view_min + state.draw_window_size / state.zoom_factor) - 1
  
  xpos = string(round(view_min[0] + 0.75 * (view_max[0] - view_min[0])))
  ypos = string(round(view_min[1] + 0.15 * (view_max[1] - view_min[1])))
  
  xposstring = strcompress('0,integer,'+xpos+',label_left=X (left end of bar): ')
  yposstring = strcompress('0,integer,'+ypos+',label_left=Y (center of bar): ')
  
  formdesc = [ $
    xposstring, $
    yposstring, $
    '0, float, 5.0, label_left=BarLength: ', $
    '0, droplist, arcsec|arcmin, label_left=Units:,set_value=0', $
    '0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Color:, set_value=0 ', $
    '0, integer, 1, label_left=LineThickness: ', $
    '0, float, 1, label_left=Charsize: ', $
    '1, base, , row,', $
    '0, button, Cancel, quit', $
    '0, button, DrawScalebar, quit']
    
  cform = cw_form(formdesc, /column, $
    title = 'phast scalebar properties')
    
  if (cform.tag8 EQ 1) then return
  
  ; switch red and black indices
  case cform.tag4 of
    0: labelcolor = 1
    1: labelcolor = 0
    else: labelcolor = cform.tag4
  endcase
  
  
  cform.tag0 = 0 > cform.tag0 < (state.image_size[0] - 1)
  cform.tag1 = 0 > cform.tag1 < (state.image_size[1] - 1)
  cform.tag3 = abs(cform.tag3 - 1)  ; set default to be arcseconds
  
  arclen = cform.tag2
  if (float(round(arclen)) EQ arclen) then arclen = round(arclen)
  
  pstruct = {type: 'scalebar',  $  ; type of plot
    arclen: arclen, $
    seconds: cform.tag3, $
    position: [cform.tag0,cform.tag1], $
    color: labelcolor, $
    thick: cform.tag5, $
    size: cform.tag6 $
    }
    
  nplot = nplot + 1
  plot_ptr[nplot] = ptr_new(pstruct)
  
  phast_plotwindow
  phast_plot1scalebar, nplot
end

;--------------------------------------------------------------------

pro phast_settitle

  ; Update title bar with the image file name

  common phast_state
  common phast_images
  
  if (state.title_extras EQ 'firstimage') then return
  
  state.title_extras = ''
  
  sizestring = strcompress('(' + string(state.image_size[0]) + 'x' + $
    string(state.image_size[1]) + ')', /remove_all)
  state.title_extras = strcompress(state.title_extras + '  ' + sizestring)
  
  if (state.cube EQ 1) then begin
    slicestring = strcompress('[' + string(state.slice) + ']')
    state.title_extras = slicestring
  endif
  
  if (state.imagename EQ '') then begin
    title = strcompress('phast: ' + state.title_extras)
    widget_control, state.base_id, tlb_set_title = title
    
  endif else begin
    ; try to get the object name from the header
    title_object = ''
    if ptr_valid(state.head_ptr) then title_object = sxpar(*(state.head_ptr), 'OBJECT')
    
    if (strcompress(string(title_object), /remove_all) EQ '0') then $
      title_object = sxpar(*(state.head_ptr), 'TARGNAME')
      
    if (strcompress(string(title_object), /remove_all) EQ '0') then $
      title_object = ''
      
    slash = strpos(state.imagename, state.delimiter, /reverse_search)
    if (slash NE -1) then name = strmid(state.imagename, slash+1) $
    else name = state.imagename
    title = strcompress('phast:  '+ name + '  ' + state.title_extras)
    
    if (title_object NE '') then  $
      title = strcompress(title + ': ' + title_object)
      
    widget_control, state.base_id, tlb_set_title = title
  endelse
end

;-------------------------------------------------------------------

pro phast_setwindow, windowid

  ; replacement for wset.  Reads the current active window first.
  ; This should be used when the currently active window is an external
  ; (i.e. non-phast) idl window.  Use phast_setwindow to set the window to
  ; one of the phast window, then display something to that window, then
  ; use phast_resetwindow to set the current window back to the currently
  ; active external window.  Make sure that device is not set to
  ; postscript, because if it is we can't display anything.

  common phast_state
  common phast_color
  
  
  state.active_window_pmulti = !p.multi
  !p.multi = 0
  
  tvlct, user_r, user_g, user_b, /get
  
  ; regenerate phast color table
  phast_initcolors
  phast_stretchct
  
  if (!d.name NE 'PS') then begin
    state.active_window_id = !d.window
    wset, windowid
  endif
  
; use for debugging
; print, 'phast_setwindow', state.active_window_id
end

;----------------------------------------------------------------------

pro phast_set_minmax

  ; Updates the min and max text boxes with new values.

  common phast_state
  
  widget_control, state.min_text_id, set_value = string(state.min_value)
  widget_control, state.max_text_id, set_value = string(state.max_value)
end

;----------------------------------------------------------------------

pro phast_showstats

  ; Brings up a widget window for displaying image statistics

  common phast_state
  common phast_images
  
  common phast_state
  
  state.cursorpos = state.coord
  
  if (not (xregistered('phast_stats', /noshow))) then begin
  
    stats_base = $
      widget_base(group_leader = state.base_id, $
      /column, $
      /base_align_center, $
      title = 'phast image statistics', $
      uvalue = 'stats_base')
    state.stats_base_id = stats_base
    
    stats_nbase = widget_base(stats_base, /row, /base_align_center)
    stats_base1 = widget_base(stats_nbase, /column, frame=1)
    stats_base2 = widget_base(stats_nbase, /column)
    stats_base2a = widget_base(stats_base2, /column, frame=1)
    stats_zoombase = widget_base(stats_base, /column)
    
    tmp_string = strcompress('Image size:  ' + $
      string(state.image_size[0]) + $
      ' x ' + $
      string(state.image_size[1]))
      
    size_label = widget_label(stats_base1, value = tmp_string)
    
    tmp_string = strcompress('Image Min:  ' + string(state.image_min))
    min_label= widget_label(stats_base1, value = tmp_string)
    tmp_string = strcompress('Image Max:  ' + string(state.image_max))
    max_label= widget_label(stats_base1, value = tmp_string)
    
    state.statbox_id = $
      cw_field(stats_base1, $
      /long, $
      /return_events, $
      title = 'Box Size for Stats:', $
      uvalue = 'statbox', $
      value = state.statboxsize, $
      xsize = 5)
      
    state.statxcenter_id = $
      cw_field(stats_base1, $
      /long, $
      /return_events, $
      title = 'Box X Center:', $
      uvalue = 'statxcenter', $
      value = state.cursorpos[0], $
      xsize = 5)
      
    state.statycenter_id = $
      cw_field(stats_base1, $
      /long, $
      /return_events, $
      title = 'Box Y Center:', $
      uvalue = 'statycenter', $
      value = state.cursorpos[1], $
      xsize = 5)
      
    tmp_string = strcompress('# Pixels in Box: ' + string(10000000))
    state.stat_npix_id = widget_label(stats_base2a, value = tmp_string)
    tmp_string = strcompress('Min:  ' + '0.00000000000000')
    state.statbox_min_id = widget_label(stats_base2a, value = tmp_string)
    tmp_string = strcompress('Max: ' + '0.00000000000000')
    state.statbox_max_id = widget_label(stats_base2a, value = tmp_string)
    tmp_string = strcompress('Mean: ' + '0.00000000000000')
    state.statbox_mean_id = widget_label(stats_base2a, value = tmp_string)
    tmp_string = strcompress('Median: ' + '0.00000000000000')
    state.statbox_median_id = widget_label(stats_base2a, value = tmp_string)
    tmp_string = strcompress('StdDev: ' + '0.00000000000000')
    state.statbox_stdev_id = widget_label(stats_base2a, value = tmp_string)
    
    state.showstatzoom_id = widget_button(stats_base2, $
      value = 'Show Region', uvalue = 'showstatzoom')
      
    stat_done = $
      widget_button(stats_base2, $
      value = 'Done', $
      uvalue = 'stats_done')
      
    state.statzoom_widget_id = widget_draw(stats_zoombase, $
      scr_xsize = 1, scr_ysize = 1)
      
    widget_control, stats_base, /realize
    
    xmanager, 'phast_stats', stats_base, /no_block
    
    widget_control, state.statzoom_widget_id, get_value = tmp_val
    state.statzoom_window_id = tmp_val
    
    phast_resetwindow
    
  endif
  
  phast_stats_refresh
end

;----------------------------------------------------------------------

pro phast_stats_event, event

  ; event handler for image stats popup

  common phast_state
  common phast_images
  
  widget_control, event.id, get_uvalue = uvalue
  
  case uvalue of
  
    'statbox': begin
      state.statboxsize = long(event.value) > 3
      if ( (state.statboxsize / 2 ) EQ $
        round(state.statboxsize / 2.)) then $
        state.statboxsize = state.statboxsize + 1
      phast_stats_refresh
    end
    
    'statxcenter': begin
      state.cursorpos[0] = 0 > long(event.value) < (state.image_size[0] - 1)
      phast_stats_refresh
    end
    
    'statycenter': begin
      state.cursorpos[1] = 0 > long(event.value) < (state.image_size[1] - 1)
      phast_stats_refresh
    end
    
    'showstatzoom': begin
      widget_control, state.showstatzoom_id, get_value=val
      case val of
        'Show Region': begin
          widget_control, state.statzoom_widget_id, $
            xsize=state.statzoom_size, ysize=state.statzoom_size
          widget_control, state.showstatzoom_id, $
            set_value='Hide Region'
        end
        'Hide Region': begin
          widget_control, state.statzoom_widget_id, $
            xsize=1, ysize=1
          widget_control, state.showstatzoom_id, $
            set_value='Show Region'
        end
      endcase
      phast_stats_refresh
    end
    
    'stats_done': widget_control, event.top, /destroy
    else:
  endcase
end

;----------------------------------------------------------------------

pro phast_stats_refresh

  ; Calculate box statistics and update the results

  common phast_state
  common phast_images
  
  b = round((state.statboxsize - 1) / 2)
  
  xmin = 0 > (state.cursorpos[0] - b) < (state.image_size[0] - 1)
  xmax = 0 > (state.cursorpos[0] + b) < (state.image_size[0] - 1)
  ymin = 0 > (state.cursorpos[1] - b) < (state.image_size[1] - 1)
  ymax = 0 > (state.cursorpos[1] + b) < (state.image_size[1] - 1)
  
  xmin = round(xmin)
  xmax = round(xmax)
  ymin = round(ymin)
  ymax = round(ymax)
  
  cut = float(main_image[xmin:xmax, ymin:ymax])
  npix = (xmax - xmin + 1) * (ymax - ymin + 1)
  
  cutmin = min(cut, max=maxx, /nan)
  cutmax = maxx
  cutmean = mean(cut, /nan)
  cutmedian = median(cut)
  cutstddev = stddev(cut)
  
  widget_control, state.statbox_id, set_value=state.statboxsize
  widget_control, state.statxcenter_id, set_value = state.cursorpos[0]
  widget_control, state.statycenter_id, set_value = state.cursorpos[1]
  tmp_string = strcompress('# Pixels in Box:  ' + string(npix))
  widget_control, state.stat_npix_id, set_value = tmp_string
  tmp_string = strcompress('Min:  ' + string(cutmin))
  widget_control, state.statbox_min_id, set_value = tmp_string
  tmp_string = strcompress('Max:  ' + string(cutmax))
  widget_control, state.statbox_max_id, set_value = tmp_string
  tmp_string = strcompress('Mean:  ' + string(cutmean))
  widget_control, state.statbox_mean_id, set_value = tmp_string
  tmp_string = strcompress('Median:  ' + string(cutmedian))
  widget_control, state.statbox_median_id, set_value = tmp_string
  tmp_string = strcompress('StdDev:  ' + string(cutstddev))
  widget_control, state.statbox_stdev_id, set_value = tmp_string
  
  phast_tvstats
end

;----------------------------------------------------------------------

pro phast_stretchct, brightness, contrast,  getcursor = getcursor

  ; routine to change color stretch for given values of brightness and contrast.
  ; Complete rewrite 2000-Sep-21 - Doug Finkbeiner
  ; Updated 12/2006 to allow for brightness,contrast param input
  ; without changing the state.brightness and state.contrast values.
  ; Better for surface plots in plot window.

  common phast_state
  common phast_color
  
  ; if GETCURSOR then assume mouse position passed and save as
  ; state.brightness and state.contrast.  If no params passed, then use
  ; the current state.brightness and state.contrast.  If b, c passed
  ; without /getcursor, then make a new color table stretch for that
  ; brightness and contrast but don't modify the current
  ; state.brightness and state.contrast
  
  ; New in 2.0: scale the contrast by 0.75- gives better contrast by
  ; default when first starting up, and better in general with asinh
  ; scaling
  
  contrastscale=0.75
  
  if (keyword_set(getcursor)) then begin
    state.brightness = brightness/float(state.draw_window_size[0])
    state.contrast = contrast/float(state.draw_window_size[1])
    x = state.brightness*(state.ncolors-1)
    y = state.contrast*(state.ncolors-1)*contrastscale > 2
  endif else begin
    if (n_elements(brightness) EQ 0 OR n_elements(contrast) EQ 0) then begin
      x = state.brightness*(state.ncolors-1)
      y = state.contrast*(state.ncolors-1)*contrastscale > 2
    endif else begin
      x = brightness*(state.ncolors-1)
      y = contrast*(state.ncolors-1)*contrastscale > 2
    endelse
  endelse
  
  high = x+y & low = x-y
  diff = (high-low) > 1
  
  slope = float(state.ncolors-1)/diff ;Scale to range of 0 : nc-1
  intercept = -slope*low
  p = long(findgen(state.ncolors)*slope+intercept) ;subscripts to select
  tvlct, r_vector[p], g_vector[p], b_vector[p], 8
end

;--------------------------------------------------------------------

pro phast_surfplot, ps=ps, fullrange=fullrange, newcoord=newcoord

  common phast_state
  common phast_images
  
  if (keyword_set(ps)) then begin
    thick = 3
    color = 0
  endif else begin
    thick = 1
    color = 7
  endelse
  
  if (not (keyword_set(ps))) then begin
  
    newplot = 0
    if (not (xregistered('phast_lineplot', /noshow))) then begin
      phast_lineplot_init
      newplot = 1
    endif
    
    widget_control, state.histbutton_base_id, map=0
    widget_control, state.holdrange_button_id, sensitive=0
    
    ; set new plot coords if passed from a main window keyboard event
    if (keyword_set(newcoord)) then begin
      plotsize = $
        fix(min([50, state.image_size[0]/2., state.image_size[1]/2.]))
      center = plotsize > state.coord < (state.image_size[0:1] - plotsize)
      
      shade_image = main_image[center[0]-plotsize:center[0]+plotsize-1, $
        center[1]-plotsize:center[1]+plotsize-1]
        
      state.lineplot_xmin = center[0]-plotsize
      state.lineplot_xmax = center[0]+plotsize-1
      state.lineplot_ymin = center[1]-plotsize
      state.lineplot_ymax = center[1]+plotsize-1
      
      state.plot_coord = state.coord
      
      widget_control, state.lineplot_xmin_id, $
        set_value = state.lineplot_xmin
      widget_control, state.lineplot_xmax_id, $
        set_value = state.lineplot_xmax
      widget_control, state.lineplot_ymin_id, $
        set_value = state.lineplot_ymin
      widget_control, state.lineplot_ymax_id, $
        set_value = state.lineplot_ymax
    endif
    
    if (keyword_set(fullrange)) then begin
      widget_control, state.lineplot_xmin_id, set_value = 0
      widget_control, state.lineplot_xmax_id, $
        set_value = state.image_size[0]-1
      widget_control, state.lineplot_ymin_id, set_value = 0
      widget_control, state.lineplot_ymax_id, $
        set_value = state.image_size[1]-1
    endif
    
    state.plot_type = 'surfplot'
    phast_setwindow, state.lineplot_window_id
    erase
    
    ; now get plot coords from the widget box
    widget_control,state.lineplot_xmin_id, get_value=xmin
    widget_control,state.lineplot_xmax_id, get_value=xmax
    widget_control,state.lineplot_ymin_id, get_value=ymin
    widget_control,state.lineplot_ymax_id, get_value=ymax
    
    state.lineplot_xmin = xmin
    state.lineplot_xmax = xmax
    state.lineplot_ymin = ymin
    state.lineplot_ymax = ymax
  endif
  
  shade_image =  main_image[state.lineplot_xmin:state.lineplot_xmax, $
    state.lineplot_ymin:state.lineplot_ymax]
  ;shades = scaled_image[state.lineplot_xmin:state.lineplot_xmax, $
  ;                          state.lineplot_ymin:state.lineplot_ymax]
    
  plottitle = $
    strcompress('Surface plot of ' + $
    strcompress('['+string(round(state.lineplot_xmin))+ $
    ':'+string(round(state.lineplot_xmax))+ $
    ','+string(round(state.lineplot_ymin))+ $
    ':'+string(round(state.lineplot_ymax))+ $
    ']', /remove_all))
    
  xdim = state.lineplot_xmax - state.lineplot_xmin + 1
  ydim = state.lineplot_ymax - state.lineplot_ymin + 1
  
  xran = lindgen(xdim) + state.lineplot_xmin
  yran = lindgen(ydim) + state.lineplot_ymin
  
  ; reload the color table of the main window with default brightness
  ; and contrast, to make the surface plot come out ok
  phast_stretchct, 0.5, 0.5
  
  shade_surf, shade_image, xst=3, yst=3, zst=3, $
    xran, yran, $
    title = plottitle, $
    xtitle = 'X', ytitle = 'Y', ztitle = 'Pixel Value', $
    color = color, charsize= state.plotcharsize, $
    thick = thick, xthick = thick, ythick = thick, zthick = thick, $
    charthick = thick  ;, shades = shades
    
  if (not (keyword_set(ps))) then begin
    widget_control, state.lineplot_base_id, /clear_events
    phast_resetwindow
  endif
  
end

;----------------------------------------------------------------------

pro phast_textlabel

  ; widget front end for phastxyouts

  formdesc = ['0, text, , label_left=Text: , width=15', $
    '0, integer, , label_left=x: ', $
    '0, integer, , label_left=y: ', $
    '0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Color:, set_value=0 ', $
    '0, float, 2.0, label_left=Charsize: ', $
    '0, integer, 1, label_left=Charthick: ', $
    '0, integer, 0, label_left=Orientation: ', $
    '1, base, , row', $
    '0, button, Cancel, quit', $
    '0, button, DrawText, quit']
    
  textform = cw_form(formdesc, /column, $
    title = 'phast text label')
    
  if (textform.tag9 EQ 1) then begin
    ; switch red and black indices
    case textform.tag3 of
      0: labelcolor = 1
      1: labelcolor = 0
      else: labelcolor = textform.tag3
    endcase
    
    phastxyouts, textform.tag1, textform.tag2, textform.tag0, $
      color = labelcolor, charsize = textform.tag4, $
      charthick = textform.tag5, orientation = textform.tag6
  endif
end

;---------------------------------------------------------------------

pro phast_tvstats

  ; Routine to display the zoomed region around a stats point

  common phast_state
  common phast_images
  
  phast_setwindow, state.statzoom_window_id
  erase
  
  x = round(state.cursorpos[0])
  y = round(state.cursorpos[1])
  
  boxsize = (state.statboxsize - 1) / 2
  xsize = state.statboxsize
  ysize = state.statboxsize
  image = bytarr(xsize,ysize)
  
  xmin = (0 > (x - boxsize))
  xmax = ((x + boxsize) < (state.image_size[0] - 1) )
  ymin = (0 > (y - boxsize) )
  ymax = ((y + boxsize) < (state.image_size[1] - 1))
  
  startx = abs( (x - boxsize) < 0 )
  starty = abs( (y - boxsize) < 0 )
  
  image[startx, starty] = scaled_image[xmin:xmax, ymin:ymax]
  
  xs = indgen(xsize) + xmin - startx
  ys = indgen(ysize) + ymin - starty
  
  xs_delta = (xs[xsize-1] - xs[0]) / float(xsize - 1.0)
  ys_delta = (ys[ysize-1] - ys[0]) / float(ysize - 1.0)
  x_ran = [xs[0]-xs_delta/2.0,xs[xsize-1]+xs_delta/2.0]
  y_ran = [ys[0]-ys_delta/2.0,ys[ysize-1]+ys_delta/2.0]
  
  dev_width = 0.8 * state.statzoom_size
  dev_pos = [0.15 * state.statzoom_size, $
    0.15 * state.statzoom_size, $
    0.95 * state.statzoom_size, $
    0.95 * state.statzoom_size]
    
  x_factor = dev_width / xsize
  y_factor = dev_width / ysize
  x_offset = (x_factor - 1.0) / x_factor / 2.0
  y_offset = (y_factor - 1.0) / y_factor / 2.0
  xi = findgen(dev_width) / x_factor - x_offset ;x interp index
  yi = findgen(dev_width) / y_factor - y_offset ;y interp index
  
  image = Poly_2D(image, [[0,0],[1.0/x_factor,0]], $
    [[0,1.0/y_factor],[0,0]], $
    0, dev_width, dev_width)
    
  xsize = (size(image))[1]
  ysize = (size(image))[2]
  out_xs = xi * xs_delta + xs[0]
  out_ys = yi * ys_delta + ys[0]
  
  sz = size(image)
  xsize = Float(sz[1])       ;image width
  ysize = Float(sz[2])       ;image height
  dev_width = dev_pos[2] - dev_pos[0] + 1
  dev_width = dev_pos[3] - dev_pos[1] + 1
  
  tv, image, /device, dev_pos[0], dev_pos[1], $
    xsize=dev_pos[2]-dev_pos[0], $
    ysize=dev_pos[3]-dev_pos[1]
    
  plot, [0, 1], /noerase, /nodata, xstyle = 1, ystyle = 1, $
    /device, position = dev_pos, color=7, $
    xrange = x_ran, yrange = y_ran
    
  phast_resetwindow
end

;----------------------------------------------------------------------

pro phast_vectorplot, ps=ps, fullrange=fullrange, newcoord=newcoord

  common phast_state
  common phast_images
  
  if (keyword_set(ps)) then begin
    thick = 3
    color = 0
  endif else begin
    thick = 1
    color = 7
  endelse  
  
  d = sqrt((state.vector_coord1[0]-state.vector_coord2[0])^2 + $
    (state.vector_coord1[1]-state.vector_coord2[1])^2)
    
  v_d = fix(d + 1)
  dx = (state.vector_coord2[0]-state.vector_coord1[0]) / float(v_d - 1)
  dy = (state.vector_coord2[1]-state.vector_coord1[1]) / float(v_d - 1)
  
  x = fltarr(v_d)
  y = fltarr(v_d)
  vectdist = indgen(v_d)
  pixval = fltarr(v_d)
  
  x[0] = state.vector_coord1[0]
  y[0] = state.vector_coord1[1]
  for i = 1, n_elements(x) - 1 do begin
    x[i] = state.vector_coord1[0] + dx * i
    y[i] = state.vector_coord1[1] + dy * i
  endfor
  
  
  
  for j = 0, n_elements(x) - 1 do begin
    col = x[j]
    row = y[j]
    floor_col = floor(col)
    ceil_col = ceil(col)
    floor_row = floor(row)
    ceil_row = ceil(row)
    
    pixval[j] = (total([main_image[floor_col,floor_row], $
      main_image[floor_col,ceil_row], $
      main_image[ceil_col,floor_row], $
      main_image[ceil_col,ceil_row]])) / 4.
      
  endfor
  
  if (not (keyword_set(ps))) then begin
  
    newplot = 0
    if (not (xregistered('phast_lineplot', /noshow))) then begin
      phast_lineplot_init
      newplot = 1
    endif
    
    widget_control, state.histbutton_base_id, map=0
    widget_control, state.holdrange_button_id, sensitive=1
    
    widget_control, state.lineplot_xmin_id, get_value=xmin
    widget_control, state.lineplot_xmax_id, get_value=xmax
    widget_control, state.lineplot_ymin_id, get_value=ymin
    widget_control, state.lineplot_ymax_id, get_value=ymax
    
    if (newplot EQ 1 OR state.plot_type NE 'vectorplot' OR $
      keyword_set(fullrange) OR $
      (state.holdrange_value EQ 0 AND keyword_set(newcoord))) then begin
      xmin = 0.0
      xmax = max(vectdist)
      ymin = min(pixval)
      ymax = max(pixval)
      
    endif
    
    widget_control, state.lineplot_xmin_id, set_value=xmin
    widget_control, state.lineplot_xmax_id, set_value=xmax
    widget_control, state.lineplot_ymin_id, set_value=ymin
    widget_control, state.lineplot_ymax_id, set_value=ymax
    
    state.lineplot_xmin = xmin
    state.lineplot_xmax = xmax
    state.lineplot_ymin = ymin
    state.lineplot_ymax = ymax
    
    state.plot_type = 'vectorplot'
    phast_setwindow, state.lineplot_window_id
    erase
    
  endif
  
  
  plottitle = strcompress('Plot of vector [' + $
    strcompress(string(state.vector_coord1[0]) + ',' + $
    string(state.vector_coord1[1]), $
    /remove_all) + $
    '] to [' + $
    strcompress(string(state.vector_coord2[0]) + ',' + $
    string(state.vector_coord2[1]), $
    /remove_all) + ']')
    
  plot, vectdist, pixval, $
    xst = 3, yst = 3, psym = 10, $
    title = plottitle, $
    xtitle = 'Vector Distance', $
    ytitle = 'Pixel Value', $
    color = color, xmargin=[15,3], $
    xran = [state.lineplot_xmin, state.lineplot_xmax], $
    yran = [state.lineplot_ymin, state.lineplot_ymax], $
    thick = thick, xthick = thick, ythick = thick, charthick = thick, $
    charsize = state.plotcharsize
    
    
  if (not (keyword_set(ps))) then begin
    widget_control, state.lineplot_base_id, /clear_events
    phast_resetwindow
  endif
end

;--------------------------------------------------------------------

pro phast_zoom, zchange, recenter = recenter
  
  ; Routine to do zoom in/out and recentering of image.  The /recenter
  ; option sets the new display center to the current cursor position.

  common phast_state
  
  case zchange of
    'in':    state.zoom_level = (state.zoom_level + 1) < 6
    'out':   begin
      sizeratio = fix(min(state.image_size) / 16.) > 1
      minzoom = -1.*fix(alog(sizeratio)/alog(2.0))
      state.zoom_level = (state.zoom_level - 1) > minzoom
    end
    'onesixteenth': state.zoom_level =  -4
    'oneeighth': state.zoom_level =  -3
    'onefourth': state.zoom_level =  -2
    'onehalf': state.zoom_level =  -1
    'two':   state.zoom_level =  1
    'four':  state.zoom_level =  2
    'eight': state.zoom_level =  3
    'sixteen': state.zoom_level = 4
    'one':   state.zoom_level =  0
    'none':  ; no change to zoom level: recenter on current mouse position
    else:  print,  'problem in phast_zoom!'
  endcase
  
  state.zoom_factor = (2.0)^(state.zoom_level)
  
  if (n_elements(recenter) GT 0) then begin
    state.centerpix = state.coord
    phast_getoffset
  endif
  
  phast_refresh
  
  if (n_elements(recenter) GT 0) then begin
    newpos = (state.coord - state.offset + 0.5) * state.zoom_factor
    phast_setwindow,  state.draw_window_id
    tvcrs, newpos[0], newpos[1], /device
    phast_resetwindow
    phast_gettrack
  endif
  
  phast_resetwindow
end

;--------------------------------------------------------------------

pro phast_display

;for compilation purposes only

end
