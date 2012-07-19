;-----------------------------------------------------------------

pro phast_trace, newcoord

;MUST BE FIRST IN FILE

  common phast_state
  common phast_images
  common phast_spectrum, traceinit, tracecenters, tracepoints, $
    xspec, fulltrace, spectrum
    
  if (keyword_set(newcoord) AND state.x_fixed EQ 0) then begin
    ; get new starting position from cursor
    xstart = state.x_tracestep > state.coord[0] < $
      (state.image_size[0] - state.x_tracestep)
    traceguess = ((state.x_traceheight / 2.)) > state.coord[1] < $
      (state.image_size[1] - (state.x_traceheight / 2.))
    traceinit = [xstart, traceguess]
    
    ;   if (state.x_xregion[1] GT (state.image_size[0]-1)) then $
    state.x_xregion = [0, state.image_size[0]-1]
    
    widget_control, state.x_xstart_id, $
      set_value = state.x_xregion[0]
    widget_control, state.x_xend_id, $
      set_value = state.x_xregion[1]
      
  endif else begin
    xstart = traceinit[0]
    traceguess = traceinit[1]
  endelse
  
  xsize = state.x_xregion[1] - state.x_xregion[0] + 1
  ysize = state.image_size[1]
  
  twidth = fix(state.x_tracestep / 2)
  ntracepoints = fix(xsize / state.x_tracestep)
  tracecenters = lindgen(ntracepoints) * state.x_tracestep + $
    fix(state.x_tracestep/2) + state.x_xregion[0]
  tracepoints = fltarr(ntracepoints)
  
  ; find the array element closest to the starting guess point
  m = min(abs(tracecenters-xstart), midtracepoint)
  
  ; peak up on the first trace point
  xtracestart = xstart - twidth
  xtraceend = xstart + twidth
  tracecutout = main_image[xtracestart:xtraceend, *]
  
  ymin = 1 > (traceguess - (state.x_traceheight / 2.))
  ymax = (traceguess + (state.x_traceheight / 2.)) < (ysize - 2)
  yslice = (total(tracecutout,1))[ymin:ymax]
  w = where(yslice EQ max(yslice), count)
  if (count EQ 1) then traceguess = traceguess - (state.x_traceheight/2.) + w
  
  ; trace from initial guess point to higher x
  for i = midtracepoint, ntracepoints-1 do begin
    xtracestart = tracecenters[i] - twidth
    xtraceend = tracecenters[i] + twidth
    
    tracecutout = main_image[xtracestart:xtraceend, *]
    yslice = total(tracecutout,1)
    
    ; replace NaNs when tracing to avert disaster
    w = where(finite(yslice) EQ 0, count)
    if (count GT 0) then yslice[w] = 0
    
    if (min(yslice) EQ max(yslice)) then begin
      ; if slice is blank, don't try to trace-- i.e. STIS image edges
      tracepoints[i] = traceguess
      ycen = traceguess
    endif else begin
      ycen = phast_get_tracepoint(yslice, traceguess)
      tracepoints[i] = ycen
    endelse
    
    ; set next guess, accounting for local slope of trace
    if (i EQ midtracepoint) then begin
      traceguess = ycen
    endif else begin
      traceguess = 1 > (ycen + (tracepoints[i] - tracepoints[i-1])/2) < $
        (ysize-1)
    endelse
    if (finite(traceguess) EQ 0) then traceguess = tracepoints[i-1]
    
    
  endfor
  
  traceguess = tracepoints[midtracepoint]
  
  ; now trace from initial guess point to lower x
  for i = midtracepoint-1, 0, -1 do begin
    xtracestart = tracecenters[i] - twidth
    xtraceend = tracecenters[i] + twidth
    
    tracecutout = main_image[xtracestart:xtraceend, *]
    yslice = total(tracecutout,1)
    
    w = where(finite(yslice) EQ 0, count)
    if (count GT 0) then yslice[w] = 0
    
    if (min(yslice) EQ max(yslice)) then begin
      tracepoints[i] = traceguess
      ycen = traceguess
    endif else begin
      ycen = phast_get_tracepoint(yslice, traceguess)
      tracepoints[i] = ycen
    endelse
    
    traceguess = 1 > (ycen - (tracepoints[i+1] - tracepoints[i])/2) < $
      (ysize-1)
    if (finite(traceguess) EQ 0) then traceguess = tracepoints[i+1]
    
  endfor
  
  result = poly_fit(double(tracecenters), tracepoints, $
    state.x_traceorder, yfit, /double)
    
  xspec = lindgen(xsize) + state.x_xregion[0]
  fulltrace = dblarr(xsize)
  for i = 0, state.x_traceorder do begin
    fulltrace = fulltrace + (result[i] * (double(xspec))^i)
  endfor
