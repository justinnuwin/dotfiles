" ==============================================================================
" git_diff_tree.vim - Minimal per-tab file-tree sidebar for gshow / gdiff.
"
" The gshow / gdiff shell aliases open one Vim tab per changed file (each a
" vertical diff). This plugin renders a narrow sidebar, displayed identically in
" every tab, that shows exactly those files as a collapsible directory tree
" (like NERDTree, scoped to the diff). It also owns tab setup/teardown:
"
"   - Selecting a file (click, <CR>, or o) switches to the tab already showing
"     that file's diff; if that tab was closed, it reopens the diff.
"   - Selecting a directory toggles it open/closed.
"   - Closing a diff window (:q) closes the whole tab.
"   - The tab bar is replaced by a static title bar (the sidebar already lists
"     every open tab), e.g. "Git Show HEAD (12 tabs open)".
"
" The aliases populate it with a title string, a list of entries (one per tab,
" in order), and a refresh command (argv list, shell-escaped here):
"     call GDiffTreeSetup('Git Show HEAD',
"       \ [{'label': 'Commit', 'file': '/tmp/.../COMMIT_DESCRIPTION',
"       \   'setup': 'setlocal readonly nomodifiable', 'stat': ''},
"       \  {'label': 'a/b.cc', 'file': '/repo/a/b.cc',
"       \   'setup': 'try | Gedit HEAD:% | Gvdiffsplit HEAD~1 | catch | endtry',
"       \   'stat': '+3 -1'}, ...],
"       \ ['git', '-C', '/repo', 'diff', '--numstat'])
" where 'file' is the buffer opened in that tab and 'setup' is the Ex command
" that turns it into the diff. Tabs are already opened by `vim -p`; this applies
" 'setup', tags each tab with a stable id, and reuses (file, setup) to reopen.
" A non-empty refresh command re-derives the per-file stats on every :w (for
" working-tree diffs, whose stats change as you edit); pass [] to disable it.
" ==============================================================================

if exists('g:loaded_git_diff_tree')
    finish
endif
let g:loaded_git_diff_tree = 1

let g:gdifftree_width = get(g:, 'gdifftree_width', 52)

let s:bufname = '__gdifftree__'

" s:title        - text shown in the title bar (before the tab count)
" s:entries      - list of {'label', 'file', 'setup', 'stat', ['pinned']};
"                  index == tab id. Pinned entries render above the diff tree
"                  (see s:Rebuild): a pinned label with no '/' is a flat line
"                  (commit description), one with a '/' joins the pinned subtree
"                  (the collapsible 'Commit Notes' folder).
" s:tree         - nested node {'dirs': {name: node}, 'files': {name: id},
"                  'name', 'path'} built from the unpinned (diff) entries
" s:pinned_tree  - same node shape, built from pinned entries whose label has a
"                  '/', i.e. the pinned folder(s) shown above the diff tree
" s:collapsed    - set (dict used as a set) of directory paths that are closed
" s:line_to_node - {lnum: {'type':'dir','path'} | {'type':'file','id'}}
" s:pending_close- tab ids queued for deferred close (see s:OnQuitPre)
let s:title = ''
let s:entries = []
let s:refresh = []
let s:tree = {}
let s:pinned_tree = {}
let s:collapsed = {}
let s:line_to_node = {}
let s:pending_close = []

function! s:NewNode(name, path) abort
    return {'dirs': {}, 'files': {}, 'name': a:name, 'path': a:path}
endfunction

" Total number of directory and file nodes when the tree is fully expanded.
function! s:CountNodes(node) abort
    let l:count = len(keys(a:node.files))
    for l:dir in values(a:node.dirs)
        let l:count += 1 + s:CountNodes(l:dir)
    endfor
    return l:count
endfunction

" Mark every directory in the tree as collapsed.
function! s:CollapseAll(node) abort
    for l:dir in values(a:node.dirs)
        let s:collapsed[l:dir.path] = 1
        call s:CollapseAll(l:dir)
    endfor
endfunction

