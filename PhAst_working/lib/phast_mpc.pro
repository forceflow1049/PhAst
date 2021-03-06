;----------------------------------------------------------------------

pro phast_get_mpc_data,index,magn

  ;routine to record data for mpc report and pass it back to the main
  ;MPC front end.

  common phast_state
  common phast_images
  common phast_mpc_data
  
  if index ne 0 then begin
    xy2ad,state.centerpos[0],state.centerpos[1],*(state.astr_ptr),ra1,dec1
    mpc_ra[index-1] = ra1
    mpc_dec[index-1] = dec1
    head = headfits(state.imagename)
    ;read header parameters
    obs_time = sxpar(head,'DATE-OBS')
    ut = sxpar(head,'UT')
    exptime = sxpar(head,'EXPTIME')
    ;check for missing parameters
    error = 0
    test = sxpar(head,'test')
    if obs_time eq '' then begin
      result = dialog_message('DATE-OBS parameter missing from header!',/error,/center)
      error = 1
    endif
    if ut eq '' then begin
      result = dialog_message('UT parameter missing from header!',/error,/center)
      error = 1
    endif
    if exptime eq '' then begin
      result = dialog_message('EXPTIME parameter missing from header!',/error,/center)
      error = 1
    endif
    
    if error eq 0 then begin ;parse exposure time data
      obs_split = strsplit(obs_time,'-:T',/extract)
      ut_split = strsplit(ut,':',/extract)
      day =float(ut_split[0])/24 + float(ut_split[1])/24/60 + float(ut_split[2]+0.5*exptime)/24/60/60
      day_split = strsplit(day,'.',/extract)
      mpc_date[index-1] = obs_split[0]+' '+obs_split[1]+' '+strtrim(obs_split[2])+'.'+string(strtrim(string(day_split[1]),1),format='(A5)')
      ;get passband
      mpc_band[index-1] = strtrim(sxpar(head,'magzbnd'))
      mpc_mag[index-1] = magn
      mpc_day_fraction[index-1] = day
    endif
    
  endif
end

;----------------------------------------------------------------------

function phast_get_mpc_ephem,name,date

;routine to retrieve an asteroid ephemeris from NEODyS and return the
;RA/Dec of the object. Date should be in julian date


common phast_state
common phast_mpc_data

widget_control, /hourglass

if mpc.site_code eq '000' then print, 'Warning: Using observatory code 000 (Greenwich).  Are you sure this is the correct location?'

;convert date
hour = 1./24 ;1 hour in JD
start = date - hour
finish = date + hour

start_str = date_conv(start, 'FITS') ; YYYY-MM-DDTHH:MM:SS.SS
finish_str = date_conv(finish,'FITS'); YYYY-MM-DDTHH:MM:SS.SS
start_split = strsplit(start_str,'-:T',/extract)
finish_split = strsplit(finish_str,'-:T',/extract)

tries = 0 ; allow user to self-enter name once
while 1 eq 1 do begin
   tries++
   query = 'http://newton.dm.unipi.it/neodys/index.php?pc=1.1.3.1&n='+strcompress(name,/remove_all)+'&oc='+mpc.site_code+'&y0='+start_split[0]+'&m0='+start_split[1]+'&d0='+start_split[2]+'&h0='+start_split[3]+'&mi0='+start_split[4]+'&y1='+finish_split[0]+'&m1='+finish_split[1]+'&d1='+finish_split[2]+'&h1='+finish_split[3]+'&mi1='+finish_split[4]+'&ti=1.0&tiu=minutes'
   
   a = webget(query)
   
   count = 0
   openw, 1,'ephem.txt'
   for i=154, n_elements(a.text)-30 do begin
      count++
      ;check for case of + n or - n and make it +n or -n for DEC
      if strpos(a.text[i],'+ ') ne -1 then begin
         split = strsplit(a.text[i],'+',/extract)
         a.text[i] = split[0]+'+'+strtrim(split[1],1)
      endif else if strpos(a.text[i],'- ') ne -1 then a.text[i] = strmid(a.text[i],0,strpos(a.text[i],'- '))+' -'+strmid(a.text[i],strpos(a.text[i],'- ')+2)
      printf, 1,a.text[i]
   endfor
   close,1

   if count eq 0 then begin
      if tries lt 2 then begin
         name = dialog_input(prompt='Object ' + name + ' not found.  Please enter the correct name:',title='Error')
      endif else begin
         err = dialog_message('This object is not recognized by NEODys',/error,/center)
         return, list()
      endelse
   endif else break
