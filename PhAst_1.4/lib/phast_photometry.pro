;------------------------------------------------------

pro phast_apphot

  ; aperture photometry front end

  common phast_state
  common phast_images
  common phast_filters
  
  offset = [0,0]
  if state.align_toggle eq 1 then offset = phast_get_image_offset()
  
  state.cursorpos = state.coord - offset
   ;update the exposure length and zero-point from image header
  if state.num_images gt 0 and state.image_type eq 'FITS' then begin
    ;head = headfits(state.imagename)
     head = image_archive[state.current_image_index]->get_header(/string)
     state.exptime   = sxpar(head,'EXPTIME')
     state.posFilter = sxpar(head,filters.fitsKey)
     state.photzpt   = sxpar(head,'MAGZERO',count=count)
     state.photzerr  = sxpar(head,'MAGZERR')
     state.photzbnd  = sxpar(head,'MAGZBND')
     state.photzclr  = sxpar(head,'MAGZCLR')
     state.photztrm  = sxpar(head,'MAGZTRM')
     state.photznum  = sxpar(head,'MAGZNUM')
                                ; zeropoint pre-determined by user; or
                                ; instrumental if no zeropoint
     if filters.doZeroPt[state.posFilter] EQ 0 then begin
        state.photzpt  = filters.Zeropoint[state.posFilter]
        state.photzerr = filters.errZeroPt[state.posFilter]
        state.photzbnd = filters.nameFilter[state.posFilter]
        state.photzclr =  0.0
        state.photztrm =  '   '
        state.photznum =  0
     endif
     if count EQ 0 then begin
        state.photzpt  = 0.0
        state.photzerr = 0.0
        state.photzbnd = 'Instr'
        state.photzclr =  0.0
        state.photztrm =  '   '
        state.photznum =  0
     endif
  endif
  
  if strlowcase(state.photzbnd) EQ 'instr' and state.magtype GT 0 then begin
    state.magtype = 0
    phast_message, 'Instrumental magnitudes will be used until a zeropoint is determined', $
      window = 1, msgtype = 'warning'
  endif
  
  if (not (xregistered('phast_apphot', /noshow))) then begin

     apphot_base = $
        widget_base(/base_align_center, $
                    group_leader = state.base_id, $
                    /column,$;xoffset=state.draw_window_size[0]+300, $
                    title = 'phast aperture photometry', $
                    uvalue = 'apphot_base')
     
     apphot_row_1     = widget_base(apphot_base,/row,/base_align_center)
     apphot_insert1   = widget_base(apphot_base,/row,/base_align_center)
     apphot_insert2   = widget_base(apphot_base,/row,/base_align_center)
     apphot_row_2     = widget_base(apphot_base,/row,/base_align_center)
     apphot_draw_base = widget_base(apphot_base,/row,/base_align_center, frame=0)
     
     apphot_data_base1a  = widget_base(apphot_row_1, /column, frame=4,xsize=240,ysize=200, /base_align_left)
     apphot_plot_base    = widget_base(apphot_row_1, /column, frame=4,xsize=240,ysize=200, /base_align_center)
     
     apphot_data_insert1 = widget_base(apphot_insert1,/row,   frame=4,xsize=492,ysize= 50, /base_align_center)
     apphot_data_insert2 = widget_base(apphot_insert2,/row,   frame=4,xsize=492,ysize= 50, /base_align_center)
     
     apphot_data_base1   = widget_base(apphot_row_2, /column, frame=4,xsize=240,ysize=130, /base_align_center)
     apphot_data_base2   = widget_base(apphot_row_2, /column, frame=4,xsize=240,ysize=130 ,/base_align_center)
     
                                ; populate apphot_data_base1a
     tmp_string1 = string(99999.0, 99999.0, format = '("Object position: (",f7.1,", ",f7.1,")")')
     state.centerpos_id  = widget_label(apphot_data_base1a, value = tmp_string1, uvalue = 'centerpos', /align_center)
     
     state.apphot_wcs_id = widget_label(apphot_data_base1a, value='--- No WCS Info ---', /align_center, /dynamic_resize)
     
     state.centerbox_id = $
        cw_field(apphot_data_base1a, $
                 /long, $
                 /return_events, $
                 title = 'Centering box size (pix):', $
                 uvalue = 'centerbox', $
                 value = state.centerboxsize, $
                 xsize = 7)
     
     state.radius_id = $
        cw_field(apphot_data_base1a, $
                 /floating, $
                 /return_events, $
                 title = '   Aperture radius (pix):', $
                 uvalue = 'radius', $
                 value = state.aprad, $
                 xsize = 7)
     
     state.innersky_id = $
        cw_field(apphot_data_base1a, $
                 /floating, $
                 /return_events, $
                 title = '  Inner sky radius (pix):', $
                 uvalue = 'innersky', $
                 value = state.innersky, $
                 xsize = 7)
     
     state.outersky_id = $
        cw_field(apphot_data_base1a, $
                 /floating, $
                 /return_events, $
                 title = '  Outer sky radius (pix):', $
                 uvalue = 'outersky', $
                 value = state.outersky, $
                 xsize = 7)
     
                                ; populate apphot_data_insert1
     if state.magunits EQ 1 then state.phot_aperFWHM = round(100*state.objFWHM)/100.0                       $
     else state.phot_aperFWHM = round(100*state.objFWHM * state.pixelscale)/100.0
     
     state.phot_aperFWHM_ID  = cw_field(apphot_data_insert1, /floating, /return_events, uvalue = 'aperFWHM', $
                                        value = state.phot_aperFWHM, title='Apertures:   FWHM', xsize = 4, /row)
     
     state.phot_aperUnit_ID  = cw_field(apphot_data_insert1, /string, uvalue = 'aperUnit', $
                                        value = state.phot_aperList[state.magunits], title='', xsize = 2, /row)
     
     
     state.phot_aperTrain_ID = widget_button(apphot_data_insert1, value = 'Train', uvalue = 'aperTrain', xsize=50)
     
     state.phot_aperType_ID  = cw_bgroup(apphot_data_insert1, ['Snap To', 'Centroid', 'Manual'], uvalue = 'aperType', $
                                         button_uvalue = [0, 1, 2], set_value = 0, label_left = '', $
                                         /exclusive, /no_release, /row)
     
                                ; populate apphot_data_insert2
     photSpecTypeNum = where( state.photSpecList eq state.photSpecType, count )
     if count eq 0 then begin
        state.photSpecType = 'K'
        photSpecTypeNum = where( state.photSpecList eq state.photSpecType, count )
     endif
     state.photSpecTypeNum = (0 > photSpecTypeNum[0]) < 9
     state.photSpec_Type_ID = cw_bgroup(apphot_data_insert2, state.photSpecList, uvalue = 'spectralLtr',  $
                                        button_uvalue = state.photSpecList,                              $
                                        /exclusive, set_value = state.photSpecTypeNum,                   $
                                        /no_release,                                                     $
                                        /row)
     
     state.photSpecSubNum = (0 > state.photSpecSubNum) < 9
     state.photSpec_Num_ID  = cw_field(apphot_data_insert2, /long, /return_events, uvalue = 'spectralNum', $
                                       value = state.photSpecSubNum, title='', xsize = 1, /row)
     
     colors = phast_intrinsic_colors(state.photSpecTypeNum, state.photSpecSubNum)
     state.photSpecBmV = colors[0]
     state.photSpecVmR = colors[1]
     state.photSpecRmI = colors[2]
     
     state.photSpec_BmV_ID  = cw_field(apphot_data_insert2, /floating, /return_events, uvalue = 'spectralBmV', $
                                       value = state.photSpecBmV, title='B-V', xsize = 4, /row)
     
     state.photSpec_VmR_ID  = cw_field(apphot_data_insert2, /floating, /return_events, uvalue = 'spectralVmR', $
                                       value = state.photSpecVmR, title='V-R', xsize = 4, /row)
     
     state.photSpec_RmI_ID  = cw_field(apphot_data_insert2, /floating, /return_events, uvalue = 'spectralRmI', $
                                       value = state.photSpecRmI, title='R-I', xsize = 4, /row)
     
     
                                ; populate apphot_data_base1
     apphot_cycle_base = widget_base(apphot_data_base1,/row)
     
     phot_cycle_left   = widget_button(apphot_cycle_base, value=' <---- ',  uvalue='cycle_left')
     phot_cycle_right  = widget_button(apphot_cycle_base, value=' ----> ',  uvalue='cycle_right')
     do_all            = widget_button(apphot_cycle_base, value=' Do all ', uvalue='do_all')
     
     photsettings_id   = widget_button(apphot_data_base1, value = 'Photometry settings ...', $
                                       uvalue = 'photsettings', xsize=175)
     
     if (state.photprint EQ 0) then begin
        photstring = 'Write results to file ...'
     endif else begin
        photstring = 'Close photometry file'
     endelse
     
     state.photprint_id   = widget_button(apphot_data_base1, value = photstring, $
                                          uvalue = 'photprint', xsize=175)
     
     state.showradplot_id = widget_button(apphot_data_base1, value = 'Show radial profile', $
                                          uvalue = 'showradplot', xsize=175)
     
     state.radplot_widget_id = widget_draw(apphot_draw_base, scr_xsize=1, scr_ysize=1)
     
     if state.phot_rad_plot_open eq 1 then begin
        ysize = 300 < (state.screen_ysize - 300)
        widget_control, state.radplot_widget_id, xsize=500, ysize=ysize
        widget_control, state.showradplot_id, set_value='Hide radial profile' 
     endif else begin
        widget_control, state.radplot_widget_id, xsize=500, ysize=1
        widget_control, state.showradplot_id, set_value='Show radial profile'
     endelse
     
     photzoom_widget_id = widget_draw(apphot_plot_base, scr_xsize=state.photzoom_size, scr_ysize=state.photzoom_size)
     
                                ; populate apphot_data_base2
     fldmask = 'XXXXXXXXX: XX.XX X X.XX | XXXXX: XX.XX'
     
     state.photwarning_id = widget_label(apphot_data_base2, value=fldmask, /dynamic_resize)
     
     state.objfwhm_id = widget_label(apphot_data_base2, value=fldmask, uvalue='fwhm', /align_left) ; FWHM / SNR
     
     state.photresult_id = widget_label(apphot_data_base2, value = fldmask, uvalue = 'photresult', /align_left) ; Obj Mag +/- err
     
     state.skyresult_id  = widget_label(apphot_data_base2, value = fldmask, uvalue = 'skyresult', /align_left) ; Sky Bkg +/- err
     
     state.photerror_id  = widget_label(apphot_data_base2, value = fldmask, uvalue = 'photerror', /align_left) ; Inst Prec / Limit Mag
     
     apphot_done = widget_button(apphot_data_base2, value = 'Done', uvalue = 'apphot_done')
     
     widget_control, apphot_base,/realize
     
     widget_control, photzoom_widget_id, get_value=tmp_value
     state.photzoom_window_id = tmp_value
     
     widget_control, state.radplot_widget_id, get_value=tmp_value
     state.radplot_window_id = tmp_value
     
     xmanager, 'phast_apphot', apphot_base, /no_block
     
     phast_resetwindow
  endif
  
  phast_apphot_refresh