" Insert entry a:id into tree a:root by splitting its label on '/', creating
" intermediate directory nodes as needed; the leaf stores the entry's stable id.
function! s:InsertEntry(root, label, id) abort
    let l:parts = split(a:label, '/')
    let l:node = a:root
    let l:part_index = 0
    while l:part_index < len(l:parts) - 1
        let l:part = l:parts[l:part_index]
        if !has_key(l:node.dirs, l:part)
            let l:path = l:node.path ==# '' ? l:part : l:node.path . '/' . l:part
            let l:node.dirs[l:part] = s:NewNode(l:part, l:path)
        endif
        let l:node = l:node.dirs[l:part]
        let l:part_index += 1
    endwhile
    if !empty(l:parts)
        let l:node.files[l:parts[-1]] = a:id
    endif
endfunction

" Build the directory trees from the entry labels. Unpinned entries form the
" diff tree (s:tree); pinned entries whose label contains a '/' form the pinned
" subtree (s:pinned_tree, e.g. the 'Commit Notes' folder). Flat pinned entries
" (no '/', the commit description) are not in either tree -- s:Rebuild lists them
" directly.
function! s:BuildTree() abort
    let s:tree = s:NewNode('', '')
    let s:pinned_tree = s:NewNode('', '')
    let s:collapsed = {}

    let l:entry_id = 0
    while l:entry_id < len(s:entries)
        let l:label = s:entries[l:entry_id].label
        if get(s:entries[l:entry_id], 'pinned', 0)
            if stridx(l:label, '/') >= 0
                call s:InsertEntry(s:pinned_tree, l:label, l:entry_id)
            endif
        else
            call s:InsertEntry(s:tree, l:label, l:entry_id)
        endif
        let l:entry_id += 1
    endwhile

    " Expand everything when the fully expanded diff tree fits within 150% of the
    " screen height; otherwise start with all directories collapsed. The pinned
    " subtree is small and always starts expanded.
    if s:CountNodes(s:tree) >= float2nr(1.5 * &lines)
        call s:CollapseAll(s:tree)
    endif
endfunction

" Apply each entry's diff setup to its (already open) tab, tag the tab with its
" stable id, and add the sidebar. Then wire up the autocmds that keep the
" sidebar present and close tabs when their diff is closed.
function! GDiffTreeSetup(title, entries, refresh) abort
    let s:title = a:title
    let s:entries = a:entries
    let s:refresh = a:refresh
    call s:BuildTree()
    call s:SetupTitleBar()
    call s:SetupDiffView()

    " One deliberate status line for the whole (silent) per-tab setup; it is
    " cleared at the end once every diff is wired up.
    echo 'Preparing gdifftree view (' . len(a:entries) . ' files)...'
    let l:start_tab = tabpagenr()
    let l:entry_id = 0
    while l:entry_id < len(a:entries)
        let l:tabnr = l:entry_id + 1
        execute 'tabnext ' . l:tabnr
        call s:PrepareTab(l:entry_id)
        let l:entry_id += 1
    endwhile

    augroup gdifftree
        autocmd!
        autocmd TabEnter * call s:EnsureSidebar()
        autocmd QuitPre * call s:OnQuitPre()
        " Rebalance the diff panes when the terminal/window size changes.
        autocmd VimResized * wincmd =
    augroup END
    " For working-tree diffs, re-derive the change stats whenever a buffer is
    " saved so the sidebar reflects edits made in the diff.
    if !empty(s:refresh)
        autocmd gdifftree BufWritePost * call s:RefreshStats()
    endif

    execute 'tabnext ' . l:start_tab
    call s:Render()
    " Clear the "Preparing..." progress message now that setup is done. A bare
    " :redraw repaints but does not erase an echoed message; :echo '' does.
    redraw
    echo ''
endfunction

" Re-run the numstat command, update every entry's stat, and refresh the
" sidebar. No-op when no refresh command was supplied (committed diffs).
function! s:RefreshStats() abort
    if empty(s:refresh)
        return
    endif
    let l:numstat_lines = systemlist(join(map(copy(s:refresh), 'shellescape(v:val)'), ' '))
    if v:shell_error
        return
    endif
    let l:stat_by_path = {}
    for l:line in l:numstat_lines
        let l:parts = split(l:line, '\t')
        if len(l:parts) >= 3
            let l:stat_by_path[l:parts[2]] = l:parts[0] ==# '-'
                \ ? 'bin' : '+' . l:parts[0] . ' -' . l:parts[1]
        endif
    endfor
    for l:entry in s:entries
        let l:entry.stat = get(l:stat_by_path, l:entry.label, '')
    endfor
    call s:Render()