endwhile

readcol, 'ephem.txt',day,monrh,year,hour,ra_h,ra_m,ra_s,dec_d,dec_m,dec_s,mag,alt,airmass, sun_elv, sol_elv, lun_elv,phast,glat,glon,r,delta,v_ra,v_dec,err_long,err_short,err_pa,Format='I,A,L,F,I,I,F,A,I,F,F,F,A,A,F,F,F,F,F,F,F,F,F,A,A,F'

file_delete,'ephem.txt' ;clean up

;convert to degrees
ra_deg = fltarr(n_elements(ra_h))
dec_deg = fltarr(n_elements(ra_h))
err_long_deg = fltarr(n_elements(ra_h))
err_short_deg = fltarr(n_elements(ra_h))

for i=0, n_elements(ra_deg)-1 do begin
   ra_deg[i] = ten(ra_h[i],ra_m[i],ra_s[i])*15
   dec_deg[i] = ten(dec_d[i],dec_m[i],dec_s[i])
   if strpos(err_long[i],"'") ne -1 then err_long_deg[i] = float(err_long[i])/60
   if strpos(err_long[i],'"') ne -1 then err_long_deg[i] = float(err_long[i])/60/60
   if strpos(err_short[i],"'") ne -1 then err_short_deg[i] = float(err_short[i])/60
   if strpos(err_short[i],'"') ne -1 then err_short_deg[i] = float(err_short[i])/60/60
endfor
return, list(ra_deg,dec_deg,err_long_deg,err_short_deg,err_pa) ;[ra,dec,err_long,err_short,err_pa] in degrees
end

;----------------------------------------------------------------------

pro phast_mpc_generate_report

  ;routine to generate the text file MPC report

  common phast_state
  common phast_mpc_data
  
  planet_number = '' ;in case I want it more flexible later
  asterisk = ''
  
  ;open text file
  openw,1,'output/MPC_report.txt'
  printf,1,'COD '+strtrim(string(mpc.site_code),1)
  printf,1,'CON '+mpc.contact_name + ' ' + mpc.contact_address + ' ' + mpc.contact_email
  printf,1,'OBS '+mpc.observers
  printf,1,'MEA '+mpc.measurer
  printf,1,'TEL '+mpc.telescope
  printf,1,'ACK '+mpc.ack+' -- '+mpc.prov_desig
  printf,1,'AC2 '+mpc.contact_email
  printf,1,'NET '+mpc.net
  printf,1,'COM '+mpc.com
  for i=0,n_elements(mpc_date)-1 do begin
    sign = '+'
    if mpc_ra[i] ne 0 then begin
      radec,mpc_ra[i],mpc_dec[i],rh,rm,rs,dd,dm,ds
      if dd lt 0 or dm lt 0 or ds lt 0 then sign='-'
      printf,1,planet_number,mpc.prov_desig,asterisk,mpc.note1,mpc.note2,mpc_date[i],rh,rm,rs,sign,abs(dd),abs(dm),abs(float(round(1000*ds))/1000),float(round(1000*mpc_mag[i]))/1000,mpc_band[i],mpc.site_code,format='(A5,A7,A1,A1,A1,A-17,I2,1X,I2,1X,F5.2,1X,A1,I2,1X,I2,1X,F4.1,10X,F4.1,1X,A1,6X,I3)'
    endif
  endfor
  printf,1,'----- end -----'
  close,1
end

;----------------------------------------------------------------------

