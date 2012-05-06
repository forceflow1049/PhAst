; NAME:
;       PhAst (Photometery-Astrometry)
; 
; PURPOSE: 
;
; CATEGORY: 
;       Image display, image processing
;
; CALLING SEQUENCE:
;       phast [,array_name OR fits_file] [,min = min_value] [,max=max_value] 
;           [,/linear] [,/log] [,/histeq] [,/asinh] [,/block]
;           [,/align] [,/stretch] [,header = header]
;
; REQUIRED INPUTS:
;       None.  If phast is run with no inputs, the window widgets
;       are realized and images can subsequently be passed to phast
;       from the command line or from the pull-down file menu.
;
; OPTIONAL INPUTS:
;       array_name: a 2-D array or 3-D data cube to display
;          OR
;       fits_file:  a fits file name, enclosed in single quotes
;
; KEYWORDS:
;       min:        minimum data value to be mapped to the color table
;       max:        maximum data value to be mapped to the color table
;       linear:     use linear stretch
;       log:        use log stretch 
;       histeq:     use histogram equalization
;       asinh:      use asinh stretch
;       block:      block IDL command line until PHAST terminates
;       align:      align image with previously displayed image
;       stretch:    keep same min and max as previous image
;       header:     FITS image header (string array) for use with data array
;       
; OUTPUTS:
;       None.  
; 
; COMMON BLOCKS:
;       phast_state:  contains variables describing the display state
;       phast_images: contains copies of all images and headers
;       phast_color:  contains colormap vectors
;       phast_pdata:  contains plot and text annotation information
;       phast_spectrum: contains information about extracted spectrum
;       phast_mpc_data: contains data for creating an MPC report
;
; RESTRICTIONS:
;       Requires IDL version 6.0 or greater.
;       Requires Craig Markwardt's cmps_form.pro routine.
;       Requires the GSFC IDL astronomy user's library routines.
;       Some features may not work under all operating systems.
;
; EXAMPLE:
;       To start phast running, just enter the command 'phast' at the idl
;       prompt, either with or without an array name or fits file name 
;       as an input.  Only one phast window will be created at a time,
;       so if one already exists and another image is passed to phast
;       from the idl command line, the new image will be displayed in 
;       the pre-existing phast window.
;
; MODIFICATION HISTORY:
;       2011-11-27 PhAst 1.1 released.
;       2011-08-11 PhAst 1.0 released. First public release (Morgan
;                  Rehnberg)
;       2011-08-03 PhAst 0.98 released.  First private release (Morgan
;                  Rehnberg)
;       2011-06-05 PhAst forked from ATV 2.3
;       2010-10-17 ATV 2.3 released (Aaron J. Barth)

;-
;----------------------------------------------------------------------
;        phast startup and initialization routines
;----------------------------------------------------------------------

pro phast_initcommon

; Routine to initialize the phast common blocks.  Use common blocks so
; that other IDL programs can access the phast internal data easily.

common phast_state, state
common phast_color, r_vector, g_vector, b_vector, user_r, user_g, user_b
common phast_pdata, nplot, maxplot, plot_ptr
common phast_images, $
   main_image, $
   main_image_cube, $
   display_image, $
   scaled_image, $
   blink_image1, $
   blink_image2, $
   blink_image3, $
   unblink_image, $  
   pan_image, $
   startup_image, $
   image_archive, $
   star_catalog, $
   cal_science, $
   cal_dark, $
   cal_flat, $
   cal_bias, $
   cal_science_head, $
   cal_dark_head, $
   cal_flat_head, $
   cal_bias_head
   
common phast_objects, mpeg_id

common phast_mpc_data, mpc_date, mpc_ra, mpc_dec, mpc_mag, mpc_band, mpc_day_fraction, mpc

mpc = { $
        com_text: 0L, $         ;widget id for com text box
        com: '', $              ;mpc report com line
        net: 'USNO-B1.0', $     ;mpc report net line
        ack: '', $              ;mpc report ack line
        note2_text: 0L, $       ;widget id for note 2 box          
        note1_text: 0L, $       ;widget id for note 1 box
        desig_text: 0L, $       ;widget id for designation box
        prov_desig: '', $       ;provisional designation
        pos_angle_box:0L, $     ;widget id for pos angle box
        velocity_box:0L, $      ;widget id for velocity box
        plot_id: 0L, $          ;id for draw widget for mpc
        points_added_id:0L,$    ;widget id for points counter
        select_point:0L, $      ;widget id for mpc data selector
        num_points: 1, $        ;total num chosen points (max =5)
        index: 0, $             ;where to put mpc data, 0=none
        click_mode:0, $         ;are we selecting mpc data points? 
        info_toggle:0, $        ;is the info tab showing?
        data_toggle:0, $        ;is the data tab showing?
        plot_toggle:0, $        ;is the plot tab showing?
        plot_tab: 0L, $         ;wdget id for plot tab
        data_tab: 0L, $         ;widget id for data tab
        info_tab: 0L, $         ;widget id for info tab
        height: 0.0, $          ;observ elevation
        lon_dir: 'W', $         ;east or west?
        lon: 0.0, $             ;oserv lon
        lat_dir: 'N', $         ;north or south?
        lat: 0.0, $             ;observ lat
        telescope:'', $         ;telescope name
        note1: '', $            ;MPC note 1
        note2: '', $            ;MPC note 2
        site_code:0,$           ;MPC site code
        measurer:'', $          ;list of measurers
        observers:'', $         ;list of observer names
        contact_name:'', $      ;MPC contact name
        contact_email:'',$      ;MPC contact email
        contact_address:'',$    ;MPC contact address
        code: '', $              ;single char MPC code
        name_box: 0L, $         ;widget id for contact name box
        address_box: 0L, $      ;widget id for contact address box
        email_box: 0L,$         ;widget id for contact email box
        observers_box: 0L, $    ;widget id for observers box
        measurer_box: 0L, $     ;widget id for measurer box
        code_box: 0L, $         ;widget it for code box
        tel_box: 0L, $          ;widget id for tel box
        lat_north: 0L, $         ;widget it for lat north button
        lat_south: 0L, $         ;widget it for lat south  button
        lat_box: 0L, $          ;widget id for lat box
        lon_west: 0L, $         ;widget it for lon west button
        lon_east: 0L, $         ;widget it for lon east button
        lon_box: 0L, $          ;widget id for lon box
        height_box: 0L, $       ;widget id for height box
        site_code_text: 0L $   ;widget id for site code box
        }

state = {                   $
        custom_catalogs: '', $  ;filename of catalog definitions 
        phot_rad_plot_open: 1,$ ;is the radial plot shown by default?
        kernel_list: '', $      ;path to file with kernel list
        spice_box_id: 0L, $     ;widget id for spice control box
        check_updates: 0, $     ;check for updates on startup? 1=yes
        filter_color: 'Blue', $ ;which filter for catalog photometry?
        image_type: 'FITS',  $  ;what kind of image is being viewed?
        bias_filename: 'No bias loaded',$;name of bias file
        flat_filename: 'No flat loaded',$;name of flat file
        dark_filename: 'No dark loaded',$;name of dark file
        batch_source: -1, $     ;what images to calibrate?
        batch_select_dir: 0L, $ ;widget id for dir select button
        batch_dirname: '', $    ;location of image batch
        fits_crota2:0.0, $      ;holds dec rotation (deg)
        fits_crota1:0.0, $      ;holds ra rotation (deg)
        fits_cdelt2:0.0, $      ;holds y plate scale (deg)
        fits_cdelt1:0.0, $      ;holds x plate scale (deg)
        batch_dir_id: 0L, $     ;widget id for batch dir display
        apphot_wcs_id: 0L,$     ;widget id for wcs coords in apphot
        cal_file_name: '',$     ;cal output file name
        cal_name_box_id: 0L, $  ;widget id for cal output box
        over_toggle: 0, $       ;correct images for overscan?
        sci_label_id: 0L, $     ;wodget id for science cal label
        dark_label_id:0L, $     ;widget id for dark cal label
        flat_label_id:0L, $     ;widget id for flat cal label
        bias_label_id:0L, $     ;widget id for bias cal label
        dark_toggle: 0,  $      ;is a dark cal being used
        flat_toggle: 0,  $      ;is a flat cal being used
        bias_toggle: 0,  $      ;is a bias cal being used
        dark_select_id: 0L,$    ;widget id for dark cal select
        flat_select_id: 0L,$    ;widget id for flat cal select 
        bias_select_id: 0L,$    ;widget id for bias cal select
        search_msg_id:0L, $     ;widget id of search msg box
        tb_spice_visible: 0, $  ;Are the SPICE controls shown?
        tb_spice_toggle: 0, $   ;draw the SPICE controls?
        tb_blink_toggle: 1, $   ;is the blink base shown?
        tb_blink_visible: 1, $  ;draw the blink base?
        tb_overlay_toggle: 0, $ ;is the overlay toolbox shown?
        tb_overlay_visible: 1, $ ;draw the overlay toolbox?
        overlay_stars_box_id: 0L,$ ;widget id for overlay box
        star_search_string:'',$ ;string containing serach terms
        star_search_widget_id:0L,$;widget id for search field
        zeropoint_image_widget_id:0L,$;widget id for name display
        zeropoint_image_name:'',$;holds image to calculate zeropoint for
        missfits_image_name:'',$;path to image for missfits to use 
        missfits_image_widget_id:0L,$;widget it for missfits image label
        missfits_flags: '', $   ;string to hold flag list for missfits
        scamp_flags: '', $      ;string to hold flag list for scamp 
        sex_flags: '', $        ;string to hold flag list for sextractor
        missfits_flags_widget_id: 0L,$;widget id for missfits flags box
        scamp_flags_widget_id: 0L,$;widget id for scamp flags box
        sex_flags_widget_id: 0L,$;widget id for sextractor flags box
        mpeg_id: 0L, $          ;id for movie object
        mpeg_frame_num: 0, $    ;index of current movie frame
        circ_coord: [0,0], $    ;coord of circle to be plotted on screen 
        mag_select_id: 0L,$     ;widget id for mag select text box
        align_toggle:0, $       ;attempt to align the images? 1=yes
        master_dec: 0.0, $      ;DEC in deg of center of first image
        master_ra: 0.0, $       ;RA in deg of center of first image
        rotation_deg: 0, $      ;amount of rotation (in deg)
        blink_base_id: 0L,$     ;widget id for blink control base
        catalog_name: 'USNO-B1.0',$ ;name of currently selected astrometric star cat
        catalog_loaded:0,$      ;has the astrometric star catalog been loaded? 1=yes
        display_names:0, $      ;display star names? 1=yes
        mag_limit: 20, $        ;limiting mag for star overlay
        bounce_direction: 1, $  ;current direction for bounce animation
        animate_type: 'forward', $ ;animation type to play
        pause_state: 1,$        ;is the animation paused?
        blink_base_label_id: 0L, $ ;widget id for blink base label
        speed_label_id: 0L, $   ;widget id of animate speed slider
        animate_speed: 0.4, $   ;time (in sec) per image
       ; animate_duration: 1, $  ;loops to run
        image_select_id: 0L, $  ;widget id for dropdown file list
        image_counter_id: 0L, $ ;widget id for image counter
        animate_toggle: 0, $    ;toggle animate-on-click for blink mode
        current_image_index: 0, $ ;holds index of currently displayed image
        scamp_cat_widget_id:0L,$;widget id for scamp cat name input box
        scamp_catalog_name:'',$ ;name of catalog to be processed by SCAMP
        sex_catalog_name: './output/catalogs/phast.cat',$;name of catalog to be outputted by SExtractor
        sex_catalog_path: './output/images/', $ ;pathname to current image
        sex_cat_widget_id: 0L, $;widget id for the catalog input box
        sex_PHOT_AUTOPARAMS: [2.5, 0.0], $ ; kron radius controls for ZEROPOINT determination
        num_images: 0, $        ;number of images in image archive
        version: '1.2', $       ; version # of this release
        head_ptr: ptr_new(), $  ; pointer to image header
        astr_ptr: ptr_new(), $  ; pointer to astrometry info structure
        firstimage: 1, $        ; is this the first image?
        block: 0, $             ; are we in blocking mode?
        wcstype: 'none', $      ; coord info type (none/angle/lambda)
        equinox: 'J2000', $     ; equinox of coord system
        display_coord_sys: 'RA--', $ ; coord system displayed
        display_equinox: 'J2000', $ ; equinox of displayed coords
        display_base60: 1B, $   ; Display RA,dec in base 60?
        cunit: '', $            ; wavelength units
        imagename: '', $        ; image file name
        title_extras: '', $     ; extras for image title
        bitdepth: 8, $          ; 8 or 24 bit color mode?
        screen_xsize: 1000, $   ; horizontal size of screen
        screen_ysize: 1000, $   ; vertical size of screen
        base_id: 0L, $          ; id of top-level base
        base_min_size: [512L, 300L], $ ; min size for top-level base
        draw_base_id: 0L, $     ; id of base holding draw window
        draw_window_id: 0L, $   ; window id of draw window
        draw_widget_id: 0L, $   ; widget id of draw widget
        mousemode: "imexam", $   ; color, blink, zoom, label, or imexam
        mode_droplist_id: 0L, $ ; id of mode droplist widget
        track_window_id: 0L, $  ; widget id of tracking window
        pan_widget_id: 0L, $    ; widget id of pan window
        pan_window_id: 0L, $    ; window id of pan window
        active_window_id: 0L, $ ; user's active window outside phast
        active_window_pmulti: lonarr(5), $ ; user's active window p.multi
        info_base_id: 0L, $     ; id of base holding info bars
        location_bar_id: 0L, $  ; id of (x,y,value) label
        wcs_bar_id: 0L, $       ; id of WCS label widget
        min_text_id: 0L,  $     ; id of min= widget
        max_text_id: 0L, $      ; id of max= widget
        menu_ids: lonarr(35), $ ; list of top menu items
        colorbar_base_id: 0L, $ ; id of colorbar base widget
        colorbar_widget_id: 0L, $ ; widget id of colorbar draw widget
        colorbar_window_id: 0L, $ ; window id of colorbar
        colorbar_height: 6L, $  ; height of colorbar in pixels
        ncolors: 0B, $          ; image colors (!d.table_size - 9)
        box_color: 2, $         ; color for pan box and zoom x
        brightness: 0.5, $      ; initial brightness setting
        contrast: 0.5, $        ; initial contrast setting
        image_min: 0.0, $       ; min(main_image)
        image_max: 0.0, $       ; max(main_image)
        min_value: 0.0, $       ; min data value mapped to colors
        max_value: 0.0, $       ; max data value mapped to colors
        skymode: 0.0, $         ; sky mode value
        skysig: 0.0, $          ; sky sigma value
        draw_window_size: [800L, 800L], $ ; size of main draw window WAS 512/512, then 690,/690
        track_window_size: 121L, $ ; size of tracking window
        pan_window_size: 121L, $ ; size of pan window
        pan_scale: 0.0, $       ; magnification of pan image
        image_size: [0L,0L], $  ; size of main_image
        invert_colormap: 0L, $  ; 0=normal, 1=inverted
        coord: [0L, 0L],  $     ; cursor position in image coords
        scaling: 3, $           ; 0=lin,1=log,2=histeq,3=asinh
        asinh_beta: 0.1, $      ; asinh nonlinearity parameter
        offset: [0L, 0L], $     ; offset to viewport coords
        base_pad: [0L, 0L], $   ; padding around draw base
        zoom_level: 0L, $       ; integer zoom level, 0=normal
        zoom_factor: 1.0, $     ; magnification factor = 2^zoom_level
        centerpix: [0L, 0L], $  ; pixel at center of viewport
        cstretch: 0B, $         ; flag = 1 while stretching colors
        pan_offset: [0L, 0L], $ ; image offset in pan window
        cube: 0, $              ; is main image a 3d cube?
        osiriscube: 0, $        ; is cube an osiris-style (l,y,x) cube?
        slice: 0, $             ; which slice of cube to display
        slicebase_id: 0, $      ; widget id of slice base
        slicer_id: 0, $         ; widget id of slice slider
        sliceselect_id: 0, $    ; widget id of slice selector
        slicecombine_id: 0, $   ; widget id of slice combine box
        slicecombine: 1, $      ; # slices to combine
        slicecombine_method: 1, $ ; 0 for average, 1 for median
        nslices: 0, $           ; number of slices
        frame: 1L, $            ; put frame around ps output?
        framethick: 6, $        ; thickness of frame
        plot_coord: [0L, 0L], $ ; cursor position for a plot
        vector_coord1: [0L, 0L], $ ; 1st cursor position in vector plot  
        vector_coord2: [0L, 0L], $ ; 2nd cursor position in vector plot
        vector_pixmap_id: 0L, $ ; id for vector pixmap 
        vectorpress: 0L, $      ; are we plotting a vector?
        vectorstart: [0L,0L], $ ; device x,y of vector start
        plot_type:'', $         ; plot type for plot window
        lineplot_widget_id: 0L, $ ; id of lineplot widget
        lineplot_window_id: 0L, $ ; id of lineplot window
        lineplot_base_id: 0L, $ ; id of lineplot top-level base
        lineplot_size: [600L, 500L], $ ; size of lineplot window
        lineplot_min_size: [100L, 0L], $ ; min size of lineplot window
        lineplot_pad: [0L, 0L], $ ; padding around lineplot window
        lineplot_xmin_id: 0L, $ ; id of xmin for lineplot windows
        lineplot_xmax_id: 0L, $ ; id of xmax for lineplot windows
        lineplot_ymin_id: 0L, $ ; id of ymin for lineplot windows
        lineplot_ymax_id: 0L, $ ; id of ymax for lineplot windows
        lineplot_charsize_id: 0L, $ ; id of charsize for lineplots
        lineplot_xmin: 0.0, $   ; xmin for lineplot windows
        lineplot_xmax: 0.0, $   ; xmax for lineplot windows
        lineplot_ymin: 0.0, $   ; ymin for lineplot windows
        lineplot_ymax: 0.0, $   ; ymax for lineplot windows
        lineplot_xmin_orig: 0.0, $ ; original xmin saved from histplot
        lineplot_xmax_orig: 0.0, $ ; original xmax saved from histplot
        holdrange_base_id: 0L, $ ; base id for 'Hold Range' button
        holdrange_button_id: 0L, $ ; button id for 'Hold Range' button
        holdrange_value: 0, $   ; 0=HoldRange Off, 1=HoldRange On
        histbutton_base_id: 0L, $ ; id of histogram button base
        histplot_binsize_id: 0L, $ ; id of binsize for histogram plot
        x1_pix_id: 0L, $        ; id of x1 pixel for histogram plot
        x2_pix_id: 0L, $        ; id of x2 pixel for histogram plot
        y1_pix_id: 0L, $        ; id of y1 pixel for histogram plot
        y2_pix_id: 0L, $        ; id of y2 pixel for histogram plot
        plotcharsize: 1.0, $    ; charsize for plot window
        binsize: 0.0, $         ; binsize for histogram plots
        regionform_id: 0L, $    ; id of region form widget
        reg_ids_ptr: ptr_new(), $ ; ids for region form widget
        cursorpos: lonarr(2), $ ; cursor x,y for photometry & stats
        centerpos: fltarr(2), $ ; centered x,y for photometry
        cursorpos_id: 0L, $     ; id of cursorpos widget
        centerpos_id: 0L, $     ; id of centerpos widget
        centerbox_id: 0L, $     ; id of centeringboxsize widget
        radius_id: 0L, $        ; id of radius widget
        innersky_id: 0L, $      ; id of inner sky widget
        outersky_id: 0L, $      ; id of outer sky widget
        magunits: 0, $          ; 0=counts, 1=magnitudes
        skytype: 0, $           ; 0=idlphot,1=median,2=no sky subtract
        exptime: 1.0, $         ; exposure time for photometry
        photautoaper: 0, $      ; 0=fixed aperatures; 1=auto aperture
        photcatalog_name: 'GSC-2.3',$ ;name of currently selected photometeric star cat
        photcatalog_loaded:0,$      ;has the photometric star catalog been loaded? 1=yes
        photzpt: 0.0,  $        ; magnitude zeropoint
        photclr: 0.0,  $        ; magnitude color term
        photband: '',  $        ; magnitude color band
        photzerr: 0.0, $        ; zeropoint error rms
        photznum: 0L,  $        ; zeropoint N
        photSpecList: ['B','A','F','G','K','M' ], $ ; recognized spectral types
        photSpecType:   'K',  $ ; default spectral type   
        photSpecTypeNum: 4,   $ ; default spectral type number (in photSecList)
        photSpecSubNum:  0,   $ ; default spectral subtype
        photSpecBmV:  0.60,   $ ; implied spectral color
        photSpecVmR:  0.27,   $ ; implied spectral color
        photSpecBmR:  0.87,   $ ; implied spectral color
        photSpec_Type_ID: 0L, $ ; id of photo spectral type
        photSpec_Num_ID:  0L, $ ; id of photo spectral subtyipe
        photSpec_BmV_ID:  0L, $ ; id of photo spectral BmV color
        photSpec_VmR_ID:  0L, $ ; id of photo spectral VmR color
        photSpec_BmR_ID:  0L, $ ; id of photo spectral BmR color 
        photprint: 0, $         ; print phot results to file?
        photprint_id: 0L, $     ; id of phot print button
        photfile: 0L, $         ; file unit of phot file
        photfilename: 'phastphot.dat', $ ; filename of phot file
        skyresult_id: 0L, $     ; id of sky widget
        photresult_id: 0L, $    ; id of photometry result widget
        photerror_id: 0L, $,    ; id of photometry error widget
        fwhm_id: 0L, $          ; id of fwhm widget
        radplot_widget_id: 0L, $ ; id of radial profile widget
        radplot_window_id: 0L, $ ; id of radial profile window
        photzoom_window_id: 0L, $ ; id of photometry zoom window
        photzoom_size: 190L, $  ; size in pixels of photzoom window
        showradplot_id: 0L, $   ; id of button to show/hide radplot
        photwarning_id: 0L, $   ; id of photometry warning widget
        photwarning: ' ', $     ; photometry warning text
        photerrors: 0, $        ; calculate photometric errors?
        pixelscale: 0.0, $      ; pixel scale, arcsecs/pixel
        ccdgain: 3.0, $         ; CCD gain
        ccdrn: 0.0, $           ; read noise
        centerboxsize: 9L, $    ; centering box size
        aprad_def: 5.0, $       ; default aperture photometry radius
        innersky_def: 10.0, $   ; default inner sky radius
        outersky_def: 20.0, $   ; default outer sky radius
        aprad: 5.0, $           ; aperture photometry radius (working)
        innersky: 10.0, $       ; inner sky radius (working)
        outersky: 20.0, $       ; outer sky radius (working)
        headinfo_base_id: 0L, $ ; headinfo base widget id
        pixtable_base_id: 0L, $ ; pixel table base widget id
        pixtable_tbl_id: 0L, $  ; pixel table widget_table id
        stats_base_id: 0L, $    ; base widget for image stats
        statboxsize: 11L, $     ; box size for computing statistics
        statbox_id: 0L, $       ; widget id for stat box size 
        stat_npix_id: 0L, $     ; widget id for # pixels in stats box
        statxcenter_id: 0L, $   ; widget id for stat box x center
        statycenter_id: 0L, $   ; widget id for stat box y center
        statbox_min_id: 0L, $   ; widget id for stat min box
        statbox_max_id: 0L, $   ; widget id for stat max box
        statbox_mean_id: 0L, $  ; widget id for stat mean box
        statbox_median_id: 0L, $ ; widget id for stat median box
        statbox_stdev_id: 0L, $ ; widget id for stat stdev box
        statzoom_size: 300, $   ; size of statzoom window
        statzoom_widget_id: 0L, $ ; widget id for stat zoom window
        statzoom_window_id: 0L, $ ; window id for stat zoom window
        showstatzoom_id: 0L, $  ; widget id for show/hide button
        pan_pixmap: 0L, $       ; window id of pan pixmap
        current_dir: '', $      ; current readfits directory
        graphicsdevice: '', $   ; screen device
        ispsformon: 0, $        ; is cmps_form running?
        newrefresh: 0, $        ; refresh since last blink?
        blinks: 0B, $           ; remembers which images are blinked
        x_tracestep: 21L, $     ; extraction tracing step
        x_tracestep_id: 0, $    ; widget id for tracestep
        x_traceheight: 7L, $    ; extraction tracing height
        x_traceheight_id: 0, $  ; widget id for trace height
        x_xregion: [0L, 0L], $  ; extraction x region
        x_xstart_id: 0, $       ; widget id for extraction x start
        x_xend_id: 0, $         ; widget id for extraction x end
        x_traceorder: 3, $      ; extraction trace fit order
        x_traceorder_id: 0, $   ; widget id for extraction trace order 
        x_xlower: -5, $         ; extraction lower bound
        x_xlower_id: 0, $       ; widget id for extraction lower
        x_xupper: 5, $          ; extraction upper bound
        x_xupper_id: 0, $       ; widget id for extraction upper 
        x_backsub: 1, $         ; background subtraction on?
        x_back1: -25, $         ; extraction lower background 1
        x_back2: -15, $         ; extraction lower background 2
        x_back3: 15, $          ; extraction upper background 1
        x_back4: 25, $          ; extraction upper background 2
        x_back1_id: 0, $        ; widget id for lower background 1
        x_back2_id: 0, $        ; widget id for lower background 2
        x_back3_id: 0, $        ; widget id for upper background 1
        x_back4_id: 0, $        ; widget id for upper background 2
        x_fixed: 0, $           ; hold extraction parameters fixed?
        activator: 0, $         ; is "activator" mode on?
        delimiter: '/', $       ; filesystem level delimiter 
        default_align: 1, $     ; align next image by default?
        default_autoscale: 1, $ ; autoscale images by default?
        default_stretch: 0 $    ; use previous minmax for new image?
        }