end

;----------------------------------------------------------------------

pro phast_apphot_event, event

;processes user interactions with the point-click photometry GUI

  common phast_state
  common phast_images
  
  widget_control, event.id, get_uvalue = uvalue
  
  case uvalue of
  
    'centerbox': begin
      if (event.value EQ 0) then begin
        state.centerboxsize = 0
      endif else begin
        state.centerboxsize = long(event.value) > 3
        if ( (state.centerboxsize / 2 ) EQ $
          round(state.centerboxsize / 2.)) then $
          state.centerboxsize = state.centerboxsize + 1
      endelse
      phast_apphot_refresh
    end
    
    'radius': begin
      state.aprad = 1.0 > event.value < state.innersky
      phast_apphot_refresh
    end
    
    'innersky': begin
      state.innersky = state.aprad > event.value < (state.outersky - 1)
      state.innersky = 2 > state.innersky
      if (state.outersky EQ state.innersky + 1) then $
        state.outersky = state.outersky + 1
      phast_apphot_refresh
    end
    
    'outersky': begin
      state.outersky = event.value > (state.innersky + 2)
      phast_apphot_refresh
    end
    
    'aperType': begin
      state.phot_aperType = event.value
      phast_apphot_refresh
    end
    
    'aperFWHM': begin
      if state.magunits EQ 0 then aperFWHM = round(100*event.value)/100.0 $
      else aperFWHM = round(100*event.value/state.pixelScale)/100.0
      state.phot_aperFWHM = aperFWHM
      phast_setAps, state.phot_aperFWHM, 0
      phast_apphot_refresh
    end
    
    'aperTrain': begin
      state.phot_aperFWHM = round(100*state.objfwhm)/100.0
      phast_setAps, state.objfwhm, 0
      phast_apphot_refresh
    end
    
    'spectralLtr': begin
      state.photSpecType = event.value
      state.photSpecTypeNum = where( state.photSpecList eq state.photSpecType, count )
      colors = phast_intrinsic_colors(state.photSpecTypeNum, state.photSpecSubNum)
      state.photSpecBmV = colors[0] & widget_control, state.photSpec_BmV_ID, set_value=state.photSpecBmV
      state.photSpecVmR = colors[1] & widget_control, state.photSpec_VmR_ID, set_value=state.photSpecVmR
      state.photSpecRmI = colors[2] & widget_control, state.photSpec_RmI_ID, set_value=state.photSpecRmI
    end
    
    'spectralNum': begin
      state.photSpecSubNum = (0 > event.value) < 9
      widget_control, state.photSpec_Num_ID, set_value=state.photSpecSubNum
      colors = phast_intrinsic_colors(state.photSpecTypeNum, state.photSpecSubNum)
      state.photSpecBmV = colors[0] & widget_control, state.photSpec_BmV_ID, set_value=state.photSpecBmV
      state.photSpecVmR = colors[1] & widget_control, state.photSpec_VmR_ID, set_value=state.photSpecVmR
      state.photSpecRmI = colors[2] & widget_control, state.photSpec_RmI_ID, set_value=state.photSpecRmI
    end
    
    'spectralBmV': begin
      state.photSpecBmV = event.value
      widget_control, state.photSpec_BmV_ID, set_value=state.photSpecBmV
    end
    
    'spectralVmR': begin
      state.photSpecVmR = event.value
      widget_control, state.photSpec_VmR_ID, set_value=state.photSpecVmR
    end
    
    'spectralRmI': begin
      state.photSpecRmI = event.value
      widget_control, state.photSpec_RmI_ID, set_value=state.photSpecRmI
    end
    
    'showradplot': begin
      widget_control, state.showradplot_id, get_value=val
      
      case val of
        'Show radial profile': begin
          ysize = 350 < (state.screen_ysize - 350)
          widget_control, state.radplot_widget_id, $
            xsize=500, ysize=ysize
          widget_control, state.showradplot_id, $
            set_value='Hide radial profile'
        end
        'Hide radial profile': begin
          widget_control, state.radplot_widget_id, $
            xsize=1, ysize=1
          widget_control, state.showradplot_id, $
            set_value='Show radial profile'
        end
      endcase
      phast_apphot_refresh
    end
    
    'photprint': begin
      if (state.photprint EQ 0) then begin
      
        photfilename = dialog_pickfile(file = state.photfilename, $
          dialog_parent =  state.base_id, $
          path = state.current_dir, $
          get_path = tmp_dir, $
          /write)
          
        if (photfilename EQ '') then return
        
        ; write header to output file
        openw, photfile, photfilename, /get_lun
        state.photfile = photfile
        if (state.magunits EQ 0) then begin
          photstring1 = '   x        y      r  insky outsky      sky         counts        err     fwhm'
        endif else begin
          photstring1 = '   x        y      r  insky outsky      sky          mag          err     fwhm'
        endelse
        photstring2 = '------------------------------------------------------------------------------'
        printf, state.photfile, ' '
        printf, state.photfile, photstring1
        printf, state.photfile, photstring2
        printf, state.photfile, ' '
        close, state.photfile
        
        state.photprint = 1
        widget_control, state.photprint_id, $
          set_value = 'Close photometry file'
          
      endif else begin
        free_lun, state.photfile
        state.photprint = 0
        widget_control, state.photprint_id, $
          set_value = 'Write results to file...'
      endelse
    end
    
    'photsettings': phast_apphot_settings
    
    'apphot_done': widget_control, event.top, /destroy
    
    'cycle_left': begin
      widget_control,/hourglass
      phast_cycle_images,-1
      phast_apphot_refresh
    end
    'cycle_right': begin
      widget_control,/hourglass
      phast_cycle_images,1
      phast_apphot_refresh
    end
    'do_all': begin
      widget_control,/hourglass
      phast_image_switch,0
      phast_apphot_refresh
      for i=1,state.num_images-1 do begin
        phast_cycle_images,1
        phast_apphot_refresh
      endfor
    end
    else:
  endcase
end

;-----------------------------------------------------------------------