pro phast_mpc_report

  ;front end for mpc report generation

  common phast_state
  common phast_images
  common phast_mpc_data
  
  mpc.num_points = 1
  mpc.index = 0
  mpc_date = strarr(5)
  mpc_ra = dblarr(5)
  mpc_dec = dblarr(5)
  mpc_mag = fltarr(5)
  mpc_band = strarr(5)
  
  if (not (xregistered('phast_mpc_report', /noshow))) then begin
  
    mpc_base = $
      widget_base(/base_align_left, $
      group_leader = state.base_id, $
      /column, $
      title = 'Generate an MPC report', $
      uvalue = 'mpc_base')
    top_label = widget_label(mpc_base,value='Use the following tabs to create an MPC object report.')
    
    info_toggle = widget_button(mpc_base,value='Observer Information',uvalue='info_toggle')
    mpc.info_tab = widget_base(mpc_base,/column)
    data_toggle = widget_button(mpc_base,value='Choose data', uvalue='data_toggle')
    mpc.data_tab = widget_base(mpc_base,/column)
    plot_toggle = widget_button(mpc_base,value='Check plots',uvalue='plot_toggle')
    mpc.plot_tab = widget_base(mpc_base,/column)
    endbox = widget_base(mpc_base,/row)
    
    ;info tab
    info_tab_label1 = widget_label(mpc.info_tab,value='Observatory details')
    info_1 = widget_base(mpc.info_tab,/row)
    site_code_label = widget_label(info_1,value='MPC code:  ')
    mpc.site_code_text = widget_text(info_1,value=strtrim(string(mpc.site_code),1),uvalue='site_code',/editable,/all_events,xsize=3)
    height_label = widget_label(info_1,value='Elevation: ')
    mpc.height_box = widget_text(info_1,value=strtrim(string(mpc.height),1),uvalue='height_box',/editable,/all_events,xsize=7)
    height_units = widget_label(info_1,value='m ')
    info_2 = widget_base(mpc.info_tab,/row)
    lon_label = widget_label(info_2,value='Longitude: ')
    mpc.lon_box = widget_text(info_2,value=strtrim(string(mpc.lon),1),uvalue='lon_box',/editable,/all_events,xsize=7)
    lon_unit = widget_label(info_2,value='deg')
    lon_dir_box = widget_base(info_2,/row,/exclusive)
    mpc.lon_east = widget_button(lon_dir_box,value='East ',uvalue='lon_east')
    mpc.lon_west = widget_button(lon_dir_box,value='West',uvalue='lon_west')
    info_3 = widget_base(mpc.info_tab,/row)
    lat_label = widget_label(info_3,value='Latitude:  ')
    mpc.lat_box = widget_text(info_3,value=strtrim(string(mpc.lat),1),uvalue='lat_box',/editable,/all_events,xsize=7)
    lat_unit = widget_label(info_3,value='deg')
    lat_dir_box = widget_base(info_3,/row,/exclusive)
    mpc.lat_north = widget_button(lat_dir_box,value='North',uvalue='lat_north')
    mpc.lat_south = widget_button(lat_dir_box,value='South',uvalue='lat_south')
    info_4 = widget_base(mpc.info_tab,/row)
    tel_label = widget_label(info_4, value='Telescope: ')
    mpc.tel_box = widget_text(info_4,value=mpc.telescope,uvalue='tel_box',/editable,/all_events,xsize=20)
    code_label = widget_label(info_4,value='Code: ')
    mpc.code_box = widget_text(info_4,value=strtrim(string(mpc.code),1),uvalue='code_box',xsize=1,/editable,/all_events)
    info_tab_label2 = widget_label(mpc.info_tab,value='Observer details')
    info_5 = widget_base(mpc.info_tab,/row)
    name_label = widget_label(info_5,value='Contact:   ')
    mpc.name_box = widget_text(info_5,value=mpc.contact_name,uvalue='name_box',/editable,/all_events,xsize=30)
    info_6 = widget_base(mpc.info_tab,/row)
    address_label = widget_label(info_6,value='Address:   ')
    mpc.address_box = widget_text(info_6,value=mpc.contact_address,uvalue='address_box',/editable,/all_events,xsize=30)
    info_7 = widget_base(mpc.info_tab,/row)
    email_label = widget_label(info_7,value='E-mail:    ')
    mpc.email_box = widget_text(info_7,value=mpc.contact_email,uvalue='email_box',/editable,/all_events,xsize=30)
    info_8 = widget_base(mpc.info_tab,/row)
    observers_label = widget_label(info_8,value='Observers: ')
    mpc.observers_box = widget_text(info_8,value=mpc.observers,uvalue='observers_box',/editable,/all_events,xsize=30)
    info_9 = widget_base(mpc.info_tab,/row)
    measureer_label = widget_label(info_9,value='Measuerer: ')
    mpc.measurer_box = widget_text(info_9,value=mpc.measurer,uvalue='measurers_box',/editable,/all_events,xsize=30)
    
    ;Data tab
    data_label = widget_label(mpc.data_tab,value='Select up to five date points for reporting:')
    desig_box = widget_base(mpc.data_tab,/row)
    desig_label = widget_label(desig_box,value='Designation: ')
    mpc.desig_text = widget_text(desig_box,value=mpc.prov_desig,uvalue='desig',/editable,/all_events,xsize=7)
    note1_label = widget_label(desig_box,value='Note 1: ')
    mpc.note1_text = widget_text(desig_box,value=mpc.note1,uvalue='note1',/editable,/all_events,xsize=1)
    note2_label = widget_label(desig_box,value='Note 2: ')
    mpc.note2_text = widget_text(desig_box,value=mpc.note2,uvalue='note1',/editable,/all_events,xsize=1)
    com_label = widget_label(desig_box,value='Comment: ')
    mpc.com_text = widget_text(desig_box,value=mpc.com,uvalue='com',/editable,/all_events)
    select_box = widget_base(mpc.data_tab,/row)
    mpc.select_point = widget_button(select_box,value='Choose a data point',uvalue='select_point')
    mpc.points_added_id = widget_label(select_box,value='Points added: '+strtrim(string(mpc.num_points-1),1))
    
    ;Plot tab
    refresh_plot = widget_button(mpc.plot_tab,value='Refresh plot',uvalue='refresh_plot')
    stats_box = widget_base(mpc.plot_tab,/row)
    velocity_label = widget_label(stats_box,value='Velocity: ')
    mpc.velocity_box = widget_label(stats_box,value='-',/dynamic_resize)
    velocity_unit = widget_label(stats_box,value=' arcmin/hr')
    pos_angle_label = widget_label(stats_box,value=' Position angle: ')
    mpc.pos_angle_box = widget_label(stats_box,value='-',/dynamic_resize)
    pos_angle_unit = widget_label(stats_box,value=' deg')
    plot_canvas = widget_draw(mpc.plot_tab,xsize=500,ysize=500,retain=2)
    
    
    report = widget_button(endbox,value='Report',uvalue='report')
    done = widget_button(endbox,value='Done',uvalue='done')
    
    widget_control, mpc_base, /realize
    
    xmanager, 'phast_mpc_report', mpc_base, /no_block
    
    ;collapse tabs to start
    widget_control,mpc.info_tab,ysize=1
    widget_control,mpc.data_tab,ysize=1
    widget_control,mpc.plot_tab,ysize=1
    
    WIDGET_CONTROL, plot_canvas, GET_VALUE = index
    mpc.plot_id = index
    
    phast_resetwindow
  endif
