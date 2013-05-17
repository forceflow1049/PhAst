;----------------------------------------------------------------------

function phast_degperpix, hdr

  ; This program calculates the pixel scale (deg/pixel) and returns the value

  common phast_state
  
  On_error,2                      ;Return to caller
  
  extast, hdr, bastr, noparams    ;extract astrom params in deg.
  
  a = bastr.crval[0]
  d = bastr.crval[1]
  
  factor = 60.0                   ;conversion factor from deg to arcmin
  d1 = d + (1/factor)             ;compute x,y of crval + 1 arcmin
  
  proj = strmid(bastr.ctype[0],5,3)
  
  case proj of
    'GSS': gsssadxy, bastr, [a,a], [d,d1], x, y
    else:  ad2xy, [a,a], [d,d1], bastr, x, y
  endcase
  
  dmin = sqrt( (x[1]-x[0])^2 + (y[1]-y[0])^2 ) ;det. size in pixels of 1 arcmin
  
  ; Convert to degrees per pixel and return scale
  degperpix = 1. / dmin / 60.
  
  return, degperpix
end

;----------------------------------------------------------------------

pro phast_getFieldEpoch, a0, d0, radius, X, obsDate, JD=datejul
  ; get common specs for image

  common phast_state
  common phast_images

  if ptr_valid(state.astr_ptr) then begin
     xy2ad,state.image_size[0]/2,state.image_size[1]/2,*(state.astr_ptr),a0,d0 ; center
     xy2ad,state.image_size[0]  ,state.image_size[1]  ,*(state.astr_ptr),a1,d1 ; corner
  endif else begin
     RA = sxpar(*state.head_ptr,'RA')  &  a = ten(RA)/15.0
     Dec = sxpar(*state.head_ptr,'DEC') &  d = ten(Dec)
  endelse
  radius = state.pixelscale * sqrt( (state.image_size[0]/2)^2 + (state.image_size[1]/2)^2 ) / 60.0
  X = sxpar(*state.head_ptr,'AIRMASS')  >  0.00 ; use X=0.0 if AIRMASS not present
  if image_archive[state.current_image_index]->get_obs_date() eq 0 then begin
  
  timestr = sxpar(*state.head_ptr,'UT',count=count)
  if count ne 0 then begin
     HH =  long(strmid(timestr,0,2))
     Min =  long(strmid(timestr,3,2))
     Sec = float(strmid(timestr,6))
  endif
  datestr = sxpar(*state.head_ptr,'DATE-OBS',count=count)
  if count ne 0 then begin
     YYYY =  long(strmid(datestr,0,4))
     MM =  long(strmid(datestr,5,2))
     DD =  long(strmid(datestr,8,2))
  endif  else begin
     mjd = sxpar(*state.head_ptr,'MJD-OBS',count=count)
     if count ne 0 then begin 
        daycnv, mjd, YYYY,MM,DD,HH
        Min = (HH - fix(HH))*60
        HH = fix(HH)
        Sec = (Min - fix(Min))*60
        Min = fix(Min)
     endif
  endelse
  
  datejul = JULDAY(MM,DD,YYYY,HH,Min,Sec)
  endif else begin 
     datejul = image_archive[state.current_image_index]->get_obs_date()
     date_vec = date_conv(datejul,'V')
     YYYY = date_vec[0]
  endelse
     exptime = float(sxpar(*state.head_ptr,'EXPTIME'))
     datejul = datejul + 0.5*exptime/3600./24.
  frac = (datejul-julday(01,01,YYYY,00,00,00))/365.0 ; julian year
  obsDate = float(YYYY)+frac
end

;--------------------------------------------------------------------

pro phast_getoffset
 
  ; Routine to calculate the display offset for the current value of
  ; state.centerpix, which is the central pixel in the display window.
  
  common phast_state
 
  state.offset = $
    round( state.centerpix - $
    (0.5 * state.draw_window_size / state.zoom_factor) )
end

;-----------------------------------------------------------------

pro phast_getradec, rastring, decstring, ra, dec

  ; converts ra and dec strings in hh:mm:ss and dd:mm:ss to decimal degrees
  ; new and improved version by Hal Weaver, 9/6/2010

  ra = 15.0 * ten(rastring)
  dec = ten(decstring)
