function! bufmru#sort(b1, b2)
	let t1 = str2float(reltimestr(BufMRUTime(a:b1)))
	let t2 = str2float(reltimestr(BufMRUTime(a:b2)))
	return t1 == t2 ? 0 : t1 > t2 ? -1 : 1
endfunction

function! bufmru#enter()
	let s:bufmru_entertime = reltime()
endfunction

function bufmru#save()
	let i = bufnr("%")
	let totaltime = str2float(reltimestr(reltime(s:bufmru_entertime)))
	if totaltime > 0.25 && buflisted(i)
		let oldVal = BufMRUTime(i)
		let s:bufmru_files[i] = s:bufmru_entertime
		if reltimestr(oldVal) != reltimestr(s:bufmru_entertime)
			silent doautocmd User BufMRUChange
			call airline#extensions#tabline#buflist#invalidate()
			" Change currect buffer to force updating the airline buffer list
			if bufnr("$") > 1
				execute "buffer" 1
				execute "buffer" 2
				execute "buffer" i
			endif
		endif
	endif
	"unmap <CR>
endfunction

function! bufmru#leave()
	let totaltime = str2float(reltimestr(reltime(s:bufmru_entertime)))
	if totaltime >= 1.0
		call bufmru#save()
	endif
endfunction

function! BufMRUTime(bufn)
	return has_key(s:bufmru_files, a:bufn) ? s:bufmru_files[a:bufn] : s:bufmru_starttime
endfunction

function! BufMRUList()
	let bufs = range(1, bufnr("$"))
	let res = []
	call sort(bufs, "bufmru#sort")
	for nr in bufs
		if buflisted(nr)
			call add(res, nr)
		endif
	endfor
	return res
endfunction

function! bufmru#show()
	call bufmru#save()
	let bufs = BufMRUList()
	for buf in bufs
		let bufn = bufname(str2nr(buf))
		let buft = reltimestr(reltime(BufMRUTime(buf)))
		echom buf " | " buft "s | " bufn
	endfor
endfunction

function! bufmru#go(inc)
	"call bufmru#leave()
	let list = BufMRUList()
	let idx = index(list, bufnr("%"))
	let i = list[((idx < 0 ? 0 : idx) + a:inc) % len(list)]
	execute "buffer" i
	"noremap <CR> :BufMRUCommit<CR><CR>
endfunction


function! bufmru#init()
	let s:bufmru_files = {}
	let s:bufmru_starttime = reltime()
	let s:bufmru_entertime = s:bufmru_starttime

	augroup bufmru_buffers
		autocmd!
		autocmd BufEnter * call bufmru#enter()
		"autocmd BufLeave * call bufmru#leave()
		"autocmd InsertEnter,InsertLeave * call bufmru#save()
		autocmd InsertEnter * call bufmru#save()
		autocmd InsertLeave * call bufmru#save()
		autocmd TextChanged * call bufmru#save()
		autocmd TextChangedI * call bufmru#save()
 		autocmd CursorHold,CursorHoldI * call bufmru#save()
		autocmd CursorMoved * call bufmru#save()
		autocmd CursorMovedI * call bufmru#save()
	augroup END
endfunction