end

;------------------------------------------------------------------

pro phastextract, newcoord=newcoord

  common phast_state
  common phast_images
  common phast_spectrum
  
  
  if (state.image_size[0] LT 50) OR (state.image_size[1]) LT 20 $
    then return
    
  if (state.cube EQ 1) then return
  
  if (not (xregistered('phast_extract', /noshow))) then phastextract_init
  
  phasterase
  
  if (state.x_traceheight GT state.image_size[1]) then begin
    state.x_traceheight = state.image_size[1]
    widget_control, state.x_traceheight_id, set_value = state.x_traceheight
  endif
  
  if (state.x_fixed EQ 0) then phast_trace, newcoord
  
  phastplot, tracecenters, tracepoints, psym=1
  phastplot, xspec, fulltrace, color=3
  
  xsize = state.x_xregion[1] - state.x_xregion[0] + 1
  ysize = state.image_size[1]
  
  nxpoints = state.x_xupper - state.x_xlower
  
  spectrum = dblarr(xsize)
  
  for i = xspec[0], max(xspec) do begin
  
    j = i - xspec[0]
    ; error check to see if spectrum runs off the top or bottom of image
    if (((fulltrace[j] + state.x_back1) LT 0) or $
      ((fulltrace[j] + state.x_back4) GT ysize)) then begin
      
      spectrum[j] = 0
      
    endif else begin
      ; extract the spectrum accounting for partial pixels at the
      ; aperture edges.  ybottom and ytop are the upper and lower limits
      ; for full pixels in the extraction aperture.
      ytop = fix(fulltrace[j] + state.x_xupper - 0.5)
      ybottom = fix(fulltrace[j] + state.x_xlower + 0.5) + 1
      
      ; these are the fractions of a pixel
      ; at the upper and lower edges of the
      ; extraction aperture
      upperfraction = fulltrace[j] + state.x_xupper - 0.5 - ytop
      lowerfraction = 1.0 - upperfraction
      
      ; contribution from complete pixels in the extraction window
      signal = total(main_image[i, ybottom:ytop])
      
      ; add in fractional pixels at aperture edges
      uppersignal = upperfraction * main_image[i, ytop+1]
      lowersignal = lowerfraction * main_image[i, ybottom-1]
      
      signal = signal + uppersignal + lowersignal
      
      ; for the background, just use full pixels
      if (state.x_backsub EQ 1) then begin
        lowerback = median( main_image[i, $
          fulltrace[j]+state.x_back1: $
          fulltrace[j]+state.x_back2])
        upperback = median( main_image[i, $
          fulltrace[j]+state.x_back3: $
          fulltrace[j]+state.x_back4])
        meanback = mean([lowerback,upperback])
        background = meanback * float(nxpoints)
        
        signal = signal - background
      endif
      
      spectrum[j] = signal
      
    endelse
    
  endfor
  
  phastplot, xspec, fulltrace + state.x_xupper, color=6
  phastplot, xspec, fulltrace + state.x_xlower, color=6
  
  if (state.x_backsub EQ 1) then begin
    phastplot, xspec, fulltrace + state.x_back1, color=5
    phastplot, xspec, fulltrace + state.x_back2, color=5
    phastplot, xspec, fulltrace + state.x_back3, color=5
    phastplot, xspec, fulltrace + state.x_back4, color=5
  endif
  
  phast_specplot, /newcoord
end

;-------------------------------------------------------------------