end

;----------------------------------------------------------------------

function phast_get_stars, a, d, radius, AsOf=AsOf, catalog_name=catalog_name
  
;routine to retrieve stars from an outside catalog and format into phast structure
  
  common phast_state
    
  if ~keyword_set(catalog_name) then catalog_name = state.catalog_name
  widget_control, /hourglass    ; initial load could take some time
  
  retCode = 0
  expand  = 1.25                ; add 25% to radius of image
  
  case catalog_name of
     'USNO-B1.0': begin & star_catalog = queryvizier('USNO-B1',[a,d],radius*expand)
                                ;            U     B     V     R     I   (same as GSC)
        minValid = [99.0, 11.3, 99.0, 10.5,  9.7]
        maxValid = [99.0, 22.5, 99.0, 20.8, 19.5]
        
        nLong  = n_elements(star_catalog.USNO_B1_0)
        starID = star_catalog.USNO_B1_0
        
        RA     = star_catalog.RAJ2000
        Dec    = star_catalog.DEJ2000
        Epoch  = star_catalog.Epoch
        pmRA   = star_catalog.pmRA
        pmDec  = star_catalog.pmDE
        if keyword_set(AsOf) then begin
           RA  = RA  + pmRA *(AsOf-Epoch)/1000.0/3600.0 Mod 360.0
           Dec = Dec + pmDec*(AsOf-Epoch)/1000.0/3600.0
           ; we are ignoring possibility of passing through NCP or SCP
           Epoch = replicate(AsOf,nLong)
        endif
        
        UMag   = replicate(!values.F_NaN, nLong) ; U
        
        B1Mag  = star_catalog.B1Mag
        B2Mag  = star_catalog.B2Mag
        BMag   = B1Mag
        select = where(~finite(B1Mag) And finite(B2MAG),count)
        if count GT 0 Then BMag[select] = B2MAG[select]
        select = where( finite(B1MAG) And finite(B2MAG),count)
        if count GT 0 Then BMag[select] = 0.5*(B1MAG[select]+B2MAG[select])
        BMag[ where( ~(minValid[1] LE BMag And BMag LE maxValid[1]) ) ] = !values.F_NaN ; B
        
        VMag   = replicate(!values.F_NaN, nLong) ; V
        
        R1Mag  = star_catalog.R1Mag
        R2Mag  = star_catalog.R2Mag
        RMag   = R1Mag
        select = where(~finite(R1Mag) And finite(R2MAG),count)
        if count GT 0 Then RMag[select] = R2MAG[select]
        select = where( finite(R1MAG) And finite(R2MAG),count)
        if count GT 0 Then RMag[select] = 0.5*(R1MAG[select]+R2MAG[select])
        RMag[ where( ~(minValid[3] LE RMag And RMag LE maxValid[3]) ) ] = !values.F_NaN ; R
        
        IMag   = replicate(!values.F_NaN, nLong) ; I
        
        errUMag   = replicate(!values.F_NaN, nLong) ; errU
        errBMag   = replicate(!values.F_NaN, nLong) ; errB
        errVMag   = replicate(!values.F_NaN, nLong) ; errV
        errRMag   = replicate(!values.F_NaN, nLong) ; errR
        errIMag   = replicate(!values.F_NaN, nLong) ; errI
        
                                ; USNO B1.0 cannot be standardized at this time
        
        state.catalog_loaded = 1
        catalog = { starID:starID, RA:RA, Dec:Dec, Epoch:Epoch, UMag:UMag, errUMag:errUMag, $
                    BMag:BMag, errBMag:errBMag, $
                    VMag:VMag, errVMag:errVMag, $
                    RMag:RMag, errRMag:errRMag, $
                    IMag:IMag, errIMag:errIMag }
        retCode = 1
        
     end
     
     'GSC-2.3': begin
        star_catalog = queryvizier('GSC-2.3',[a,d],radius*expand,/ALLCOLUMNS)
      ; Lasker et al. AJ, 136:735-766, 2008 August
      ; Table 7 truncating 0.01% at bright end; 1% at faint end
      ;            U     B     V     R     I
        minValid = [99.0, 11.3, 99.0, 10.5,  9.7]
        maxValid = [99.0, 22.5, 99.0, 20.8, 19.5]
        
        nLong  = n_elements(star_catalog.gsc2_3)
        starID = star_catalog.GSC2_3
        RA = star_catalog.RAJ2000
        Dec = star_catalog.DEJ2000
        Epoch  = star_catalog.Epoch
        pmRA   = 0.0            ; star_catalog.pmRA
        pmDec  = 0.0            ; star_catalog.pmDE
        if keyword_set(AsOf) then begin
           RA  = RA  + pmRA *(AsOf-Epoch)/1000.0/3600.0 Mod 360.0
           Dec = Dec + pmDec*(AsOf-Epoch)/1000.0/3600.0
           ; we are ignoring possibility of passing through NCP or SCP
           Epoch = replicate(AsOf,nLong)
        endif
        UMag = replicate(!values.F_NaN, nLong)
        BMag = star_catalog.jmag
        Vmag = replicate(!values.F_NaN, nLong)
        Rmag = star_catalog.fmag
        Imag = star_catalog.nmag
        errUMag = replicate(!values.F_NaN, nLong)
        errBMag = star_catalog.e_jmag
        errVMag = replicate(!values.F_NaN, nLong)
        errRMag = star_catalog.e_fmag
        errIMag = star_catalog.e_nmag
        
        phast_stdUBVRI, 'GSC-2.3', BMag, errBMag, VMag, errVMag, RMag, errRMag, IMag, errIMag, $
                        stdB, errStdB, stdV, errStdV, stdR, errStdR, stdI, errStdI, /forward
        
        BMag = stdB & errBMag = errStdB
        VMag = stdV & errVMag = errStdV
        RMag = stdR & errRMag = errStdR
        
        state.catalog_loaded = 1
        catalog = { starID:starID, RA:RA, Dec:Dec, Epoch:Epoch, UMag:UMag, errUMag:errUMag, $
                    BMag:BMag, errBMag:errBMag, $
                    VMag:VMag, errVMag:errVMag, $
                    RMag:RMag, errRMag:errRMag, $
                    IMag:IMag, errIMag:errIMag }
        retCode = 1
        
     end
     
     'Landolt': begin
      if file_test('./landolt_usno.1.dat') eq 0 then begin
         print, 'Landolt catalog not found in ./PhAst root directory'
         print, '    ... download landolt_usno.1.dat from http://web.pd.astro.it/blanc/landolt/landolt.html'
      endif else begin
         
         ;star_catalog = queryvizier('Landolt',[a,d],radius*expand,/ALLCOLUMNS) astrometry is poor
         readcol, './landolt_usno.1.dat', starID, RA, Dec, Vmag, BmV, UmB, VmR, RmI, VmI, NObs, Nites, e_VMag, e_BmV, e_UmB, e_VmR, e_RmI, e_VmI, $
                  delimiter=',', format='A,A,A,F,F,F,F,F,F,I,I,F,F,F,F,F,F'
         
         if n_elements(starID) le 0 then begin
            retCode = 0
         endif else begin
            nLong  = n_elements(starID)
            starID = starID
            RA = 15*tenv(RA)
            Dec = tenv(Dec)
            Epoch  = 1992.0     ; date of publication, actually
            pmRA   = 0.0        ; star_catalog.pmRA
            pmDec  = 0.0        ; star_catalog.pmDE
            if keyword_set(AsOf) then begin
               RA  = RA  + pmRA *(AsOf-Epoch)/1000.0/3600.0 Mod 360.0
               Dec = Dec + pmDec*(AsOf-Epoch)/1000.0/3600.0
               ; we are ignoring possibility of passing through NCP or SCP
               Epoch = replicate(AsOf,nLong)
            endif
            Vmag = VMag         &  errVMag = e_VMag
            
            Rmag = VMag - VmR   &  errRMag = sqrt( errVMag^2 + e_VmR^2 )
            Imag = VMag - VmI   &  errIMag = sqrt( errVMag^2 + e_VmI^2 )   
            Bmag = VMag + BmV   &  errBMag = sqrt( errVMag^2 + e_BmV^2 ) 
            Umag = BMag - UmB   &  errUMag = sqrt( errBMag^2 + e_UmB^2 )
        
            state.catalog_loaded = 1
            catalog = { starID:starID, RA:RA, Dec:Dec, Epoch:Epoch, UMag:UMag, errUMag:errUMag, $
                        BMag:BMag, errBMag:errBMag, $
                        VMag:VMag, errVMag:errVMag, $
                        RMag:RMag, errRMag:errRMag, $
                        IMag:IMag, errIMag:errIMag }
            retCode = 1
         endelse  
         
      endelse
      
   end     
     
     else: begin
        print, 'Catalog not recognized'
        retCode = 0
     end
     
  endcase
  
  if retCode eq 0 then begin
     state.catalog_loaded = 1
     nodata = [!values.F_NaN]
     catalog = { starID:nodata, RA:nodata, Dec:nodata, Epoch:nodata, UMag:nodata, errUMag:nodata, $
                 BMag:nodata, errBMag:nodata, $
                 VMag:nodata, errVMag:nodata, $
                 RMag:nodata, errRMag:nodata, $
                 IMag:nodata, errIMag:nodata }
  endif
  
  return, catalog