nplot = 0
maxplot = 5000
plot_ptr = ptrarr(maxplot+1)  ; The 0th element isn't used.

blink_image1 = 0
blink_image2 = 0
blink_image3 = 0
image_archive = objarr(1)
star_catalog=0
;state.sex_catalog_name = 'test.cat'
cal_science = 0
cal_dark = 0
cal_flat = 0
cal_bias = 0

mpc_date = strarr(5)
mpc_ra = dblarr(5)
mpc_dec = dblarr(5)
mpc_mag = fltarr(5)
mpc_band = strarr(5)
mpc_day_fraction = dblarr(5)



phast_read_config ;read configuration file and set variables as specified
if state.check_updates eq 1 then phast_check_updates,/silent
end
;---------------------------------------------------------------------
pro phast_check_updates,silent=silent

;routine to check for updates to PhAst.  Set keyword /silent to
;suppress popup if PhAst is up to date.

common phast_state

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
end
;---------------------------------------------------------------------
pro phast_read_config

;routine to read a user-supplied configuration file and make the
;appropriate changes to state variables.

common phast_state
common phast_mpc_data
common phast_images
if file_test('phast.conf') eq 1 then begin
    readcol,'phast.conf',var,val,FORMAT='A,A',/silent,delim=string(9b),comment='#'
    for i=0, n_elements(var)-1 do begin
        case var[i] of
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
                state.over_toggle = val[i]
            end    
            ;sextractor
            'sex_catalog_path': state.sex_catalog_path = val[i]
            'sex_flags': state.sex_flags = val[i]
            'fits_crota1': state.fits_crota1 = float(val[i])
            'fits_crota2': state.fits_crota2 = float(val[i])
            'fits_cdelt1': state.fits_cdelt1 = float(val[i])
            'fits_cdelt2': state.fits_cdelt2 = float(val[i])
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
            'pixelscale': state.pixelscale = float(val[i])
            'ccdgain': state.ccdgain = float(val[i])
            'ccdrn': state.ccdrn = float(val[i])
            'photerrors': state.photerrors = fix(val[i])
            'skytype': state.skytype = fix(val[i])
            'magunits': state.magunits = fix(val[i])
            'phot_rad_plot_open': state.phot_rad_plot_open = fix(val[i])
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
            ;custom catalogs
            'custom_catalogs': state.custom_catalogs = val[i]
            ;other
            'align_toggle': state.align_toggle = fix(val[i])
            'check_updates':state.check_updates = fix(val[i])


            else: print, 'Parameter '+var[i]+' not found!'
        endcase
    endfor
endif

end
;---------------------------------------------------------------------
pro phast_startup

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
phast_initcommon

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