pro phastextract_init

  ; initialize the extraction widget

  common phast_state
  
  ; reset the extraction region when starting up
  state.x_xregion = [0, state.image_size[0]-1]
  state.x_backsub = 1
  state.x_fixed = 0
  
  extract_base = widget_base(/base_align_left, $
    group_leader = state.base_id, $
    /column, $
    title = 'phast spectral extraction', $
    uvalue = 'extract_base')
    
  trace_id = widget_base(extract_base, /row, /base_align_left)
  
  state.x_tracestep_id = cw_field(trace_id, /long, /return_events, $
    title = 'Trace step:', $
    uvalue = 'tracestep', $
    value = state.x_tracestep, $
    xsize = 5)
    
  state.x_traceheight_id = cw_field(trace_id, /long, /return_events, $
    title = 'Trace height:', $
    uvalue = 'traceheight', $
    value = state.x_traceheight, $
    xsize = 5)
    
  state.x_traceorder_id = cw_field(extract_base, /long, /return_events, $
    title = 'Trace fit order:', $
    uvalue = 'traceorder', $
    value = state.x_traceorder, $
    xsize = 5)
    
  xregion_base = widget_base(extract_base, /row, /base_align_left)
  
  state.x_xregion = [0, state.image_size[0]-1]
  
  state.x_xstart_id = cw_field(xregion_base, /long, /return_events, $
    title = 'Extraction start:', $
    uvalue = 'xstart', $
    value = state.x_xregion[0], $
    xsize = 5)
    
  state.x_xend_id = cw_field(xregion_base, /long, /return_events, $
    title = 'end:', $
    uvalue = 'xend', $
    value = state.x_xregion[1], $
    xsize = 5)
    
  xwidth_base = widget_base(extract_base, /row, /base_align_left)
  
  state.x_xlower_id = cw_field(xwidth_base, /long, /return_events, $
    title = 'Extraction width lower:', $
    uvalue = 'lower', $
    value = state.x_xlower, $
    xsize = 5)
    
  state.x_xupper_id = cw_field(xwidth_base, /long, /return_events, $
    title = 'upper:', $
    uvalue = 'upper', $
    value = state.x_xupper, $
    xsize = 5)
    
  x_backsub = cw_bgroup(extract_base, ['on', 'off'], $\
  uvalue = 'backsub', $
    button_uvalue = ['on', 'off'], $
    /exclusive, set_value = 0, $
    label_left = 'Background subtraction: ', $
    /no_release, $
    /row)
    
  xbacka_base = widget_base(extract_base, /row, /base_align_left)
  
  state.x_back1_id = cw_field(xbacka_base, /long, /return_events, $
    title = 'Lower background region:', $
    uvalue = 'back1', $
    value = state.x_back1, $
    xsize = 5)
    
  state.x_back2_id = cw_field(xbacka_base, /long, /return_events, $
    title = 'to', $
    uvalue = 'back2', $
    value = state.x_back2, $
    xsize = 5)
    
  xbackb_base = widget_base(extract_base, /row, /base_align_left)
  
  state.x_back3_id = cw_field(xbackb_base, /long, /return_events, $
    title = 'Upper background region:', $
    uvalue = 'back3', $
    value = state.x_back3, $
    xsize = 5)
    
  state.x_back4_id = cw_field(xbackb_base, /long, /return_events, $
    title = 'to', $
    uvalue = 'back4', $
    value = state.x_back4, $
    xsize = 5)
    
  x_fixbutton = cw_bgroup(extract_base, ['Toggle parameter hold'], $\
  uvalue = 'fixed', $
    /no_release, $
    /row)
    
  x_writespectbutton = cw_bgroup(extract_base, $
    ['Write spectrum as FITS', $
    'Write spectrum as text'], $
    uvalue = 'writespect', $
    button_uvalue = ['fits', 'text'], $
    /no_release, /row)
    
  extract_done = $
    widget_button(extract_base, $
    value = 'Done', $
    uvalue = 'extract_done')
    
  widget_control, extract_base, /realize
  xmanager, 'phast_extract', extract_base, /no_block
  phast_resetwindow
end

;-------------------------------------------------------------------------

