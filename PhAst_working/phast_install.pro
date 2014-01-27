pro phast_install

;routine to install PhAst by adding the current directory to the IDL
;path.

  spawn, 'clear'

  answer = ''
  answer2 = ''
  option = -1
  install = 1

  print, '################################################################################'
  print, 'Welcome to PhAst'
  print, '################################################################################'

error = 0
     while (1 eq 1)do begin
        catch, error
        if error ne 0 then begin
           print, 'Error: Library not installed or out of date'
           print, ''
           catch, /cancel
           break
        endif
        print, ""
        print, 'Checking for installed NASA Astronomy User library...'
        resolve_routine, 'TPV_EVAL',/either
        print, 'Library installed'
        print, ''
        break
     endwhile
     error2 = 0
     while (1 eq 1)do begin
        catch, error2
        if error2 ne 0 then begin
           print, 'Error: Library not installed or out of date'
           print, ''
           catch, /cancel
           break
        endif
        print, 'Checking for installed Coyote Library...'
        resolve_routine, 'CGPROGRESSBAR__DEFINE'
        print, 'Library installed'
        print, ''
        break
     endwhile

if (error ne 0) or (error2 ne 0) then begin
   install = 0
   print, "Please configure your libraries before installing or upgrading PhAst"
endif

  if (file_test('output') eq 1) and (file_test('output/images') eq 1) and (file_test('output/catalogs') eq 1) and (install eq 1) then begin
     print, ''
     print, 'Your libraries appear to be installed and up to date.  If you are upgrading from an earlier PhAst release and have already replaced the files in this directory and in lib/, no further action is required.'
     while (1 eq 1) do begin
        read, answer2, prompt='Continue with new installation anyway? yes/no:'
        if (answer2 eq 'No') or (answer2 eq 'no') then begin
           install = 0
           break
        endif else if (answer2 eq 'Yes') or (answer2 eq 'yes') then break
     endwhile
  endif
  if install eq 1 then begin
     print, ''
     print, 'Please ensure that PhAst is not installed anywhere else on this system.  Other installations could lead to erratic behavior.'
  endif
  while (1 eq 1) and (install eq 1) do begin
     print, ''
     read, answer, prompt='This will install PhAst to the current direcoty by modifying the IDL path.  Is this okay?  yes/no:'
     if (answer eq 'Yes') or (answer eq 'yes') then begin
        option = 1
        break
     endif
     if (answer eq 'No') or (answer eq 'no') then begin
        option = 2
        break
     endif
  endwhile

  if option eq 1 then begin

     cd, current=current
     new_path = current+':'+!PATH
     pref_set, 'IDL_PATH', new_path, /commit
     print, ''
     print, 'Setting path... done.'
     print, ''

     
  endif
end