pro phast_apphot_refresh

  ; Do aperture photometry using idlastro daophot routines.

  common phast_state
  common phast_filters
  common phast_images
  common phast_mpc_data
  
  state.photwarning = 'Warnings: None'
  
  ; Center apertures on the object
  if (state.phot_aperType EQ 0 And state.centerboxsize NE 0) then phast_imcenterf, x, y ; snap to peak
  if (state.phot_aperType EQ 1 And state.centerboxsize NE 0) then begin ; centroid the flux
    x = state.cursorpos[0]
    y = state.cursorpos[1]
    for ipass = 1, 2 do begin
      phast_imcenterg, main_image, x, y, state.innersky, [state.innersky, state.outersky], [0, 65535], xcentroid, ycentroid
      x = xcentroid
      y = ycentroid
    endfor
  endif
  if (state.phot_aperType EQ 2 Or state.centerboxsize EQ 0) then begin ; use cursor position
    x = state.cursorpos[0]
    y = state.cursorpos[1]
  endif
  state.centerpos = [x, y]
  
  ; Make sure that object position is on the image
  x = 0 > x < (state.image_size[0] - 1)
  y = 0 > y < (state.image_size[1] - 1)
  
  if ((x - state.outersky) LT 0)                           OR $
    ((x + state.outersky) GT (state.image_size[0] - 1))   OR $
    ((y - state.outersky) LT 0)                           OR $
    ((y + state.outersky) GT (state.image_size[1] - 1)) then $
    state.photwarning = 'Warning: Sky apertures fall outside image!'
    
  ; Condition to test whether phot aperture is off the image
  if (x LT state.aprad)                          OR $
    ((state.image_size[0] - x) LT state.aprad)  OR $
    (y LT state.aprad)                          OR $
    ((state.image_size[1] - y) LT state.aprad) then begin
    flux = !values.F_NAN
    state.photwarning = 'Warning: Aperture Outside Image Border!'
  endif
  
  ; make sure there aren't NaN values in the apertures.
  minx =                    0 > (x - state.outersky)
  maxx = (x + state.outersky) < (state.image_size[0] - 1)
  miny =                    0 > (y - state.outersky)
  maxy = (y + state.outersky) < (state.image_size[1] - 1)
  
  subimg = main_image[minx:maxx, miny:maxy]
  if (finite(mean(subimg)) EQ 0) then begin
    phast_message, 'Sorry- PHAST can not do photometry on regions containing NaN values.', $
      /window, msgtype = 'error'
    return
  endif
  
  ; Assume that all pixel values are good data
  badpix = [state.image_min-1, state.image_max+1]
  
  if (state.skytype EQ 1) then begin    ; calculate median sky value
    xmin =              (x - state.outersky) > 0
    xmax = (xmin + (2 * state.outersky + 1)) < (state.image_size[0] - 1)
    ymin =              (y - state.outersky) > 0
    ymax = (ymin + (2 * state.outersky + 1)) < (state.image_size[1] - 1)
    
    small_image = main_image[xmin:xmax, ymin:ymax]
    nx = (size(small_image))[1]
    ny = (size(small_image))[2]
    i = lindgen(nx)#(lonarr(ny)+1)
    j = (lonarr(nx)+1)#lindgen(ny)
    xc = x - xmin
    yc = y - ymin
    
    w = where( (((i - xc)^2 + (j - yc)^2) GE state.innersky^2) AND $
      (((i - xc)^2 + (j - yc)^2) LE state.outersky^2), nw )
      
    if ((x - state.outersky) LT 0)                           OR $
       ((x + state.outersky) GT (state.image_size[0] - 1))   OR $
       ((y - state.outersky) LT 0)                           OR $
       ((y + state.outersky) GT (state.image_size[1] - 1)) then $
       state.photwarning = 'Warning: Sky apertures fall outside image!'
      
    if (nw GT 0) then  begin
      skyval = median(small_image(w))
    endif else begin
      skyval = !values.F_NAN
      state.photwarning = 'Warning: No pixels in sky!'
    endelse
  endif
  
  ; Do the photometry now
  phpadu =  state.ccdgain
  apr    = [state.aprad]
  skyrad = [state.innersky, state.outersky]
  
  case state.skytype of  ; have aper work in flux units; handle mag conversions ourselves
    0: aper, main_image, [x], [y], flux, fluxerr, sky, skyerr, phpadu, apr, skyrad, badpix, flux=1, $
      /silent, readnoise = state.ccdrn                     ; IDLPhot Sky (modal value)
    1: aper, main_image, [x], [y], flux, fluxerr, sky, skyerr, phpadu, apr, skyrad, badpix, flux=1, $
      /silent, readnoise = state.ccdrn, setskyval = skyval ; Median value
    2: aper, main_image, [x], [y], flux, fluxerr, sky, skyerr, phpadu, apr, skyrad, badpix, flux=1, $
      /silent, readnoise = state.ccdrn, setskyval = 0      ; No Sky Subtraction
  endcase
  flux = flux[0] & fluxerr = fluxerr[0]
  sky  =  sky[0] &  skyerr =  skyerr[0]
  
  ; Apply growth function adjustment to match Sextractor (reference) flux coverage
  fluxerr = fluxerr / flux
  flux    = flux * state.phot_aperGrow
  fluxerr = flux * fluxerr
  
  if (flux EQ !VALUES.F_NAN) then state.photwarning = 'Warning: Error in computing flux!'
  
  ; Run phast_radplotf and plot the results
  phast_setwindow, state.radplot_window_id
  phast_radplotf, x, y, FWHM
  
  plots, [state.aprad, state.aprad], !y.crange, line = 1, color=2, thick=2, psym=0 ; overplot the apertures
  ymin = !y.crange(0)
  ymax = !y.crange(1)
  ypos = ymin + 0.85*(ymax-ymin)
  xyouts, /data, state.aprad, ypos, ' aprad', color=2, charsize=1.5
  if (state.skytype NE 2) then begin
    plots, [state.innersky,state.innersky], !y.crange, line = 1, color=4, thick=2, psym=0
    ypos = ymin + 0.75*(ymax-ymin)
    xyouts, /data, state.innersky, ypos, ' insky', color=4, charsize=1.5
    plots, [state.outersky,state.outersky], !y.crange, line = 1, color=5, thick=2, psym=0
    ypos = ymin + 0.65*(ymax-ymin)
    xyouts, /data, state.outersky * 0.82, ypos, ' outsky', color=5, charsize=1.5
  endif
  plots, !x.crange, [sky, sky], color=1, thick=2, psym=0, line = 2
  xyouts, /data, state.innersky + (0.1*(state.outersky-state.innersky)), $
    sky+0.07*(!y.crange[1] - sky), 'sky level', color=1, charsize=1.5
    
  ; Update object FWHM after every measurement
  state.objfwhm = FWHM
  
  ; Update aperture sizing to be consistent with current aperFWHM and units
  phast_setAperFWHM
  
  ; assemble results and do error analysis
  area = !pi*state.aprad*state.aprad
  
  imgScale = 1.0          ; Pixel and ADU units
  FWHM = FWHM             ; from radial plot (pixels)
  
  flux     = flux          ; from APER ADUs
  instrerr = sqrt( fluxerr^2 + area*(state.ccdgain^2-1)/12 ) ; add in read and quantization noise
  fluxerr = instrerr
  SNR = flux/fluxerr
  
  sky    = sky            ; from APER ADUs
  skyerr = skyerr         ; from APER ADUs,read noise counted empirically
  
  ; solve for limiting magnitude defined by minSNR
  varOther = fluxerr^2 - flux/state.ccdgain  ; var(Other) = sky noise + var(mean sky) + read noise + quantization noise
  minSNR   = 5
  A =  1.0/minSNR^2
  B = -1.0/state.ccdgain
  C = -varOther
  limflux  = (-B + sqrt(B^2-4*A*C)) / (2*A) ; limiting magnitude ADUs
  
  magBand = 'ADU'
  if (state.magunits EQ 1) then begin
  
    case state.magtype < 1 of
      0: begin ; instrumental magnitudes
        zeropt = 0.0
        magBand = 'Instr'
        fluxerr = 1.0857*fluxerr/flux
      end
      1: begin ; cat & std BVRI magnitudes
        zeropt = state.photzpt
        magBand = state.photzbnd
        fluxerr  = 1.0857 * sqrt( fluxerr^2 + (flux*state.photzerr/1.0857)^2 ) / flux  ; missing color term errors
      end
    endcase
    
    imgScale = state.pixelscale   ; arcsecond and magnitude units
    FWHM = FWHM*imgScale
    
    objColor = phast_setObjColor(state.photztrm)
    skyColor = phast_setSkyColor(state.photztrm)
    
    instrerr = 1.0857 * instrerr/flux
    flux     = zeropt + state.photzclr*objColor - 2.5 * alog10(flux / state.exptime)
    
    ; correct for extinction (k' and k'')
    flux = phast_ExtAdjust(state.photExtAdjust,state.magtype, flux, phast_setObjColor('V-R'))
    
    ; transform from local to standard passband
    posFilter = sxpar(*state.head_ptr,filters.fitsKey)
    filterTrm = filters.transTerm[posFilter]
    flux = phast_StdAdjust(flux, posFilter, phast_setObjColor(filterTrm) ) 
    
    skyerr   = 1.0857 * skyerr/sky
    sky      = sky / (imgScale*imgScale) ; flux/arcsecond^2
    sky      = zeropt + state.photzclr*skyColor -2.5 * alog10(sky/state.exptime) ; mags/arcsecond^2
    sky      = phast_StdAdjust(sky, posFilter, skyColor)  ; transform from local to standard passband
    
    limflux  = zeropt + state.photzclr*state.photSpecRmI - 2.5 * alog10(limflux / state.exptime)
    
    ; adjust backward ; you forgot about sky here
    phast_Std2Cat, magBand, flux, fluxerr
    phast_Std2Cat, magBand,  sky,  skyerr
        
  endif
  
  
  ; Write results to file if requested
  if (state.photprint EQ 1) then begin
    openw, state.photfile, state.photfilename, /append
    if (state.photerrors EQ 0) then fluxerr = 0.0
    formatstring = '(2(f7.1," "),3(f5.1," "),3(g12.6," "),f5.2)'
    printf, state.photfile, x, y, state.aprad, $
      state.innersky, state.outersky, sky, flux, fluxerr, FWHM, $
      format = formatstring
    close, state.photfile
  endif
  
  ; Set WCS string if WCS available
  if ptr_valid(state.astr_ptr) then begin
    xy2ad,x,y,*(state.astr_ptr),ra,dec
    wcsstring = phast_wcsstring(ra, dec, (*state.astr_ptr).ctype,       $
      state.equinox, state.display_coord_sys, $
      state.display_equinox, state.display_base60)
  endif
  
  tmp_string0 = string(state.cursorpos[0], state.cursorpos[1], $
    format = '("Cursor position:  x=",i4,"  y=",i4)' )
  tmp_string1 = string(state.centerpos[0], state.centerpos[1], $
    format = '("Object position: (",f6.1,", ",f6.1,")")')
    
  if state.magunits eq 0 then begin ; pixel and ADU units
    tmp_string2 = string(FWHM, format='("      FWHM:  ",F5.1, 4h pix)' ) + string(SNR<999, format= '("   SNR  : ",f5.1)' )
    tmp_string3 = '   Obj ADU: ' + phast_fmtinteger(flux,9)
    tmp_string4 = '   Sky ADU: ' + phast_fmtinteger(sky ,9)
    errstring   = ' Instr Err:        N/A'
    if (state.photerrors EQ 1) then begin
      tmp_string3 = tmp_string3 + ' ' + string(177b) + ' ' + strtrim(phast_fmtinteger(fluxerr,9),2)
      tmp_string4 = tmp_string4 + ' ' + string(177b) + ' ' + strtrim(phast_fmtinteger( skyerr,9),2)
      errstring = ' Instr Err: ' + string(177b) + phast_fmtinteger(instrerr,8) + '   SNR=' + phast_fmtinteger(minSNR,1) + ': ' + strtrim(phast_fmtinteger(limflux,9),2)
    endif
  endif else begin  ; arcsec and magnitude units
    tmp_string2 = string(FWHM, format='("      FWHM: ",F5.1,1h")'  ) + string(SNR<999, format= '(7X,"SNR  : ",F5.1)' )
    tmp_string3 = string(flux, format='("   Obj Mag: ",f7.3  )'  )
    tmp_string4 = string(sky,  format='("   Sky Bkg: ",f7.3  )'  )
    errstring   = ' Instr:  N/A'
    if (state.photerrors EQ 1) then begin
      tmp_string3 = tmp_string3 + ' ' + string(177b) + ' ' + string(fluxerr, format= '(f5.3)' )
      tmp_string4 = tmp_string4 + ' ' + string(177b) + ' ' + string( skyerr, format= '(f5.3)' )
      errstring = ' Instr Err: ' + string(177b) + string(instrerr,format='(1X,F5.3)') + '      ' + string(limflux, format='("SNR=5: ",F5.2)' )
    endif
  endelse
  tmp_string3 = tmp_string3 + ' ' + strtrim(magBand)
  tmp_string4 = tmp_string4 + ' ' + strtrim(magBand)
  
  ;pass data to MPC report
  phast_get_mpc_data,mpc.index,flux
  
  widget_control, state.centerbox_id,   set_value = state.centerboxsize
  widget_control, state.apphot_wcs_id,  set_value = wcsstring
  widget_control, state.centerpos_id,   set_value = tmp_string1
  widget_control, state.radius_id,      set_value = state.aprad
  widget_control, state.outersky_id,    set_value = state.outersky
  widget_control, state.innersky_id,    set_value = state.innersky
  widget_control, state.photwarning_id, set_value = state.photwarning
  widget_control, state.objfwhm_id,     set_value = tmp_string2
  widget_control, state.photresult_id,  set_value = tmp_string3
  widget_control, state.skyresult_id,   set_value = tmp_string4
  widget_control, state.photerror_id,   set_value = errstring
  
  phast_tvphot
  
  phast_resetwindow
end

;----------------------------------------------------------------------

pro phast_apphot_settings

  ; Routine to get user input on various photometry settings

  common phast_state
  
  skyline  = ('0, button, IDLPhot Sky Mode|Median Sky|No Sky Subtraction,'+$
    'exclusive,' + $
    'label_left=   Select Sky Algorithm: , set_value = ' + $
    string(state.skytype))
    
  magline  = ('0, button, Pixels ADUs|Arcsecs Magnitudes, exclusive,' + $
    'label_left=    Select Output Units: , set_value = ' + $
    string(state.magunits))
    
  typeline = ('0, button, Instrumental|Catalog BVR|Standard BVR, exclusive,' + $
    'label_left=Select Magnitude System: , set_value =' + $
    string(state.magtype))
    
  extline  = ('0, button, None|At X = Xobs|At X = 0, exclusive,' + $
    'label_left=  Select Extinction Adj: , set_value =' + $
    string(state.photExtAdjust))
    
  zptline  = ('0, float,'+string(state.photzpt,'(F6.3)') + $
    ',label_left =    Magnitude Zeropoint:,'     +  'width = 6')
    
  clrline  = ('0, float,'+string(state.photzclr,'(F7.4)') + $
    ',label_left =             Color Term:,'     +  'width = 7')
    
  exptimeline = ('0, float,'+string(state.exptime,'(F6.1)') + $
    ',label_left =      Exposure Time (s):,'  + 'width = 6')
    
  errline = ('0, button, No|Yes, exclusive,' + $
    'label_left = Calculate photometric errors? ,' + 'set_value =' + $
    string(state.photerrors))
    
  gainline = ('0, float, '+string(state.ccdgain,'(F6.1)') + $
    ',label_left =   CCD Gain (e-/DN):,' + 'width = 6')
    
  rnline = ('0, float, '+string(state.ccdrn,'(F6.1)') + $
    ',label_left = Readout Noise (e-):,'   + 'width = 6')
  warningline1 = $
    ('0, label, ' + $
    'WARNING: Photometric errors only make sense if the, left')
  warningline2 = $
    ('0, label, ' + $
    'gain and readnoise are given correctly, left ')
  warningline3 = $
    ('0, label, ' + $
    'accounting for scaling or co-adding of images., left')
  warningline4 = $
    ('0, label, ' + $
    '   , left')
    
  formdesc = [skyline,      $
    magline,      $
    typeline,     $
    extline,     $
    zptline,      $
    clrline,      $
    exptimeline,  $
    '0, label, [ Magnitude = ZPT + b*CLR - 2.5 log10(DN/exptime) ]', $
    errline,      $
    gainline,     $
    rnline,       $
    warningline1, warningline2, warningline3, warningline4, $
    '0, button, Apply Settings, quit', $
    '0, button, Cancel, quit']
    
  textform = cw_form(formdesc, /column, $
    title = 'phast photometry settings')
    
  if (textform.tag16 EQ 1) then return ; cancelled
  
  state.skytype       = textform.tag0
  state.magunits      = textform.tag1
  if strlowcase(state.photzbnd) EQ 'instr' And textform.tag2 GT 0 then begin
    phast_message, 'Catalog magnitudes cannot be selected until a zeropoint is determined', $
      window = 1, msgtype = 'error'
    state.magtype = 0
  endif else begin
    state.magtype       = textform.tag2
  endelse
  state.photExtAdjust = textform.tag3
  state.photzpt       = textform.tag4
  state.photzclr      = textform.tag5
  state.exptime       = textform.tag6
  state.photerrors    = textform.tag8
  state.ccdgain       = (1E-5) > textform.tag9
  state.ccdrn         =    0   > textform.tag10
  
  if (state.exptime LE 0) then state.exptime = 1.0
  
  phast_apphot_refresh
end

;----------------------------------------------------------------------

function phast_ExtAdjust, ExtMethod, MagType, magVal, magColor

  ; adjust instrumental magnitude for extinction (k' k'')

  common phast_state
  common phast_filters

  posFilter = sxpar(*state.head_ptr,filters.fitsKey)
  case ExtMethod of
    0: ; do nothing
    1: begin ; adjust at airmass of observation
       phast_getFieldEpoch, a, d,radius, X0, obsDate
       if ptr_valid(state.astr_ptr) then begin
          ; adjust magVal for differential airmass within frame (k' term)
       endif
       ; adjust for color effect (k'' term)
       magVal = magVal - filters.atmColorVI[posFilter] * 1.9480*magColor * X0
       end
    2: begin ; adjust to ex-atmosphere (X=0)
       phast_getFieldEpoch, a, d,radius, X0, obsDate
       if ptr_valid(state.astr_ptr) then begin
          ; adjust magVal for differential airmass within frame
       endif
       ; only Instr magnitudes need adjustment to X = 0; the zeropoint does this for catalog magnitudes
       if magType EQ 0 then magVal = magVal - ( filters.atmExtinct[posFilter] + filters.atmColorVI[posFilter] * 1.9480*magColor ) * X0 $
       else magVal = magVal                 -                                   filters.atmColorVI[posFilter] * 1.9480*magColor   * X0
    end
    else: ; do nothing
  endcase
  return, magVal
end

;----------------------------------------------------------------------

function phast_fmtinteger, number, fldwidth

; format an integer with commas (NNN,NNN)

  value = string(round(number),format='(I12)')
  len  = strlen(value)-1
  field = strmid(value,len-2,3)
  
  char  = strmid(value,len-3,1)
  while char NE ' ' do begin
    value = strmid(value,0,len-2)
    len = strlen(value)-1
    field = strmid(value,len-2,3) + ',' + field
    char = strmid(value,len-3,1)
  endwhile
  
  field = strtrim(field,2)
  if strlen(field) LE fldwidth then begin
    if strlen(field) LT fldwidth then for i = strlen(field), fldwidth do field = ' ' + field
  endif else begin
    field = ''
    for i = 1, fldwidth do field = field + '*'
  endelse
  return, field
end

;---------------------------------------------------------------------------

pro phast_getCatMags, star_catalog, Band, cat_RA, cat_Dec, cat_Mag, cat_Err

  ; access star catalog by color letter as needed

  cat_RA   = star_catalog.RA
  cat_Dec  = star_catalog.Dec
  case strlowcase(Band) of
     'u': begin & cat_Mag = star_catalog.UMag
        cat_Err = star_catalog.errUMag
     end
     'b': begin & cat_Mag = star_catalog.BMag
        cat_Err = star_catalog.errBMag
     end
     'v': begin & cat_Mag = star_catalog.VMag
        cat_Err = star_catalog.errVMag
     end
     'r': begin & cat_Mag = star_catalog.RMag
        cat_Err = star_catalog.errRMag
     end
     'i': begin & cat_Mag = star_catalog.IMag
        cat_Err = star_catalog.errIMag
     end
  endcase
end

;----------------------------------------------------------------------

pro phast_imcenterf, xcen, ycen

  ; program to calculate the center of mass of an image around
  ; the point (x,y), return the answer in (xcen,ycen).
  ;
  ; by M. Liu, adapted for inclusion in PHAST by AJB
  ;
  ; ALGORITHM:
  ;   1. first finds max pixel value in
  ;	   a 'bigbox' box around the cursor
  ;   2. then calculates centroid around the object
  ;   3. iterates, recalculating the center of mass
  ;      around centroid until the shifts become smaller
  ;      than MINSHIFT (0.3 pixels)

  common phast_images
  common phast_state
  
  ; iteration controls
  MINSHIFT = 0.3
  
  ; max possible x or y direction shift
  MAXSHIFT = 3
  
  ; Bug fix 4/16/2000: added call to round to make sure bigbox is an integer
  bigbox=round(1.5*state.centerboxsize)
  
  sz = size(main_image)
  
  ; box size must be odd
  dc = (state.centerboxsize-1)/2
  if ( (bigbox / 2 ) EQ round(bigbox / 2.)) then bigbox = bigbox + 1
  db = (bigbox-1)/2
  
  ; need to start with integers
  xx = state.cursorpos[0]
  yy = state.cursorpos[1]
  
  ; make sure there aren't NaN values in the apertures.
  minx = 0 > (xx - state.outersky)
  maxx = (xx + state.outersky) < (state.image_size[0] - 1)
  miny = 0 > (yy - state.outersky)
  maxy = (yy + state.outersky) < (state.image_size[1] - 1)
  
  subimg = main_image[minx:maxx, miny:maxy]
  if (finite(mean(subimg)) EQ 0) then begin
    xcen = xx
    ycen = yy
    state.photwarning = 'WARNING: Region contains NaN values.'
    return
  endif
  
  ; first find max pixel in box around the cursor
  x0 = (xx-db) > 0
  x1 = (xx+db) < (sz(1)-1)
  y0 = (yy-db) > 0
  y1 = (yy+db) < (sz(2)-1)
  cut = main_image[x0:x1,y0:y1]
  cutmax = max(cut)
  w=where(cut EQ cutmax)
  cutsize = size(cut)
  my = (floor(w/cutsize[1]))[0]
  mx = (w - my*cutsize[1])[0]
  
  xx = mx + x0
  yy = my + y0
  xcen = xx
  ycen = yy
  
  ; then find centroid
  if  (n_elements(xcen) gt 1) then begin
    xx = round(total(xcen)/n_elements(xcen))
    yy = round(total(ycen)/n_elements(ycen))
  endif
  
  done = 0
  niter = 1
  
  ;	cut out relevant portion
  sz = size(main_image)
  x0 = round((xx-dc) > 0)		; need the ()'s
  x1 = round((xx+dc) < (sz[1]-1))
  y0 = round((yy-dc) > 0)
  y1 = round((yy+dc) < (sz[2]-1))
  xs = x1 - x0 + 1
  ys = y1 - y0 + 1
  cut = float(main_image[x0:x1, y0:y1])
  
  ; sky subtract before centering
  ; note that this is a quick and dirty solution, and may cause
  ; centering problems for poorly behaved data  -- AB, 2/28/07
  cut = cut - min(cut)
  ; find x position of center of mass
  cenxx = fltarr(xs, ys, /nozero)
  for i = 0L, (xs-1) do $         ; column loop
    cenxx[i, *] = cut[i, *] * i
  xcen = total(cenxx) / total(cut) + x0
  
  ; find y position of center of mass
  cenyy = fltarr(xs, ys, /nozero)
  for i = 0L, (ys-1) do $         ; row loop
    cenyy[*, i] = cut[*, i] * i
  ycen = total(cenyy) / total(cut) + y0
  
  if (abs(xcen-state.cursorpos[0]) gt MAXSHIFT) or $
    (abs(ycen-state.cursorpos[1]) gt MAXSHIFT) then begin
    state.photwarning = 'Warning: Possible mis-centering?'
  endif
  
  ; add final check for xcen, ycen = NaN: this can happen if the region
  ; contains all negative values
  if (finite(xcen) EQ 0 OR finite(ycen) EQ 0) then begin
    state.photwarning = 'Warning: Unable to center.'
    xcen = state.cursorpos[0]
    ycen = state.cursorpos[1]
  endif
end

;----------------------------------------------------------------------

pro phast_imcenterg, image, xcenter, ycenter, apr, skyrad, badpix, xcentroid, ycentroid
  
  ; NAME: phast_imgcenterg
  ;
  ; PURPOSE: Image Centroiding, based on simplified version of APER (adapted from DAOPHOT)
  ;
  ; EXPLANATION:  phast_imgcenterg will compute the (x,y) centroid of the flux within the measuring
  ;     aperture apr after subtracting the median sky brightness from total counts.  The centroids
  ;     are the first-moments of the flux distribution considering (whole) pixels with flux
  ;     at least 1 sigma above the sky background.
  ;
  ; CALLING SEQUENCE:
  ;     phast_imgcenterg, image, xcenter, ycenter, apr, skyrad, badpix, xcentroid, ycentroid
  ;
  ; INPUTS:
  ;     IMAGE   - input image array
  ;     XCENTER - center x coordinate
  ;     YCENTER - center y coordinate
  ;     APR     - centroiding aperture radius
  ;     SKYRAD  - Two element vector giving the inner and outer radii for the sky annulus.
  ;     BADPIX  - Two element vector giving the minimum and maximum value of a good pixel.
  ;
  ; OUTPUTS:
  ;     XCENTROID - flux-weighted x centroid
  ;     YCENTROID - flux-weighted y centroid
  ;     FWHM      - FWHM assuming Gaussian PSF
  ;     errFWHM   - standard error in FWHM
  ;
  ; EXAMPLE: phast_imcenterg, main_image, x, y, state.innersky, [state.innersky, state.outersky], [0, 65535], xcentroid, ycentroid
  ;
  ; PROCEDURES USED: (none)
  ;
  ; NOTES:
  ;
  ; internal parameters
  minsky = 20      ; smallest number of pixels from which the sky may be determined
  maxsky = 10000   ; maximum number of pixels allowed in the sky annulus.
  ;
  ; Get input image characteristics
  s = size(image)
  ncol = s[1]
  nrow = s[2]
  
  chk_badpix = badpix[0] LT badpix[1]  ; check for bad pixels or ignore?
  
  ; Compute the limits of the submatrix.
  
  lx = fix(xcenter-skyrad[1]) > 0           ; Lower limit X direction
  ux = fix(xcenter+skyrad[1]) < (ncol-1)    ; Upper limit X direction
  nx = ux-lx+1                              ; Number of pixels X direction
  ly = fix(ycenter-skyrad[1]) > 0           ; Lower limit Y direction
  uy = fix(ycenter+skyrad[1]) < (nrow-1);   ; Upper limit Y direction
  ny = uy-ly+1                              ; Number of pixels Y direction
  dx = xcenter-lx                           ; X coordinate of star's centroid in subarray
  dy = ycenter-ly                           ; Y coordinate of star's centroid in subarray
  
  ; Determine if star is too close to the edge for measuring aperture to fit on image
  edge    = (dx-0.5) < (nx+0.5-dx) < (dy-0.5) < (ny+0.5-dy) ; closest edge to star
  if ( edge LT apr ) then goto, BADSTAR
  
  ; Begin determination of centroid and fwhm
  xcentroid = xcenter
  ycentroid = ycenter
  
  rotbuf = image[ lx:ux, ly:uy ]        ; Extract subarray from image
  
  rsq = fltarr( nx, ny, /NOZERO )    ; Square of the distance of each pixel from the center
  dxsq = ( findgen( nx ) - dx )^2
  for ii = 0, ny-1 do rsq[0,ii] = dxsq + (ii-dy)^2
  r = sqrt(rsq) - 0.5              ; Radius of each pixel in the subarray
  
  ; Select pixels within sky annulus, and eliminate bad pixels
  rinsq  = (skyrad[0] > 0.0         )^2
  routsq = (skyrad[1] > skyrad[0]+1 )^2
  skypix = ( rsq GE rinsq ) and ( rsq LE routsq )
  
  if chk_badpix then skypix = skypix and (rotbuf GT badpix[0] ) $
    and (rotbuf LT badpix[1] )
    
  sindex =  where(skypix, Nsky)
  Nsky   =  Nsky < maxsky               ; limit to MAXSKY pixels
  if ( nsky LT minsky ) then goto, BADSTAR
  
  skybuf = rotbuf[ sindex[0:nsky-1] ]     ; SKYBUF is the 1-d array of sky pixels
  skymed = median(skybuf)                 ; median sky brightness
  skyvar = variance(skybuf)               ; variance of sky brightness
  skystd = sqrt(skyvar)
  if (skystd LT 0.0) then goto, BADSTAR
  
  
  ; Centroid the aperture
  thisap  = where( r LT apr )           ; select pixels within radius
  thisapd = rotbuf[thisap]
  thisapr =      r[thisap]
  
  xindex = replicate(1,1,ny) ## (lx+indgen(ux-lx+1)) ;
  xvalue = xindex[thisap]
  yindex = transpose( (ly+indgen(uy-ly+1)) ) ## replicate(1,nx,1)
  yvalue = yindex[thisap]
  
  netflux = (thisapd-skymed)   ;*fractn
  tstat = 1.645 ; 5% chance this high by chance (sky)
  ptrflux = where( (netflux-tstat*skystd)>0 ,npix)
  if npix EQ 0 then goto, BADSTAR
  
  totalflux = total(netflux[ptrflux])
  xcentroid = total(netflux[ptrflux]*xvalue[ptrflux]) / totalflux
  ycentroid = total(netflux[ptrflux]*yvalue[ptrflux]) / totalflux
  
  return
  
  BADSTAR:
  return
end

;---------------------------------------------------------------------------

function phast_intrinsic_colors, specTypeNum, specSubNum

; return 3 color indices from spectral type, sub type

  common phast_state
  
  ; Intrinsic colors from www-int.stsci.edu/~inr/instrins.html
  ;              B      A      F      G      K      M
  BmVtbl = [ [-0.30, -0.01,  0.32,  0.60,  0.81,  1.37], $
    [-0.26,  0.02,  0.34,  0.62,  0.86,  1.47], $
    [-0.24,  0.05,  0.35,  0.63,  0.92,  1.47], $
    [-0.20,  0.08,  0.38,  0.65,  0.95,  1.50], $
    [-0.18,  0.12,  0.42,  0.67,  1.00,  1.52], $
    [-0.16,  0.15,  0.45,  0.68,  1.15,  1.52], $
    [-0.14,  0.17,  0.48,  0.70,  1.24,  1.52], $
    [-0.13,  0.20,  0.50,  0.72,  1.33,  1.52], $
    [-0.11,  0.27,  0.53,  0.74,  1.34,  1.52], $
    [-0.07,  0.30,  0.57,  0.78,  1.36,  1.52] ]
    
  VmRtbl = [ [-0.19, -0.04,  0.12,  0.27,  0.42,  0.70], $
    [-0.16, -0.02,  0.14,  0.29,  0.46,  0.76], $
    [-0.14, -0.01,  0.15,  0.30,  0.50,  0.83], $
    [-0.12,  0.01,  0.17,  0.30,  0.55,  0.89], $
    [-0.11,  0.02,  0.19,  0.31,  0.60,  0.94], $
    [-0.10,  0.04,  0.21,  0.31,  0.68,  0.94], $
    [-0.10,  0.05,  0.22,  0.32,  0.65,  0.94], $
    [-0.09,  0.06,  0.23,  0.34,  0.62,  0.94], $
    [-0.08,  0.09,  0.24,  0.35,  0.63,  0.94], $
    [-0.07,  0.10,  0.26,  0.39,  0.65,  0.94] ]
    
  RmItbl = [ [-0.12,  0.00,  0.16,  0.27,  0.33,  0.97], $
    [-0.14,  0.00,  0.17,  0.28,  0.36,  1.08], $
    [-0.15,  0.01,  0.20,  0.28,  0.39,  1.23], $
    [-0.15,  0.01,  0.21,  0.29,  0.42,  1.35], $
    [-0.14,  0.03,  0.22,  0.30,  0.44,  1.49], $
    [-0.14,  0.05,  0.23,  0.30,  0.52,  1.49], $
    [-0.11,  0.07,  0.24,  0.30,  0.68,  1.49], $
    [-0.10,  0.09,  0.25,  0.31,  0.83,  1.49], $
    [-0.08,  0.11,  0.26,  0.31,  0.84,  1.49], $
    [-0.03,  0.14,  0.27,  0.32,  0.86,  1.49] ]
    
  col = ( 0 > specTypeNum ) < (n_elements(state.photSpecList)-1)
  row = ( 0 > specSubNum  ) < 9
  
  BmV = BmVtbl(col,row)
  VmR = VmRtbl(col,row)
  RmI = RmItbl(col,row)
  
  retValues = [BmV, VmR, RmI]
  return, retValues
end

;---------------------------------------------------------------------------

pro phast_meanerr,x,sigmax,xmean,sigmam,sigmad

  ; Revised from Marc W. Buie, Lowell Observatory, 1992 Feb 20

  if n_elements(x) eq 1 then begin
    xmean  = x[0]
    sigmam = sigmax[0]
    sigmad = sigmax[0]
  endif else begin
    weight = 1.0/sigmax^2
    sum    = total(weight)
    if sum eq 0.0 then print,'MEANERR: sum of weights is zero.'
    weight = n_elements(x)*weight/sum
    sumwt  = total(weight)
    xmean  = total(weight*x)/sumwt
    sigmad = sqrt(total(weight*(x-xmean)^2)/(sumwt-1))
    sigmam = sqrt(sigmad/n_elements(x))
  endelse
end

;---------------------------------------------------------------------------

pro phast_phot_updateFits, image, head, magzero, magzerr, magzbnd, magzclr, magztrm, magznum

  ; update FITS header with photometric zeropoint keywords

  common phast_state

  sxaddpar,head,'MAGZERO',magzero
  sxaddpar,head,'MAGZERR',magzerr
  sxaddpar,head,'MAGZBND',magzbnd
  sxaddpar,head,'MAGZCLR',magzclr
  sxaddpar,head,'MAGZTRM',magztrm
  sxaddpar,head,'MAGZNUM',magznum
  fits_write, state.imagename, image, head
end

;-----------------------------------------------------------------------
pro phast_radplotf, x, y, fwhm

  ; Program to calculate radial profile of an image
  ; given aperture location, range of sizes, and inner and
  ; outer radius for sky subtraction annulus.  Calculates sky by
  ; median.
  ;
  ; original version by M. Liu, adapted for inclusion in PHAST by AJB

  common phast_state
  common phast_images
  
  ; set defaults
  inrad = 0.5*sqrt(2)
  outrad = round(state.outersky * 1.2)
  drad=1.
  insky = outrad+drad
  outsky = insky+drad+20.
  
  ; initialize arrays
  inrad = float(inrad)
  outrad = float(outrad)
  drad = float(drad)
  nrad = ceil((outrad-inrad)/drad) + 1
  out = fltarr(nrad,12)
  
  ; extract relevant image subset (may be rectangular), translate coord origin,
  ;   bounded by edges of image
  ;   (there must be a cute IDL way to do this neater)
  sz = size(main_image)
  x0 = floor(x-outsky)
  x1 = ceil(x+outsky)   ; one pixel too many?
  y0 = floor(y-outsky)
  y1 = ceil(y+outsky)
  x0 = x0 > 0.0
  x1 = x1 < (sz[1]-1)
  y0 = y0 > 0.0
  y1 = y1 < (sz[2]-1)
  nx = x1 - x0 + 1
  ny = y1 - y0 + 1
  
  ; trim the image, translate coords
  img = main_image[x0:x1,y0:y1]
  xcen = x - x0
  ycen = y - y0
  
  ; for debugging, can make some masks showing different regions
  skyimg = fltarr(nx,ny)			; don't use /nozero!!
  photimg = fltarr(nx,ny)			; don't use /nozero!!
  
  ; makes an array of (distance)^2 from center of aperture
  ;   where distance is the radial or the semi-major axis distance.
  ;   based on DIST_CIRCLE and DIST_ELLIPSE in Goddard IDL package,
  ;   but deals with rectangular image sections
  distsq = fltarr(nx,ny,/nozero)
  
  xx = findgen(nx)
  yy = findgen(ny)
  x2 = (xx - xcen)^(2.0)
  y2 = (yy - ycen)^(2.0)
  for i = 0L,(ny-1) do $          ; row loop
    distsq[*,i] = x2 + y2(i)
    
  ; get sky level by masking and then medianing remaining pixels
  ; note use of "gt" to avoid picking same pixels as flux aperture
  ns = 0
  msky = 0.0
  errsky = 0.0
  
  in2 = insky^(2.0)
  out2 = outsky^(2.0)
  if (in2 LT max(distsq)) then begin
    w = where((distsq gt in2) and (distsq le out2),ns)
    skyann = img[w]
  endif else begin
    w = where(distsq EQ distsq)
    skyann = img[w]
    state.photwarning = 'Not enough pixels in sky!'
  endelse
  
  msky = median(skyann)
  errsky = stddev(skyann)
  skyimg[w] = -5.0
  photimg = skyimg
  
  errsky2 = errsky * errsky
  
  out[*,8] = msky
  out[*,9] = ns
  out[*,10]= errsky
  
  ; now loop through photometry radii, finding the total flux, differential
  ;	flux, and differential average pixel value along with 1 sigma scatter
  ; 	relies on the fact the output array is full of zeroes
  for i = 0,nrad-1 do begin
  
    dr = drad
    if i eq 0 then begin
      rin =  0.0
      rout = inrad
      rin2 = -0.01
    endif else begin
      rin = inrad + drad *(i-1)
      rout = (rin + drad) < outrad
      rin2 = rin*rin
    endelse
    rout2 = rout*rout
    
    ; 	get flux and pixel stats in annulus, wary of counting pixels twice
    ;	checking if necessary if there are pixels in the sector
    w = where(distsq gt rin2 and distsq le rout2,np)
    
    pfrac = 1.0                 ; fraction of pixels in each annulus used
    
    if np gt 0 then begin
      ann = img[w]
      dflux = total(ann) * 1./pfrac
      dnpix = np
      dnet = dflux - (dnpix * msky) * 1./pfrac
      davg = dnet / (dnpix * 1./pfrac)
      if np gt 1 then dsig = stddev(ann) else dsig = 0.00
      
      ;		std dev in each annulus including sky sub error
      derr = sqrt(dsig*dsig + errsky2)
      
      photimg[w] = rout2
      
      out[i,0] = (rout+rin)/2.0
      out[i,1] = out[i-1>0,1] + dflux
      out[i,2] = out[i-1>0,2] + dnet
      out[i,3] = out[i-1>0,3] + dnpix
      out[i,4] = dflux
      out[i,5] = dnpix
      out[i,6] = davg
      out[i,7] = dsig
      out[i,11] = derr
    endif else if (i ne 0) then begin
      out[i,0]= rout
      out[i,1:3] = out[i-1,1:3]
      out[i, 4:7] = 0.0
      out[i,11] = 0.0
    endif else begin
      out[i, 0] = rout
    endelse
    
  endfor
  
  ; fill radpts array after done with differential photometry
  w = where(distsq ge 0.0 and distsq le outrad*outrad)
  radpts = dblarr(2,n_elements(w))
  radpts[0,*] = sqrt(distsq[w])
  radpts[1,*] = img[w]
  
  ; compute FWHM via spline interpolation of radial profile
  fwhm = phast_splinefwhm(out[*,0],out[*,6])
  if fwhm lt 1.0 then fwhm = !values.F_NaN
  
  ; plot the results
  
  if n_elements(radpts(1, *)) gt 100 then pp = 3 else pp = 1
  
  yminpoint = msky
  ymaxpoint = max(radpts[1,*])
  blankspace=0.08
  ymin = yminpoint - blankspace*(ymaxpoint - yminpoint)
  ymax = ymaxpoint + blankspace*(ymaxpoint - yminpoint)
  
  
  plot, radpts[0, *], radpts[1, *], /nodata, xtitle = 'Radius (pixels)', $
    ytitle = 'Counts', color=7, charsize=1.2, yrange = [ymin,ymax], yst=1
  oplot, radpts[0, *], radpts[1, *], psym = pp, color=6
  if (finite(mean(out)) EQ 1) then $
    oploterror, out[*, 0], out[*, 6]+out[*, 8], $
    out[*, 11]/sqrt(out[*, 5]), psym=-4, color=7, errcolor=7 
end

;----------------------------------------------------------------------

pro phast_setAperFWHM ; update aperture FWHM and units

  common phast_state

  case state.magunits of
    0: FWHM = state.phot_aperFWHM
    1: FWHM = state.phot_aperFWHM * state.pixelScale
  endcase
  widget_control, state.phot_aperFWHM_id, set_value = round(100*FWHM)/100.0
  widget_control, state.phot_aperUnit_ID, set_value = state.phot_aperList[state.magunits]
end

;----------------------------------------------------------------------

pro phast_setAps, fwhm, magunits

  ; set apertures consistent with fwhm and sextractor ellipses

  common phast_state

  ; state.objfwhm always kept in pixel units
  if magunits EQ 0 then state.objfwhm = fwhm                    $
  else state.objfwhm = fwhm / state.pixelscale
  state.phot_aperFWHM = round(100*state.objfwhm)/100.0
  
  ; now set measuring aperature to cover same flux as sextractor
  gaussSigma = state.objfwhm/(2*sqrt(2*alog(2)))
  case state.sex_PHOT_AUTOPARAMS[0] of
    2.0 : state.phot_aperFRef = 0.90
    2.5 : state.phot_aperFRef = 0.94
    else: state.phot_aperFRef = 0.94
  endcase
  state.phot_aperFCvg = state.phot_aperFRef ; activate to deactivate growth curve
  state.phot_aperGrow = state.phot_aperFRef / state.phot_aperFCvg
  state.aprad = gaussSigma*sqrt(-2*alog(1.0-state.phot_aperFCvg))
  
  ; set apertures to nearest 0.01 pixels
  state.aprad    = round( 100 * state.aprad                           ) / 100.0 ; 90-94% flux inside
  state.innersky = round( 100 * gaussSigma*sqrt(-2*alog(1-0.999))     ) / 100.0 ; <= 0.01% flux outside
  state.outersky = round( 100 * sqrt( (!pi*state.innersky^2+200)/!pi) ) / 100.0 ; 200 pixels to set sky
  state.centerboxsize = 9 > (1+2*floor(ceil(state.outersky)/2)) ; next odd integer > state.outersky
  return
end

;----------------------------------------------------------------------

pro phast_setGSCV, B, errB, R, errR, V, errV

  ; synthesize V band for GSC-2.3.2 catalog

  c0 = 0.0057
  c1 = 0.3691
  V = R + c0 + c1*(B-R)
  errV = sqrt( errR*errR*(1.0+c1*c1) + errB*errB*c1*c1 )
  return
end

;----------------------------------------------------------------------

function phast_setObjColor, fitTerm

  ; estimate object's color term from intrinsic colors

  common phast_state

  case strtrim(strlowcase(fitTerm)) of
    'b-v': color = state.photSpecBmV
    'b-r': color = state.photSpecBmV + state.photSpecVmR
    'b-i': color = state.photSpecBmV + state.photSpecVmR + state.photSpecRmI
    'v-r': color = state.photSpecVmR
    'r-i': color = state.photSpecRmI
    else : color = 0.0
 endcase
  return, color
end

;----------------------------------------------------------------------

function phast_setSkyColor, fitTerm

  ; estimate sky color term from intrinsic colors

  phast_getFieldEpoch, a, d, radius, X, obsDate, JD=obsJD
  MPHASE, obsJD, Illum
  ; Source: Direct Imaging Manual for Kitt Peak (May 30, 2002)
  ;           Phase    B-V    B-R    B-I    V-R    R-I
  table = [ [0.00,  0.90,  1.80,  2.80,  0.90,  1.00], $
    [0.25,  0.70,  1.60,  2.50,  0.90,  0.90], $
    [0.50,  0.20,  1.00,  1.90,  0.80,  0.90], $
    [0.75,  0.00,  0.40,  1.20,  0.40,  0.80], $
    [1.00, -0.50, -0.40,  0.30,  0.10,  0.70] ]
  case strtrim(strlowcase(fitTerm)) of
    'b-v': color = interpolate(table[1,*],4*illum)
    'b-r': color = interpolate(table[1,*],4*illum) + interpolate(table[4,*],4*illum)
    'b-i': color = interpolate(table[1,*],4*illum) + interpolate(table[4,*],4*illum) $
      + interpolate(table[5,*],4*illum)
    'v-r': color = interpolate(table[4,*],4*illum)
    'r-i': color = interpolate(table[5,*],4*illum)
    else : color = 0.0
 endcase
  return, color
end

;----------------------------------------------------------------------

function phast_splinefwhm, rad, prof, splrad, splprof

  ; given a radial profile (counts vs radius) will use
  ; a spline to extract the FWHM
  ;
  ; ALGORITHM
  ;   finds peak in radial profile, then marches along until finds
  ;   where radial profile has dropped to half of that,
  ;   assumes peak value of radial profile is at minimum radius
  ;
  ; original version by M. Liu, adapted for PHAST by AJB

  common phast_state
  
  nrad = n_elements(rad)
  
  ; check the peak
  w = where(prof eq max(prof))
  if float(rad(w[0])) ne min(rad) then begin
    state.photwarning = 'Warning: Profile peak is off-center!'
    return,-1
  endif
  
  ; interpolate radial profile at 50 times as many points
  splrad = min(rad) + findgen(nrad*50+1) * (max(rad)-min(rad)) / (nrad*50)
  nspl = n_elements(splrad)
  
  ; spline the profile
  splprof = spline(rad,prof,splrad)
  
  ; march along splined profile until cross 0.5*peak value
  found = 0
  i = 0
  repeat begin
     if splprof(i) lt 0.5*max(splprof) then $
        found = 1 $
     else $
        i = i+1
  endrep until ((found) or (i eq nspl))
  
  if (i lt 2) or (i eq nspl) then begin
     state.photwarning = 'Warning: Unable to measure FWHM!'
     return,-1
  endif
  
  ; now interpolate across the 2 points straddling the 0.5*peak
  fwhm = splrad(i)+splrad(i-1)
  
  return,fwhm
end

;----------------------------------------------------------------------

pro phast_Std2Cat, magBand, flux, fluxerr

  ; correct backward from UBVRI standard to catalog magnitudes

  common phast_state

  if state.magtype EQ 1 then begin
     case strlowcase(strtrim(magBand)) of
      'u': ; do nothing
      'b': begin & stdB = flux                      &  errstdB = fluxerr
      stdV = stdB - state.photSpecBmV  &  errstdV = 0.0
      stdR = stdV - state.photSpecVmR  &  errstdR = 0.0
      stdI = stdR - state.photSpecRmI  &  errstdI = 0.0
      phast_stdUBVRI, state.photcatalog_name, BMag, errBMag, VMag, errVMag, RMag, errRMag, IMag, errIMag, $
        stdB, errStdB, stdV, errStdV, stdR, errStdR, stdI, errStdI
      flux = BMag
   end
      'v': begin & stdV = flux                      &  errstdV = fluxerr
         stdB = stdV + state.photSpecBmV  &  errstdB = 0.0
         stdR = stdV - state.photSpecVmR  &  errstdR = 0.0
         stdI = stdR - state.photSpecRmI  &  errstdI = 0.0
         phast_stdUBVRI, state.photcatalog_name, BMag, errBMag, VMag, errVMag, RMag, errRMag, IMag, errIMag, $
                         stdB, errStdB, stdV, errStdV, stdR, errStdR, stdI, errStdI
         flux = VMag
      end
      'r': begin & stdR = flux                      &  errstdR = fluxerr
         stdV = stdR + state.photSpecVmR  &  errstdV = 0.0
         stdB = stdV + state.photSpecBmV  &  errstdB = 0.0
         stdI = stdR - state.photSpecRmI  &  errstdI = 0.0
         phast_stdUBVRI, state.photcatalog_name, BMag, errBMag, VMag, errVMag, RMag, errRMag, IMag, errIMag, $
                         stdB, errStdB, stdV, errStdV, stdR, errStdR, stdI, errStdI
         flux = RMag
      end
      'i': begin & stdI = flux                      &  errstdI = fluxerr
         stdR = stdI + state.photSpecRmI  &  errstdR = 0.0
         stdV = stdR + state.photSpecVmR  &  errstdV = 0.0
         stdB = stdV + state.photSpecBmV  &  errstdB = 0.0
         phast_stdUBVRI, state.photcatalog_name, BMag, errBMag, VMag, errVMag, RMag, errRMag, IMag, errIMag, $
                         stdB, errStdB, stdV, errStdV, stdR, errStdR, stdI, errStdI
         flux = IMag
      end
   endcase
  endif
end

;----------------------------------------------------------------------

function phast_StdAdjust, magVal, posFilter, color

  ; adjust catalog magnitudes for difference between local and standard passbands
  
  common phast_state
  common phast_filters
  
  magVal = magVal - filters.transCoeff[posFilter] * color
  return, magVal
end

;----------------------------------------------------------------------

pro phast_stdUBVRI, catalog, catB, errCatB, catV, errCatV, catR, errCatR, catI, errCatI,  $
    stdB, errStdB, stdV, errStdV, stdR, errStdR, stdI, errStdI,  forward=forward

  ; forward: predict stdUBVRI from catalog mags;
  ; if forward not set: reduce from stdUBVRI to catalog mags

  case catalog of
     'USNO-B1.0': begin         ; cannot estimate std UBVRI
        if keyword_set(forward) then begin
           stdB = catB  &  errStdB = errCatB
           stdV = catV  &  errStdV = errCatV
           stdR = catR  &  errStdR = errCatR
           stdI = catI  &  errStdI = errCatI
        endif else begin
           catB = stdB  &  errCatB = errStdB
           catV = stdV  &  errCatV = errStdV
           catR = stdR  &  errCatR = errStdR
           catI = stdI  &  errCatI = errStdI
        endelse
     end
     'GSC-2.3'  : begin
        ; Rf - R = 0
        ; Bf - B = c0 + c1*(B-R) + c2*(B-R)^2
        ; If - I = 0 (for now)
        c0 = +0.052
        c1 = -0.107
        c2 = -0.0228
        if keyword_set(forward) then begin
           stdR = catR
           A = -c2
           B = 1.0-c1+2.0*c2*stdR
           C = -catB-c0+c1*stdR-c2*stdR*stdR
           stdB = (-B + sqrt(B*B-4.0*A*C) ) / (2.0*A)
           stdI = catI
           
           errStdR = errCatR
           errStdB = sqrt( (errCatB^2 - (errStdR^2)*(c1^2 + (2*c2*errCatB)^2 +(2*c2*errStdR)^2) ) / $
                           (            1.0 + c1^2 + (2*c2*errCatB)^2 +(2*c2*errStdR)^2         ) )
           phast_setGSCV, stdB, errStdB, stdR, errStdR, stdV, errStdV
           
        endif else begin
           BmR  = stdB - stdR
           catR = stdR
           catB = stdB - (c0 + c1*BmR + c2*BmR*BmR)
           catI = stdI
           
           errCatR = errStdR
           errCatB = sqrt( (errStdB^2)*(1.0 + c1^2 + (2*c2*errStdB)^2 +(2*c2*errStdR)^2) + $
                           (errStdR^2)*(      c1^2 + (2*c2*errStdB)^2 +(2*c2*errStdR)^2) )
           phast_setGSCV, catB, errCatB, catR, errCatR, catV, errCatV
        endelse
     end
     'Landolt': begin           ; Cat Mag = Std UBVRI
        if keyword_set(forward) then begin
           stdB = catB  &  errStdB = errCatB
           stdV = catV  &  errStdV = errCatV
           stdR = catR  &  errStdR = errCatR
           stdI = catI  &  errStdI = errCatI
        endif else begin
           catB = stdB  &  errCatB = errStdB
           catV = stdV  &  errCatV = errStdV
           catR = stdR  &  errCatR = errStdR
           catI = stdI  &  errCatI = errStdI
        endelse
    end
     else : begin               ; cannot estimate std UBVRI
        if keyword_set(forward) then begin
           stdB = catB  &  errStdB = errCatB
           stdV = catV  &  errStdV = errCatV
           stdR = catR  &  errStdR = errCatR
           stdI = catI  &  errStdI = errCatI
        endif else begin
           catB = stdB  &  errCatB = errStdB
           catV = stdV  &  errCatV = errStdV
           catR = stdR  &  errCatR = errStdR
           catI = stdI  &  errCatI = errStdI
        endelse
     end
  endcase
end

;----------------------------------------------------------------------

pro phast_tvphot

  ; Routine to display the zoomed region around a photometry point,
  ; with circles showing the photometric apterture and sky radii.

  common phast_state
  common phast_images
  
  phast_setwindow, state.photzoom_window_id
  erase
  
  x = round(state.centerpos[0])
  y = round(state.centerpos[1])
  
  boxsize = round(state.outersky * 1.2)
  xsize = (2 * boxsize) + 1
  ysize = (2 * boxsize) + 1
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
  
  dev_width = 0.8 * state.photzoom_size
  dev_pos = [0.15 * state.photzoom_size, $
    0.15 * state.photzoom_size, $
    0.95 * state.photzoom_size, $
    0.95 * state.photzoom_size]
    
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
    
  tvcircle, /data, state.aprad, state.centerpos[0], state.centerpos[1], $
    color=2, thick=2, psym=0
  if (state.skytype NE 2) then begin
    tvcircle, /data, state.innersky, state.centerpos[0], state.centerpos[1], $
      color=4, thick=2, psym=0
    tvcircle, /data, state.outersky, state.centerpos[0], state.centerpos[1], $
      color=5, thick=2, psym=0
  endif
  
  phast_resetwindow
end

;----------------------------------------------------------------------

pro phast_photometry

;for compilation purposes only

end