pro phast_extract_event, event

  common phast_state
  
  widget_control, event.id, get_uvalue = uvalue
  
  case uvalue of
  
    'tracestep': begin
      state.x_tracestep = 1 > event.value < 101
      if NOT(long(state.x_tracestep)/2 ne state.x_tracestep/2.0) then $
        state.x_tracestep = state.x_tracestep + 1
      widget_control, state.x_tracestep_id, $
        set_value = state.x_tracestep
      phastextract
    end
    
    'traceheight': begin
      state.x_traceheight = 3 > event.value < 101
      state.x_traceheight = state.x_traceheight < state.image_size[1]
      widget_control, state.x_traceheight_id, $
        set_value = state.x_traceheight
      phastextract
    end
    
    'traceorder': begin
      state.x_traceorder = 0 > event.value < 10
      widget_control, state.x_traceorder_id, $
        set_value = state.x_traceorder
      phastextract
    end
    
    'xstart': begin
      state.x_xregion[0] = 0 > event.value < (state.x_xregion[1] - 50)
      widget_control, state.x_xstart_id, $
        set_value = state.x_xregion[0]
      phastextract
    end
    
    'xend': begin
      state.x_xregion[1] = (state.x_xregion[0] + 50) > event.value < $
        (state.image_size[0] - 1)
      widget_control, state.x_xend_id, $
        set_value = state.x_xregion[1]
      phastextract
    end
    
    'lower': begin
      state.x_xlower = event.value < (state.x_xupper - 2)
      if (state.x_xlower LT state.x_back2) then $
        state.x_xlower = state.x_back2 + 1
      widget_control, state.x_xlower_id, $
        set_value = state.x_xlower
      phastextract
    end
    
    'upper': begin
      state.x_xupper = (state.x_xlower + 2) > event.value
      if (state.x_xupper GT state.x_back3) then $
        state.x_xupper = state.x_back3 - 1
      widget_control, state.x_xupper_id, $
        set_value = state.x_xupper
      phastextract
    end
    
    'backsub': begin
      if (event.value EQ 'on') then state.x_backsub = 1 $
      else state.x_backsub = 0
      phastextract
    end
    
    'back1': begin
      state.x_back1 = (-0.5 * state.image_size[1]) > event.value < $
        (state.x_back2 - 1)
      widget_control, state.x_back1_id, $
        set_value = state.x_back1
      phastextract
    end
    
    'back2': begin
      state.x_back2 = (state.x_back1 + 1) > event.value < (state.x_xlower - 1)
      widget_control, state.x_back2_id, $
        set_value = state.x_back2
      phastextract
    end
    
    'back3': begin
      state.x_back3 = (state.x_xupper + 1) > event.value < (state.x_back4 - 1)
      widget_control, state.x_back3_id, $
        set_value = state.x_back3
      phastextract
    end
    
    'back4': begin
      state.x_back4 = (state.x_back3 + 1) > event.value < $
        (0.5 * state.image_size[1])
      widget_control, state.x_back4_id, $
        set_value = state.x_back4
      phastextract
    end
    
    'fixed': begin
      if (state.x_fixed EQ 1) then begin
        widget_control, state.x_tracestep_id, sensitive=1
        widget_control, state.x_traceheight_id, sensitive=1
        widget_control, state.x_traceorder_id, sensitive=1
        widget_control, state.x_xstart_id, sensitive=1
        widget_control, state.x_xend_id, sensitive=1
        widget_control, state.x_xlower_id, sensitive=1
        widget_control, state.x_xupper_id, sensitive=1
        widget_control, state.x_back1_id, sensitive=1
        widget_control, state.x_back2_id, sensitive=1
        widget_control, state.x_back3_id, sensitive=1
        widget_control, state.x_back4_id, sensitive=1
        state.x_fixed = 0
      endif else begin
        widget_control, state.x_tracestep_id, sensitive=0
        widget_control, state.x_traceheight_id, sensitive=0
        widget_control, state.x_traceorder_id, sensitive=0
        widget_control, state.x_xstart_id, sensitive=0
        widget_control, state.x_xend_id, sensitive=0
        widget_control, state.x_xlower_id, sensitive=0
        widget_control, state.x_xupper_id, sensitive=0
        widget_control, state.x_back1_id, sensitive=0
        widget_control, state.x_back2_id, sensitive=0
        widget_control, state.x_back3_id, sensitive=0
        widget_control, state.x_back4_id, sensitive=0
        state.x_fixed = 1
      endelse
    end
    
    'writespect': begin
      if (event.value EQ 'fits') then begin
        phast_writespecfits
      endif else begin
        phast_writespectext
      endelse
    end
    
    'extract_done': widget_control, event.top, /destroy
    else:
  endcase
