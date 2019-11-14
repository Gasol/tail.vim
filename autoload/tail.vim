function! tail#OnStdout(bufnr, chan_id, data, name)
    let lines = filter(a:data, 'strlen(v:val) > 0')
    if len(lines) == 0
        return
    endif

    keepjump call appendbufline(a:bufnr, '$', lines)
    if get(b:, 'tail_lnum', 0) == getcurpos()[1]
        normal! G
    endif
endfunction

function! tail#Run(mods, file)
    let mods = ''
    if a:mods =~# '\<\%(aboveleft\|belowright\|leftabove\|rightbelow\|topleft\|botright\|tab\)\>'
        let mods = a:mods
    endif

    let file = a:file
    if file ==# ''
        let file = expand('%')
    endif
    if !filereadable(file)
        echom 'File ' . file . ' does not exists'
        return
    endif

    let cmd = ['tail', '-f', file]
    execute mods 'enew'
    setl buftype=nofile
    let bufnr = bufnr('%')

    if has('job')
        let b:chan_id = job_start(cmd, {
        \ 'out_io': 'buffer',
        \ 'out_buf': bufnr,
        \ })
        let s:Jobstop = function('job_stop')
    elseif has('nvim')
        let b:chan_id = jobstart(cmd, {
        \ 'on_stdout': function('tail#OnStdout', [bufnr])
        \ })
        let s:Jobstop = function('jobstop')
    else
        echom 'error'
        return
    endif

    augroup tail
        execute 'autocmd' 'BufUnload' '<buffer>' 'call' 's:Jobstop(' b:chan_id ')'
        autocmd TextChanged <buffer> let b:tail_lnum = line('$')
    augroup END
    execute 'doautocmd' 'BufRead' file
endfunction
