;----------------------------------------------------------------------

pro phast_check_moons

  ;routine to check the current VICAR image for moons with the SPICE
  ;kernels

  common phast_state
  common phast_images
  
  ;check that the ICY DLM is installed
  
  ;load the SPICE kernels specified in state.kernel_list
  readcol,state.kernel_list,kernels, delimiter='|',format='A'
  cspice_furnsh,kernels
end

;----------------------------------------------------------------------

pro phast_gaussfit, ps=ps, fullrange=fullrange, newcoord=newcoord

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
    
    if (newplot EQ 1 OR state.plot_type NE 'gaussplot' OR $
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
    
    state.plot_type = 'gaussplot'
    phast_setwindow, state.lineplot_window_id
    erase
    
  endif
  
  plottitle = strcompress('Gaussfit: vector [' + $
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
    
  ; do the fit
    
  if (n_elements(vectdist) GT 10) then begin
    result = gaussfit(vectdist, pixval, a, nterms=5)
    
    oplot, vectdist, result, color=1
    
    amplitude = a[0]
    centroid = a[1]
    fwhm = a[2] * 2.355
    
    ;   print, 'Gaussian fit parameters:'
    ;   print, 'Amplitude: ', amplitude
    ;   print, 'Centroid:  ', centroid
    ;   print, 'FWHM:      ', fwhm
    ;   print
    
    fwhmstring = strcompress(string(fwhm, format='("FWHM = ", f7.2)'), /remove_all)
    
    xyouts, 0.25, 0.85, fwhmstring, /normal, charsize = state.plotcharsize
    
  endif
  
  if (not (keyword_set(ps))) then begin
    widget_control, state.lineplot_base_id, /clear_events
    phast_resetwindow
  endif
end

;----------------------------------------------------------------------

pro phast_getstats, align=align, noerase=noerase

  ; Get basic image stats: min and max, and size.
  ; set align keyword to preserve alignment of previous image

  common phast_state
  common phast_images
  
  ; this routine operates on main_image, which is in the
  ; phast_images common block
  
  ;widget_control, /hourglass
  
  oldimagesize = state.image_size
  
  state.image_size = [ (size(main_image))[1], (size(main_image))[2] ]
  
  if ((oldimagesize[0] NE state.image_size[0]) OR $
    (oldimagesize[1] NE state.image_size[1])) then align = 0
    
  state.image_min = min(main_image, max=maxx, /nan)
  state.image_max = maxx
  
  ; Get sky value for autoscaling and asinh stretch.  Eliminate
  ; zero-valued and NaN pixels from sky calculation, i.e. for HST ACS
  ; drizzled images, WFPC2 mosaics, or Spitzer images.
  w = where(finite(main_image) AND (main_image NE 0.0), goodcount)
  if (goodcount GT 25) then begin
    sky, main_image[w], skymode, skysig, /silent
  endif else if (goodcount GT 5 AND goodcount LE 25) then begin
    skysig = stddev(main_image[w])
    skymode = median(main_image[w])
  endif else if (goodcount LE 5) then begin ; really pathological images
    skysig = 1.
    skymode = 0.
  endif
  
  ; error checking- in case sky.pro returns a zero or negative sigma
  if (skysig LE 0.0) then skysig = stddev(main_image)
  if (skysig LE 0.0) then skysig = 1.0
  
  state.skymode = skymode
  state.skysig = skysig
  ;state.asinh_beta = state.skysig
  
  if (state.min_value GE state.max_value) then begin
    state.min_value = state.min_value - 1
    state.max_value = state.max_value + 1
  endif
  
  ; zero the current display position on the center of the image,
  ; unless user selected /align keyword
  
  state.coord = round(state.image_size / 2.)
  IF (NOT keyword_set(align) OR (state.firstimage EQ 1)) THEN $
    state.centerpix = round(state.image_size / 2.)
  phast_getoffset
  
  ; Clear all plot annotations
  if (not(keyword_set(noerase))) then phasterase, /norefresh
end

;---------------------------------------------------------------------

function phast_get_obs_time, header

  ;routine to return the Julian date of an observation given the header

  common phast_state

  if not keyword_set(header) then header = *state.astr_ptr
  jd = -1d
  while (1 eq 1) do begin       ;choose only one
     mjd = sxpar(header,'MJD-OBS',count=count)
     if count ne 0 then begin
        jd = double(mjd) + 2400000.5d
        break
     endif
     jd = sxpar(header,'JD',count=count)
     if count ne 0 then begin
        if long(jd) gt 240000 then begin
           break
        endif else print, 'Warning: FITS keyword JD appears incorrect.  Trying other methods.'
     endif
     datestr = sxpar(header,'DATE-OBS',count=date_count)
     timestr = sxpar(header,'UT',count=time_count)
     if (date_count ne 0) and (time_count ne 0) then begin
        YYYY =  long(strmid(datestr,0,4))
        MM =  long(strmid(datestr,5,2))
        DD =  long(strmid(datestr,8,2))
        HH =  long(strmid(timestr,0,2))
        Min =  long(strmid(timestr,3,2))
        Sec = float(strmid(timestr,6))
        jd = JULDAY(MM,DD,YYYY,HH,Min,Sec)
        break
     endif
     datestr = sxpar(header,'DATE-OBS',count=date_count)
     timestr = sxpar(header,'UTC-OBS',count=time_count)
     if (date_count ne 0) and (time_count ne 0) then begin
        YYYY =  long(strmid(datestr,0,4))
        MM =  long(strmid(datestr,5,2))
        DD =  long(strmid(datestr,8,2))
        HH =  long(strmid(timestr,0,2))
        Min =  long(strmid(timestr,3,2))
        Sec = float(strmid(timestr,6))
        jd = JULDAY(MM,DD,YYYY,HH,Min,Sec)        
        break
     endif
     print, 'Supported date keyword not found in FITS header.'
     break
  endwhile

  return, double(jd)
end

;---------------------------------------------------------------------

pro phast_help

  ;display the help menu

  common phast_state
  
  h = strarr(130)
  i = 0
  h[i] =  'PHAST HELP'
  i = i + 1
  h[i] =  ''
  i = i + 1
  h[i] =  'MENU BAR:'
  i = i + 1
  h[i] =  'File->ReadFits:         Read in a new fits image from disk'
  i = i + 1
  h[i] =  'File->WritePS:          Write a PostScript file of the current display'
  i = i + 1
  h[i] =  'File->WriteImage:       Write an output png, jpg, or tiff image of the current display'
  i = i + 1
  h[i] =  'File->GetImage:         Download an archival image based on object name or coordinates'
  i = i + 1
  h[i] =  'File->Quit:             Quits phast'
  i = i + 1
  h[i] =  'ColorMap Menu:          Selects color table'
  i = i + 1
  h[i] =  'Scaling Menu:           Selects linear, log, or histogram-equalized scaling'
  i = i + 1
  h[i] =  'Labels->TextLabel:      Brings up a dialog box for text input'
  i = i + 1
  h[i] =  'Labels->Contour:        Brings up a dialog box for overplotting contours'
  i = i + 1
  h[i] =  'Labels->Compass:        Draws a compass (requires WCS info in header)'
  i = i + 1
  h[i] =  'Labels->Scalebar:       Draws a scale bar (requires WCS info in header)'
  i = i + 1
  h[i] =  'Labels->EraseLast:      Erases the most recent plot label'
  i = i + 1
  h[i] =  'Labels->EraseAll:       Erases all plot labels'
  i = i + 1
  h[i] =  'Blink->SetBlink:        Sets the current display to be the blink image'
  i = i + 1
  h[i] =  '                             for mouse button 1, 2, or 3'
  i = i + 1
  h[i] =  'Blink->MakeRGB:         Make an RGB truecolor image from the 3 blink channels'
  i = i + 1
  h[i] =  'Rotate/Zoom->Rotate:    Rotate image clockwise by an arbitrary angle'
  i = i + 1
  h[i] =  'Rotate/Zoom->90, 180, or 270 deg: rotates clockwise'
  i = i + 1
  h[i] =  'Rotate/Zoom->Invert:    Inverts image along x, y, or both axes'
  i = i + 1
  h[i] =  'Rotate/Zoom->1/16x, etc: Sets zoom factor to selected scaling'
  i = i + 1
  h[i] =  'ImageInfo->ImageHeader: Display the FITS header, if there is one.'
  i = i + 1
  h[i] =  'ImageInfo->Photometry:  Brings up photometry window'
  i = i + 1
  h[i] =  'ImageInfo->Statistics:  Brings up stats window'
  i = i + 1
  h[i] =  'ImageInfo->PixelTable:  Brings up table window that tracks nearby pixel values'
  i = i + 1
  h[i] =  'ImageInfo menu also gives a choice of coordinate systems, '
  i = i + 1
  h[i] =  '    or of native image coordinates (default), for images with a WCS.'
  i = i + 1
  h[i] =  ''
  i = i + 1
  h[i] =  'CONTROL PANEL ITEMS:'
  i = i + 1
  h[i] = 'Min:             shows minimum data value displayed; enter new min value here'
  i = i + 1
  h[i] = 'Max:             shows maximum data value displayed; enter new max value here'
  i = i + 1
  h[i] = 'Pan Window:      use mouse to drag the image-view box around'
  i = i + 1
  h[i] = ''
  i = i + 1
  h[i] = 'MOUSE MODE SELECTOR:'
  i = i + 1
  h[i] =  'Color:          sets color-stretch mode:'
  i = i + 1
  h[i] = '                    With mouse button 1 down, drag mouse to change the color stretch.  '
  i = i + 1
  h[i] = '                    Move vertically to change contrast, and'
  i = i + 1
  h[i] = '                         horizontally to change brightness.'
  i = i + 1
  h[i] = '                    button 2 or 3: center on current position'
  i = i + 1
  h[i] = 'Zoom:           sets zoom mode:'
  i = i + 1
  h[i] = '                    button1: zoom in & center on current position'
  i = i + 1
  h[i] = '                    button2: center on current position'
  i = i + 1
  h[i] = '                    button3: zoom out & center on current position'
  i = i + 1
  h[i] = 'Blink:           sets blink mode:'
  i = i + 1
  h[i] = '                    press mouse button in main window to show blink image'
  i = i + 1
  h[i] = 'ImExam:          sets ImageExamine mode:'
  i = i + 1
  h[i] = '                    button 1: photometry'
  i = i + 1
  h[i] = '                    button 2: center on current position'
  i = i + 1
  h[i] = '                    button 3: image statistics'
  i = i + 1
  h[i] = 'Vector:          sets vector mode: click and drag in main window to select plot region'
  i = i + 1
  h[i] = '                    button 1: vector plot'
  i = i + 1
  h[i] = '                    button 2: vector plot with gaussian fit to peak'
  i = i + 1
  h[i] = '                    button 3: depth plot for 3d data cubes'
  i = i + 2
  h[i] = 'BUTTONS:'
  i = i + 1
  h[i] = 'Invert:          inverts the current color table'
  i = i + 1
  h[i] = 'Restretch:       sets min and max to preserve display colors while linearizing the color table'
  i = i + 1
  h[i] = 'AutoScale:       sets min and max to show data values around image median'
  i = i + 1
  h[i] = 'FullRange:       sets min and max to show the full data range of the image'
  i = i + 1
  h[i] = 'ZoomIn:          zooms in by x2'
  i = i + 1
  h[i] = 'ZoomOut:         zooms out by x2'
  i = i + 1
  h[i] = 'Zoom1:           sets zoom level to original scale'
  i = i + 1
  h[i] = 'Center:          centers image on display window'
  i = i + 1
  ;h[i] = 'Done:            quits phast'
  ;i = i + 1
  h[i] = ''
  i = i + 1
  h[i] = 'Keyboard commands in display window:'
  i = i + 1
  h[i] = '    Arrow keys or numeric keypad (with NUM LOCK on) moves cursor'
  i = i + 1
  h[i] = '    r: row plot'
  i = i + 1
  h[i] = '    c: column plot'
  i = i + 1
  h[i] = '    s: surface plot'
  i = i + 1
  h[i] = '    t: contour plot'
  i = i + 1
  h[i] = '    h: histogram of pixel values'
  i = i + 1
  i = i + 1
  h[i] = '    p: aperture photometry at current position'
  i = i + 1
  h[i] = '    i: image statistics at current position'
  i = i + 1
  h[i] = '    x: extract spectrum at current position'
  i = i + 1
  h[i] = '    m: cycles through mouse modes'
  i = i + 1
  h[i] = '    e: erase all overplots'
  i = i + 1
  h[i] = '    Shift-1,2,3:  sets blink buffer 1, 2, or 3'
  i = i + 1
  h[i] = '    q: quits phast'
  i = i + 2
  h[i] = 'IDL COMMAND LINE HELP:'
  i = i + 1
  h[i] =  'To pass an array to phast:'
  i = i + 1
  h[i] =  '   phast, array_name [, options]'
  i = i + 1
  h[i] = 'To pass a fits filename to phast:'
  i = i + 1
  h[i] = '    phast, fitsfile_name [, options] (enclose filename in single quotes) '
  i = i + 1
  h[i] = 'Command-line options are: '
  i = i + 1
  h[i]  = '   [,min = min_value] [,max=max_value] [,/linear] [,/log] [,/histeq] [,/asinh]'
  i = i + 1
  h[i]  = '   [,/block] [,/align] [,/stretch] [,header=header]'
  i = i + 2
  h[i] = 'To overplot a contour plot on the draw window:'
  i = i + 1
  h[i] = '    phastcontour, array_name [, options...]'
  i = i + 1
  h[i] = 'To overplot text on the draw window: '
  i = i + 1
  h[i] = '    phastxyouts, x, y, text_string [, options]  (enclose string in single quotes)'
  i = i + 1
  h[i] = 'To overplot points or lines on the current plot:'
  i = i + 1
  h[i] = '    phastplot, xvector, yvector [, options]'
  i = i + 2
  h[i] = 'The options for phastcontour, phastxyouts, and phastplot are essentially'
  i = i + 1
  h[i] =  'the same as those for the idl contour, xyouts, and plot commands,'
  i = i + 1
  h[i] = 'except that data coordinates are always used.'
  i = i + 1
  h[i] = 'The default color for overplots is red.'
  i = i + 2
  h[i] = 'The lowest 8 entries in the color table are:'
  i = i + 1
  h[i] = '    0 = black'
  i = i + 1
  h[i] = '    1 = red'
  i = i + 1
  h[i] = '    2 = green'
  i = i + 1
  h[i] = '    3 = blue'
  i = i + 1
  h[i] = '    4 = cyan'
  i = i + 1
  h[i] = '    5 = magenta'
  i = i + 1
  h[i] = '    6 = yellow'
  i = i + 1
  h[i] = '    7 = white'
  i = i + 1
  h[i] = '    The top entry in the color table is also reserved for white. '
  i = i + 2
  h[i] = 'Other commands:'
  i = i + 1
  h[i] = 'phasterase [, N]:       erases all (or last N) plots and text'
  i = i + 1
  h[i] = 'phastclear: displays a small blank image (can be useful to clear memory)'
  i = i + 1
  h[i] = 'phast_activate: reanimates a frozen phast if another idl program crashes or hits a stop'
  i = i + 1
  h[i] = 'phast_shutdown:   quits phast'
  i = i + 2
  h[i] = 'NOTE: If phast should crash, type phast_shutdown at the idl prompt.'
  i = i + 3
  h[i] = strcompress('PHAST.PRO version '+state.version)
  i = i + 1
  
  
  if (not (xregistered('phast_help', /noshow))) then begin
  
    helptitle = strcompress('phast v' + state.version + ' help')
    
    help_base =  widget_base(group_leader = state.base_id, $
      /column, $
      /base_align_right, $
      title = helptitle, $
      uvalue = 'help_base')
      
    help_text = widget_text(help_base, $
      /scroll, $
      value = h, $
      xsize = 85, $
      ysize = 24)
      
    help_done = widget_button(help_base, $
      value = 'Done', $
      uvalue = 'help_done')
      
    widget_control, help_base, /realize
    xmanager, 'phast_help', help_base, /no_block
    
  endif
end

;----------------------------------------------------------------------

pro phast_help_event, event

  ;event handler for phast_help window

  widget_control, event.id, get_uvalue = uvalue
  
  case uvalue of
    'help_done': widget_control, event.top, /destroy
    else:
  endcase
end

;------------------------------------------------------------------

pro phast_loadregion

  ; Routine to read in region filename, store in a heap variable
  ; structure, and overplot the regions

  common phast_state
  common phast_pdata
  
  if (not(xregistered('phast', /noshow))) then begin
    print, 'You need to start PHAST first!'
    return
  endif
  
  region_file = dialog_pickfile(/read, filter='*.reg')
  if (region_file EQ '') then return
  
  if (nplot LT maxplot) then begin
    nplot = nplot + 1
    
    options = {color: 'green'}
    options.color = phast_icolor(options.color)
    
    readfmt, region_file, 'a200', reg_array, /silent
    
    pstruct = {type:'region', $            ; type of plot
      reg_array: reg_array, $     ; array of regions to plot
      options: options $          ; plot keyword options
      }
      
    plot_ptr[nplot] = ptr_new(pstruct)
    
    phast_plotwindow
    phast_plot1region, nplot
    
  endif else begin
    print, 'Too many calls to PHASTPLOT.'
  endelse
end

;----------------------------------------------------------------------

pro phast_saveregion

  ; Save currently displayed regions to a file

  common phast_state
  common phast_pdata
  
  reg_savefile = dialog_pickfile(file='phast.reg', filter='*.reg', /write)
  
  if (reg_savefile ne '') then begin
    openw, lun, reg_savefile, /get_lun
    
    for iplot = 1, nplot do begin
      if ((*(plot_ptr[iplot])).type eq 'region') then begin
        n_regions = n_elements((*(plot_ptr[iplot])).reg_array)
        for n = 0, n_regions - 1 do begin
          printf, lun, strcompress((*(plot_ptr[iplot])).reg_array[n])
        endfor
      endif
    endfor
    
    close, lun
    free_lun, lun
  endif else begin
    return
  endelse
end

;----------------------------------------------------------------------

pro phast_setasinh

  ; get the asinh beta parameter

  common phast_state
  
  b = string(state.asinh_beta)
  
  formline = strcompress('0,float,' + b + $
    ',label_left=Asinh beta parameter: ,width=10')
    
  formdesc = [formline, $
    '0, button, Set beta, quit', $
    '0, button, Cancel, quit']
    
  textform = cw_form(formdesc, ids=ids, /column, $
    title = 'phast asinh stretch settings')
    
  if (textform.tag2 EQ 1) then return
  
  state.asinh_beta = float(textform.tag0)
  
  phast_displayall
  
end

;----------------------------------------------------------------------

pro phast_other

;for compilation purposes only

compile_opt IDL2, hidden

end