endfunction

" Turn the current tab into entry a:id's diff: run its setup, tag it, match diff
" folds on both panes, and open the sidebar.
function! s:PrepareTab(id) abort
    call settabvar(tabpagenr(), 'gdifftree_id', a:id)
    call settabvar(tabpagenr(), 'gdifftree_label', s:entries[a:id].label)
    if s:entries[a:id].setup !=# ''
        " silent! swallows the git stderr fugitive surfaces for added/deleted
        " files (e.g. "fatal: path ... does not exist in <sha>"); with many tabs
        " these otherwise pile up and flicker during setup. The try/catch in the
        " setup already handles the Vim-level exception.
        silent! execute s:entries[a:id].setup
    endif
    " signcolumn=no hides gitgutter's gutter within the diff panes only -- the
    " side-by-side diff already shows added/removed lines, so the gutter is
    " redundant here (and coc diagnostics are disabled for this session).
    silent! windo if &diff | setlocal foldmethod=diff foldlevel=0 signcolumn=no | endif
    call s:SetupDiffPaneColors()
    call s:OpenSidebar()
endfunction

" Diff appearance for the managed diff panes. Neovim only: these rely on a
" full-cell fill character and per-window highlight remaps (winhighlight), so
" under classic Vim the diff keeps the colors set in the vimrc. Scoped to this
" (diff-only) editor session regardless.
"
"   - Deleted hunks show as filler lines in the opposite pane; instead of a
"     solid red block, render them on the normal background with a muted gray
"     slashed hatch, so a deletion reads as absent content.
"   - Within a changed line, the differing span is tinted per pane by
"     s:SetupDiffPaneColors (removed text red on the left, added text green on
"     the right); the groups it maps DiffText onto are defined here.
function! s:SetupDiffView() abort
    if !has('nvim')
        return
    endif
    " U+2571 is a full-cell diagonal that tiles into a continuous slash across
    " the filler line. Written as an escape to keep the source ASCII-only.
    execute "set fillchars+=diff:\u2571"
    highlight DiffDelete cterm=none ctermfg=240 ctermbg=none gui=none guifg=#585858 guibg=bg
    " Whole added/removed lines (DiffAdd): red on the older (left) pane where the
    " line is a removal, green on the newer (right) pane where it is an addition.
    highlight GDiffTreeDiffLineDel cterm=bold gui=bold ctermfg=none ctermbg=52 guifg=fg guibg=#5f0000
    highlight GDiffTreeDiffLineAdd cterm=bold gui=bold ctermfg=none ctermbg=22 guifg=fg guibg=#005f00
    " Changed-line background (DiffChange): a very muted red/green wash (not the
    " default blue) so the changed-text span below stands out against it. 52/22
    " are the darkest red/green in the 256-color cube, which termguicolors=false
    " limits us to here.
    highlight GDiffTreeDiffChangeDel cterm=none gui=none ctermfg=none ctermbg=52 guifg=fg guibg=#3a1e1e
    highlight GDiffTreeDiffChangeAdd cterm=none gui=none ctermfg=none ctermbg=22 guifg=fg guibg=#1e3a1e
    " Changed-text spans within a changed line (DiffText): a brighter red/green
    " on top of the DiffChange line background.
    highlight GDiffTreeDiffTextDel cterm=bold gui=bold ctermfg=none ctermbg=88 guifg=fg guibg=#870000
    highlight GDiffTreeDiffTextAdd cterm=bold gui=bold ctermfg=none ctermbg=28 guifg=fg guibg=#008700
endfunction

" Tint each diff pane per side: the older (left) pane in red, the newer (right)
" pane in green -- both the whole added/removed lines (DiffAdd) and the changed
" span within a changed line (DiffText). Done with a per-window highlight remap
" (winhighlight), so it is neovim only. Must run while
" the two diff panes are the only windows in the tab (before the sidebar opens),
" so screen position identifies left vs right unambiguously.
function! s:SetupDiffPaneColors() abort
    if !has('nvim')
        return
    endif
    let l:diff_wins = []
    for l:nr in range(1, winnr('$'))
        if getwinvar(l:nr, '&diff')
            call add(l:diff_wins, [l:nr, win_screenpos(l:nr)[1]])
        endif
    endfor
    if len(l:diff_wins) < 2
        return
    endif
    call sort(l:diff_wins, {a, b -> a[1] - b[1]})
    call setwinvar(l:diff_wins[0][0], '&winhighlight',
        \ 'DiffAdd:GDiffTreeDiffLineDel,DiffChange:GDiffTreeDiffChangeDel,DiffText:GDiffTreeDiffTextDel')
    call setwinvar(l:diff_wins[-1][0], '&winhighlight',
        \ 'DiffAdd:GDiffTreeDiffLineAdd,DiffChange:GDiffTreeDiffChangeAdd,DiffText:GDiffTreeDiffTextAdd')