base = widget_base(title = 'phast', $
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
;                {cw_pdmenu_s, 2, ' FIRST'}, 
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
                {cw_pdmenu_s, 2, 'Asinh Settings'}, $
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
                {cw_pdmenu_s, 0, 'Rotate'}, $
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
                {cw_pdmenu_s, 0, 'Calibration'},$
                {cw_pdmenu_s, 0, '--------------'},$
                {cw_pdmenu_s, 0, 'SExtractor'}, $
                {cw_pdmenu_s, 0, 'SCAMP'}, $
                {cw_pdmenu_s, 0, 'missFITS'},$
                {cw_pdmenu_s, 0, 'Photometric zero-point'},$
                {cw_pdmenu_s, 0, 'Do all'}, $
                {cw_pdmenu_s, 0, '--------------'}, $
                {cw_pdmenu_s, 2, 'Batch process'}, $
                {cw_pdmenu_s, 1, 'Help'}, $ ; help menu
                {cw_pdmenu_s, 0, 'PHAST Help'},$
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
                                      uvalue = 'cqolorbar_base', $
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

align_toggle = widget_button(toggle_buttonbox,value='Align',uvalue='align_toggle',$
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

;done_button = widget_button(button_base, $
;                            value = 'Done', $
;                            uvalue = 'done')

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
   overlay_toggle = widget_button(left_pane,value='Overlay stars',uvalue='overlay_toggle')
   overlay_stars_box = widget_base(left_pane,/column,frame=4,xsize=250)
;overlay_stars_label = widget_label(overlay_stars_box,value='Overlay Stars')
   overlay_sub_box = widget_base(overlay_stars_box,/row)
   mag_select_label = widget_label(overlay_sub_box,value='Mag limit:')
   mag_select = widget_text(overlay_sub_box,value='20',uvalue='mag_select',xsize=3,/editable,/all_events)
   stars_button_box = widget_base(overlay_sub_box,/nonexclusive)
   display_names = widget_button(stars_button_box,value='Names',uvalue='display_names',$
                                 tooltip='Display USNO-B1.0 designations')
   display_stars = widget_button(overlay_sub_box,value='Display',uvalue='display_stars',$
                                 tooltip='Overlay stars from USNO-B1.0 catalog')
   star_search_box = widget_base(overlay_stars_box,/row)
   search_field = widget_text(star_search_box,value='Search for a star...',uvalue='search_field',/editable)
   search_button = widget_button(star_search_box,value='Search',uvalue='search_button')
   search_notify = widget_label(overlay_stars_box,value='---------------',/dynamic_resize)

   state.mag_select_id = mag_select
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
   erase_labels = widget_button(spice_sub_box,value='Clear labels',uvalue='erase_labels')

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
                                       xsize=245,/align_center,$
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
state.base_pad[1] = 20 ;set y pad staticlly

;check for output directories
if not (file_test('output',/directory) and file_test('output/images',/directory) and file_test('output/catalogs',/directory)) then begin
    result = dialog_message('Output directories not found.  Create them?',/question,/center)
    if result eq 'Yes' then begin
        file_mkdir,'output/images'
        file_mkdir,'output/catalogs'
    endif else begin
        result = dialog_message('PHAST will not function correctly without the appropriate output directories.',/center)
    endelse
endif

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
        image_archive = temp_image
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
        image_archive = 0.0
        state.num_images = 0
        state.current_image_index = 0
        state.catalog_loaded = 0
        state.firstimage = 1
        widget_control,state.image_counter_id,set_value='Cycle images: no image loaded'
        widget_control,state.image_select_id,set_value='no image'
        phast_base_image
    endelse
endif else begin
   for i=0,state.num_images-1 do obj_destroy,image_archive[i]
   image_archive = 0.0
   state.num_images = 0
   state.current_image_index = 0
   state.catalog_loaded = 0
   state.firstimage = 1
   widget_control,state.image_counter_id,set_value='Cycle images: no image loaded'
   widget_control,state.image_select_id,set_value='no image'
   phast_base_image
endelse

end

;-------------------------------------------------------------------
pro phast_add_image, new_image, filename, head, refresh_index = refresh, refresh_toggle=refresh_toggle, newimage = newimage, dir_add=dir_add,dir_num=dir_num

;routine to add a newly-loaded image to the image archive.  If this is
;the first image, the archive is initiallized before the image is added.


common phast_state
common phast_images
if not keyword_set(refresh_toggle) then begin ;normal image adding 
   new_image_size = size(new_image)
   if not keyword_set(dir_add) then begin
      if state.num_images gt 0 then begin ;check not first image
         state.num_images++
         temp_arr = image_archive
         image_archive = objarr(state.num_images)
         for i=0, state.num_images-2 do image_archive[i] = temp_arr[i]
         image_archive[state.num_images-1] = obj_new('phast_image') ;create new image object
         image_archive[state.num_images-1]->set_image, new_image
         image_archive[state.num_images-1]->set_name, filename
         image_archive[state.num_images-1]->set_header, head
         image_archive[state.num_images-1]->set_rotation,0.0
         phast_setheader,head
         newimage = 1
         state.current_image_index = state.num_images-1
      endif else begin          ;handle first image add
         state.num_images++
         image_archive = objarr(1)
         image_archive[0] = obj_new('phast_image') ;create new image object
         image_archive[0]->set_image, new_image
         image_archive[0]->set_name, filename
         image_archive[0]->set_header, head
         image_archive[0]->set_rotation,0.0
         newimage = 1 
      endelse 
   endif else begin             ;handle directory add
      if keyword_set(dir_num) then begin
             if state.num_images gt 0 then begin
                temp_image = image_archive                
                image_archive = objarr(state.num_images+dir_num)
                for i=0, state.num_images-1 do image_archive[i] = temp_image[i]
                image_archive[state.num_images] = obj_new('phast_image') ;create new image object
                image_archive[state.num_images]->set_image, new_image
                image_archive[state.num_images]->set_name, filename
                image_archive[state.num_images]->set_header, head
                image_archive[state.num_images]->set_rotation,0.0
                state.num_images++
             endif else begin   ;handle first image add
                state.num_images++
                image_archive = objarr(dir_num)
                image_archive[0] = obj_new('phast_image') ;create new image object
                image_archive[0]->set_image, new_image
                image_archive[0]->set_name, filename
                image_archive[0]->set_header, head
                image_archive[0]->set_rotation,0.0
                newimage = 1 
             endelse
          endif else begin
             image_archive[state.num_images] = obj_new('phast_image') ;create new image object
             image_archive[state.num_images]->set_image, new_image
             image_archive[state.num_images]->set_name, filename
             image_archive[state.num_images]->set_header, head
             image_archive[state.num_images]->set_rotation,0.0
             state.num_images++
          endelse
          state.current_image_index = state.num_images-1
       endelse 
   
endif else begin                ;handle image refresh
   image_archive[refresh]->set_image, new_image
   image_archive[refresh]->set_name, filename
   image_archive[refresh]->set_header, head
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

;-------------------------------------------------------------------

pro phastclear

; displays a small blank image, useful for clearing memory if phast is
; displaying a huge image.

phast, fltarr(10,10)

end


;--------------------------------------------------------------------
;                  main phast event loops
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
            phast_displayall
            phast_settitle
            state.firstimage = 0
        endif
    end
    'Read FITS directory': begin
       widget_control,/hourglass
        phast_readfits, /dir, newimage=newimage
       ; if (state.firstimage EQ 1) then begin
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
            ;phast_displayall
            phast_image_switch,0
            phast_settitle
            state.firstimage = 0
        endif
     end

    'Read VICAR file': begin
       if file_test('read_vicar.pro') eq 1 and file_test('vicgetpars.pro') eq 1 then begin
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
       endif else result = dialog_message('VICAR files cannot be opened without read_vicar.pro and vicgetpars.pro',/center,/error)
    end

    'Read VICAR directory': begin
       if file_test('read_vicar.pro') eq 1 and file_test('vicgetpars.pro') eq 1 then begin
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
          endif else result = dialog_message('VICAR files cannot be opened without read_vicar.pro and vicgetpars.pro',/center,/error)
    end

    
    'Write FITS file': phast_writefits
    'Write postscript file' : phast_writeps
    'PNG': phast_writeimage, 'png'
    'JPEG': phast_writeimage, 'jpg'
    'TIFF': phast_writeimage, 'tiff'
    'WriteMPEG': phast_write_mpeg
    'GetImage':
    ' DSS': phast_getdss
    ' FIRST': phast_getfirst
    'LoadRegions': phast_loadregion
    'SaveRegions': phast_saveregion
    'Remove current image': phast_remove_image,index=state.current_image_index
    'Remove all images': begin
        widget_control,/hourglass
        state.current_image_index = 0
        phast_remove_image,/all
        ;for i=0,state.num_images-1 do phast_remove_image,0
    end
    'Clear output directory': begin
        result = dialog_message('Empty ./output/images/ ?  This will remove all files from this directory',/question,/center)
        if result eq 'Yes' then spawn, 'rm ./output/images/*'
    end
    'Refresh current image': phast_refresh_image,state.current_image_index,state.imagename
    'Refresh all images': for i=0, state.num_images-1 do phast_refresh_image,i,image_archive[i]->get_name()
    'Quit':     if (state.activator EQ 0) then phast_shutdown $
      else state.activator = 0
; ColorMap menu options:            
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
       phast_gettrack             ; refresh coordinate window
    END 
    'RA,dec (B1950)': BEGIN 
       state.display_coord_sys = 'RA--'
       state.display_equinox = 'B1950'
       state.display_base60 = 1B
       phast_gettrack             ; refresh coordinate window
    END
    'RA,dec (J2000) deg': BEGIN 
       state.display_coord_sys = 'RA--'
       state.display_equinox = 'J2000'
       state.display_base60 = 0B
       phast_gettrack             ; refresh coordinate window
    END 
    'Galactic': BEGIN 
       state.display_coord_sys = 'GLON'
       phast_gettrack             ; refresh coordinate window
    END 
    'Ecliptic (J2000)': BEGIN 
       state.display_coord_sys = 'ELON'
       state.display_equinox = 'J2000'
       phast_gettrack             ; refresh coordinate window
    END 
    'Native': BEGIN 
       IF (state.wcstype EQ 'angle') THEN BEGIN 
          state.display_coord_sys = strmid((*state.astr_ptr).ctype[0], 0, 4)
          state.display_equinox = state.equinox
          phast_gettrack          ; refresh coordinate window
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
    'Batch process': phast_batch
    
    
; Help options:            
    'PHAST Help': phast_help
    'Check for updates': phast_check_updates
    
    else: print, 'Unknown event in file menu!'
endcase

; Need to test whether phast is still alive, since the quit option
; might have been selected.
if (xregistered('phast', /noshow)) then phast_resetwindow


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
        'imexam': phast_draw_phot_event, event
        'vector': phast_draw_vector_event, event
        'label':  phast_draw_label_event, event
    endcase
endif

if (event.type EQ 5 or event.type EQ 6) then $
  phast_draw_keyboard_event, event

if (xregistered('phast', /noshow)) then $
  widget_control, state.draw_widget_id, /sensitive;, /input_focus

end

;--------------------------------------------------------------------
pro phast_draw_label_event, event

;Event handler for label mode

common phast_state

if (event.type EQ 2) then phast_draw_motion_event, event

case event.press of
    1: begin ;left mouse button
        state.circ_coord[0] = event.x
        state.circ_coord[1] = event.y
    end
    ;2: print,state.offset
    4: begin ;right mouse button
        text = dialog_input()
        phastxyouts,event.x+state.offset[0],event.y+state.offset[1],text,charsize=2.0
    end
    else: ;other buttons do nothing
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
pro phast_draw_color_event, event

; Event handler for color mode

common phast_state
common phast_images

;if (!d.name NE state.graphicsdevice) then return

case event.type of
    0: begin           ; button press
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
        state.cstretch = 0  ; button release
        if (state.bitdepth EQ 24) then phast_refresh
        phast_draw_motion_event, event
    end
    2: begin                ; motion event
        if (state.cstretch EQ 1) then begin
            phast_stretchct, event.x, event.y, /getcursor 
            phast_resetwindow
            if (state.bitdepth EQ 24) then phast_refresh, /fast
        endif else begin 
            phast_draw_motion_event, event
        endelse
    end 
endcase

widget_control, state.draw_widget_id, /sensitive;, /input_focus

end

;--------------------------------------------------------------------

pro phast_draw_keyboard_event, event


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
        else:
    endcase
endif 
   
if (xregistered('phast', /noshow)) then $
  widget_control, state.draw_widget_id, /sensitive;, /input_focus

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
pro phast_read_vicar,  newimage=newimage, dir=dir

;routine to read a VICAR image file and store it in the archive

common phast_state
common phast_images

widget_control,/hourglass

if not keyword_set(dir) then begin
   file = dialog_pickfile(filter='*.IMG,*.img')
   if file ne '' then begin                             ;check for cancel
      image = read_vicar(file,label)                    ;read the image
      phast_add_image,image,file, label, newimage=newimage ;omit label for now
      main_image = image_archive[state.current_image_index]->get_image()
      phast_getstats
   endif
endif else begin
   fileloc = dialog_pickfile(/directory)
   vicarfile = findfile(fileloc+'*.IMG')
   if vicarfile[0] ne '' then begin ;check the directory actually contains images
      image = read_vicar(vicarfile[0],label) ;read the image
      phast_add_image,image,vicarfile[0],label,newimage=newimage, /dir_add, dir_num = n_elements(vicarfile)     
      for i=1, n_elements(vicarfile)-1 do begin
         image = read_vicar(vicarfile[i],label) ;read the image
         phast_add_image,image,vicarfile[i],label,newimage=newimage, /dir_add
      endfor
   endif else begin
      newimage = 0
      result = dialog_message('Directory contains no VICAR images!',/center,/error)
   endelse 
endelse         
end
;-------------------------------------------------------------------
pro phast_animate

common phast_state
common phast_images

remember_main = main_image ;remember current image to redraw at end

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
  widget_control, state.draw_widget_id, /sensitive;, /input_focus

end

;---------------------------------------------------------------------

pro phast_draw_blink_event, event

; Event handler for blink mode

common phast_state
common phast_images

if (!d.name NE state.graphicsdevice) then return
if (state.bitdepth EQ 24) then true = 1 else true = 0
case event.type of
    0: begin                    ; button press
        if state.animate_toggle eq 1 then begin
            phast_animate
        endif else begin
            phast_setwindow, state.draw_window_id
                                ; define the unblink image if needed
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
     1: begin                    ; button release
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
                 else: begin    ; check for errors
                     state.blinks = 0
                     tv, unblink_image, true = true
                 end
             endcase
         end
     end
     2: phast_draw_motion_event, event ; motion event
endcase

widget_control, state.draw_widget_id, /sensitive;, /input_focus
phast_resetwindow

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

widget_control, state.draw_widget_id, /sensitive;, /input_focus


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

widget_control, state.draw_widget_id, /sensitive;, /input_focus

;if phast_pixtable on, then create a 5x5 array of pixel values and the 
;X & Y location strings that are fed to the pixel table 

if (xregistered('phast_pixtable', /noshow)) then phast_pixtable_update

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
   0: begin                     ; button press
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
   1: begin                     ; button release
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
   2: begin                     ; motion event
      phast_draw_motion_event, event 
      if (state.vectorpress EQ 1) then phast_drawvector, event
      if (state.vectorpress EQ 2) then phast_drawvector, event
      if (state.vectorpress EQ 4) then phast_drawdepth, event
   end
   
   

   else:
endcase

widget_control, state.draw_widget_id, /sensitive;, /input_focus

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

pro phast_pan_event, event

; event procedure for moving the box around in the pan window

common phast_state

if (!d.name NE state.graphicsdevice) then return

case event.type of
    0: begin                     ; button press
        widget_control, state.pan_widget_id, draw_motion_events = 1
        phast_pantrack, event
    end
    1: begin                     ; button release
        widget_control, state.pan_widget_id, draw_motion_events = 0
        widget_control, state.pan_widget_id, /clear_events
        phast_pantrack, event
        phast_refresh
    end
    2: begin
        phast_pantrack, event     ; motion event
        widget_control, state.pan_widget_id, /clear_events
    end
    else:
endcase

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
        if (count EQ 0) then begin       ; resize event
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

    'invert': begin                  ; invert the color table
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

    'min_text': begin     ; text entry in 'min = ' box
        phast_get_minmax, uvalue, event.value
        phast_displayall
    end

    'max_text': begin     ; text entry in 'max = ' box
        phast_get_minmax, uvalue, event.value
        phast_displayall
    end

    'autoscale_button': begin   ; autoscale the image
        phast_autoscale
        phast_displayall
    end

    'full_range': begin    ; display the full intensity range
        state.min_value = state.image_min
        state.max_value = state.image_max
        if state.min_value GE state.max_value then begin
            state.min_value = state.max_value - 1
            state.max_value = state.max_value + 1
        endif
        phast_set_minmax
        phast_displayall
    end
    
    'zoom_in':  phast_zoom, 'in'         ; zoom buttons
    'zoom_out': phast_zoom, 'out'
    'zoom_one': phast_zoom, 'one'

    'center': begin   ; center image and preserve current zoom level
        state.centerpix = round(state.image_size / 2.)
        phast_refresh
    end

    'fullview': phast_fullview

;    'sliceselect': phast_setslice, event

;    'done':  if (state.activator EQ 0) then phast_shutdown $
;      else state.activator = 0

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
    'blink_base_label': begin ;NOTE: USED FOR ANIMATIONS ONLY
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
            widget_control,state.overlay_stars_box_id,ysize=100
            state.tb_overlay_toggle = 1
        endif else begin
            widget_control,state.overlay_stars_box_id,ysize=1
            state.tb_overlay_toggle = 0
        endelse   
    end
    'mag_select': begin
        widget_control,state.mag_select_id,get_value=str
        state.mag_limit = fix(str) ;convert to int
        end
    'display_stars': phast_display_stars
    'display_names': begin
        state.display_names = event.select
    end
    'search_field':
    'search_button': phast_search_stars

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
    'erase_labels': phasterase

;align
    'align_toggle': begin
        if state.align_toggle eq 0 then begin
            state.align_toggle = 1
        endif else state.align_toggle = 0
    end

    else:  print, 'No match for uvalue....'  ; bad news if this happens


endcase
widget_control, state.draw_base_id, /input_focus

end
;----------------------------------------------------------------------
pro phast_image__define

;class definition for image class

struct = {phast_image,$
          image: ptr_new(),$ ;array which holds the image data
          header:ptr_new(),$ ;holds the image header
          name:ptr_new(),$   ;holds the file path to the image
          size:ptr_new(),$   ;contains the size of the image: [x,y]
          astr:ptr_new(),$   ;holds astrometry data, if available
          rotation:ptr_new()$;holds rotation state of image in deg
          }
end
;----------------------------------------------------------------------
function phast_image::init

;constructor for image class

  self.image = ptr_new(/allocate)
  self.header = ptr_new(/allocate)
  self.name = ptr_new(/allocate)
  self.size = ptr_new(/allocate)
  self.rotation = ptr_new(/allocate)
  self.astr = ptr_new() ;this will be allocated when astrometry data is present
  return,1
end
;----------------------------------------------------------------------
pro phast_image::Cleanup

;Routine called by IDL destructor to free memory claimed by object

ptr_free,self.image
ptr_free,self.header
ptr_free,self.name
ptr_free,self.size
ptr_free,self.rotation
ptr_free,self.astr
end
;----------------------------------------------------------------------
function phast_image::get_header

;routine to get header from image object

  return, *(self.header)
end
;----------------------------------------------------------------------
pro phast_image::set_header, header

;routine to set header of image object

  *(self.header) = header
end
;----------------------------------------------------------------------
function phast_image::get_image

;routine to get image from image object

  return, *(self.image)
end
;----------------------------------------------------------------------
pro phast_image::set_image, image

;routine to set image of image object

  *(self.image) = image
  image_size= size(image)
  *(self.size) = [image_size[2],image_size[3]]
end
;----------------------------------------------------------------------
function phast_image::get_name

;routine to get image name from image object

  return, *(self.name)
end
;----------------------------------------------------------------------
pro phast_image::set_name, name

;routine to set image name for image object

  *(self.name) = name
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
pro phast_image::set_rotation,deg,add=add

;routine to set the rotation state of the image in degrees

  common phast_state

  if not keyword_set(add) then begin
     *(self.rotation) = deg mod 360
  endif else begin
     *(self.rotation) = (*(self.rotation) + deg) mod 360
  endelse
  if self.astr_valid() then begin
     hrot, *self.image, *self.header, -1, -1, deg, -1, -1, 2
  endif else *self.image = rot(*self.image,deg)
end
;----------------------------------------------------------------------
function phast_image::get_rotation

;routine to get image rotation state in degrees

  return, *(self.rotation)
end
;----------------------------------------------------------------------
pro phast_image::set_astr,new_astr

;routine to set the astrometry info for the image
  self.astr = ptr_new(new_astr)
end
;----------------------------------------------------------------------
function phast_image::get_astr

;routine to return astrometry data for the image

return,*(self.astr)
end
;----------------------------------------------------------------------
function phast_image::astr_valid

;routine to check if astrometry data present

if ptr_valid(self.astr) then begin
   return, 1
endif else return, 0
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
    xyxy,image_archive[index]->get_header(),image_archive[ref]->get_header(),0,0,x,y
    offset = [x,y]
    if keyword_set(round) then offset = round(offset)
    return, offset
endif else return, [0,0]
end

;----------------------------------------------------------------------
function phast_get_stars, a, d, catalog_name=catalog_name

;routine to retrieve stars from an outside catalog and return
;parameters in the result as follows:
;result[0.*] = name
;result[1,*] = ra
;result[2,*] = dec
;result[3,*] = blue mag
;result[4,*] = clear mag
;result[5.*] = red mag

common phast_state
common phast_images

if not keyword_set(catalog_name) then catalog_name = state.catalog_name
result = -1

widget_control,/hourglass       ;initial load could take some time
case catalog_name of
'USNO-B1.0': begin
   star_catalog = queryvizier('USNO-B1',[a,d],10) ;10 arcmin radius
   result = strarr(8,n_elements(star_catalog.B1MAG))
   result[0,*] = star_catalog.USNO_B1_0
   result[1,*] = star_catalog.RAJ2000
   result[2,*] = star_catalog.DEJ2000
   result[3,*] = star_catalog.B1MAG
   result[5,*] = star_catalog.R1MAG
end 
'GSC-2.3': begin
   star_catalog = queryvizier('GSC-2.3',[a,d],10,/ALLCOLUMNS)
   result = strarr(9,n_elements(star_catalog.GSC2_3))
   result[0,*] = star_catalog.GSC2_3
   result[1,*] = star_catalog.RAJ2000
   result[2,*] = star_catalog.DEJ2000
   result[3,*] = star_catalog.jmag
   result[4,*] = star_catalog.vmag
   result[5,*] = star_catalog.fmag
   result[6,*] = star_catalog.e_jmag
   result[7,*] = star_catalog.e_vmag
   result[8,*] = star_catalog.e_fmag
   
end
endcase
state.catalog_loaded = 1
return, result
end
;----------------------------------------------------------------------

pro phast_display_stars

;routine to overlay catalog star postions/names based on WCS pointing
;info

common phast_state
common phast_images
common phast_pdata

if ptr_valid(state.astr_ptr) then begin
    xy2ad,state.image_size[0]/2,state.image_size[1]/2,*(state.astr_ptr),a,d
    star_catalog = phast_get_stars(a,d,catalog_name='USNO-B1.0')
    phasterase
    mag = float(reform(star_catalog[3,*])) ;choose blue mag
    ra = float(reform(star_catalog[1,*]))
    dec = float(reform(star_catalog[2,*]))
    name = reform(star_catalog[0,*])
    limit = state.mag_limit
    ad2xy,ra[where(mag lt limit)],dec[where(mag lt limit)],*(state.astr_ptr),x,y
    name = name[where(mag lt limit)]
    x1 = x[where(x gt 0 and x lt state.image_size[0] and y gt 0 and y lt state.image_size[1])]
    y1 = y[where(x gt 0 and x lt state.image_size[0] and y gt 0 and y lt state.image_size[1])]
    name1 = name[where(x gt 0 and x lt state.image_size[0] and y gt 0 and y lt state.image_size[1])]
    for i = 0, n_elements(x1)-1 do begin
        if nplot lt maxplot then begin
            nplot++
            region_str = 'circle('+strtrim(string(x1[i]),2)+', '+strtrim(string(y1[i]),2)+', 4) # color=blue'
            options = {color:'blue',thick:'1'}
            options.color = phast_icolor(options.color)
            pstruct = {type:'region',reg_array:[region_str],options:options}
            plot_ptr[nplot] =ptr_new(pstruct)
            phast_plotwindow
            phast_plot1region,nplot
        endif
    endfor
    if state.display_names eq 1 then phastxyouts,x1+5,y1,name1,charsize=1.5,color='blue'
    widget_control,state.search_msg_id,set_value='Overlay successful!'
endif else widget_control,state.search_msg_id,set_value='WCS data not present'
end
;----------------------------------------------------------------------
pro phast_search_stars

common phast_state
common phast_images
common phast_pdata

widget_control,state.star_search_widget_id,get_value=term


if ptr_valid(state.astr_ptr) then begin
    xy2ad,state.image_size[0]/2,state.image_size[1]/2,*(state.astr_ptr),a,d
    star_catalog = phast_get_stars(a,d,catalog_name='USNO-B1.0')
    ra = float(reform(star_catalog[1,*]))
    dec = float(reform(star_catalog[2,*]))
    name = reform(star_catalog[0,*])
    ad2xy,ra,dec,*(state.astr_ptr),x,y
    x1 = x[where(x gt 0 and x lt state.image_size[0] and y gt 0 and y lt state.image_size[1])]
    y1 = y[where(x gt 0 and x lt state.image_size[0] and y gt 0 and y lt state.image_size[1])]
    name1 = name[where(x gt 0 and x lt state.image_size[0] and y gt 0 and y lt state.image_size[1])]
    index_list = where(name1 eq term[0])
    if index_list ne -1 then begin
                                ;phastxyouts,x1[index_list],y1[index_list],'.',charsize=5,alignment=0.5,color='blue'
        if nplot lt maxplot then begin
            nplot++
            region_str = 'circle('+strtrim(string(x1[index_list]),2)+', '+strtrim(string(y1[index_list]),2)+', 4) # color=blue'
            options = {color:'blue',thick:'1'}
            options.color = phast_icolor(options.color)
            pstruct = {type:'region',reg_array:[region_str],options:options}
            plot_ptr[nplot] =ptr_new(pstruct)
            phast_plotwindow
            phast_plot1region,nplot
        endif
        phastxyouts,x1[index_list]+5,y1[index_list],name1[index_list],charsize=1.5,color='blue'
        widget_control,state.search_msg_id,set_value='Search successful!'
    endif else begin
        widget_control,state.search_msg_id,set_value='Search term not found'
    endelse

endif else begin
    widget_control,state.search_msg_id,set_value='WCS data not present'
end

end
;----------------------------------------------------------------------
function phast_label_get_par,lab,par

;routine to return specificed parameter from VICAR label.  Similar to
;SXGETPAR

readcol, lab, label,delimiter='|',FORMAT='A',/silent
 
result = ''
success = 0
for i=0, n_elements(label)-1 do begin
   split = strsplit(label[i],'=',/extract) ;separate parameter from value
   if strmatch(strtrim(split[0],2),par) ne 0 then begin
      result = strtrim(split(n_elements(split)-1),2)
      success = 1
   endif
endfor 
return,result
end
;----------------------------------------------------------------------
pro phast_check_moons

;routine to check the current VICAR image for moons with the SPICE
;kernels

common phast_state
common phast_images

;check that the ICY DLM is installed

;load the SPICE kernels specified in state.kernel_list
readcol,state.kernel_list,kernels, delimiter='|',format='A',/silent
cspice_furnsh,kernels

;retrive start and stop times for image
split_filename = strsplit(image_archive[state.current_image_index]->get_name(),'.',/extract)
filename = split_filename[0]+'.LBL'
start = strsplit(phast_label_get_par(filename,'START_TIME'),'"',/extract)
start = strsplit(start[0],'Z',/extract)
start = start[0]
stop = strsplit(phast_label_get_par(filename,'STOP_TIME'),'"',/extract)
stop = strsplit(stop[0],'Z',/extract)
stop = stop[0]
utc = [start,stop]
cspice_str2et, utc, et
full_time = [et[0]-3600,et[0]+3600] 
maxwin = 1000
TIMFMT  = 'YYYY-MON-DD HR:MN:SC.###### (TDB) ::TDB ::RND'
TIMLEN  =  41
                        
moons = ["PANDORA","MIMAS","JANUS","ENCELADUS","RHEA","TETHYS","DIONE","TITAN","PAN",$
                                "IAPETUS","PHOEBE","EPIMETHEUS","CALYPSO","HELENE","TELESTO","ATLAS","PROMETHEUS"]
moon_naif =  [617,601,610,602,605,603,604,606,618,608,609,611,614,612,613,615,616]
i=0

while(i lt n_elements(moons)) do begin
   cnfine = cspice_celld( 2 )
   full_range = cspice_celld( 2 )
   cspice_wninsd, et[0], et[1], cnfine
   cspice_wninsd,full_time[0],full_time[1],full_range
   inst   = 'CASSINI_ISS_NAC'
   target = moons[i]
   tshape = 'ELLIPSOID'
   tframe = 'IAU_'+moons[i]
   abcorr = 'LT+S'
   obsrvr = 'CASSINI'
   step   = 10.D
   result = cspice_celld( MAXWIN*2)
   full_result = cspice_celld( MAXWIN*2)
                                ;check for moon in fov
   cspice_gftfov, inst,  target, tshape, tframe, abcorr, obsrvr, $
                  step, cnfine, result
   cspice_gftfov, inst,  target, tshape, tframe, abcorr, obsrvr, $
                  step, full_range, full_result
   count = cspice_wncard( result )
   num = cspice_wncard( full_result ) ;check whether moon found in fov
   if(num ne 0 and count ne 0) then begin
      cspice_wnfetd, full_result, 0, left, right ;determine time moon enters/leaves frame

      offset = (left-et[0])/(left-right) ;position in frame as percent [0,1]
      cspice_spkez,moon_naif[i],et[0],'J2000','NONE',-82,vec,ltime                    ;get moon state
      range = (vec[0]^2+vec[1]^2+vec[2]^2)^(.5)                                   ;calculate range
      
      if (vec[4] gt 0) then offset = 1-offset
      x = offset*1024
      phastxyouts,x,600+40*i,moons[i],color='green',charsize=1.5
      phastxyouts,x,580+40*i,"Range: "+strtrim(range,2)+" km", color='red', charsize=1.5
   end
   
   i++
end
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
    phast_setheader, image_archive[state.current_image_index]->get_header()
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
pro phast_refresh_image,index,filename

;routine to refresh an image already in the archive with an updated
;version

common phast_state

phast_readfits,fitsfilename=filename,/refresh_toggle,refresh_index=index

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
    phast_setheader, image_archive[state.current_image_index]->get_header()
    counter_string = 'Cycle images: ' + strtrim(string(state.current_image_index+1),1) + ' of ' + strtrim(string(state.num_images),1)
;update widgets
    widget_control,state.image_counter_id,set_value= counter_string
    phast_getstats,/align,/noerase                ;update stats based on new image
    phast_settitle                                ;update title bar with object name
    phast_displayall            ;redraw screen
end
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

;-----------------------------------------------------------------------
;      main phast routines for scaling, displaying, cursor tracking...
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

;-----------------------------------------------------------------------

pro phast_displaymain

; Display the main image and overplots

common phast_state
common phast_images
offset = [0,0]
if state.align_toggle eq 1 then offset = phast_get_image_offset()
phast_setwindow, state.draw_window_id

if state.align_toggle eq 1 then tv, display_image,offset[0],offset[1]
if state.align_toggle ne 1 then tv, display_image
phast_resetwindow

end

;--------------------------------------------------------------------

pro phast_getoffset
common phast_state

; Routine to calculate the display offset for the current value of
; state.centerpix, which is the central pixel in the display window.

state.offset = $
  round( state.centerpix - $
         (0.5 * state.draw_window_size / state.zoom_factor) )

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

;----------------------------------------------------------------------

pro phast_set_minmax

; Updates the min and max text boxes with new values.

common phast_state

widget_control, state.min_text_id, set_value = string(state.min_value)
widget_control, state.max_text_id, set_value = string(state.max_value)

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

;--------------------------------------------------------------------

pro phast_zoom, zchange, recenter = recenter
common phast_state

; Routine to do zoom in/out and recentering of image.  The /recenter
; option sets the new display center to the current cursor position.

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

;-----------------------------------------------------------------------

pro phast_fullview
common phast_state

; set the zoom level so that the full image fits in the display window

sizeratio = float(state.image_size) / float(state.draw_window_size)
maxratio = (max(sizeratio)) 

state.zoom_level = floor((alog(maxratio) / alog(2.0)) * (-1))
state.zoom_factor = (2.0)^(state.zoom_level)

; recenter
state.centerpix = round(state.image_size / 2.)

phast_refresh

phast_resetwindow

end

;----------------------------------------------------------------------

pro phast_invert, ichange
common phast_state
common phast_images

; Routine to do image axis-inversion (X,Y,X&Y)

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

;------------------------------------------------------------------

pro phast_rotate, rchange, get_angle=get_angle
common phast_state
common phast_images

; Routine to do image rotation

; If /get_angle set, create widget to enter rotation angle

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

;---------------------------------------------------------------------

function phast_wcsstring, lon, lat, ctype, equinox, disp_type, disp_equinox, $
            disp_base60

common phast_state

; Routine to return a string which displays cursor coordinates.
; Allows choice of various coordinate systems.
; Contributed by D. Finkbeiner, April 2000.
; 29 Sep 2000 - added degree (RA,dec) option DPF
; Apr 2007: AJB added additional error checking to prevent crashes

; ctype - coord system in header
; disp_type - type of coords to display

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
   IF num_disp_equinox NE 2000.0 THEN precess, disp_ra, disp_dec, $
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
xmin = 0 > (zcenter[0] - boxsize)
xmax = (zcenter[0] + boxsize) < (state.image_size[0] - 1) 
ymin = 0 > (zcenter[1] - boxsize) 
ymax = (zcenter[1] + boxsize) < (state.image_size[1] - 1)

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

common phast_state

widget_control, event.id, get_uvalue = uvalue

case uvalue of
    'pixtable_done': widget_control, event.top, /destroy
    else:
endcase

end

;--------------------------------------------------------------------

pro phast_pixtable_update

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



;--------------------------------------------------------------------
;    Fits file reading routines
;--------------------------------------------------------------------

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
        phast_fitsext_read, fitsfile, numext, head, cancelled
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

;----------------------------------------------------------
;  Subroutines for reading specific data formats
;---------------------------------------------------------------

pro phast_fitsext_read, fitsfile, numext, head, cancelled

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

;------------------------------------------------------------------

pro phast_plainfits_read, fitsloc, head, cancelled,dir=dir,refresh_index=index,refresh_toggle=refresh, newimage = newimage

common phast_images

; Fits reader for plain fits files, no extensions.
;main_image=0
if keyword_set(dir) then begin
    fitsfile = findfile(fitsloc+'*.fits')
    if fitsfile[0] ne '' then begin ;check folder actually contains any images
       ;read first image and set up directory add
       fits_read, fitsfile[0],main_image,head
       head = headfits(fitsfile[0])
       phast_add_image,main_image,fitsfile[0],head, newimage = newimage, /dir_add, dir_num = n_elements(fitsfile)
       for i=1, n_elements(fitsfile)-1 do begin
            fits_read, fitsfile[i],main_image,head
            head = headfits(fitsfile[i])
            phast_add_image,main_image,fitsfile[i],head, newimage = newimage,/dir_add
        endfor
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

;-----------------------------------------------------------------

pro phast_getfirst

common phast_state
common phast_images

; This feature is currently disabled in the top-level menu.  FIRST
; changed their image server to send out images as "chunked" data
; and webget.pro can't read chunked HTTP files.  If webget ever
; adds support for chunked data then we can turn this back on again.

formdesc = ['0, text, , label_left=Object Name: , width=15, tag=objname', $
            '0, button, NED|SIMBAD, set_value=0, label_left=Object Lookup:, exclusive, tag=lookupsource', $
            '0, label, Or enter J2000 Coordinates:, CENTER', $
            '0, text, , label_left=RA   (hh:mm:ss.ss): , width=15, tag=ra', $
            '0, text, , label_left=Dec (+dd:mm:ss.ss): , width=15, tag=dec', $
            '0, float, 10.0, label_left=Image Size (arcmin; max=30): ,tag=imsize', $
            '1, base, , row', $
            '0, button, GetImage, tag=getimage, quit', $
            '0, button, Cancel, tag=cancel, quit']    

archiveform = cw_form(formdesc, /column, title = 'phast: Get FIRST Image')

if (archiveform.cancel EQ 1) then return

if (archiveform.imsize LE 0.0 OR archiveform.imsize GT 30.0) then begin
    phast_message, 'Image size must be between 0 and 30 arcmin.', $
      msgtype='error', /window
    return
endif

imsize = string(round(archiveform.imsize))

case archiveform.lookupsource of
    0: ned = 1
    1: ned = 0  ; simbad lookup
endcase

widget_control, /hourglass
if (archiveform.objname NE '') then begin
    ; user entered object name
    querysimbad, archiveform.objname, ra, dec, found=found, ned=ned, $
      errmsg=errmsg
    if (found EQ 0) then begin
        phast_message, errmsg, msgtype='error', /window
        return
    endif
    
; convert decimal ra, dec to hms, dms
    sra = sixty(ra/15.0)
    rahour = string(round(sra[0]))
    ramin = string(round(sra[1]))
    rasec = string(sra[2])

    if (dec LT 0) then begin
        decsign = '-'
    endif else begin
        decsign = '+'
    endelse
    sdec = sixty(abs(dec))
 
    decdeg = strcompress(decsign + string(round(sdec[0])), /remove_all)
    decmin = string(round(sdec[1]))
    decsec = string(sdec[2])

endif else begin
    ;  user entered ra, dec
    rastring = archiveform.ra
    decstring = archiveform.dec
    phast_getradec, rastring, decstring, ra, dec

endelse

; build the url to get image

url = 'http://third.ucllnl.org/cgi-bin/firstimage'
url = strcompress(url + '?RA=' + rahour + '%20' + ramin + '%20' + rasec, $
                 /remove_all)
url = strcompress(url + '%20' + decdeg + '%20' + decmin + '%20' + $
                  decsec + '&Dec=', /remove_all)
url = strcompress(url + '&Equinox=J2000&ImageSize=' + imsize + $
                  'MaxInt=10&FITS=1&Download=1', /remove_all)

; now use webget to get the image
result = webget(url)

if (n_elements(result.image) LE 1) then begin
    phast_message, result.text, msgtype='error', /window
    return
endif else begin  ; valid image
    phast, result.image, header=result.imageheader
    result.header = ''
    result.text =  ''
    result.imageheader = ''
    result.image = ''
endelse

end

;-----------------------------------------------------------------

pro phast_getradec, rastring, decstring, ra, dec

; converts ra and dec strings in hh:mm:ss and dd:mm:ss to decimal degrees
; new and improved version by Hal Weaver, 9/6/2010

ra = 15.0 * ten(rastring)
dec = ten(decstring)


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

;-------------------------------------------------------------------

pro phastslicer_event, event

common phast_state
common phast_images

; event handler for data cube slice selector widgets

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

;-----------------------------------------------------------------------
;     Routines for creating output graphics
;----------------------------------------------------------------------


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
;       routines for defining the color maps
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
 
;---------------------------------------------------------------------
;    routines dealing with image header, title,  and related info
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

;---------------------------------------------------------------------


pro phast_headinfo

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

common phast_state

widget_control, event.id, get_uvalue = uvalue

case uvalue of
    'headinfo_done': widget_control, event.top, /destroy
    else:
endcase

end

;----------------------------------------------------------------------
;             routines to do plot overlays
;----------------------------------------------------------------------

pro phast_plot1plot, iplot
common phast_pdata
common phast_state

; Plot a point or line overplot on the image

phast_setwindow, state.draw_window_id

widget_control, /hourglass

oplot, [(*(plot_ptr[iplot])).x], [(*(plot_ptr[iplot])).y], $
  _extra = (*(plot_ptr[iplot])).options

phast_resetwindow
state.newrefresh=1
end

;----------------------------------------------------------------------

pro phast_plot1text, iplot
common phast_pdata
common phast_state

; Plot a text overlay on the image
phast_setwindow, state.draw_window_id

widget_control, /hourglass

xyouts, (*(plot_ptr[iplot])).x, (*(plot_ptr[iplot])).y, $
  (*(plot_ptr[iplot])).text, _extra = (*(plot_ptr[iplot])).options

phast_resetwindow
state.newrefresh=1
end

;----------------------------------------------------------------------

pro phast_plot1arrow, iplot
common phast_pdata
common phast_state

; Plot a arrow overlay on the image
phast_setwindow, state.draw_window_id

widget_control, /hourglass

arrow, (*(plot_ptr[iplot])).x1, (*(plot_ptr[iplot])).y1, $
  (*(plot_ptr[iplot])).x2, (*(plot_ptr[iplot])).y2, $
  _extra = (*(plot_ptr[iplot])).options, /data

phast_resetwindow
state.newrefresh=1
end


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

;----------------------------------------------------------------------


pro phast_plot1region, iplot
common phast_pdata
common phast_state

; Plot a region overlay on the image
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

;----------------------------------------------------------------------


pro phast_plot1contour, iplot
common phast_pdata
common phast_state

; Overplot contours on the image

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

pro phast_arcbar, hdr, arclen, LABEL = label, SIZE = size, THICK = thick, $
                DATA =data, COLOR = color, POSITION = position, $
                NORMAL = normal, SECONDS=SECONDS

common phast_state

; This is a copy of the IDL Astronomy User's Library routine 'arcbar',
; abbreviated for phast and modified to work with zoomed images.  For
; the revision history of the original arcbar routine, look at
; arcbar.pro in the pro/astro subdirectory of the IDL Astronomy User's
; Library.

; Modifications for phast:
; Modified to work with zoomed PHAST images, AJB Jan. 2000 
; Moved text label upwards a bit for better results, AJB Jan. 2000

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

;----------------------------------------------------------------------

pro phast_plotwindow
common phast_state

phast_setwindow, state.draw_window_id

; Set plot window

; improved version by N. Cunningham- different scaling for postscript
; vs non-postscript output  -- added 4/14/06
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

;---------------------------------------------------------------------

pro phast_plotall
common phast_state
common phast_pdata

; Routine to overplot all line, text, and contour plots

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

pro phastplot, x, y, _extra = options
common phast_pdata
common phast_state

; Routine to read in line plot data and options, store in a heap
; variable structure, and plot the line plot

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
common phast_pdata
common phast_state

; Routine to read in text overplot string and options, store in a heap
; variable structure, and overplot the text

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

;----------------------------------------------------------------------

pro phastarrow, x1, y1, x2, y2, _extra = options
common phast_pdata
common phast_state

; Routine to read in arrow overplot options, store in a heap
; variable structure, and overplot the arrow

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


;---------------------------------------------------------------------

pro phastcontour, z, x, y, _extra = options
common phast_pdata
common phast_state

; Routine to read in contour plot data and options, store in a heap
; variable structure, and overplot the contours.  Data to be contoured
; need not be the same dataset displayed in the phast window, but it
; should have the same x and y dimensions in order to align the
; overplot correctly.

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
common phast_pdata

; Routine to erase line plots from PHASTPLOT, text from PHASTXYOUTS, and
; contours from PHASTCONTOUR.

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

;------------------------------------------------------------------


pro phast_loadregion

common phast_state
common phast_pdata

; Routine to read in region filename, store in a heap variable
; structure, and overplot the regions

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



;---------------------------------------------------------------------
;          routines for drawing in the lineplot window
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


;--------------------------------------------------------------------

pro phast_contourplot, ps=ps, fullrange=fullrange, newcoord=newcoord

if (keyword_set(ps)) then begin
    thick = 3
    color = 0
endif else begin
    thick = 1
    color = 7
endelse

common phast_state
common phast_images

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


;----------------------------------------------------------------------
;                         help window
;---------------------------------------------------------------------

pro phast_help
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

widget_control, event.id, get_uvalue = uvalue

case uvalue of
    'help_done': widget_control, event.top, /destroy
    else:
endcase

end

;----------------------------------------------------------------------
;      Routines for displaying image statistics
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

pro phast_stats_event, event

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
;        aperture photometry and radial profile routines
;---------------------------------------------------------------------

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

;-----------------------------------------------------------------------
pro phast_apphot_refresh

; Do aperture photometry using idlastro daophot routines.

common phast_state
common phast_images
common phast_mpc_data

state.photwarning = 'Warnings: None'

; Center on the object position nearest to the cursor
if (state.centerboxsize GT 0) then begin
    phast_imcenterf, x, y
endif else begin ; no centering
    x = state.cursorpos[0]
    y = state.cursorpos[1]
endelse

;update the exposure length and zero-point from image header
;if state.num_images gt 0 and state.image_type eq 'FITS' then begin
;    head = headfits(state.imagename)
;    state.exptime = sxpar(head,'EXPTIME')
;    state.photzpt = sxpar(head,'MAGZERO')
;    state.photclr = sxpar(head,'MAGZCLR')
;    state.photband= sxpar(head,'MAGZBND')
;    state.photzerr= sxpar(head,'MAGZERR')
;    state.photznum= sxpar(head,'MAGZNUM')
;endif

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
    phast_message, $
      'Sorry- PHAST can not do photometry on regions containing NaN values.', $
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

  ipass = 0
maxpass = 2
repeat begin
  ipass = ipass + 1

  phpadu = state.ccdgain
  apr    = [state.aprad]
  skyrad = [state.innersky, state.outersky]

  ; Do the photometry now
  case state.skytype of
    0: aper, main_image, [x], [y], flux, errap, sky, skyerr, phpadu, apr, $
             skyrad, badpix, flux=abs(state.magunits-1), /silent, $
             readnoise = state.ccdrn
    1: aper, main_image, [x], [y], flux, errap, sky, skyerr, phpadu, apr, $
             skyrad, badpix, flux=abs(state.magunits-1), /silent, $
             setskyval = skyval, readnoise = state.ccdrn
    2: aper, main_image, [x], [y], flux, errap, sky, skyerr, phpadu, apr, $
             skyrad, badpix, flux=abs(state.magunits-1), /silent, $
             setskyval = 0, readnoise = state.ccdrn
  endcase

  flux = flux[0]
  sky  =  sky[0]

  if (flux EQ 99.999) then begin
    state.photwarning = 'Warning: Error in computing flux!'
    flux = !values.F_NAN
    endif

  if (state.magunits EQ 1) then flux = (flux - 25.0) + state.photzpt + state.photclr*state.photSpecBmR  + 2.5 * alog10(state.exptime)

  ; Run phast_radplotf and plot the results
  phast_setwindow, state.radplot_window_id
  phast_radplotf, x, y, fwhm

  ; overplot the phot apertures on radial plot
  plots, [state.aprad, state.aprad], !y.crange, line = 1, color=2, thick=2, psym=0

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
          
  ; reset the apertures
  if (state.photautoaper EQ 1) then begin
    gaussSigma = fwhm/(2*sqrt(2*alog(2)))
    case state.sex_PHOT_AUTOPARAMS[0] of
      2.0 : state.aprad = gaussSigma*sqrt(-2*alog(1-0.90))
      2.5 : state.aprad = gaussSigma*sqrt(-2*alog(1-0.94))
      else: state.aprad = gaussSigma*sqrt(-2*alog(1-0.90))
      endcase
      state.aprad    = round( 100 * state.aprad                           ) / 100.0
      state.innersky = round( 100 * gaussSigma*sqrt(-2*alog(1-0.9999))    ) / 100.0
      state.outersky = round( 100 * sqrt( (!pi*state.innersky^2+100)/!pi) ) / 100.0
      state.centerboxsize = 9 > round( 1.2*state.outersky )
  endif
  
  phast_resetwindow
endrep until (ipass eq maxpass)

; write results to file if requested  
if (state.photprint EQ 1) then begin
   openw, state.photfile, state.photfilename, /append
   if (state.photerrors EQ 0) then errap = 0.0
   formatstring = '(2(f7.1," "),3(f5.1," "),3(g12.6," "),f5.2)'
   printf, state.photfile, x, y, state.aprad, $
           state.innersky, state.outersky, sky, flux, errap, fwhm, $
           format = formatstring
   close, state.photfile
endif

; output the results
case state.magunits of
    0: begin
        imgScale = 1.0
       end
    1: begin
        imgScale = state.pixelscale
       end
endcase

state.centerpos = [x, y]
if ptr_valid(state.astr_ptr) then begin
    xy2ad,x,y,*(state.astr_ptr),ra,dec
    wcsstring = phast_wcsstring(ra, dec, (*state.astr_ptr).ctype,  $
                              state.equinox, state.display_coord_sys, $
                              state.display_equinox, state.display_base60)
end

tmp_string0 = string(state.cursorpos[0], state.cursorpos[1], $
                     format = '("Cursor position:  x=",i4,"  y=",i4)' )
tmp_string1 = string(state.centerpos[0], state.centerpos[1], $
                     format = '("Object position: (",f6.1,", ",f6.1,")")')


if state.magunits eq 0 then begin ; pixel and ADU units
    tmp_string2 = string(flux, format= '("Object counts: ",F12.1)' )  + ' ' + string(177b) + ' ' + string(errap,  format= '(f5.3)' ) 
    tmp_string3 = string(sky,  format= '(" Sky Bkg: ",F9.1)' )        + ' ' + string(177b) + ' ' + string(skyerr, format= '(f5.3)' )
    SNR = 999.9 < flux/errap  
    tmp_string4 = string(imgScale*fwhm, format='("  FWHM: ",f4.2, 1h")' ) + string(SNR, format= '(2x,"SNR: ",f5.1)' )
endif else begin  ; arcsec and magnitude units
    skyerr = 1.0857 * skyerr/sky
    sky = sky / (!pi*state.aprad*state.aprad)                         ; flux per pixel = sky flux/(!pi*state.aprad*state.aprad)
    sky = sky / (imgScale*imgScale)                                   ; magnitude/arcsecond^2
    sky =  state.photzpt -2.5 * alog10(sky/state.exptime) ; 
    SNR = 1.0 / (errap/1.0857)
    tmp_string2 = string(flux, format= '("    Magnitude: ",f5.2)' ) + ' ' + string(177b) + ' ' + string(sqrt(errap^2+state.photzerr^2), format= '(f4.2)' )  
    tmp_string3 = string(sky,  format= '("  Sky Bkg: ",f5.2)' ) + ' ' + string(177b) + ' ' + string(skyerr                        , format= '(f4.2)' )             
    tmp_string4 = string(imgScale*fwhm, format='("    FWHM: ",f4.2, 1h")' ) + string(SNR, format= '(2x,"SNR: ",f5.1)' )
endelse

if (state.photerrors EQ 0) then begin
   errstring = 'Photometric error: N/A'
endif else begin
   if state.magunits eq 0 then errstring = strcompress('Precision: ' + ' ' + string(177b) + ' ' + string(errap, format = '(F12.1)' )) $
                          else errstring = strcompress('Precision: ' + ' ' + string(177b) + ' ' + string(errap, format = '(f7.4)' ))
endelse

;pass data to MPC report
phast_get_mpc_data,mpc.index,flux

widget_control, state.centerbox_id,   set_value = state.centerboxsize
;widget_control, state.cursorpos_id,  set_value = tmp_string0
widget_control, state.apphot_wcs_id,  set_value=wcsstring
widget_control, state.centerpos_id,   set_value = tmp_string1
widget_control, state.radius_id,      set_value = state.aprad 
widget_control, state.outersky_id,    set_value = state.outersky
widget_control, state.innersky_id,    set_value = state.innersky
widget_control, state.skyresult_id,   set_value = tmp_string3
widget_control, state.photresult_id,  set_value = tmp_string2
widget_control, state.fwhm_id,        set_value = tmp_string4
widget_control, state.photwarning_id, set_value=state.photwarning
widget_control, state.photerror_id,   set_value = errstring

; Uncomment next lines if you want phast to output the WCS coords of 
; the centroid for the photometry object:
;if (state.wcstype EQ 'angle') then begin
;    xy2ad, state.centerpos[0], state.centerpos[1], *(state.astr_ptr), $
;      clon, clat
;    wcsstring = phast_wcsstring(clon, clat, (*state.astr_ptr).ctype,  $
;                state.equinox, state.display_coord_sys, state.display_equinox)
;    print, 'Centroid WCS coords: ', wcsstring
;endif

phast_tvphot

phast_resetwindow
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

pro phast_apphot_event, event

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

    'spectralLtr': begin
        state.photSpecType = event.value
        state.photSpecTypeNum = where( state.photSpecList eq state.photSpecType, count )
        colors = phast_intrinsic_colors(state.photSpecTypeNum, state.photSpecSubNum)
        state.photSpecBmV = colors[0] & widget_control, state.photSpec_BmV_ID, set_value=state.photSpecBmV
        state.photSpecVmR = colors[1] & widget_control, state.photSpec_VmR_ID, set_value=state.photSpecVmR
        state.photSpecBmR = colors[2] & widget_control, state.photSpec_BmR_ID, set_value=state.photSpecBmR  
    end

    'spectralNum': begin
        state.photSpecSubNum = (0 > event.value) < 9
        widget_control, state.photSpec_Num_ID, set_value=state.photSpecSubNum
        colors = phast_intrinsic_colors(state.photSpecTypeNum, state.photSpecSubNum)
        state.photSpecBmV = colors[0] & widget_control, state.photSpec_BmV_ID, set_value=state.photSpecBmV
        state.photSpecVmR = colors[1] & widget_control, state.photSpec_VmR_ID, set_value=state.photSpecVmR
        state.photSpecBmR = colors[2] & widget_control, state.photSpec_BmR_ID, set_value=state.photSpecBmR  
    end

    'spectralBmV': begin
        state.photSpecBmV = event.value 
        state.photSpecBmR = state.photSpecBmV + state.photSpecVmR
        widget_control, state.photSpec_BmV_ID, set_value=state.photSpecBmV
        widget_control, state.photSpec_VmR_ID, set_value=state.photSpecVmR
        widget_control, state.photSpec_BmR_ID, set_value=state.photSpecBmR  
    end

    'spectralVmR': begin
        state.photSpecVmR = event.value 
        state.photSpecBmR = state.photSpecBmV + state.photSpecVmR
        widget_control, state.photSpec_BmV_ID, set_value=state.photSpecBmV
        widget_control, state.photSpec_VmR_ID, set_value=state.photSpecVmR
        widget_control, state.photSpec_BmR_ID, set_value=state.photSpecBmR  
    end
 
    'spectralBmR': begin
        state.photSpecBmR = event.value 
        widget_control, state.photSpec_BmV_ID, set_value=0.0
        widget_control, state.photSpec_VmR_ID, set_value=0.0
        widget_control, state.photSpec_BmR_ID, set_value=state.photSpecBmR  
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
          openw, photfile, photfilename, /get_lun, /append
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

;    'magunits': begin
;        state.magunits = event.value
;        phast_apphot_refresh
;    end

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

;----------------------------------------------------------------------

pro phast_apphot_settings

; Routine to get user input on various photometry settings

common phast_state

skyline = ('0, button, IDLPhot Sky Mode|Median Sky|No Sky Subtraction,'+$
                      'exclusive,' + $
                      'label_left=Select Sky Algorithm: , set_value = ' + $
                      string(state.skytype))

magline =  ('0, button, Pixels ADUs|Arcsecs Magnitudes, exclusive,' + $
            'label_left =Select Output Units: , set_value =' + $
            string(state.magunits))

aperline =  ('0, button, Fixed Apertures|Auto Apertures, exclusive,' + $
            'label_left =Select Aperture Sizes: , set_value =' + $
            string(state.photautoaper))
            
zptline =  ('0, float,'+string(state.photzpt,'(F6.3)') + $
            ',label_left = Magnitude Zeropoint:,'  +  'width = 6')

clrline =  ('0, float,'+string(state.photclr,'(F7.4)') + $
            ',label_left =          Color Term:,'  +  'width = 7')
                      
exptimeline = ('0, float,'+string(state.exptime,'(F6.1)') + $
               ',label_left =   Exposure Time (s):,'  + 'width = 6')

errline = ('0, button, No|Yes, exclusive,' + $
                      'label_left = Calculate photometric errors? ,' + $
                      'set_value =' + $
                      string(state.photerrors))

gainline = ('0, float,'+string(state.ccdgain,'(F6.1)') + $
                      ',label_left = CCD Gain (e-/DN):,' + $
                      'width = 6')

rnline = ('0, float,'+string(state.ccdrn,'(F6.1)') + $
                      ',label_left = Readout Noise (e-):,' + $
                      'width = 6')
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
            aperline,     $
            zptline,      $
            clrline,      $
            exptimeline,  $
            '0, label, [ Magnitude = ZPT + CLR*(b-r) - 2.5 log10(DN/exptime) ]', $
            errline,      $ 
            gainline,     $
            rnline,       $
            warningline1, warningline2, warningline3, warningline4, $
            '0, button, Apply Settings, quit', $
            '0, button, Cancel, quit']

textform = cw_form(formdesc, /column, $
                   title = 'phast photometry settings')

if (textform.tag15 EQ 1) then return ; cancelled

state.skytype = textform.tag0
state.magunits = textform.tag1
if (state.photautoaper NE textform.tag2) then begin
  if textform.tag2 EQ 0 then begin      ; return to defauult apertures
    state.aprad = state.aprad_def
    state.innersky = state.innersky_def
    state.outersky = state.outersky_def
  endif
  state.photautoaper = textform.tag2
endif
state.photzpt = textform.tag3
state.photclr = textform.tag4
state.exptime = textform.tag5
state.photerrors = textform.tag7
state.ccdgain = (1.e-5) > textform.tag8
state.ccdrn = 0 > textform.tag9

if (state.exptime LE 0) then state.exptime = 1.0

phast_apphot_refresh

end
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
printf,1,'ACK '+mpc.ack
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
pro phast_do_all

;routine to automatically process an image through the entire pipeline

common phast_state
common phast_images

widget_control, /hourglass

;run SExtractor
;spawn, 'sex ' + state.imagename + ' -CATALOG_NAME phast.cat'
phast_do_sextractor, cat_name = 'phast.cat'

;run Scamp
;spawn, 'scamp phast.cat'
phast_do_scamp,cat_name = 'phast.cat'

;write astrometric solution to calibrated image
;spawn,'missfits phast.fits -SAVE_TYPE REPLACE'
phast_do_missfits, image = 'phast.fits', flags = '-SAVE_TYPE REPLACE'

;find zero-point
phast_calculate_zeropoint, magzero, magzerr, magzclr, magzbnd

;report finished
result = dialog_message('Done!              ',/center,/information)

end

;---------------------------------------------------------------------------
pro phast_calculate_zeropoint, magzero, magzerr, magzclr, magzbnd, msgarr

;routine to match SExtractor catalog to reference catalog and
;calculate a photometric zero-point

common phast_state
common phast_images

; must have astrometric solution to match to catalog
if not ptr_valid(state.astr_ptr) then begin
  magzero =  0.0
  magzerr = 99.0
  magzclr =  0.0
  magzbnd = 'INSTR'

  msgarr = strarr(2)
  msgarr(0) = 'Photometric zeropoint can not be determined'
  msgarr(1) = 'Perform astrometric calibration first'                                                                                
  return
endif

; begin zeropoint determination
widget_control,/hourglass ;this could be slow

match_tol = 1.5 / 3600.   ; astrometric matching tolerance (arcsecs converted to degrees)
sigmaClip = 2.00          ; outlier rejection: 1-in-25 chance of false positive (N=25)
minSNRe   = 10.0          ; minimum detection SNRe to use in calibration

; 1) determine filter and exposure for image (patch=filter info should be read from config file)
keyFilter = 'FILTERS'
txtFilter = [ '', 'V', 'B', '?', 'R', '?', '?', 'C', 'C' ]