end

;----------------------------------------------------------------------

pro phast_search_stars

  ; Routine to search currently displayed image for a given star

  common phast_state
  common phast_images
  common phast_pdata
  
  widget_control,state.star_search_widget_id,get_value=term
  
  if ptr_valid(state.astr_ptr) then begin
     phast_getFieldEpoch, a, d,radius, X, obsDate
     catalog_name = state.overlay_catList(state.overlay_catalog)
     star_catalog = phast_get_stars(a,d,radius,AsOf=obsDate,catalog_name=catalog_name)
     ra    = star_catalog.RA
     dec   = star_catalog.Dec
     name  = star_catalog.starID
     ad2xy,ra,dec,*(state.astr_ptr),x,y
     x1 = x[where(x gt 0 and x lt state.image_size[0] and y gt 0 and y lt state.image_size[1])]
     y1 = y[where(x gt 0 and x lt state.image_size[0] and y gt 0 and y lt state.image_size[1])]
     name1 = name[where(x gt 0 and x lt state.image_size[0] and y gt 0 and y lt state.image_size[1])]
     index_list = where(name1 eq term[0])
     if index_list ne -1 then begin
        colorcode = 'blue'
        circlesize = 7   &  circletext = strtrim(string(circlesize))
        fontsize = 1.75  &    fonttext = strtrim(string(fontsize))
        offset = circlesize + 3     
        if nplot lt maxplot then begin
           nplot++
           region_str = 'circle('+strtrim(string(x1[index_list]),2)+', '+strtrim(string(y1[index_list]),2)+', ' $
                        + circletext + ') # color=' + colorcode
           options = {color:colorcode,thick:fonttext}
           options.color = phast_icolor(options.color)
           pstruct = {type:'region',reg_array:[region_str],options:options}
           plot_ptr[nplot] =ptr_new(pstruct)
           phast_plotwindow
           phast_plot1region,nplot
        endif
        phastxyouts,x1[index_list]+5,y1[index_list],name1[index_list],charsize=fontsize,color=colorcode
        widget_control,state.search_msg_id,set_value='Search successful!'
     endif else begin
        widget_control,state.search_msg_id,set_value='Search term not found'
     endelse
     
  endif else begin
     widget_control,state.search_msg_id,set_value='WCS data not present'
  end