end

;----------------------------------------------------------------------

pro phast_mpc_report_event, event

  ;event handler for mpc report frontend

  common phast_state
  common phast_mpc_data
  
  widget_control, event.id, get_uvalue = uvalue
  
  case uvalue of
    ;info tab
    'info_toggle': begin
      if mpc.info_toggle eq 0 then begin
        widget_control,mpc.info_tab,ysize=400
        widget_control,mpc.data_tab,ysize=1
        widget_control,mpc.plot_tab,ysize=1
        mpc.info_toggle = 1
        mpc.data_toggle = 0
        mpc.plot_toggle = 0
      endif else begin
        widget_control,mpc.info_tab,ysize=1
        mpc.info_toggle = 0
      endelse
    end
    'site_code': begin
      widget_control,mpc.site_code_text,get_value=value
      mpc.site_code = value
    end
    'height_box': begin
      widget_control,mpc.height_box,get_value=value
      mpc.height = value
    end
    'lon_box': begin
      widget_control,mpc.lon_box,get_value=value
      mpc.lon = value
    end
    'lon_east': mpc.lon_dir = 'E'
    'lon_west': mpc.lon_dir = 'W'
    'lat_box': begin
      widget_control,mpc.lat_box,get_value=value
      mpc.lat = value
    end
    'lat_north': mpc.lat_dir = 'N'
    'lat_south': mpc.lat_dir = 'S'
    'tel_box': begin
      widget_control,mpc.tel_box,get_value=value
      mpc.telescope = value
    end
    'code_box': begin
      widget_control,mpc.code_box,get_value=value
      mpc.code = value
    end
    'name_box': begin
      widget_control,mpc.name_box,get_value=value
      mpc.contact_name = value
    end
    'address_box': begin
      widget_control, mpc.address_box,get_value=value
      mpc.contact_address = value
    end
    'email_box': begin
      widget_control,mpc.email_box,get_value=value
      mpc.contact_email = value
    end
    'observers_box': begin
      widget_control,mpc.observers_box,get_value=value
      mpc.observers = value
    end
    'measurers_box': begin
      widget_control,mpc.measurer_box,get_value=value
      mpc.measurer = value
    end
    
    ;data tab
    'data_toggle': begin
      if mpc.data_toggle eq 0 then begin
        widget_control,mpc.data_tab,ysize=110
        widget_control,mpc.info_tab,ysize=1
        widget_control,mpc.plot_tab,ysize=1
        mpc.data_toggle = 1
        mpc.info_toggle = 0
        mpc.plot_toggle = 0
      endif else begin
        widget_control,mpc.data_tab,ysize=1
        mpc.data_toggle = 0
      endelse
    end
    'select_point': begin
      if mpc.index eq 0 then begin
        widget_control,mpc.select_point,set_value='Add selected point'
        mpc.index = mpc.num_points
      endif else begin
        widget_control,mpc.select_point,set_value='Choose a data point'
        mpc.index = 0
        if mpc.num_points lt 6 then mpc.num_points++
        widget_control,mpc.points_added_id,set_value='Points added: '+strtrim(string(mpc.num_points-1),1)
        
      endelse
    end
    'desig': begin
      widget_control,mpc.desig_text,get_value=value
      mpc.prov_desig = value
    end
    'note1': begin
      widget_control,mpc.note1_text, get_value=value
      mpc.note1 = value
    end
    'note2': begin
      widget_control,mpc.note2_text, get_value=value
      mpc.note2 = value
    end
    'com': begin
      widget_control,mpc.com_text, get_value=value
      mpc.com = value
    end
    
    ;plot_tab
    'plot_toggle': begin
      if mpc.plot_toggle eq 0 then begin
        widget_control,mpc.plot_tab,ysize=570
        widget_control,mpc.info_tab,ysize=1
        widget_control,mpc.data_tab,ysize=1
        mpc.plot_toggle = 1
        mpc.info_toggle = 0
        mpc.data_toggle = 0
      endif else begin
        widget_control,mpc.plot_tab,ysize=1
        mpc.plot_toggle = 0
      endelse
    end
    'refresh_plot': begin
      phast_setwindow,mpc.plot_id
      !p.multi = [0,0,3,0,0]
      day_limit = mpc_day_fraction[where(mpc_day_fraction ne 0)]-mpc_day_fraction[0]
      dec_limit = mpc_dec[where(mpc_dec ne 0)]-mpc_dec[0]
      ra_limit = mpc_ra[where(mpc_ra ne 0)]-mpc_ra[0]
      mag_limit = mpc_mag[where(mpc_mag ne 0)]
      num = n_elements(ra_limit)
      ;calculate motion rate and position angle
      distance = sqrt((ra_limit[num-1]-ra_limit[0])^2+(dec_limit[num-1]-dec_limit[0])^2)
      velocity = distance/(day_limit[num-1]-day_limit[0])*60/24 ;unit: arcmin/hr
      v_ra = (ra_limit[num-1] - ra_limit[0])/(day_limit[num-1]-day_limit[0])
      v_dec = (dec_limit[num-1] - dec_limit[0])/(day_limit[num-1]-day_limit[0])
      pos_angle = (atan(v_dec/v_ra)*180/3.14159) mod 360
      
      ;calcluate best fit lines
      dec_fit = linfit(day_limit,dec_limit)
      ra_fit = linfit(day_limit,ra_limit)
      
      if mpc.num_points ge 2 then begin
        plot,day_limit,dec_limit,psym=2,xticks=3,xtickname=[' ', ' ', ' ', ' '],ymargin=[0,0],ytitle='delta Dec (deg)',charsize=2
        oplot,day_limit,dec_fit[1]*day_limit+dec_fit[0]
        plot,day_limit,ra_limit,psym=2,xticks=3,ymargin=[0,0],ytitle='delta RA (deg)',xtickname=[' ',' ',' ',' '],charsize=2
        oplot,day_limit,ra_fit[1]*day_limit+ra_fit[0]
        plot,day_limit,mag_limit,psym=2,xticks=3,/ynozero,ytitle='Magnitude',xtitle='delta time (days)',ymargin=[3,0],charsize=2
      endif
      ;update stats
      widget_control,mpc.velocity_box,set_value=strtrim(velocity,1)
      widget_control,mpc.pos_angle_box,set_value=strtrim(pos_angle,1)
      
      !p.multi=0
      phast_resetwindow
    end
    
    'report': begin
      phast_mpc_generate_report
      result = dialog_message('Report generated!',/info,/center)
    end
    'done': widget_control,event.top,/destroy
    
    else: print,'uvalue not found'
  endcase
end

pro phast_mpc

;for compilation purposes only

compile_opt IDL2, hidden

end