fits_read, state.imagename, image, head  
exposure  = sxpar(head,'EXPTIME')
posFilter = sxpar(head,keyFilter)
imgBand   = txtFilter[posFilter]

; 2) obtain catalog for matching area on the sky  (patch=pass in sky area size)
xy2ad,state.image_size[0]/2,state.image_size[1]/2,*(state.astr_ptr),a,d
star_catalog = phast_get_stars(a,d,catalog_name=state.photcatalog_name)
state.photcatalog_loaded = 1

cat_RA   = float(reform(star_catalog[1,*]))
cat_dec  = float(reform(star_catalog[2,*]))
cat_BMag = float(reform(star_catalog[3,*])) ; blue mag
cat_errB = float(reform(star_catalog[6,*])) 
cat_VMag = float(reform(star_catalog[4,*])) ; visual mag
cat_errV = float(reform(star_catalog[7,*]))
cat_RMag = float(reform(star_catalog[5,*])) ; red mag
cat_errR = float(reform(star_catalog[8,*])) 

; qualify catalog mags (generally valid ranges by color)
for i=0, n_elements(cat_RA)-1 do begin 
  if not (11. lt cat_BMag[i] And cat_BMag[i] lt 20.) then begin 
                                                          cat_BMag[i] = !values.F_NAN  
                                                          cat_errB[i] = !values.F_NAN
  endif
  if not (10. lt cat_VMag[i] And cat_VMag[i] lt 19.) then begin 
                                                          cat_VMag[i] = !values.F_NAN  
                                                          cat_errV[i] = !values.F_NAN
  endif
  if not ( 8. lt cat_RMag[i] And cat_RMag[i] lt 18.) then begin
                                                          cat_RMag[i] = !values.F_NAN
                                                          cat_errR[i] = !values.F_NAN
  endif