end

;----------------------------------------------------------------------

function phast_wavestring

  ; function to return string with wavelength info for spectral images.
  ; Currently works for HST STIS 2-d images.

  common phast_state
  
  cd = float(sxpar(*state.head_ptr,'CD1_1'));, /silent))
  if (cd EQ 0.0) then $
    cd = float(sxpar(*state.head_ptr,'CDELT1'));, /silent))
  crpix = float(sxpar(*state.head_ptr,'CRPIX1'));, /silent)) - 1
  crval = float(sxpar(*state.head_ptr,'CRVAL1'));, /silent))
  shifta = float(sxpar(*state.head_ptr, 'SHIFTA1'));, /silent))
  
  if ((state.cube EQ 1) AND (state.osiriscube EQ 1)) then begin
    wavelength = crval + ((state.slice - crpix) * cd)
  endif else begin
    wavelength = crval + ((state.coord[0] - crpix) * cd) + (shifta * cd)
  endelse
  
  wstring = string(wavelength, format='(F8.2)')
  
  wavestring = strcompress('Wavelength:  ' + wstring + ' ' + state.cunit)
  
  return, wavestring
end

;----------------------------------------------------------------------

function phast_wcs2pix, coords, coord_sys=coord_sys, line=line

  common phast_state
  
  ; check validity of state.astr_ptr and state.head_ptr before
  ; proceeding to grab wcs information
  
  if ptr_valid(state.astr_ptr) then begin
    ctype = (*state.astr_ptr).ctype
    equinox = state.equinox
    disp_type = state.display_coord_sys
    disp_equinox = state.display_equinox
    disp_base60 = state.display_base60
    bastr = *(state.astr_ptr)
    
    ; function to convert an PHAST region from wcs coordinates to pixel coordinates
    degperpix = phast_degperpix(*(state.head_ptr))
    
    ; need numerical equinox values
    IF (equinox EQ 'J2000') THEN num_equinox = 2000.0 ELSE $
      IF (equinox EQ 'B1950') THEN num_equinox = 1950.0 ELSE $
      num_equinox = float(equinox)
      
    headtype = strmid(ctype[0], 0, 4)
    n_coords = n_elements(coords)
  endif
  
  case coord_sys of
  
    'j2000': begin
      if (strpos(coords[0], ':')) ne -1 then begin
        ra_arr = strsplit(coords[0],':',/extract)
        dec_arr = strsplit(coords[1],':',/extract)
        ra = ten(float(ra_arr[0]), float(ra_arr[1]), $
          float(ra_arr[2])) * 15.0
        dec = ten(float(dec_arr[0]), float(dec_arr[1]), $
          float(dec_arr[2]))
        if (keyword_set(line)) then begin
          ra1_arr = strsplit(coords[2],':',/extract)
          dec1_arr = strsplit(coords[3],':',/extract)
          ra1 = ten(float(ra1_arr[0]), float(ra1_arr[1]), $
            float(ra1_arr[2])) * 15.0
          dec1 = ten(float(dec1_arr[0]), float(dec1_arr[1]), $
            float(dec1_arr[2]))
        endif
      endif else begin        ; coordinates in degrees
        ra=float(coords[0])
        dec=float(coords[1])
        if (keyword_set(line)) then begin
          ra1=float(coords[2])
          dec1=float(coords[3])
        endif
      endelse
      
      if (not keyword_set(line)) then begin
        if (n_coords ne 6) then $
          coords[2:n_coords-2] = $
          strcompress(string(float(coords[2:n_coords-2]) / $
          (degperpix * 60.)),/remove_all) $
        else $
          coords[2:n_coords-3] = $
          strcompress(string(float(coords[2:n_coords-3]) / $
          (degperpix * 60.)),/remove_all)
      endif
      
    end
    
    'b1950': begin
      if (strpos(coords[0], ':')) ne -1 then begin
        ra_arr = strsplit(coords[0],':',/extract)
        dec_arr = strsplit(coords[1],':',/extract)
        ra = ten(float(ra_arr[0]), float(ra_arr[1]), $
          float(ra_arr[2])) * 15.0
        dec = ten(float(dec_arr[0]), float(dec_arr[1]), float(dec_arr[2]))
        precess, ra, dec, 1950.0, 2000.0
        if (keyword_set(line)) then begin
          ra1_arr = strsplit(coords[2],':',/extract)
          dec1_arr = strsplit(coords[3],':',/extract)
          ra1 = ten(float(ra1_arr[0]), float(ra1_arr[1]), $
            float(ra1_arr[2])) * 15.0
          dec1 = ten(float(dec1_arr[0]), float(dec1_arr[1]), $
            float(dec1_arr[2]))
          precess, ra1, dec1, 1950.0,2000.0
        endif
      endif else begin      ; convert B1950 degrees to J2000 degrees
        ra = float(coords[0])
        dec = float(coords[1])
        precess, ra, dec, 1950.0, 2000.0
        if (keyword_set(line)) then begin
          ra1=float(coords[2])
          dec1=float(coords[3])
          precess, ra1, dec1, 1950., 2000.0
        endif
      endelse
      
      if (not keyword_set(line)) then begin
        if (n_coords ne 6) then $
          coords[2:n_coords-2] = $
          strcompress(string(float(coords[2:n_coords-2]) / $
          (degperpix * 60.)),/remove_all) $
        else $
          coords[2:n_coords-3] = $
          strcompress(string(float(coords[2:n_coords-3]) / $
          (degperpix * 60.)),/remove_all)
      endif
    end
    
    'galactic': begin           ; convert galactic to J2000 degrees
      euler, float(coords[0]), float(coords[1]), ra, dec, 2
      if (not keyword_set(line)) then begin
        if (n_coords ne 6) then $
          coords[2:n_coords-2] = $
          strcompress(string(float(coords[2:n_coords-2]) / $
          (degperpix * 60.)),/remove_all) $
        else $
          coords[2:n_coords-3] = $
          strcompress(string(float(coords[2:n_coords-3]) / $
          (degperpix * 60.)),/remove_all)
      endif else begin
        euler, float(coords[2]), float(coords[3]), ra1, dec1, 2
      endelse
    end
    
    'ecliptic': begin           ; convert ecliptic to J2000 degrees
      euler, float(coords[0]), float(coords[1]), ra, dec, 4
      if (not keyword_set(line)) then begin
        if (n_coords ne 6) then $
          coords[2:n_coords-2] = $
          strcompress(string(float(coords[2:n_coords-2]) / $
          (degperpix * 60.)),/remove_all) $
        else $
          coords[2:n_coords-3] = $
          strcompress(string(float(coords[2:n_coords-3]) / $
          (degperpix * 60.)),/remove_all)
      endif else begin
        euler, float(coords[2]), float(coords[3]), ra1, dec1, 4
      endelse
    end
    
    'current': begin
      ra_arr = strsplit(coords[0],':',/extract)
      dec_arr = strsplit(coords[1],':',/extract)
      ra = ten(float(ra_arr[0]), float(ra_arr[1]), float(ra_arr[2])) * 15.0
      dec = ten(float(dec_arr[0]), float(dec_arr[1]), float(dec_arr[2]))
      if (not keyword_set(line)) then begin
        coords[2] = strcompress(string(float(coords[2]) / $
          (degperpix * 60.)),/remove_all)
        if (n_coords gt 3) then $
          coords[3] = strcompress(string(float(coords[3]) / $
          (degperpix * 60.)),/remove_all)
      endif else begin
        ra1_arr = strsplit(coords[2],':',/extract)
        dec1_arr = strsplit(coords[3],':',/extract)
        ra1 = ten(float(ra1_arr[0]), float(ra1_arr[1]), float(ra1_arr[2])) * 15.0
        dec1 = ten(float(dec1_arr[0]), float(dec1_arr[1]), float(dec1_arr[2]))
      endelse
      
      if (num_equinox ne 2000.) then begin
        precess, ra, dec, num_equinox, 2000.
        if (keyword_set(line)) then precess, ra1, dec1, num_equinox, 2000.
      endif
      
    end
    
    'pixel': begin
    ; Do nothing when pixel.  Will pass pixel coords array back.
    end
    
    else:
    
  endcase
  
  if (ptr_valid(state.astr_ptr) AND coord_sys ne 'pixel') then begin
  
    if (num_equinox ne 2000) then begin
      precess, ra, dec, 2000., num_equinox
      if (keyword_set(line)) then precess, ra1, dec1, 2000., num_equinox
    endif
    
    proj = strmid(ctype[0],5,3)
    
    case proj of
      'GSS': begin
        gsssadxy, bastr, ra, dec, x, y
        if (keyword_set(line)) then gsssadxy, bastr, ra1, dec1, x1, y1
      end
      else: begin
        ad2xy, ra, dec, bastr, x, y
        if (keyword_set(line)) then ad2xy, ra1, dec1, bastr, x1, y1
      end
    endcase
    
    coords[0] = strcompress(string(x),/remove_all)
    coords[1] = strcompress(string(y),/remove_all)
    if (keyword_set(line)) then begin
      coords[2] = strcompress(string(x1),/remove_all)
      coords[3] = strcompress(string(y1),/remove_all)
    endif
  endif
  
  return, coords