end

;---------------------------------------------------------------------

function phast_get_tracepoint, yslice, traceguess

    
  ; find the trace points by simple centroiding after subtracting off
  ; the background level.  iterate up to maxrep times to fine-tune the
  ; centroid position.

  common phast_state
   
  ysize = n_elements(yslice)
  yvec = indgen(ysize)
  
  icounter = 0L
  ycen = traceguess
  maxrep = 10
  ; convergence criterion for accepting centroid: change in pixels from
  ; previous iteration smaller than mindelta
  mindelta = 0.2
  
  repeat begin
    lastycen = ycen
    icounter = icounter + 1
    
    ylow = round(lastycen - (state.x_traceheight / 2.)) > 0
    yhigh = round(lastycen + (state.x_traceheight / 2.)) < (ysize-1)
    
    smallslice = yslice[ylow:yhigh]
    minyslice = min(smallslice)
    smallslice = smallslice - minyslice
    
    ycen = total( float((yvec * (yslice - minyslice))[ylow:yhigh])) / $
      float(total(smallslice))
      
    ; check for major failures from pathological images
    if (finite(ycen) EQ 0) then ycen = lastycen
    
    deltat = ycen - lastycen
    
  endrep until ((abs(deltat) LT mindelta) OR (icounter GE maxrep))
  
  ; check again for major failures
  if (ycen LT ylow OR ycen GT yhigh) then ycen = traceguess
  if (finite(ycen) EQ 0) then ycen = traceguess
  
  return, ycen
end

;-----------------------------------------------------------------

pro phast_specplot, ps=ps, fullrange=fullrange, newcoord=newcoord

  ; draws a new row plot in the plot window or to postscript output

  common phast_state
  common phast_images
  common phast_spectrum
  
  if (keyword_set(ps)) then begin
    thick = 3
    color = 0
  endif else begin
    thick = 1
    color = 7
  endelse
  
  if (keyword_set(newcoord)) then newcoord = 1 else newcoord = 0
  
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
    
    if (newplot EQ 1 OR state.plot_type NE 'specplot' OR $
      keyword_set(fullrange) OR $
      ((state.holdrange_value EQ 0) AND newcoord EQ 1)) then begin
      xmin = min(xspec)
      xmax = max(xspec)
      ymin = min(spectrum)
      ymax = max(spectrum)
    endif
    
    widget_control, state.lineplot_xmin_id, set_value=xmin
    widget_control, state.lineplot_xmax_id, set_value=xmax
    widget_control, state.lineplot_ymin_id, set_value=ymin
    widget_control, state.lineplot_ymax_id, set_value=ymax
    
    state.lineplot_xmin = xmin
    state.lineplot_xmax = xmax
    state.lineplot_ymin = ymin
    state.lineplot_ymax = ymax
    
    state.plot_type = 'specplot'
    phast_setwindow, state.lineplot_window_id
    erase
    
  endif
  
  plot, xspec, spectrum, $
    xst = 3, yst = 3, psym = 10, $
    title = strcompress('Extracted Spectrum'), $
    
    xtitle = 'Column', $
    ytitle = 'Counts', $
    color = color, xmargin=[15,3], $
    xran = [state.lineplot_xmin, state.lineplot_xmax], $
    yran = [state.lineplot_ymin, state.lineplot_ymax], $
    thick = thick, xthick = thick, ythick = thick, charthick = thick
    
    
  if (not (keyword_set(ps))) then begin
    widget_control, state.lineplot_base_id, /clear_events
    phast_resetwindow
  endif
end

;-----------------------------------------------------------------