endfor

good = where(finite(cat_BMag),count)  &  if count gt 0 then haveB = 1 else haveB = 0
good = where(finite(cat_VMag),count)  &  if count gt 0 then haveV = 1 else haveV = 0
good = where(finite(cat_RMag),count)  &  if count gt 0 then haveR = 1 else haveR = 0

cat_BmR  = cat_BMag - cat_RMag ; B-R color index
good = where(finite(cat_BmR),count)   &  if count gt 0 then haveBmR = 1 else haveBmR = 0
  
if not (haveB or haveV or haveR) then begin  ; bad catalog
  msgarr = strarr(2)
  msgarr(0) = 'Photometric zeropoint can not be determined'
  msgarr(1) = state.photcatalog_name + ' is missing b, v, and r mags'                                                                               
  return
endif
  
case imgBand of  ; determine if catalog supports the filter passband
'B': begin
        if haveB then begin
           cat_Mag = cat_BMag
           cat_err = cat_errB
           magzbnd = 'b'
        endif else begin
           msgarr = strarr(2)
           msgarr(0) = 'Photometric ' + imgBand + ' zeropoint can not be determined'
           msgarr(1) = state.photcatalog_name + ' is missing b'                                                                               
           return
        endelse
     end
'V': begin
        if haveV then begin
           cat_Mag = cat_VMag
           cat_err = cat_errV
           magzbnd = 'v'
        endif else begin
           msgarr = strarr(2)
           msgarr(0) = 'Photometric ' + imgBand + ' zeropoint can not be determined'
           msgarr(1) = state.photcatalog_name + ' is missing v'                                                                               
           return
        endelse
     end
'R': begin
        if haveR then begin
           cat_Mag = cat_RMag
           cat_err = cat_errR
           magzbnd = 'r'
        endif else begin
           msgarr = strarr(2)
           msgarr(0) = 'Photometric ' + imgBand + ' zeropoint can not be determined'
           msgarr(1) = state.photcatalog_name + ' is missing r'                                                                               
           return
        endelse
     end
