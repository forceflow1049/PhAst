;       PhAst (Photometry-Astrometry)
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
;       Requires IDL version 8.0 or greater.
;       Requires the Coyote Library
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
;       2013-05-31 PhAst 1.4 released.
;       2012-12-02 PhAst 1.3 reseased.
;       2012-05-10 PhAst 1.2 released.
;       2011-11-27 PhAst 1.1 released.
;       2011-08-11 PhAst 1.0 released. First public release (Morgan
;                  Rehnberg)
;       2011-08-03 PhAst 0.98 released.  First private release (Morgan
;                  Rehnberg)
;       2011-06-05 PhAst forked from ATV 2.3
;       2010-10-17 ATV 2.3 released (Aaron J. Barth)



;----------------------------------------------------------------------

pro phast_initcommon, phast_dir, launch_dir

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
    
  state = {                $
    bin_label: 0L, $       ;widget ID for bin label warning
    batch_current_toggle:0L,$;widget ID for current image button
    astrometry_toggle: 0L, $;compute astrometry using SExtractor, etc?
    bin_x_widget: 0L, $     ;widget id for bin level text box
    bin_y_widget: 0L, $     ;widget id for bin level text box
    x_bin: 1, $             ;multiple to bin pixels on calibration
    y_bin: 1, $             ;multiple to bin pixels on calibration
    batch_single_current_toggle:0L,$;widget ID for single image button
    batch_imagename: '', $  ;image to be processed
    batch_single_image_base:0L,$;base ID for batch single base
    batch_multi_image_base:0L,$;base ID for batch multi base
    combine_dir: '', $      ;directory of images to be combined
    combine_dir_widget_id: 0L,$;widget ID for selecting combine dir
    align_toggle_button: 0l, $;widget ID for align toggle button
    filters_loaded: 0, $    ;are filter specifications loaded?
    launch_dir: launch_dir, $;location where phast is being run 
    phast_dir: phast_dir, $ ;location of phast.pro
    archive_size: 25, $     ;number of chunks created
    archive_chunk_size: 25,$;block size for incresing archive
    phot_rad_plot_open: 1, $
    kernel_list: '', $      ;path to file with kernel list
    spice_box_id: 0L, $     ;widget id for spice control box
    check_updates: 1, $     ;check for updates on startup? 1=yes
    filter_color: 'Blue', $ ;which filter for catalog photometry?
    image_type: 'FITS',  $  ;what kind of image is being viewed?
    bias_filename: 'No bias loaded',$;name of bias file
    flat_filename: 'No flat loaded',$;name of flat file
    dark_filename: 'No dark loaded',$;name of dark file
    batch_image_id: 0L, $   ;widget ID for batch image display
    batch_select_image: 0L,$;widget ID for image select button
    batch_source: -1, $     ;what images to calibrate?
    batch_select_dir: 0L, $ ;widget id for dir select button
    batch_dirname: '', $    ;location of image batch
    fits_crota2:-999.9, $      ;holds dec rotation (deg)
    fits_crota1:-999.9, $      ;holds ra rotation (deg)
    fits_cdelt2:0.0, $      ;holds y plate scale (deg)
    fits_cdelt1:0.0, $      ;holds x plate scale (deg)
    batch_dir_id: 0L, $     ;widget id for batch dir display
    apphot_wcs_id: 0L,$     ;widget id for wcs coords in apphot
    cal_file_name: './output/images/phast.fits',$;cal output file name
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
    overlay_stars_box_id: 0L, $ ;widget id for overlay box
    overlay_catalog_id: 0L,   $ ;widget id for overlay catalog droplist
    overlay_catList: [ 'USNO-B1.0', 'GSC-2.3', 'Landolt' ], $ ;overlay catalog options
    overlay_catalog: 0L,  $ ;overlay catalog [0, 1, 2 as above]  
    overlay_char_id: 0L,  $ ;widget id for overlay characteristic
    display_char: 0, $      ;display star characteristics? 0=name; 1=magnitude; 2=color 
    mag_limit: 20.0, $      ;limiting mag for star overlay    
    star_search_string:'',$ ;string containing search terms
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
    version: '1.4', $       ; version # of this release
    head_ptr: ptr_new(), $  ; pointer to image header
    astr_ptr: ptr_new(), $  ; pointer to astrometry info structure
    firstimage: 1, $        ; is this the first image?
    block: 0, $             ; are we in blocking mode?
    wcstype: 'none', $      ; coord info type (none/angle/lambda)
    equinox: 'J2000', $     ; equinox of coord system
    wcsKPNO21m: 1,        $ ; activates patch for incorrectly coded coord sys on KPNO 2.1m
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
    draw_window_size: [800L, 760L], $ ; size of main draw window WAS 512/512, then 690/690
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
    magtype: 2,           $ ; 0=instrumental; 1=catalog; 2=std BVRI
    skytype: 0,           $ ; 0=idlphot,1=median,2=no sky subtract
    exptime: 1.0, $         ; exposure time for photometry
    nFilters: 0L,         $ ; number of filters defined
    phot_aperFWHM_id: 0L, $ ; id of aperture FWHM box
    phot_aperFWHM: 2.0,   $ ; FWHM (pixels) used to size apertures
    phot_aperFCvg: 0.94,  $ ; flux coverage (fraction) of measuring aperture
    phot_aperFRef: 0.94,  $ ; flux coverage (fraction) of SExtractor ellipses
    phot_aperGrow: 1.00,  $ ; growth fractor from FCvg to SEx coverage
    phot_aperUnit_id: 0L, $ ; widget to display units of aperFWHM
    phot_aperList: ['px', '" '], $
    phot_aperTrain_ID: 0L,$ ; id of aperture Train/Lock button
    phot_aperType_ID: 0L, $ ; widget for type of autocentering
    phot_aperType: 0L,    $ ; 0=snap-to; 1=flux centroid; 2=manual centering
    photcatalog_name: 'GSC-2.3',$ ; name of currently selected photometeric star cat
    photcatalog_loaded:0L,      $ ; has the photometric star catalog been loaded? 1=yes
    photcatalog_UBVRI: 0L,      $ ; does catalog have standard UBVRI photometry? 1=yes
    photcatalog_bands: [0L,0L,0L,0L,0L], $ ; does catalog have ubvri mag bands? 1=yes
    posFilter: 0L,        $ ; filter position
    photzpt:  0.0,        $ ; magnitude zeropoint
    photzerr: 0.0,        $ ; zeropoint error rms
    photzbnd: '',         $ ; magnitude color band
    photzclr: 0.0,        $ ; magnitude color coefficient
    photztrm:  '',        $ ; magnitude color term (e.g, B-V)
    photznum: 0L,         $ ; zeropoint N
    photSpecList: ['B','A','F','G','K','M' ], $ ; recognized spectral types
    photSpecType:   'K',  $ ; default spectral type
    photSpecTypeNum: 4,   $ ; default spectral type number (in photSecList)
    photSpecSubNum:  0,   $ ; default spectral subtype
    photSpecBmV:  0.60,   $ ; implied spectral color
    photSpecVmR:  0.27,   $ ; implied spectral color
    photSpecRmI:  0.87,   $ ; implied spectral color
    photSpec_Type_ID: 0L, $ ; id of photo spectral type
    photSpec_Num_ID:  0L, $ ; id of photo spectral subtyipe
    photSpec_BmV_ID:  0L, $ ; id of photo spectral BmV color
    photSpec_VmR_ID:  0L, $ ; id of photo spectral VmR color
    photSpec_RmI_ID:  0L, $ ; id of photo spectral BmR color
    photExtAdjust:    0L, $ ; extinction adjustment: 0=none; 1=at X=Xobs; 2=at X=0
    photprint: 0, $         ; print phot results to file?
    photprint_id: 0L, $     ; id of phot print button
    photfile: 0L, $         ; file unit of phot file
    photfilename: 'phastphot.dat', $ ; filename of phot file
    skyresult_id: 0L, $     ; id of sky widget
    photresult_id: 0L, $    ; id of photometry result widget
    photerror_id: 0L, $,    ; id of photometry error widget
    radplot_widget_id: 0L,$ ; id of radial profile widget
    radplot_window_id: 0L,$ ; id of radial profile window
    photzoom_window_id: 0L,$ ; id of photometry zoom window
    photzoom_size: 190L, $  ; size in pixels of photzoom window
    showradplot_id: 0L, $   ; id of button to show/hide radplot
    photwarning_id: 0L, $   ; id of photometry warning widget
    photwarning: ' ', $     ; photometry warning text
    photerrors: 0, $        ; calculate photometric errors
    objfwhm_id: 0L,       $ ; id of photometry fwhm widget
    objfwhm: 0.0,         $ ; object fwhm (latest measured) (pixel units)
    pixelscale: 0.0,      $ ; pixel scale, arcsecs/pixel
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
  image_archive = objarr(25)
  star_catalog=0
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
  phast_read_filters ;read filters file to define passbands
  if state.check_updates eq 1 then phast_check_updates,/silent
end

;--------------------------------------------------------------------

pro phast_compile_modules, phast_location, launch_dir

  ;routine to compile other PhAst procdueres on startup

  ;switch to PhAst's library directory
  cd, phast_location+'lib'
  
  filelist =findfile('*.pro')
  
  for j=0, 1 do begin           ;need multiple compiles for some reason
     for i=0, n_elements(filelist)-1 do begin
        temp = strsplit(filelist[i],'.',/extract)
        if (temp[0] eq 'cmps_form') or( temp[0] eq 'dialog_input') $
           or (temp[0] eq 'read_vicar') or (temp[0] eq 'vicgetpars') then begin
           resolve_routine, temp[0], /compile_full_file, /is_function
        endif else resolve_routine, temp[0], /compile_full_file
     endfor
  endfor
  
  cd, launch_dir
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

;find directory where PhAst is located and the current dir
  cd, current=launch_dir
  findpro, 'phast.pro', dirlist=list, /noprint
  phast_dir = list[0]

  ;compile program 
  phast_compile_modules, phast_dir, launch_dir

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
    phast_startup, phast_dir, launch_dir
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