endfunction

function! s:SetupTitleBar() abort
    " Medium/dark gray bar so it reads clearly as a title, not a tab row.
    highlight GDiffTreeTitleBar cterm=bold gui=bold ctermbg=240 ctermfg=253 guibg=#585858 guifg=#dadada
    set showtabline=2
    set tabline=%!GDiffTreeTitle()
endfunction

" Escape '%' so it is not interpreted as a tabline field (it renders literally).
function! s:EscapePercent(text) abort
    return substitute(a:text, '%', '%%', 'g')
endfunction

" Render the title bar on a gray background: the previous file (gT target) at
" the far left, the diff/show description plus a live tab count centered, and
" the next file (gt target) at the far right.
"
" Vim's '%=' cannot true-center between two side blocks of unequal width, so the
" title drifts as the prev/next names change per tab. Instead we center the
" title against the full window width and pad the gaps ourselves. On a window
" too narrow to fit the side blocks without touching the centered title, we drop
" them. strwidth measures the raw text (the single '%#..#' highlight token is
" prepended only at return, so it never distorts the width math).
function! GDiffTreeTitle() abort
    let l:tab_count = tabpagenr('$')
    let l:title = s:title . ' (' . l:tab_count . ' tab' . (l:tab_count == 1 ? '' : 's') . ' open)'
    let l:hl = '%#GDiffTreeTitleBar#'
    let l:columns = &columns
    let l:title_width = strwidth(l:title)
    let l:title_start = (l:columns - l:title_width) / 2
    if l:title_start < 0 | let l:title_start = 0 | endif

    if l:tab_count <= 1
        return l:hl . repeat(' ', l:title_start) . s:EscapePercent(l:title)
    endif

    let l:current_tab = tabpagenr()
    let l:prev_tab = l:current_tab > 1 ? l:current_tab - 1 : l:tab_count
    let l:next_tab = l:current_tab < l:tab_count ? l:current_tab + 1 : 1
    let l:prev_name = fnamemodify(gettabvar(l:prev_tab, 'gdifftree_label', ''), ':t')
    let l:next_name = fnamemodify(gettabvar(l:next_tab, 'gdifftree_label', ''), ':t')
    let l:left = ' gT <- ' . l:prev_name
    let l:right = l:next_name . ' -> gt '
    let l:left_width = strwidth(l:left)
    let l:right_width = strwidth(l:right)

    " Drop the side blocks if they would overlap the centered title.
    if l:title_start < l:left_width || l:title_start + l:title_width > l:columns - l:right_width
        return l:hl . repeat(' ', l:title_start) . s:EscapePercent(l:title)
    endif

    let l:gap_left = l:title_start - l:left_width
    let l:gap_right = l:columns - l:right_width - l:title_start - l:title_width
    return l:hl . s:EscapePercent(l:left) . repeat(' ', l:gap_left)
        \ . s:EscapePercent(l:title) . repeat(' ', l:gap_right) . s:EscapePercent(l:right)
endfunction

" Window number of the sidebar in the current tab, or -1 if it is absent.
function! s:SidebarWinnr() abort
    let l:winnr = 1
    while l:winnr <= winnr('$')
        if getwinvar(l:winnr, '&filetype') ==# 'gdifftree'
            return l:winnr
        endif
        let l:winnr += 1
    endwhile
    return -1
endfunction

" Ensure the sidebar exists in the current tab and its contents are current,
" then rebalance the diff panes (winfixwidth keeps the sidebar's width).
function! s:EnsureSidebar() abort
    if s:SidebarWinnr() == -1
        call s:OpenSidebar()
    endif
    call s:Render()
    wincmd =