'C': begin
        if haveR then begin
          cat_Mag = cat_RMag
          cat_err = cat_errR
          magzbnd = 'r'
        endif else begin
          if haveV then begin
            cat_Mag = cat_VMag
            cat_Err = cat_ErrV
            magzbnd = 'v'
          endif else begin
            msgarr = strarr(2)
            msgarr(0) = 'Photometric ' + imgBand + ' zeropoint can not be determined'
            msgarr(1) = state.photcatalog_name + ' is missing v,r magnitudes'                                                                               
            return
          endelse
        endelse
     end 
endcase

good = where( finite(cat_Mag) and finite(cat_Err) and finite(cat_BmR) )  ; reduce to surviving catalog entries
if n_elements(good) lt n_elements(cat_BmR) then begin
   index = indgen(n_elements(cat_BmR))
   remove, good, index ; index is now bad points
   if count gt 0 then begin
      remove, index, cat_RA, cat_dec, cat_Mag, cat_Err, cat_Bmr, cat_Bmag, cat_ErrB, cat_VMag, cat_ErrV, cat_RMag, cat_ErrR
   endif
endif

; 3) determine instrumental instMages
textstr = '-CATALOG_TYPE ASCII_HEAD -PARAMETERS_NAME zeropoint.param ' +   $
          '-PHOT_AUTOPARAMS '                                          +   $ 
           strcompress( string(state.sex_PHOT_AUTOPARAMS[0],'(F6.3)') + ',' + string(state.sex_PHOT_AUTOPARAMS[1],'(F6.3)'), /REMOVE_ALL)
                                                             
phast_do_sextractor, image=state.imagename, flags=textstr, cat_name='./output/catalogs/zeropoint.cat'
readcol, './output/catalogs/zeropoint.cat', im_ra, im_dec, Instr, errInstr, flags, comment='#', Format='D,D,D,D,I', /silent

; qualify SExtractor detections
Instr( where(   flags gt  0  ) ) = !values.F_NAN  ; avoid complicated/corrupted detections
Instr( where(   Instr ge 99.0) ) = !values.F_NAN  ; avoid sextractor missing value code (99.0)
Instr( where(errInstr ge 99.0) ) = !values.F_NAN  ; avoid sextractor missing value code (99.0)

signal = 10^(-0.4*Instr)  &  sigma = 10^(-0.4*errInstr)  &  SNR = signal/sigma
Instr( where(SNR lt 10.0) ) = !values.F_NAN       ; avoid low SNR detections

; scale to 1 sec (makes assumption that photon noise dominates read noise and other sources)
   Instr = -2.5*alog10(signal /      exposure )
errInstr = -2.5*alog10(sigma  / sqrt(exposure))

good = where( finite(Instr) and finite(errInstr) )  ; reduce to surviving detections
if n_elements(good) lt n_elements(Instr) then begin
   index = indgen(n_elements(Instr))
   remove, good, index ; index is now bad points
   if count gt 0 then begin
      remove, index, im_ra, im_dec, Instr, errInstr, flags
   endif
endif
  
; 4) match catalog to image
   Cat = make_array(1,n_elements(im_ra),/DOUBLE,VALUE=!VALUES.f_nan) ; will hold the R magnitude of matching star
errCat = make_array(1,n_elements(im_ra),/DOUBLE,VALUE=!VALUES.f_nan)
   BmR = make_array(1,n_elements(im_ra),/DOUBLE,VALUE=!VALUES.f_nan) ; will hold the B-R color index of matching star
errBmR = make_array(1,n_elements(im_ra),/DOUBLE,VALUE=!VALUES.f_nan)
    
  for i=0, n_elements(Instr)-1 do begin 
      match_dist = 1.0 ;(in deg)
      match_index = -1 ; will be set to catalog index j when a match is found
      for j=0, n_elements(cat_RA)-1 do begin
        dist = sqrt((cat_RA[j]-im_ra[i])^2 + (cat_Dec[j]-im_dec[i])^2)
        ; match must be within match_tol with valid instrumental Mag and catalog magnitudes
        if (dist lt match_dist) and (dist lt match_tol) and finite(Instr[i]) and finite(cat_BmR[j]) then begin 
          match_dist  = dist
          match_index = j
         endif
      endfor
      if match_index ne -1 then begin
            Cat[i] = cat_Mag[match_index]
         errCat[i] = cat_Err[match_index]
            BmR[i] = cat_BmR[match_index]
         errBmR[i] = sqrt( cat_ErrB[match_index]^2 + cat_ErrR[match_index]^2  )
      endif
  endfor
     Y = Cat - Instr ; dependent variable
  errY = sqrt( errCat^2 + errInstr^2 )
  
  ;reduce to matching and non-missing data
  good = where( finite(BmR) )
  if n_elements(good) lt n_elements(Cat) then begin
    index = indgen(n_elements(Cat))
    remove, good, index ; index is now bad points
    if count gt 0 then begin
      remove, index, im_ra, im_dec, flags, Y, errY, Instr, errInstr, Cat, errCat, BmR, errBmR
    endif
  endif
  
; 5) Solve in <= 5 passes with outlier rejection at sigmaClip level after each pass (except last)
openw, 1, './output/photoZeroPointF.csv'  ; dataset at start of solution
for i=0, n_elements(Instr)-1 do begin
  printf, 1, Cat[i], errCat[i], BmR[i], errBmR[i], Instr[i], errInstr[i], Y[i], errY[i], FORMAT='(8F8.3)'
endfor
close, 1
  
  ipass = 0
maxpass = 5
repeat begin
 ipass = ipass + 1

  B0 = regress( BmR, Y, MEASURE_ERRORS=errY, CONST=A0, SIGMA=errB0, /Double, $
                STATUS=retCode, YFIT=Yfit, CORRELATION=corrVec, CHISQ=chisq, FTEST=Ftest, MCORRELATION=corrR )
 
  if ipass lt maxpass then begin ; reject outliers
    sigmaY = stddev(Y-Yfit) ; approximation
    outliers = abs(Y-Yfit) gt sigmaClip*MAKE_ARRAY(1, n_elements(Y), /Double, VALUE = sigmaY)
    index = indgen(n_elements(outliers))
    index = index( where(outliers eq 1) )
    if total(outliers) > 0 then remove, index, Cat, errCat, BmR, errBmR, Instr, errInstr, Y, errY
  endif
  
endrep until (total(outliers) eq 0) or (ipass eq maxpass)

;covar=transpose(errCat)*errBmR
;xvcovar=fltarr(n_elements(Y))
;xvcovar=covar
;LINMIX_ERR, BmR, Y, POST, XSIG=errBmR, YSIG=errY, XYCOV=xycovar, /METRO

;B0 = robust_poly_fit(BmR, Y, 1, Yfit, sigmaY)
;if B0[0] eq 0 Then retCode = 0 else retCode = 1
  
openw, 1, './output/photoZeroPoint.csv'
for i=0, n_elements(Instr)-1 do begin
  printf, 1, Cat[i], errCat[i], BmR[i], errBmR[i], Instr[i], errInstr[i], Y[i], errY[i], FORMAT='(8F8.3)'
endfor
close, 1
  
if retCode eq 0 then begin
  
  magzero = float(A0[0])
  magzclr = float(B0[0]) 
  magzerr = float(sigmaY[0])
  magznum = 999 < n_elements(Y)  
   
  ; update FITS header              
  sxaddpar,head,'MAGZERO',magzero       
  sxaddpar,head,'MAGZCLR',magzclr
  sxaddpar,head,'MAGZBND',magzbnd
  sxaddpar,head,'MAGZERR',magzerr 
  sxaddpar,head,'MAGZNUM',magznum
  fits_write, state.imagename, image,head
  phast_refresh_image, state.current_image_index, state.imagename
  
  ; construct return message text
  msgarr = strarr(5)
  msgarr(0) = 'Zero-point = ' + string(magzero,'(F6.3)') + ' ' + string(177b) + ' ' + string(magzerr,'(F5.3)') + ' ' + magzbnd
  msgarr(1) = '           + ' + string(magzclr,'(F6.3)') + ' * (b-r)' + '   (N=' + string(magznum,'(I3)') + ')'
  msgarr(2) = ''
  msgarr(3) = 'Zeropoint determination was successful'                                                                           
  if retCode eq 0 then msgarr(4) = '' $
                  else msgarr(4) = '' ;'warning: matrix near-singular'
  endif else begin
    msgarr = strarr(2)
    msgarr(0) = 'Zeropoint determination failed'
    msgarr(1) = 'Check ./output/photoZeroPoint.txt for data'
  endelse

end

;----------------------------------------------------------------------
pro phast_zeropoint_event,event

;event handler for phast_zeropoint

common phast_state

widget_control, event.id, get_uvalue = uvalue

case uvalue of
    'image_select': begin
        state.zeropoint_image_name = dialog_pickfile(filter='*.fits',/must_exist,$
                                                    path=state.sex_catalog_path)
        widget_control,state.zeropoint_image_widget_id,set_value=state.zeropoint_image_name
    end
    'start_zeropoint':begin
        phast_calculate_zeropoint, magzero, magzerr, magzclr, magzbnd, msgarr
        result = dialog_message(msgarr,/center,/information)
    end
    'done':widget_control,event.top,/destroy
endcase

end
;----------------------------------------------------------------------
pro phast_zeropoint

;front end for photometric zeropoint calculation

common phast_state

if (not (xregistered('phast_missfits', /noshow))) then begin

    zero_base = $
      widget_base(/base_align_left, $
                  group_leader = state.base_id, $
                  /column, $
                  title = 'Photometric Zero-point', $
                  uvalue = 'apphot_base',xsize=450)
    desc_label = widget_label(zero_base,value='Calculate a photometric zero-point')
;     temp_base = widget_base(zero_base,/row)
;     cat_select = widget_button(temp_base,value='Choose image',uvalue='image_select')
;     image_name = widget_label(temp_base,value='No image loaded',/dynamic_resize)
    ;temp2_base = widget_base(missfits_base,/row)
    ;flags_label = widget_label(temp2_base,value='Flags:')
    ;state.missfits_flags_widget_id = widget_text(temp2_base,value=state.missfits_flags,uvalue='flags',xsize=50,/editable,/all_events)
    buttonbox = widget_base(zero_base,/row)
    start_scamp = widget_button(buttonbox,value='Start', uvalue='start_zeropoint')
    done = widget_button(buttonbox,value='Done',uvalue='done')
    
   ; state.zeropoint_image_widget_id = image_name
    widget_control, zero_base, /realize

    xmanager, 'phast_zeropoint', zero_base, /no_block
    
    phast_resetwindow
endif


end
;----------------------------------------------------------------------
pro phast_do_missfits,image = image, flags = flags

;routine to use missFITS to write a SCAMP header to the main FITS file

common phast_state

if not keyword_set(flags) then flags = ''
if not keyword_set(image) then image = state.imagename

widget_control,/hourglass
spawn,'missfits ' + image + ' ' + flags

end
;----------------------------------------------------------------------
pro phast_do_batch

;routine to batch process images.  Loads images from a give directory
;and passes them sequentially through the pipeline of processing tools

common phast_state
common phast_images

widget_control,/hourglass

case state.batch_source of
    0: begin
        num_files = state.num_images
        filelist = strarr(num_files)
        for i=0, num_files-1 do filelist[i] = image_archive[i]->get_name()
    end
    1: filelist = findfile(state.batch_dirpath+'*.fits',count=num_files)
endcase

for i=0,num_files-1 do begin
    fits_read,filelist[i],cal_science,cal_science_head
    split = strsplit(filelist[i],'/\.',count=count,/extract)
    state.cal_file_name = './output/images/'+split[count-2]+'.'+split[count-1]
    phast_calibrate
    phast_do_sextractor,image = state.cal_file_name,cat_name='./output/images/'+split[count-2]+'.cat'
    phast_do_scamp,cat_name='./output/images/'+split[count-2]+'.cat'
    phast_do_missfits, image = state.cal_file_name, flags = state.missfits_flags+' -SAVE_TYPE REPLACE'
endfor
result = dialog_message('Batch processing complete!',/information,/center)

end
;----------------------------------------------------------------------
pro phast_batch_event,event

;event handler for batch processing dialog window

common phast_state
common phast_images

widget_control, event.id, get_uvalue = uvalue

case uvalue of

    ;image base
    'dark_toggle': begin
        if state.dark_toggle eq 0 then begin
            widget_control,state.dark_select_id,/sensitive
            state.dark_toggle = 1
        endif else begin
            widget_control,state.dark_select_id,sensitive=0
            state.dark_toggle = 0
        endelse
    end
    'flat_toggle': begin
        if state.flat_toggle eq 0 then begin
            widget_control,state.flat_select_id,/sensitive
            state.flat_toggle = 1
        endif else begin
            widget_control,state.flat_select_id,sensitive=0
            state.flat_toggle = 0
        endelse
    end
    'bias_toggle': begin
        if state.bias_toggle eq 0 then begin
            widget_control,state.bias_select_id,/sensitive
            state.bias_toggle = 1
        endif else begin
            widget_control,state.bias_select_id,sensitive=0
            state.bias_toggle = 0
        endelse
    end
    'dark_select': begin
        state.dark_filename = dialog_pickfile(/must_exist,/read,filter='*.fits')
        if state.dark_filename ne '' then begin
            widget_control,state.dark_label_id,set_value=state.dark_filename
            fits_read,state.dark_filename,cal_dark,cal_dark_head
        endif
    end
    'flat_select': begin
        state.flat_filename = dialog_pickfile(/must_exist,/read,filter='*.fits')
        if state.flat_filename ne '' then begin
            widget_control,state.flat_label_id,set_value=state.flat_filename
            fits_read,state.flat_filename,cal_flat,cal_flat_head
        endif
    end
    'bias_select': begin
        state.bias_filename = dialog_pickfile(/must_exist,/read,filter='*.fits')
        if state.bias_filename ne '' then begin
            widget_control,state.bias_label_id,set_value=state.bias_filename
            fits_read,state.bias_filename,cal_bias,cal_bias_head
        endif
    end
    'select_dir': begin
        state.batch_dirname = dialog_pickfile(/dir)
        if state.batch_dirname ne '' then widget_control,state.batch_dir_id,set_value=state.batch_dirname
    end
    'current_toggle': begin
        widget_control,state.batch_select_dir,sensitive=0
        state.batch_source = 0
        state.batch_dirname = ''
        widget_control,state.batch_dir_id,set_value=' No Directory Selected'
    end   
    'dir_toggle': begin
        widget_control,state.batch_select_dir,sensitive=1
        state.batch_source = 1
    end    
    'over_correct': begin
        if state.over_toggle eq 0 then begin
            state.over_toggle = 1
        endif else begin
            state.over_toggle = 0
        endelse
    end

    ;SExtractor base
   'sex_flags': begin
       widget_control,state.sex_flags_widget_id,get_value=value
       state.sex_flags = value
   end
   
   ;SCAMP base
   'scamp_flags': begin
       widget_control,state.scamp_flags_widget_id,get_value=value
       state.scamp_flags = value
   end      

   ;missFITS base
    'missfits_flags': begin
        widget_control,state.missfits_flags_widget_id,get_value=value
        state.missfits_flags = value
    end       

   ;other
   'start': begin
       while 1 eq 1 do begin
           if state.batch_source eq -1 then begin
               result = dialog_message('Science images must be loaded!',/center)
               break
           endif
           if state.batch_source eq 1 and state.batch_dirname eq '' then begin
               result = dialog_message('Image directory must be selected!',/center)
               break
           endif
           if state.batch_source eq 0 and state.num_images eq 0 then begin
               result = dialog_message('No images are loaded!',/center)  
               break
           endif
           phast_do_batch
           break
       endwhile
   end
   'done': widget_control,event.top,/destroy
    
   else: print,'uvalue not found'

endcase

end
;----------------------------------------------------------------------
pro phast_batch

;batch processing dialogue window

common phast_state

state.batch_source = -1

if (not (xregistered('phast_batch', /noshow))) then begin



    batch_base = $
      widget_base(/base_align_left, $
                  group_leader = state.base_id, $
                  /column, $
                  title = 'Batch image processing', $
                  uvalue = 'apphot_base')
    
    image_label = widget_label(batch_base,value='Select images')
    image_base  = widget_base(batch_base,frame=4,/column,xsize=500)
    cal_label = widget_label(batch_base,value='Calibration settings')
    calibrate_base = widget_base(batch_base,frame=4,/column,xsize=500)
    sex_label = widget_label(batch_base,value='SExtractor settings')
    sextractor_base = widget_base(batch_base,frame=4,/row,xsize=500)
    scamp_label = widget_label(batch_base,value='SCAMP settings')
    scamp_base = widget_base(batch_base,frame=4,/row,xsize=500)
    missfits_label = widget_label(batch_base,value='missFITS settings')
    missfits_base = widget_base(batch_base,frame=4,/row,xsize=500)

    ;image base

    image_toggles = widget_base(image_base,/row,/exclusive)
    current_toggle = widget_button(image_toggles,value='Current images',uvalue='current_toggle')
        dir_toggle = widget_button(image_toggles,value='Directory',uvalue='dir_toggle')
    dirname_base = widget_base(image_base,/row)
    state.batch_select_dir = widget_button(dirname_base,value='Select directory',uvalue='select_dir',sensitive=0)
    state.batch_dir_id = widget_label(dirname_base,value=' No directory loaded',/dynamic_resize)
   
    ;calibrate base
    cal_select_box = widget_base(calibrate_base,/row)
    overscan_base = widget_base(calibrate_base,/nonexclusive,/column)
    over_correct = widget_button(overscan_base,value='Overscan correction',uvalue='over_correct')
    button_box1 = widget_base(cal_select_box,/nonexclusive,/column)
    bias_toggle = widget_button(button_box1,value='Bias',uvalue='bias_toggle')
    dark_toggle = widget_button(button_box1,value='Dark',uvalue='dark_toggle')
    flat_toggle = widget_button(button_box1,value='Flat',uvalue='flat_toggle')
    button_box2 = widget_base(cal_select_box,/column)
    state.bias_select_id = widget_button(button_box2,value='Select a bias',uvalue='bias_select',sensitive=0)
    state.dark_select_id = widget_button(button_box2,value='Select a dark',uvalue='dark_select',sensitive=0)
    state.flat_select_id = widget_button(button_box2,value='Select a flat',uvalue='flat_select',sensitive=0)
    label_box1 = widget_base(cal_select_box,/column)
    spacer_1 = widget_label(label_box1,value='')
    state.bias_label_id = widget_label(label_box1,value=state.bias_filename, /align_left, /dynamic_resize)    
    spacer_2  = widget_label(label_box1,value='')
    state.dark_label_id = widget_label(label_box1,value=state.dark_filename, /align_left, /dynamic_resize)
    spacer_3 = widget_label(label_box1,value='')
    state.flat_label_id = widget_label(label_box1,value=state.flat_filename, /align_left, /dynamic_resize)
    
    ;SExtractor base
    sex_flags_label = widget_label(sextractor_base,value='Flags:')
    state.sex_flags_widget_id = widget_text(sextractor_base,value=state.sex_flags,uvalue='sex_flags',xsize=50,/all_events,/editable)

    ;SCAMP base
    scamp_flags_label = widget_label(scamp_base,value='Flags:')
    state.scamp_flags_widget_id = widget_text(scamp_base,value=state.scamp_flags,uvalue='scamp_flags',xsize=50,/all_events,/editable)

    ;missFITS base
    missfits_flags_label = widget_label(missfits_base,value='Flags:')
    state.missfits_flags_widget_id = widget_text(missfits_base,value=state.missfits_flags,uvalue='missfits_flags',xsize=50,/all_events,/editable)

    tmp_base = widget_base(batch_base,/row)
    start = widget_button(tmp_base,value='Start',uvalue='start')
    done = widget_button(tmp_base,value='Done',uvalue='done')

    widget_control, batch_base, /realize

    xmanager, 'phast_batch', batch_base, /no_block

    ;set intial button states
    widget_control, current_toggle, set_button=1  &  state.batch_source = 0
    if state.bias_toggle eq 1 then begin
        widget_control,bias_toggle,set_button=1
        widget_control,state.bias_select_id,sensitive=1
    end
    if state.dark_toggle eq 1 then begin
        widget_control,dark_toggle,set_button=1
        widget_control,state.dark_select_id,sensitive=1
    end
    if state.flat_toggle eq 1 then begin
        widget_control,flat_toggle,set_button=1
        widget_control,state.flat_select_id,sensitive=1
    end
    if state.over_toggle eq 1 then widget_control,over_correct,set_button=1

    phast_resetwindow