pro phast_writespecfits

  common phast_state
  common phast_spectrum
  
  filename = dialog_pickfile(group=state.base_id, $
    filter = '*.fits', $
    file = 'phastspectrum.fits', $
    default_extension = '.fits', $
    /write, $
    /overwrite_prompt, $
    path = state.current_dir, $
    get_path = tmp_dir, $
    title = 'Write FITS Spectrum')
  if (tmp_dir NE '') then state.current_dir = tmp_dir
  if (filename EQ '') then return
  
  
  if (ptr_valid(state.head_ptr)) then begin
    outheader = *(state.head_ptr)
    ; keep wavelength scale from STIS if available  EDITED TO REMOVE /silent
    cd = double(sxpar(*state.head_ptr,'CD1_1'));, /silent))
    crpix = double(sxpar(*state.head_ptr,'CRPIX1'));, /silent))
    crval = double(sxpar(*state.head_ptr,'CRVAL1'));, /silent))
    shifta = double(sxpar(*state.head_ptr, 'SHIFTA1'));, /silent))
    
    sxdelpar, outheader, 'CD1_1'
    sxdelpar, outheader, 'CRPIX1'
    sxdelpar, outheader, 'CRVAL1'
    sxdelpar, outheader, 'SHIFTA1'
  endif else begin
    cd = 0
    crpix = 0
    crval = 0
    shifta = 0
  endelse
  
  if (crval NE 0) AND (cd NE 0) then begin
    ; get wavelength scale, accounting for extraction start and end
    wavelength = crval + ((dindgen(state.image_size[0]) - crpix) * cd) + $
      (shifta * cd)
    wavelength = wavelength[state.x_xregion[0]:state.x_xregion[1]]
  endif else begin
    wavelength = xspec
  endelse
  
  ; note, this works for linear wavelength scales only
  cd = wavelength[1] - wavelength[0]
  crval = wavelength[0]
  
  if (ptr_valid(state.head_ptr)) then begin
    sxaddpar, outheader, 'CRVAL1', crval
    sxaddpar, outheader, 'CD1_1', cd
    writefits, filename, spectrum, outheader
  endif else begin
    writefits, filename, spectrum
    spectrum = readfits(filename, outheader)
    sxaddpar, outheader, 'CRVAL1', crval
    sxaddpar, outheader, 'CD1_1', cd
    writefits, filename, spectrum, outheader
  endelse
end

;------------------------------------------------------------------

pro phast_writespectext

  common phast_state
  common phast_spectrum
  
  filename = dialog_pickfile(group=state.base_id, $
    /write, $
    file = 'phastspectrum.txt', $
    /overwrite_prompt, $
    path = state.current_dir, $
    get_path = tmp_dir, $
    title = 'Write Text Spectrum')
  if (tmp_dir NE '') then state.current_dir = tmp_dir
  if (filename EQ '') then return
  
  if (ptr_valid(state.head_ptr)) then begin
    ; keep wavelength scale from STIS if available  EDITED TO REMOVE /silent
    cd = double(sxpar(*state.head_ptr,'CD1_1'));, /silent))
    crpix = double(sxpar(*state.head_ptr,'CRPIX1'));, /silent))
    crval = double(sxpar(*state.head_ptr,'CRVAL1'));, /silent))
    shifta = double(sxpar(*state.head_ptr, 'SHIFTA1'));, /silent))
  endif else begin
    cd = 0
    crpix = 0
    crval = 0
    shifta = 0
  endelse
  
  if (crval NE 0) AND (cd NE 0) then begin
    ; get wavelength scale, accounting for extraction start and end
    wavelength = crval + ((dindgen(state.image_size[0]) - crpix) * cd) + $
      (shifta * cd)
    wavelength = wavelength[state.x_xregion[0]:state.x_xregion[1]]
  endif else begin
    wavelength = xspec
  endelse
  
  openw, unit0, filename, /get_lun
  
  for i = 0L, n_elements(xspec)-1 do begin
    printf, unit0, wavelength[i], spectrum[i]
  endfor
  
  close, unit0
  free_lun, unit0
end

;------------------------------------------------------------------

pro phast_spectra

;for compilation purposes only

end