endfunction

function! s:OpenSidebar() abort
    let l:content_win = win_getid()

    execute 'topleft vsplit'
    if exists('s:bufnr') && bufexists(s:bufnr)
        execute 'buffer ' . s:bufnr
    else
        execute 'edit ' . fnameescape(s:bufname)
        let s:bufnr = bufnr('%')
    endif
    execute 'vertical resize ' . g:gdifftree_width

    setlocal buftype=nofile bufhidden=hide noswapfile nobuflisted
    setlocal nonumber norelativenumber nolist nowrap nospell
    setlocal signcolumn=no foldcolumn=0
    setlocal cursorline winfixwidth
    setlocal filetype=gdifftree
    call s:SetupSyntax()
    nnoremap <buffer> <silent> <CR> :call <SID>Select()<CR>
    nnoremap <buffer> <silent> o :call <SID>Select()<CR>
    nnoremap <buffer> <silent> <LeftRelease> :call <SID>Select()<CR>

    call s:Render()
    call win_gotoid(l:content_win)
    " Force the diff panes back to equal width now that the fixed-width sidebar
    " exists (winfixwidth keeps the sidebar itself out of the equalization).
    wincmd =
endfunction

function! s:SetupSyntax() abort
    syntax clear
    syntax match gdifftreeHeader /\%1l.*/
    syntax match gdifftreeDir /^.*\/$/
    syntax match gdifftreeStat / +\d\+ -\d\+$/ contains=gdifftreeAdd,gdifftreeDel
    syntax match gdifftreeAdd /+\d\+/ contained
    syntax match gdifftreeDel /-\d\+/ contained
    syntax match gdifftreeBin / bin$/
    highlight default link gdifftreeHeader Title
    highlight default link gdifftreeDir Directory
    highlight default link gdifftreeBin Comment
    highlight GDiffTreeAdd ctermfg=green guifg=#5faf5f
    highlight GDiffTreeDel ctermfg=red guifg=#d75f5f
    highlight default link gdifftreeAdd GDiffTreeAdd
    highlight default link gdifftreeDel GDiffTreeDel
endfunction

" Append tree items (each {'text', 'node', ['stat']}) for a node's children.
" Directories are listed (sorted) before files.
function! s:BuildLines(node, depth, items) abort
    let l:indent = repeat('  ', a:depth)
    for l:name in sort(keys(a:node.dirs))
        let l:child = a:node.dirs[l:name]
        let l:closed = has_key(s:collapsed, l:child.path)
        let l:marker = l:closed ? '+' : '-'
        call add(a:items, {'text': l:indent . l:marker . ' ' . l:name . '/',
            \ 'node': {'type': 'dir', 'path': l:child.path}})
        if !l:closed
            call s:BuildLines(l:child, a:depth + 1, a:items)
        endif
    endfor
    for l:name in sort(keys(a:node.files))
        let l:file_id = a:node.files[l:name]
        call add(a:items, {'text': l:indent . '  ' . l:name,
            \ 'stat': get(s:entries[l:file_id], 'stat', ''),
            \ 'node': {'type': 'file', 'id': l:file_id}})
    endfor
endfunction