endif


end
;----------------------------------------------------------------------
pro phast_calibrate

;routine to calibrate an image based on any or all of dark/flat/bias
;and trim any image overscan

common phast_state
common phast_images

;copy images so that originals are not modified
main = float(cal_science)
bias = float(cal_bias)
flat = float(cal_flat)
dark = float(cal_dark)
;print,bias[50:60,50:60]

;correct overscan
 error = 0
 catch,error
 if error ne 0 then result = dialog_message('Error encountered.  No overscan region present?',/error,/center)
if state.over_toggle ne 0 and error eq 0 then begin

    ;determine overscan region
    overscan = sxpar(cal_science_head,'BIASSEC')
    split = strsplit(overscan,'[,:]',/extract)
    region = fix(split)-1
    region[0] = region[0]-1 
    ;remove overscan from each image
    for i=0,region[0] do begin
        med_main = median(main[region[0]+1:region[1],i])
        main[*,i] = main[*,i]-med_main
       if state.dark_toggle ne 0 then begin
           med_dark = median(dark[region[0]+1:region[1],i])
           dark[*,i] = dark[*,i]-med_dark
       endif
        if state.flat_toggle ne 0 then begin
            med_flat = median(flat[region[0]+1:region[1],i])
            flat[*,i] = flat[*,i]-med_flat
        endif
        if state.bias_toggle ne 0 then begin
            med_bias = median(bias[region[0]+1:region[1],i])
            bias[*,i] = bias[*,i]-med_bias
        endif
    endfor
  ;  print,bias[50:60,50:60]
    ;trim overscan region from each image
    main = main(0 : region[0],region[2] : region[3])
    if state.dark_toggle ne 0 then dark = dark(0 : region[0],region[2] : region[3])
    if state.flat_toggle ne 0 then flat = flat(0 : region[0],region[2] : region[3])
    if state.bias_toggle ne 0 then bias = bias(0 : region[0],region[2] : region[3])
    ; fits_write, 'bias-overscan.fits',bias,cal_bias_head

endif
;subtract bias
if state.bias_toggle ne 0 then begin
    main = main-bias
endif

;subtract dark
if state.dark_toggle ne 0 then begin
    ;subtract bias
    dark = dark-bias
    ;normalize dark to science image exposure length
    dark_exp = sxpar(cal_dark_head,'EXPTIME')
    sci_exp = sxpar(cal_science_head,'EXPTIME')
    scale_factor = sci_exp/dark_exp
    dark = scale_factor*dark
    ;subtract dark from science image
    main = main-dark
endif

;divide by flat
if state.flat_toggle ne 0 then begin
    ;subtract bias from flat
    flat = flat - bias
    ;scale dark to match flat exposure time
    if state.dark_toggle ne 0 then begin
        dark = cal_dark
        flat_exp = sxpar(cal_flat_head,'EXPTIME')
        scale_factor = flat_exp/dark_exp
        dark = scale_factor*dark
        flat = flat - dark
    endif
        
    ;find median value in middle 50% of image
    size = size(flat)
    h_seg = .25*size[1]
    v_seg = .25*size[2]
    med=median(flat[h_seg : 3*h_seg,v_seg : 3*v_seg])

    ;create flat map
    map = flat/med
    ;divide by map
    main = main/map
endif


size = size(main) ;get image size
ra = sxpar(cal_science_head,'RA') ;get approx ra
dec = sxpar(cal_science_head,'DEC') ;get approx dec
;convert to degrees
ra = 15*ten(ra)
dec = ten(dec)
;get current EQUINOX
equinox = sxpar(cal_science_head,'EQUINOX')
;precess,ra,dec,equinox,2000 ; precess to J2000   rwc patch for 2.1m

;write header values required for plate solution
sxaddpar,cal_science_head,'CTYPE1','RA---TAN'
sxaddpar,cal_science_head,'CTYPE2','DEC--TAN'
sxaddpar,cal_science_head,'CUNIT1','deg'
sxaddpar,cal_science_head,'CUNIT2','deg'
sxaddpar,cal_science_head,'CRPIX1',size[1]/2,format='E11.5'
sxaddpar,cal_science_head,'CRPIX2',size[2]/2,format='E11.5'
sxaddpar,cal_science_head,'CRVAL1',ra,format='E12.5'
sxaddpar,cal_science_head,'CRVAl2',dec,format='E12.5'
sxaddpar,cal_science_head,'CDELT1',state.fits_cdelt1,format='E14.7'
sxaddpar,cal_science_head,'CDELT2',state.fits_cdelt2,format='E14.7'
sxaddpar,cal_science_head,'CROTA1',state.fits_crota1,format='E11.5'
sxaddpar,cal_science_head,'CROTA2',state.fits_crota2,format='E11.5'
sxaddpar,cal_science_head,'EQUINOX',2000.0
sxaddpar,cal_science_head,'EPOCH',2000.0
sxdelpar,cal_science_head,'' ;trim whitespace entries
sxaddpar,cal_science_header, 'END',''

fits_write,state.cal_file_name,main,cal_science_head

end
;----------------------------------------------------------------------
pro phast_calibrate_image_event,event

;event handler for image calibration front end

common phast_state
common phast_images

widget_control, event.id, get_uvalue = uvalue

case uvalue of
    'sci_select': begin
        filename = dialog_pickfile(/must_exist,/read,filter='*.fits')
        if filename ne '' then begin
            widget_control,state.sci_label_id,set_value=filename
            fits_read,filename,cal_science,cal_science_head
        endif
    end
    'dark_toggle': begin
        if state.dark_toggle eq 0 then begin
            widget_control,state.dark_select_id,/sensitive
            state.dark_toggle = 1
        endif else begin
            widget_control,state.dark_select_id,sensitive=0
            state.dark_toggle = 0
        endelse
    end
    'flat_toggle': begin
        if state.flat_toggle eq 0 then begin
            widget_control,state.flat_select_id,/sensitive
            state.flat_toggle = 1
        endif else begin
            widget_control,state.flat_select_id,sensitive=0
            state.flat_toggle = 0
        endelse
    end
    'bias_toggle': begin
        if state.bias_toggle eq 0 then begin
            widget_control,state.bias_select_id,/sensitive
            state.bias_toggle = 1
        endif else begin
            widget_control,state.bias_select_id,sensitive=0
            state.bias_toggle = 0
        endelse
    end
    'dark_select': begin
        state.dark_filename = dialog_pickfile(/must_exist,/read,filter='*.fits')
        if state.dark_filename ne '' then begin
            widget_control,state.dark_label_id,set_value=state.dark_filename
            fits_read,state.dark_filename,cal_dark,cal_dark_head
        endif
    end
    'flat_select': begin
        state.flat_filename = dialog_pickfile(/must_exist,/read,filter='*.fits')
        if state.flat_filename ne '' then begin
            widget_control,state.flat_label_id,set_value=state.flat_filename
            fits_read,state.flat_filename,cal_flat,cal_flat_head
        endif
    end
    'bias_select': begin
        state.bias_filename = dialog_pickfile(/must_exist,/read,filter='*.fits')
        if state.bias_filename ne '' then begin
            widget_control,state.bias_label_id,set_value=state.bias_filename
            fits_read,state.bias_filename,cal_bias,cal_bias_head
        endif
    end
    
    'over_correct': begin
        if state.over_toggle eq 0 then begin
            state.over_toggle = 1
        endif else begin
            state.over_toggle = 0
        endelse
    end
    'filename_text': begin
        widget_control,state.cal_name_box_id,get_value=string
        state.cal_file_name = string
    end
    'calibrate': begin
        if n_elements(cal_science) gt 1 then begin
            phast_calibrate
            result = dialog_message('Calibration complete!',/center,/information)
        endif else begin ;warn if no science image is loaded
            result = dialog_message('Science image must be loaded!',/center)
        endelse
    end
    'done': widget_control,event.top,/destroy
    
    else: print,'uvalue not recognized'
endcase


end
;----------------------------------------------------------------------
pro phast_calibrate_image

;image calibration dialog window

common phast_state

if (not (xregistered('phast_calibrate', /noshow))) then begin

    cal_base = $
      widget_base(/base_align_left, $
                  group_leader = state.base_id, $
                  /column, $
                  title = 'Calibrate an image', $
                  uvalue = 'apphot_base')
    desc_label = widget_label(cal_base,value='Calibrate an image with a dark, flat, or bias frame.')
    main_box = widget_base(cal_base,/row)
    left_box = widget_base(main_box,/column,frame=4)
    science_select_label = widget_label(left_box,value='Select an image to be calibrated:')
    sci_select_box = widget_base(left_box, /row)
    sci_select = widget_button(sci_select_box,value='Select a science image',uvalue='sci_select')
    state.sci_label_id = widget_label(sci_select_box,value='No science image loaded',/dynamic_resize)
    cal_select_label = widget_label(left_box,value='Select calibration images:')
    cal_select_box = widget_base(left_box,/row)
    button_box1 = widget_base(cal_select_box,/nonexclusive,/column)
    dark_toggle = widget_button(button_box1,value='Dark',uvalue='dark_toggle')
    flat_toggle = widget_button(button_box1,value='Flat',uvalue='flat_toggle')
    bias_toggle = widget_button(button_box1,value='Bias',uvalue='bias_toggle')
    button_box2 = widget_base(cal_select_box,/column)
    state.dark_select_id = widget_button(button_box2,value='Select a dark',uvalue='dark_select',sensitive=0)
    state.flat_select_id = widget_button(button_box2,value='Select a flat',uvalue='flat_select',sensitive=0)
    state.bias_select_id = widget_button(button_box2,value='Select a bias',uvalue='bias_select',sensitive=0)
    label_box1 = widget_base(cal_select_box,/column)
    spacer_1  = widget_label(label_box1,value='')
    state.dark_label_id = widget_label(label_box1,value=state.dark_filename,/dynamic_resize)
    spacer_2 = widget_label(label_box1,value='')
    state.flat_label_id = widget_label(label_box1,value=state.flat_filename,/dynamic_resize)
    spacer_3 = widget_label(label_box1,value='')
    state.bias_label_id = widget_label(label_box1,value=state.bias_filename,/dynamic_resize)
    
    ;right_box = widget_base(main_box,/column,frame=4)
    ;parem_label = widget_label(right_box,value='Parameters')


    overscan_base = widget_base(left_box,/nonexclusive,/row)
    over_correct = widget_button(overscan_base,value='Correct overscan',uvalue='over_correct')
    filename_box = widget_base(left_box,/row)
    filename_label = widget_label(filename_box,value='Output filename:')
    state.cal_name_box_id = widget_text(filename_box,value=state.cal_file_name,uvalue='filename_text',/all_events,xsize=30,/editable)
    
    buttonbox = widget_base(cal_base,/row)
    calibrate = widget_button(buttonbox,value='Start',uvalue='calibrate')
    done = widget_button(buttonbox,value='Done',uvalue='done')

    widget_control, cal_base, /realize

    xmanager, 'phast_calibrate_image', cal_base, /no_block

    ;set intial button states
    if state.dark_toggle eq 1 then begin
        widget_control,dark_toggle,set_button=1
        widget_control,state.dark_select_id,sensitive=1
    end
    if state.flat_toggle eq 1 then begin
        widget_control,flat_toggle,set_button=1
        widget_control,state.flat_select_id,sensitive=1
    end
    if state.bias_toggle eq 1 then begin
        widget_control,bias_toggle,set_button=1
        widget_control,state.bias_select_id,sensitive=1
    end
    if state.over_toggle eq 1 then widget_control,over_correct,set_button=1

    phast_resetwindow
endif


end
;----------------------------------------------------------------------
pro phast_do_scamp, cat_name = cat_name, flags = flags

common phast_state

if not keyword_set(cat_name) then cat_name = state.scamp_catalog_name
if not keyword_set(flags) then flags = ''

widget_control,/hourglass
spawn, 'scamp ' + cat_name + flags


end
;----------------------------------------------------------------------
pro phast_scamp_event, event

common phast_state

widget_control, event.id, get_uvalue = uvalue


case uvalue of
    'start_scamp': begin
        phast_do_scamp
        widget_control, event.top, /destroy
   end
   'cat_select': begin
       ;print,state.sex_catalog_path
       state.scamp_catalog_name = dialog_pickfile(filter='*.cat',/must_exist,$
                                                 path=state.sex_catalog_path)
       widget_control,state.scamp_cat_widget_id, set_value =  state.scamp_catalog_name

   end
   'flags': begin
       widget_control,state.scamp_flags_widget_id,get_value=value
       state.scamp_flags = value
   end
   'done':widget_control,event.top,/destroy
    
endcase

end

;----------------------------------------------------------------------
pro phast_scamp

;routine to run SCAMP on a given catalog

common phast_state

if (not (xregistered('phast_scamp', /noshow))) then begin

    scamp_base = $
      widget_base(/base_align_left, $
                  group_leader = state.base_id, $
                  /column, $
                  title = 'SCAMP interface', $
                  uvalue = 'apphot_base',xsize = 500)
    desc_label = widget_label(scamp_base,value='Analyze a catalog generated by SExtractor')
    desc_label2 = widget_label(scamp_base, value= 'The file scamp.conf must be in the local directory.')
    temp_base = widget_base(scamp_base,/row)
    cat_select = widget_button(temp_base,value='Choose catalog',uvalue='cat_select')
    cat_name = widget_label(temp_base,value='No catalog loaded',/dynamic_resize)
    temp2_base = widget_base(scamp_base,/row)
    flags_label = widget_label(temp2_base,value='Flags:')
    state.scamp_flags_widget_id = widget_text(temp2_base,value=state.scamp_flags,uvalue='flags',xsize=50,/editable,/all_events)
    buttonbox = widget_base(scamp_base,/row)
    start_scamp = widget_button(buttonbox,value='Start', uvalue='start_scamp')
    done = widget_button(buttonbox,value='Done',uvalue='done')
    
    state.scamp_cat_widget_id = cat_name
    widget_control, scamp_base, /realize

    xmanager, 'phast_scamp', scamp_base, /no_block
    
    phast_resetwindow
endif


end
;----------------------------------------------------------------------
pro phast_missfits_event,event

common phast_state

widget_control, event.id, get_uvalue = uvalue

case uvalue of
    'image_select': begin
        state.missfits_image_name = dialog_pickfile(filter='*.fits',/must_exist,$
                                                 path=state.sex_catalog_path)
        widget_control,state.missfits_image_widget_id,set_value=state.missfits_image_name
    end
    'flags': begin
        widget_control,state.missfits_flags_widget_id,get_value=value
        state.missfits_flags = value
    end
    'start_missfits':phast_do_missfits,image=state.missfits_image_name,flags=state.missfits_flags
    'done':widget_control,event.top,/destroy
    

endcase
end
;----------------------------------------------------------------------
pro phast_missfits

;routine to run missFITS to combine a header with a FITS image

common phast_state

if (not (xregistered('phast_missfits', /noshow))) then begin

    missfits_base = $
      widget_base(/base_align_left, $
                  group_leader = state.base_id, $
                  /column, $
                  title = 'missFITS interface', $
                  uvalue = 'apphot_base',xsize = 500)
    desc_label = widget_label(missfits_base,value='Combine a header with a FITS image,')
    temp_base = widget_base(missfits_base,/row)
    cat_select = widget_button(temp_base,value='Choose image',uvalue='image_select')
    image_name = widget_label(temp_base,value='No image loaded',/dynamic_resize)
    temp2_base = widget_base(missfits_base,/row)
    flags_label = widget_label(temp2_base,value='Flags:')
    state.missfits_flags_widget_id = widget_text(temp2_base,value=state.missfits_flags,uvalue='flags',xsize=50,/editable,/all_events)
    buttonbox = widget_base(missfits_base,/row)
    start_scamp = widget_button(buttonbox,value='Start', uvalue='start_missfits')
    done = widget_button(buttonbox,value='Done',uvalue='done')
    
    state.missfits_image_widget_id = image_name
    widget_control, missfits_base, /realize

    xmanager, 'phast_missfits', missfits_base, /no_block
    
    phast_resetwindow
endif


end


;----------------------------------------------------------------------
pro phast_do_sextractor,image = image, flags = flags, cat_name = cat_name

common phast_state
common phast_images

if not keyword_set(image) then image = state.imagename
if not keyword_set(flags) then flags = state.sex_flags
if not keyword_set(cat_name) then cat_name = state.sex_catalog_name

widget_control,/hourglass
textstr = 'sex ' + image + ' ' + flags +  ' -CATALOG_NAME ' + cat_name
spawn, 'sex ' + image + ' ' + flags +  ' -CATALOG_NAME ' + cat_name

end
;----------------------------------------------------------------------

pro phast_sextractor_event, event