end

;---------------------------------------------------------------------

function phast_wcsstring, lon, lat, ctype, equinox, disp_type, disp_equinox, $
                          disp_base60
    
  ; Routine to return a string which displays cursor coordinates.
  ; Allows choice of various coordinate systems.
  ; Contributed by D. Finkbeiner, April 2000.
  ; 29 Sep 2000 - added degree (RA,dec) option DPF
  ; Apr 2007: AJB added additional error checking to prevent crashes
  
  ; ctype - coord system in header
  ; disp_type - type of coords to display

  common phast_state
  
  
  headtype = strmid(ctype[0], 0, 4)
  
  ; need numerical equinox values
  IF (equinox EQ 'J2000') THEN num_equinox = 2000.0 ELSE $
    IF (equinox EQ 'B1950') THEN num_equinox = 1950.0 ELSE $
    num_equinox = float(equinox)
    
  IF (disp_equinox EQ 'J2000') THEN num_disp_equinox = 2000.0 ELSE $
    IF (disp_equinox EQ 'B1950') THEN num_disp_equinox = 1950.0 ELSE $
    num_disp_equinox = float(equinox)
    
  ; first convert lon,lat to RA,dec (J2000)
  CASE headtype OF
    'GLON': euler, lon, lat, ra, dec, 2 ; J2000
    'ELON': BEGIN
      euler, lon, lat, ra, dec, 4 ; J2000
      IF num_equinox NE 2000.0 THEN precess, ra, dec, num_equinox, 2000.0
    END
    'RA--': BEGIN
      ra = lon
      dec = lat
      IF num_equinox NE 2000.0 THEN precess, ra, dec, num_equinox, 2000.0
    END
    'DEC-': BEGIN       ; for SDSS images
      ra = lon
      dec = lat
      IF num_equinox NE 2000.0 THEN precess, ra, dec, num_equinox, 2000.0
    END
    else: begin
      wcsstring = '---No WCS Info---'
      widget_control, state.wcs_bar_id, set_value = wcsstring
      state.wcstype = 'none'
      return, wcsstring
    end
  ENDCASE
  
  ; Now convert RA,dec (J2000) to desired display coordinates:
  
  IF (disp_type[0] EQ 'RA--' or disp_type[0] EQ 'DEC-') THEN BEGIN
    ; generate (RA,dec) string
    disp_ra  = ra
    disp_dec = dec
    IF (num_disp_equinox NE 2000.0) THEN precess, disp_ra, disp_dec, $
      2000.0, num_disp_equinox
      
    IF disp_base60 THEN BEGIN ; (hh:mm:ss) format
    
      neg_dec  = disp_dec LT 0
      radec, disp_ra, abs(disp_dec), ihr, imin, xsec, ideg, imn, xsc
      wcsstring = string(ihr, imin, xsec, ideg, imn, xsc, disp_equinox, $
        format = '(i2.2,":",i2.2,":",f6.3,"   ",i2.2,":",i2.2,":",f5.2," ",a6)' )
      if (strmid(wcsstring, 6, 1) EQ ' ') then $
        strput, wcsstring, '0', 6
      if (strmid(wcsstring, 21, 1) EQ ' ') then $
        strput, wcsstring, '0', 21
      IF neg_dec THEN strput, wcsstring, '-', 14
      
    ENDIF ELSE BEGIN ; decimal degree format
    
      wcsstring = string(disp_ra, disp_dec, disp_equinox, $
        format='("Deg ",F9.5,",",F9.5,a6)')
    ENDELSE
  ENDIF
  
  
  IF disp_type[0] EQ 'GLON' THEN BEGIN ; generate (l,b) string
    euler, ra, dec, l, b, 1
    
    wcsstring = string(l, b, format='("Galactic (",F9.5,",",F9.5,")")')
  ENDIF
  
  IF disp_type[0] EQ 'ELON' THEN BEGIN ; generate (l,b) string
  
    disp_ra = ra
    disp_dec = dec
    IF num_disp_equinox NE 2000.0 THEN precess, disp_ra, disp_dec, $
      2000.0, num_disp_equinox
    euler, disp_ra, disp_dec, lam, bet, 3
    
    wcsstring = string(lam, bet, format='("Ecliptic (",F9.5,",",F9.5,")")')
  ENDIF
  
  return, wcsstring
END

;---------------------------------------------------------------------

pro aaac_phast_astrometry

;for compilation purposes only

end