" Rewrite the sidebar buffer contents. Must run with the sidebar as the current
" window; leaves the cursor untouched. Change stats are aligned into a single
" column (just past the longest file name) so they are easy to scan.
function! s:Rebuild() abort
    let s:line_to_node = {}
    let l:items = []
    call s:BuildLines(s:tree, 0, l:items)

    let l:max_name_width = 0
    let l:max_stat_width = 0
    for l:item in l:items
        if get(l:item, 'stat', '') !=# ''
            let l:max_name_width = max([l:max_name_width, strdisplaywidth(l:item.text)])
            let l:max_stat_width = max([l:max_stat_width, strdisplaywidth(l:item.stat)])
        endif
    endfor
    let l:stat_col = l:max_name_width + 2
    let l:max_stat_col = g:gdifftree_width - l:max_stat_width - 1
    if l:stat_col > l:max_stat_col | let l:stat_col = l:max_stat_col | endif
    if l:stat_col < 1 | let l:stat_col = 1 | endif

    " Line 1 is the pane title; the tree follows after a blank spacer. Both are
    " non-selectable (absent from s:line_to_node).
    let l:lines = ['gdifftree - Tabs Open', '']

    " Pinned section, above the diff tree: flat pinned entries (the commit
    " description) first, in tab order, then the pinned subtree (the collapsible
    " 'Commit Notes' folder), then a blank spacer. All stay selectable.
    let l:pinned = 0
    let l:pin_id = 0
    while l:pin_id < len(s:entries)
        if get(s:entries[l:pin_id], 'pinned', 0) && stridx(s:entries[l:pin_id].label, '/') < 0
            call add(l:lines, s:entries[l:pin_id].label)
            let s:line_to_node[len(l:lines)] = {'type': 'file', 'id': l:pin_id}
            let l:pinned += 1
        endif
        let l:pin_id += 1
    endwhile
    let l:pinned_items = []
    call s:BuildLines(s:pinned_tree, 0, l:pinned_items)
    for l:item in l:pinned_items
        call add(l:lines, l:item.text)
        let s:line_to_node[len(l:lines)] = l:item.node
        let l:pinned += 1
    endfor
    if l:pinned > 0
        call add(l:lines, '')
    endif

    for l:item in l:items
        let l:text = l:item.text
        if get(l:item, 'stat', '') !=# ''
            let l:pad = l:stat_col - strdisplaywidth(l:text)
            let l:text .= repeat(' ', l:pad > 0 ? l:pad : 1) . l:item.stat
        endif
        call add(l:lines, l:text)
        let s:line_to_node[len(l:lines)] = l:item.node
    endfor

    setlocal modifiable
    silent %delete _
    call setline(1, l:lines)
    setlocal nomodifiable
endfunction

" Refresh the sidebar in the current tab and park the cursor on the entry for
" the tab currently in view.
function! s:Render() abort
    let l:sidebar_winnr = s:SidebarWinnr()
    if l:sidebar_winnr == -1
        return
    endif

    let l:prev_win = win_getid()
    let l:current_id = gettabvar(tabpagenr(), 'gdifftree_id', -2)
    execute l:sidebar_winnr . 'wincmd w'
    call s:Rebuild()

    for l:linenr in keys(s:line_to_node)
        let l:node = s:line_to_node[l:linenr]
        if l:node.type ==# 'file' && l:node.id == l:current_id
            call cursor(str2nr(l:linenr), 1)
            break
        endif
    endfor

    call win_gotoid(l:prev_win)
endfunction

" Toggle a directory, or jump to (reopening if needed) the file under the
" cursor.
function! s:Select() abort
    let l:linenr = line('.')
    if !has_key(s:line_to_node, l:linenr)
        return
    endif

    let l:node = s:line_to_node[l:linenr]
    if l:node.type ==# 'dir'
        if has_key(s:collapsed, l:node.path)
            call remove(s:collapsed, l:node.path)
        else
            let s:collapsed[l:node.path] = 1
        endif
        call s:Rebuild()
        call cursor(l:linenr, 1)
    else
        call s:GotoOrReopen(l:node.id)
    endif
endfunction

" Switch to the tab holding entry a:id, recreating its diff tab if it was
" closed.
function! s:GotoOrReopen(id) abort
    for l:tabnr in range(1, tabpagenr('$'))
        if gettabvar(l:tabnr, 'gdifftree_id', -2) == a:id
            execute 'tabnext ' . l:tabnr
            return
        endif
    endfor

    execute '$tabnew ' . fnameescape(s:entries[a:id].file)
    call s:PrepareTab(a:id)
endfunction

" On :quit inside a diff window (not the sidebar) of a managed tab, close the
" whole tab. Deferred via a timer because a window cannot be closed from within
" QuitPre while the original :quit is still unwinding.
function! s:OnQuitPre() abort
    if !exists('t:gdifftree_id') || &filetype ==# 'gdifftree'
        return
    endif
    call add(s:pending_close, t:gdifftree_id)
    call timer_start(0, function('s:DrainClose'))
endfunction

function! s:DrainClose(timer) abort
    while !empty(s:pending_close)
        let l:target_id = remove(s:pending_close, 0)
        for l:tabnr in range(1, tabpagenr('$'))
            if gettabvar(l:tabnr, 'gdifftree_id', -2) == l:target_id
                execute l:tabnr . 'tabclose'
                break
            endif
        endfor
    endwhile
endfunction