common phast_state
common phast_images

widget_control, event.id, get_uvalue = uvalue


case uvalue of
    'start_sex': begin
        phast_do_sextractor
        widget_control, event.top, /destroy
   end
   'cat_name': begin
       widget_control,state.sex_cat_widget_id, get_value =  value
       state.sex_catalog_name = value
   end
   'flags': begin
       widget_control,state.sex_flags_widget_id,get_value=value
       state.sex_flags = value
   end
   'done': widget_control,event.top,/destroy
    
endcase

end

;----------------------------------------------------

pro phast_sextractor

common phast_state

state.cursorpos = state.coord

if (not (xregistered('phast_sextractor', /noshow))) then begin

    sex_base = $
      widget_base(/base_align_left, $
                  group_leader = state.base_id, $
                  /column, $
                  title = 'SExtractor interface', $
                  uvalue = 'apphot_base',xsize = 500)
    desc_label = widget_label(sex_base,value='Pass the current image to SExtractor for analysis and catalog creation.')
    desc_label2 = widget_label(sex_base, value= 'The files default.sex, default.conv, and default.param must be in the local dir.')
    temp_base = widget_base(sex_base,/row)
    file_label = widget_label(temp_base, value='Filename:')
    file_name = widget_label(temp_base,value=state.imagename)
    temp2_base = widget_base(sex_base,/row)
    cat_label = widget_label(temp2_base,value='Catalog name:')
    cat_name = widget_text(temp2_base,value=state.sex_catalog_path+'test.cat',uvalue='cat_name',/editable,/all_events)
    temp3_base = widget_base(sex_base,/row)
    flags_label = widget_label(temp3_base,value='Flags:')
    flags = widget_text(temp3_base,value=state.sex_flags,uvalue='flags',xsize=50,/editable,/all_events)

    buttonbox = widget_base(sex_base,/row)
    start_sextractor = widget_button(buttonbox,value='Start', uvalue='start_sex')
    done = widget_button(buttonbox,value='Done',uvalue='done')
    
    state.sex_cat_widget_id = cat_name
    state.sex_flags_widget_id = flags
    widget_control, sex_base, /realize

    xmanager, 'phast_sextractor', sex_base, /no_block
    
    phast_resetwindow
endif

end
;------------------------------------------------------
pro phast_write_mpeg_event, event

common phast_images
common phast_state
common phast_objects

widget_control, event.id, get_uvalue = uvalue
case uvalue of
    'add_frame': result = mpeg_id->SetData(display_image)
    'done': begin
        widget_control,/hourglass
        result = mpeg_id->Commit(10000)
        widget_control, event.top, /destroy
    end
    else: print,'uvalue not found'
 endcase

end
;------------------------------------------------------
pro phast_write_mpeg

;routine to create a movie from stored images

common phast_images
common phast_state
common phast_objects

size=size(display_image)

mpeg_id = obj_new('IDLffMJPEG2000','phast.mj2',/write)


mpeg_base = $
  widget_base(/base_align_left, $
              group_leader = state.base_id, $
              /column, $
              title = 'Create a movie', $
              uvalue = 'mpeg_base',xsize = 500)
desc_label = widget_label(mpeg_base,value="Create a custom movie based on the PHAST display.")
add_frame = widget_button(mpeg_base,value='Add frame',uvalue='add_frame')
done = widget_button(mpeg_base,value='Done',uvalue='done')


widget_control,mpeg_base,/realize
xmanager, 'phast_write_mpeg',mpeg_base,/no_block


end

; return 3 color indices from spectral type, sub type
function phast_intrinsic_colors, specTypeNum, specSubNum

common phast_state

; Instrinsic colors from www-int.stsci.edu/~inr/instrins.html
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
            [-0.10,  0.04,  0.21,  0.31,  0.68,  1.52], $
            [-0.10,  0.05,  0.22,  0.32,  0.65,  1.52], $
            [-0.09,  0.06,  0.23,  0.34,  0.62,  1.52], $
            [-0.08,  0.09,  0.24,  0.35,  0.63,  1.52], $
            [-0.07,  0.10,  0.26,  0.39,  0.65,  1.52] ]
            
 col = ( 0 > specTypeNum ) < (n_elements(state.photSpecList)-1)
 row = ( 0 > specSubNum  ) < 9
 
 BmV = BmVtbl(col,row)
 VmR = VmRtbl(col,row)
 BmR = BmV + VmR
 
 retValues = [BmV, VmR, BmR]
 return, retValues
 
end

;------------------------------------------------------
pro phast_apphot

; aperture photometry front end

common phast_state

offset = [0,0]
if state.align_toggle eq 1 then offset = phast_get_image_offset()

state.cursorpos = state.coord - offset

;update the exposure length and zero-point from image header
if state.num_images gt 0 and state.image_type eq 'FITS' then begin
    head = headfits(state.imagename)
    state.exptime = sxpar(head,'EXPTIME')
    state.photzpt = sxpar(head,'MAGZERO')
    state.photclr = sxpar(head,'MAGZCLR')
    state.photband= sxpar(head,'MAGZBND')
    state.photzerr= sxpar(head,'MAGZERR')
    state.photznum= sxpar(head,'MAGZNUM')
endif

if (not (xregistered('phast_apphot', /noshow))) then begin

    apphot_base = $
      widget_base(/base_align_center, $
                  group_leader = state.base_id, $
                  /column,xoffset=state.draw_window_size[0]+300, $
                  title = 'phast aperture photometry', $
                  uvalue = 'apphot_base')
    
    ;apphot_top_base = widget_base(apphot_base, /column, /base_align_center)

    apphot_row_1     = widget_base(apphot_base,/row,/base_align_center)
    apphot_insert    = widget_base(apphot_base,/row,/base_align_center)
    apphot_row_2     = widget_base(apphot_base,/row,/base_align_center)
    apphot_draw_base = widget_base(apphot_base,/row,/base_align_center, frame=0)

    apphot_data_base1a = widget_base(apphot_row_1, /column, frame=4,xsize=240,ysize=200, /base_align_left)

    apphot_plot_base   = widget_base(apphot_row_1, /column, frame=4,xsize=240,ysize=200, /base_align_center)

    apphot_data_insert = widget_base(apphot_insert,/row,    frame=4,xsize=492,ysize= 50, /base_align_center)

    apphot_data_base1  = widget_base(apphot_row_2, /column, frame=4,xsize=240,ysize=130, /base_align_center)

    apphot_data_base2  = widget_base(apphot_row_2, /column, frame=4,xsize=240,ysize=130 ,/base_align_center)


   
    photSpecTypeNum = where( state.photSpecList eq state.photSpecType, count )
    if count eq 0 then begin
                       state.photSpecType = 'K'
                       photSpecTypeNum = where( state.photSpecList eq state.photSpecType, count )
    endif
    state.photSpecTypeNum = (0 > photSpecTypeNum[0]) < 9 
    state.photSpec_Type_ID = cw_bgroup(apphot_data_insert, state.photSpecList, uvalue = 'spectralLtr',  $
                                 button_uvalue = state.photSpecList,                              $
                                 /exclusive, set_value = state.photSpecTypeNum,                   $
                                 /no_release,                                                     $
                                 /row)

    state.photSpecSubNum = (0 > state.photSpecSubNum) < 9
    state.photSpec_Num_ID  = cw_field(apphot_data_insert, /long, /return_events, uvalue = 'spectralNum', $
                                value = state.photSpecSubNum, title='', xsize = 2, /row)                              

    colors = phast_intrinsic_colors(state.photSpecTypeNum, state.photSpecSubNum)
    state.photSpecBmV = colors[0]
    state.photSpecVmR = colors[1]
    state.photSpecBmR = colors[2]
        
    state.photSpec_BmV_ID  = cw_field(apphot_data_insert, /floating, /return_events, uvalue = 'spectralBmV', $
                                      value = state.photSpecBmV, title='B-V', xsize = 5, /row)                              

    state.photSpec_VmR_ID  = cw_field(apphot_data_insert, /floating, /return_events, uvalue = 'spectralVmR', $
                                      value = state.photSpecVmR, title='V-R', xsize = 5, /row)
                                
    state.photSpec_BmR_ID  = cw_field(apphot_data_insert, /floating, /return_events, uvalue = 'spectralBmR', $
                                      value = state.photSpecBmR, title='B-R', xsize = 5, /row)   

                                                     
    tmp_string1 = $
      string(99999.0, 99999.0, $
             format = '("Object position: (",f6.1,", ",f6.1,")")')
    
 ;   position_label = widget_label(apphot_data_base1a,value='Object position:')

    state.centerpos_id = widget_label(apphot_data_base1a, value = tmp_string1, uvalue = 'centerpos')

    state.apphot_wcs_id = widget_label(apphot_data_base1a,value='---No WCS Info---',/dynamic_resize)

    state.centerbox_id = $
      cw_field(apphot_data_base1a, $
               /long, $
               /return_events, $
               title = 'Centering box size (px):', $
               uvalue = 'centerbox', $
               value = state.centerboxsize, $
               xsize = 5)
    
    state.radius_id = $
      cw_field(apphot_data_base1a, $
               /floating, $
               /return_events, $
               title = ' Aperture radius:', $
               uvalue = 'radius', $
               value = state.aprad, $
               xsize = 8)
    
    state.innersky_id = $
      cw_field(apphot_data_base1a, $
               /floating, $
               /return_events, $
               title = 'Inner sky radius:', $
               uvalue = 'innersky', $
               value = state.innersky, $
               xsize = 8)
    
    state.outersky_id = $
      cw_field(apphot_data_base1a, $
               /floating, $
               /return_events, $
               title = 'Outer sky radius:', $
               uvalue = 'outersky', $
               value = state.outersky, $
               xsize = 8)
    
    photzoom_widget_id = widget_draw( $
         apphot_plot_base,$
         scr_xsize=state.photzoom_size, scr_ysize=state.photzoom_size)

        state.photwarning_id = $
      widget_label(apphot_data_base2, $
                   value='-------------------------', $
                   /dynamic_resize)

    tmp_string4 = string(0.0, format='("FWHM (pix): ",g15.6)' )
    state.fwhm_id = widget_label(apphot_data_base2, $
                                 value=tmp_string4, $
                                 uvalue='fwhm')

    tmp_string3 = string(10000000.00, $
                         format = '("Sky level: ",g12.6)' )
    
    state.skyresult_id = $
      widget_label(apphot_data_base2, $
                   value = tmp_string3, $
                   uvalue = 'skyresult')
    
    tmp_string2 = string(1000000000.00, $
                         format = '("Object counts: ",g12.6)' )
    
    state.photresult_id = $
      widget_label(apphot_data_base2, $
                   value = tmp_string2, $
                   uvalue = 'photresult')

    tmp_string2 = '                           '

    state.photerror_id = $
      widget_label(apphot_data_base2, $
                   value = tmp_string2, $
                   uvalue = 'photerror')

    apphot_cycle_base = widget_base(apphot_data_base1,/row)
    phot_cycle_left = widget_button(apphot_cycle_base,value='<---',uvalue='cycle_left')
    phot_cycle_right = widget_button(apphot_cycle_base,value='--->',uvalue='cycle_right')
    do_all = widget_button(apphot_cycle_base,value='Do all',uvalue='do_all')

    photsettings_id = $
      widget_button(apphot_data_base1, $
                    value = 'Photometry settings...', $
                    uvalue = 'photsettings',xsize=160)

    if (state.photprint EQ 0) then begin
       photstring = 'Write results to file...'
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

    state.objfwhm_id = widget_label(apphot_data_base2, value=fldmask, uvalue='fwhm', /align_left)                  ; FWHM / SNR
   
    state.photresult_id = widget_label(apphot_data_base2, value = fldmask, uvalue = 'photresult', /align_left)  ; Obj Mag +/- err

    state.skyresult_id  = widget_label(apphot_data_base2, value = fldmask, uvalue = 'skyresult', /align_left)   ; Sky Bkg +/- err
 
    state.photerror_id  = widget_label(apphot_data_base2, value = fldmask, uvalue = 'photerror', /align_left)   ; Inst Prec / Limit Mag

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

;--------------------------------------------------------------------
;    Spectral extraction routines
;---------------------------------------------------------------------

function phast_get_tracepoint, yslice, traceguess

common phast_state

; find the trace points by simple centroiding after subtracting off
; the background level.  iterate up to maxrep times to fine-tune the
; centroid position.

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

pro phast_trace, newcoord

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


;--------------------------------------------------------------------
;    shutdown routine
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
;--------------------------------------------------------------------
;    phast main program.  needs to be last in order to compile.
;---------------------------------------------------------------------

; Main program routine for PHAST.  If there is no current PHAST session,
; then run phast_startup to create the widgets.  If PHAST already exists,
; then display the new image to the current PHAST window.

pro phast, image, $
         min = minimum, $
         max = maximum, $
         autoscale = autoscale,  $
         linear = linear, $
         log = log, $
         histeq = histeq, $
         asinh = asinh, $
         block = block, $
         align = align, $
         stretch = stretch, $
         header = header

common phast_state
common phast_images

if (long(strmid(!version.release,0,1)) LT 6) then begin
    print, 'PHAST requires IDL version 6.0 or greater.'
    retall
endif

if (not(keyword_set(block))) then block = 0 else block = 1

newimage = 0

if ( (n_params() EQ 0) AND (xregistered('phast', /noshow))) then begin
    print, 'USAGE: phast, array_name OR fitsfile'
    print, '         [,min = min_value] [,max=max_value] '
    print, '         [,/linear] [,/log] [,/histeq] [,/block]'
    print, '         [,/align] [,/stretch] [,header=header]'
    return
endif

if (!d.name NE 'X' AND !d.name NE 'WIN' AND !d.name NE 'MAC') then begin
    print, 'Graphics device must be set to X, WIN, or MAC for PHAST to work.'
    retall
endif


; Before starting up phast, get the user's external window id.  We can't
; use the phast_getwindow routine yet because we haven't run phast
; startup.  A subtle issue: phast_resetwindow won't work the first time
; through because xmanager doesn't get called until the end of this
; routine.  So we have to deal with the external window explicitly in
; this routine.
if (not (xregistered('phast', /noshow))) then begin
   userwindow = !d.window
   phast_startup
   align = 0B     ; align, stretch keywords make no sense if we are
   stretch = 0B   ; just starting up. 

; Startup message, if desired   
;   print
;   msgstring = strcompress('PHAST ' + state.version + ' starting. ')
;   print, msgstring  
;   print

endif


if (n_elements(align) EQ 0) then align = state.default_align
if (n_elements(stretch) EQ 0) then stretch = state.default_stretch

; If image is a filename, read in the file
if ( (n_params() NE 0) AND (size(image, /tname) EQ 'STRING')) then begin
    ifexists = findfile(image, count=count)
    if (count EQ 0) then begin
        print, 'ERROR: File not found!'
    endif else begin
        phast_readfits, fitsfilename=image, newimage=newimage
        if (state.firstimage EQ 1) then begin
            align = 0
            stretch = 0
        endif
    endelse
endif

; Check for existence of array
if ( (n_params() NE 0) AND (size(image, /tname) NE 'STRING') AND $
   (size(image, /tname) EQ 'UNDEFINED')) then begin
    print, 'ERROR: Data array does not exist!'
endif

; If user has passed phast a data array, read it into main_image.
if ( (n_params() NE 0) AND (size(image, /tname) NE 'STRING') AND $
     (size(image, /tname) NE 'UNDEFINED')) then begin
; Make sure it's a 2-d array
   if ( ((size(image))[0] GT 3) OR $
        ((size(image))[0] LT 2) OR $
        ((size(image))[1] EQ 1) OR $
        ((size(image))[2] EQ 1)  ) then begin
      print, 'ERROR: Input data must be a 2-d array or 3-d data cube.'    
   endif else begin
      main_image = image
      newimage = 1
      state.imagename = ''
      state.title_extras = ''
      phast_setheader, header
      
      ; check for cube
      if ((size(image))[0] EQ 3) then begin
         main_image_cube = main_image
         main_image = 0
         state.cube = 1
         phast_initcube
      endif else begin   ; plain 2d image
         state.cube = 0
         main_image_cube = 0
         phast_killcube      
      endelse

      if (state.firstimage EQ 1) then begin
         align = 0
         stretch = 0
      endif        
   endelse
endif

;   Define default startup image 
if (n_elements(main_image) LE 1) then begin
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
    newimage = 2             ; flag for startup image
    phast_setheader, ''
    state.title_extras = 'firstimage'
endif


if (newimage GE 1) then begin  
; skip this part if new image is invalid or if user selected 'cancel'
; in dialog box
    phast_getstats, align=align
    
    display_image = 0

    if n_elements(minimum) GT 0 then begin
        state.min_value = minimum
    endif
    
    if n_elements(maximum) GT 0 then begin 
        state.max_value = maximum
    endif
    
    if state.min_value GE state.max_value then begin
        state.min_value = state.max_value - 1.
    endif
    
    if (keyword_set(linear)) then state.scaling = 0
    if (keyword_set(log))    then state.scaling = 1
    if (keyword_set(histeq)) then state.scaling = 2
    if (keyword_set(asinh))  then state.scaling = 3
    
; Perform autoscale if current stretch invalid or stretch keyword
; not set, or if this is the first image
    IF (state.min_value EQ state.max_value) OR (stretch EQ 0) THEN BEGIN 

       if (keyword_set(autoscale) OR $
           ((state.default_autoscale EQ 1) AND (n_elements(minimum) EQ 0) $
            AND (n_elements(maximum) EQ 0)) ) $
         then phast_autoscale
    ENDIF 

;    if (state.firstimage EQ 1 AND newimage EQ 1) then phast_autoscale
    if (state.firstimage EQ 1) then phast_autoscale
    if (newimage EQ 1) then state.firstimage = 0  ; now have a real image
        
    phast_set_minmax
    
    IF ((NOT keyword_set(align)) AND state.default_align EQ 0) THEN BEGIN 
       state.zoom_level = 0
       state.zoom_factor = 1.0
    ENDIF 

    phast_displayall
    phast_settitle
    
    phast_resetwindow
endif

state.block = block

; Register the widget with xmanager if it's not already registered
if (not(xregistered('phast', /noshow))) then begin
    nb = abs(block - 1)
    xmanager, 'phast', state.base_id, no_block = nb, cleanup = 'phast_shutdown'
    wset, userwindow
    ; if blocking mode is set, then when the procedure reaches this
    ; line phast has already been terminated.  If non-blocking, then
    ; the procedure continues below.  If blocking, then the state
    ; structure doesn't exist any more so don't set active window.
    if (block EQ 0) then state.active_window_id = userwindow
endif




end
