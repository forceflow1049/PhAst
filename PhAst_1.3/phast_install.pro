pro phast_install

;routine to install PhAst by adding the current directory to the IDL
;path.

  spawn, 'clear'

  answer = ''
  option = -1

  print, '###################################################################################'
  print, 'Welcome to PhAst'
  print, '###################################################################################'

  
  while (1 eq 1) do begin
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

     error = 0
     while (1 eq 1)do begin
        catch, error
        if error ne 0 then begin
           print, 'Error: Library not installed'
           print, ''
           catch, /cancel
           break
        endif
        print, 'Checking for installed NASA Astronomy User library...'
        resolve_routine, 'MMM'
        print, 'Library installed'
        print, ''
        break
     endwhile
     error2=0
     while (1 eq 1)do begin
        catch, error2
        if error2 ne 0 then begin
           print, 'Error: Library not installed'
           print, ''
           catch, /cancel
           break
        endif
        print, 'Checking for installed Coyote Library...'
        resolve_routine, 'CGSET'
        print, 'Library installed'
        print, ''
        break
     endwhile
  endif
end
