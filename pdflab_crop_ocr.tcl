#!/usr/bin/env wish
# PDFLab Crop & OCR
# Tcl/Tk GUI for PDF rendering, rectangular cropping, PNG export and OCR.
# Produced by Giux-Lab — https://giux-lab.it
# Copyright (C) 2026 Giuseppe Lanzani / Giux-Lab
# License: GNU General Public License v3.0 or later (GPL-3.0-or-later)

package require Tk 8.6

namespace eval ::PDFLab {
    variable pdfFile ""
    variable pageCount 0
    variable currentPage 1
    variable dpi 400
    variable zoom 50
    variable zoomLevels {25 33 50 67 75 100 125 150 200 250 300 400}
    variable panActive 0
    variable sourceWidth 0
    variable sourceHeight 0
    variable selectionAction "new"
    variable selectionHandle ""
    variable selectionDragStartSource {}
    variable selectionOriginal {}
    variable handleSize 5
    variable ocrLang "eng"
    variable psmLabel "Block"
    variable status "Ready"
    variable renderFile ""
    variable previewFile ""
    variable workDir ""
    variable pageImage ""
    variable selRect ""
    variable dragStartX 0
    variable dragStartY 0
    variable selSource {}
    variable cropCounter 1
    variable inputDir "/home/giu/pdf-lab/Input_Originali"
    variable tempRoot "/home/giu/pdf-lab/Lavoro_Temporaneo_PDF"
    variable resultsDir "/home/giu/pdf-lab/Risultati"
    variable lastOcrText ""

    # Built-in defaults and persistent per-user configuration.
    variable builtinInputDir "/home/giu/pdf-lab/Input_Originali"
    variable builtinTempRoot "/home/giu/pdf-lab/Lavoro_Temporaneo_PDF"
    variable builtinResultsDir "/home/giu/pdf-lab/Risultati"
    variable builtinDpi 400
    variable builtinZoom 50
    variable builtinOcrLang "eng"
    variable builtinPsmLabel "Block"
    variable configFile [file join [file normalize ~] .config giux-lab pdflab-crop-ocr.conf]

    # Temporary variables used by the Preferences dialog.
    variable prefInputDir ""
    variable prefTempRoot ""
    variable prefResultsDir ""
    variable prefDpi 400
    variable prefZoom 50
    variable prefOcrLang "eng"
    variable prefPsmLabel "Block"
}

proc ::PDFLab::loadSettings {} {
    variable configFile
    variable inputDir
    variable tempRoot
    variable resultsDir
    variable dpi
    variable zoom
    variable ocrLang
    variable psmLabel

    if {![file exists $configFile]} { return }
    if {[catch {set ch [open $configFile r]}]} { return }
    fconfigure $ch -encoding utf-8 -translation lf
    while {[gets $ch line] >= 0} {
        if {[string trim $line] eq ""} { continue }
        if {[catch {lassign $line key value}]} { continue }
        switch -- $key {
            inputDir   { set inputDir $value }
            tempRoot   { set tempRoot $value }
            resultsDir { set resultsDir $value }
            dpi        { if {$value in {150 200 300 400 600}} { set dpi $value } }
            zoom       { if {$value in {25 33 50 67 75 100 125 150 200 250 300 400}} { set zoom $value } }
            ocrLang    { if {$value in {eng chi_sim+eng chi_tra+eng}} { set ocrLang $value } }
            psmLabel   { if {$value in {Auto Block {Single line} {Sparse text}}} { set psmLabel $value } }
        }
    }
    close $ch
}

proc ::PDFLab::saveSettings {} {
    variable configFile
    variable inputDir
    variable tempRoot
    variable resultsDir
    variable dpi
    variable zoom
    variable ocrLang
    variable psmLabel

    set cfgDir [file dirname $configFile]
    if {![file isdirectory $cfgDir]} { file mkdir $cfgDir }
    if {[catch {set ch [open $configFile w]} err]} {
        tk_messageBox -icon error -title "Settings error" -message "Cannot save settings:\n$err"
        return 0
    }
    fconfigure $ch -encoding utf-8 -translation lf
    puts $ch [list inputDir $inputDir]
    puts $ch [list tempRoot $tempRoot]
    puts $ch [list resultsDir $resultsDir]
    puts $ch [list dpi $dpi]
    puts $ch [list zoom $zoom]
    puts $ch [list ocrLang $ocrLang]
    puts $ch [list psmLabel $psmLabel]
    close $ch
    return 1
}

proc ::PDFLab::preferencesBrowse {which} {
    variable prefInputDir
    variable prefTempRoot
    variable prefResultsDir
    switch -- $which {
        input { set current $prefInputDir }
        temp  { set current $prefTempRoot }
        output { set current $prefResultsDir }
        default { return }
    }
    set initial [expr {[file isdirectory $current] ? $current : [pwd]}]
    set d [tk_chooseDirectory -title "Select directory" -initialdir $initial -mustexist 1]
    if {$d eq ""} { return }
    switch -- $which {
        input  { set prefInputDir [file normalize $d] }
        temp   { set prefTempRoot [file normalize $d] }
        output { set prefResultsDir [file normalize $d] }
    }
}

proc ::PDFLab::resetPreferenceFields {} {
    variable builtinInputDir
    variable builtinTempRoot
    variable builtinResultsDir
    variable builtinDpi
    variable builtinZoom
    variable builtinOcrLang
    variable builtinPsmLabel
    variable prefInputDir
    variable prefTempRoot
    variable prefResultsDir
    variable prefDpi
    variable prefZoom
    variable prefOcrLang
    variable prefPsmLabel

    set prefInputDir $builtinInputDir
    set prefTempRoot $builtinTempRoot
    set prefResultsDir $builtinResultsDir
    set prefDpi $builtinDpi
    set prefZoom $builtinZoom
    set prefOcrLang $builtinOcrLang
    set prefPsmLabel $builtinPsmLabel
}

proc ::PDFLab::applyPreferences {} {
    variable prefInputDir
    variable prefTempRoot
    variable prefResultsDir
    variable prefDpi
    variable prefZoom
    variable prefOcrLang
    variable prefPsmLabel
    variable inputDir
    variable tempRoot
    variable resultsDir
    variable dpi
    variable zoom
    variable ocrLang
    variable psmLabel

    if {![file isdirectory $prefInputDir]} {
        tk_messageBox -icon error -title "Invalid directory" -message "The PDF input directory does not exist."
        return
    }
    foreach d [list $prefTempRoot $prefResultsDir] {
        if {![file isdirectory $d]} {
            if {[catch {file mkdir $d} err]} {
                tk_messageBox -icon error -title "Directory error" -message "Cannot create directory:\n$d\n\n$err"
                return
            }
        }
    }
    set inputDir [file normalize $prefInputDir]
    set tempRoot [file normalize $prefTempRoot]
    set resultsDir [file normalize $prefResultsDir]
    set dpi $prefDpi
    set zoom $prefZoom
    set ocrLang $prefOcrLang
    set psmLabel $prefPsmLabel
    if {[saveSettings]} {
        destroy .prefs
        setStatus "Settings saved"
    }
}

proc ::PDFLab::showPreferences {} {
    variable inputDir
    variable tempRoot
    variable resultsDir
    variable dpi
    variable zoom
    variable ocrLang
    variable psmLabel
    variable prefInputDir
    variable prefTempRoot
    variable prefResultsDir
    variable prefDpi
    variable prefZoom
    variable prefOcrLang
    variable prefPsmLabel

    if {[winfo exists .prefs]} { raise .prefs; focus .prefs; return }
    set prefInputDir $inputDir
    set prefTempRoot $tempRoot
    set prefResultsDir $resultsDir
    set prefDpi $dpi
    set prefZoom $zoom
    set prefOcrLang $ocrLang
    set prefPsmLabel $psmLabel

    toplevel .prefs
    wm title .prefs "Preferences"
    wm resizable .prefs 1 0
    wm transient .prefs .

    ttk::frame .prefs.body -padding 12
    pack .prefs.body -fill both -expand 1

    ttk::labelframe .prefs.body.dirs -text "Default directories" -padding 10
    pack .prefs.body.dirs -fill x -pady {0 10}
    grid columnconfigure .prefs.body.dirs 1 -weight 1

    ttk::label .prefs.body.dirs.li -text "PDF input directory:"
    ttk::entry .prefs.body.dirs.ei -textvariable ::PDFLab::prefInputDir -width 70
    ttk::button .prefs.body.dirs.bi -text "Browse…" -command {::PDFLab::preferencesBrowse input}
    ttk::label .prefs.body.dirs.lo -text "Images / text output directory:"
    ttk::entry .prefs.body.dirs.eo -textvariable ::PDFLab::prefResultsDir -width 70
    ttk::button .prefs.body.dirs.bo -text "Browse…" -command {::PDFLab::preferencesBrowse output}
    ttk::label .prefs.body.dirs.lt -text "Temporary working directory:"
    ttk::entry .prefs.body.dirs.et -textvariable ::PDFLab::prefTempRoot -width 70
    ttk::button .prefs.body.dirs.bt -text "Browse…" -command {::PDFLab::preferencesBrowse temp}

    grid .prefs.body.dirs.li -row 0 -column 0 -sticky w -padx {0 8} -pady 4
    grid .prefs.body.dirs.ei -row 0 -column 1 -sticky ew -pady 4
    grid .prefs.body.dirs.bi -row 0 -column 2 -padx {8 0} -pady 4
    grid .prefs.body.dirs.lo -row 1 -column 0 -sticky w -padx {0 8} -pady 4
    grid .prefs.body.dirs.eo -row 1 -column 1 -sticky ew -pady 4
    grid .prefs.body.dirs.bo -row 1 -column 2 -padx {8 0} -pady 4
    grid .prefs.body.dirs.lt -row 2 -column 0 -sticky w -padx {0 8} -pady 4
    grid .prefs.body.dirs.et -row 2 -column 1 -sticky ew -pady 4
    grid .prefs.body.dirs.bt -row 2 -column 2 -padx {8 0} -pady 4

    ttk::labelframe .prefs.body.defaults -text "Startup defaults" -padding 10
    pack .prefs.body.defaults -fill x
    ttk::label .prefs.body.defaults.ld -text "Render DPI:"
    ttk::combobox .prefs.body.defaults.dpi -state readonly -width 8 -values {150 200 300 400 600} -textvariable ::PDFLab::prefDpi
    ttk::label .prefs.body.defaults.lz -text "Preview zoom:"
    ttk::combobox .prefs.body.defaults.zoom -state readonly -width 8 -values {25 33 50 67 75 100 125 150 200 250 300 400} -textvariable ::PDFLab::prefZoom
    ttk::label .prefs.body.defaults.ll -text "OCR language:"
    ttk::combobox .prefs.body.defaults.lang -state readonly -width 18 -values {eng chi_sim+eng chi_tra+eng} -textvariable ::PDFLab::prefOcrLang
    ttk::label .prefs.body.defaults.lp -text "OCR layout:"
    ttk::combobox .prefs.body.defaults.psm -state readonly -width 16 -values {Auto Block {Single line} {Sparse text}} -textvariable ::PDFLab::prefPsmLabel
    grid .prefs.body.defaults.ld -row 0 -column 0 -sticky w -padx {0 8} -pady 4
    grid .prefs.body.defaults.dpi -row 0 -column 1 -sticky w -pady 4
    grid .prefs.body.defaults.lz -row 0 -column 2 -sticky w -padx {20 8} -pady 4
    grid .prefs.body.defaults.zoom -row 0 -column 3 -sticky w -pady 4
    grid .prefs.body.defaults.ll -row 1 -column 0 -sticky w -padx {0 8} -pady 4
    grid .prefs.body.defaults.lang -row 1 -column 1 -sticky w -pady 4
    grid .prefs.body.defaults.lp -row 1 -column 2 -sticky w -padx {20 8} -pady 4
    grid .prefs.body.defaults.psm -row 1 -column 3 -sticky w -pady 4

    ttk::frame .prefs.buttons
    pack .prefs.buttons -fill x -pady {12 0}
    ttk::button .prefs.buttons.reset -text "Restore built-in defaults" -command ::PDFLab::resetPreferenceFields
    ttk::button .prefs.buttons.cancel -text "Cancel" -command {destroy .prefs}
    ttk::button .prefs.buttons.save -text "Save" -command ::PDFLab::applyPreferences
    pack .prefs.buttons.reset -side left
    pack .prefs.buttons.save .prefs.buttons.cancel -side right -padx {8 0}
}

proc ::PDFLab::showTextWindow {name title content} {
    if {[winfo exists $name]} { destroy $name }
    toplevel $name
    wm title $name $title
    wm geometry $name 760x620
    ttk::frame $name.f -padding 10
    pack $name.f -fill both -expand 1
    text $name.f.t -wrap word -padx 8 -pady 8
    ttk::scrollbar $name.f.s -orient vertical -command [list $name.f.t yview]
    $name.f.t configure -yscrollcommand [list $name.f.s set]
    pack $name.f.s -side right -fill y
    pack $name.f.t -side left -fill both -expand 1
    $name.f.t insert end $content
    $name.f.t configure -state disabled
}

proc ::PDFLab::showGuide {} {
    set txt {PDFLab Crop & OCR — Quick Guide

Produced by Giux-Lab — https://giux-lab.it

Purpose
PDFLab Crop & OCR is a Tcl/Tk utility for opening PDF documents, rendering pages at high resolution, selecting rectangular areas, exporting figures as PNG images, and running OCR on selected text areas or on the whole PDF.

Basic workflow
1. Open a PDF with File > Open PDF.
2. Choose the page and render resolution (DPI).
3. Use the mouse wheel to zoom around the pointer.
4. Use the arrow keys or drag with the middle mouse button to pan.
5. Drag with the left mouse button to create a selection.
6. Drag inside the selection to move it, or use the eight handles to resize it.
7. Use Export PNG for figures/graphs, OCR Selection for text, or PNG + OCR TXT to save both.

OCR
Use "eng" for English documents, "chi_sim+eng" for Simplified Chinese + English, and "chi_tra+eng" for Traditional Chinese + English. OCR layout modes are Auto, Block, Single line, and Sparse text.

Directories and defaults
Open Settings > Preferences to choose the default PDF input directory, the output directory for images/text/PDF OCR results, the temporary working directory, render DPI, preview zoom, OCR language, and OCR layout. Settings are stored per user and restored at the next start.

Important
The original PDF is never modified. Rendering, temporary crops, and OCR intermediates are produced in the configured temporary working directory. High-resolution exports use the source raster coordinates, so preview zoom does not reduce export quality.

License
GNU General Public License v3.0 or later (GPL-3.0-or-later). See Help > License for the license notice.}
    showTextWindow .guide "PDFLab Crop & OCR — Quick Guide" $txt
}

proc ::PDFLab::showLicense {} {
    set txt {PDFLab Crop & OCR
Produced by Giux-Lab — https://giux-lab.it
Copyright (C) 2026 Giuseppe Lanzani / Giux-Lab

License: GNU General Public License v3.0 or later (GPL-3.0-or-later)

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

A copy of the GNU GPL v3 should be distributed with the software. The complete license text is available from the Free Software Foundation at https://www.gnu.org/licenses/gpl-3.0.html .}
    showTextWindow .license "License" $txt
}

proc ::PDFLab::showAbout {} {
    tk_messageBox -icon info -title "About PDFLab Crop & OCR" -message \
        "PDFLab Crop & OCR\n\nProduced by Giux-Lab\nhttps://giux-lab.it\n\nCopyright © 2026 Giuseppe Lanzani / Giux-Lab\nGNU GPL v3.0 or later"
}

proc ::PDFLab::haveCommand {name} {
    expr {[auto_execok $name] ne ""}
}

proc ::PDFLab::checkDependencies {} {
    set missing {}
    foreach cmd {pdfinfo pdftoppm magick tesseract ocrmypdf qpdf} {
        if {![haveCommand $cmd]} { lappend missing $cmd }
    }
    if {[llength $missing]} {
        tk_messageBox -icon error -title "Missing dependencies" \
            -message "The following programs are missing:\n[join $missing {, }]"
        return 0
    }
    return 1
}

proc ::PDFLab::safeBaseName {path} {
    set s [file rootname [file tail $path]]
    regsub -all {[^[:alnum:]_.-]+} $s {_} s
    if {$s eq ""} { set s "document" }
    return $s
}

proc ::PDFLab::makeWorkDir {} {
    variable tempRoot
    variable pdfFile
    variable workDir
    if {![file isdirectory $tempRoot]} {
        file mkdir $tempRoot
    }
    set base [safeBaseName $pdfFile]
    set stamp [clock format [clock seconds] -format "%Y%m%d-%H%M%S"]
    set workDir [file join $tempRoot "${base}-${stamp}-[pid]"]
    file mkdir $workDir
}

proc ::PDFLab::setStatus {msg} {
    variable status
    set status $msg
    update idletasks
}

proc ::PDFLab::openPdf {} {
    variable inputDir
    variable pdfFile
    variable pageCount
    variable currentPage
    variable cropCounter
    variable selSource

    set initial [expr {[file isdirectory $inputDir] ? $inputDir : [pwd]}]
    set f [tk_getOpenFile -title "Open PDF" -initialdir $initial \
        -filetypes {{{PDF} {.pdf}} {{Tutti i file} *}}]
    if {$f eq ""} { return }

    setStatus "Reading PDF information..."
    if {[catch {exec pdfinfo -- $f 2>@1} info]} {
        tk_messageBox -icon error -title "PDF error" -message $info
        setStatus "Error"
        return
    }
    if {![regexp -line {^Pages:[[:space:]]+([0-9]+)} $info -> n]} {
        tk_messageBox -icon error -title "PDF error" -message "Cannot determine the number of pages."
        setStatus "Error"
        return
    }

    set pdfFile [file normalize $f]
    set pageCount $n
    set currentPage 1
    set cropCounter 1
    set selSource {}
    makeWorkDir

    .top.file configure -text [file tail $pdfFile]
    .top.pages configure -text "/ $pageCount"
    renderPage
}

proc ::PDFLab::renderPage {} {
    variable pdfFile
    variable pageCount
    variable currentPage
    variable dpi
    variable workDir
    variable renderFile
    variable selSource

    if {$pdfFile eq ""} { return }
    if {$currentPage < 1} { set currentPage 1 }
    if {$currentPage > $pageCount} { set currentPage $pageCount }
    if {$dpi ni {150 200 300 400 600}} { set dpi 400 }
    if {$workDir eq "" || ![file isdirectory $workDir]} { makeWorkDir }

    set base [file join $workDir [format "page-%04d-%ddpi" $currentPage $dpi]]
    set renderFile "${base}.png"
    setStatus "Rendering page $currentPage at $dpi dpi..."

    if {[catch {
        exec pdftoppm -f $currentPage -l $currentPage -singlefile -png -r $dpi -- $pdfFile $base 2>@1
    } err]} {
        tk_messageBox -icon error -title "Rendering error" -message $err
        setStatus "Rendering error"
        return
    }

    set selSource {}
    # Memorizza le dimensioni della rasterizzazione sorgente per evitare
    # di ricaricare il PNG completo durante trascinamenti e ridimensionamenti.
    variable sourceWidth
    variable sourceHeight
    if {[catch {exec magick identify -format {%w %h} -- $renderFile 2>@1} dims] ||
        ![regexp {^([0-9]+)[[:space:]]+([0-9]+)$} [string trim $dims] -> sourceWidth sourceHeight]} {
        set sourceWidth 0
        set sourceHeight 0
    }
    updatePreview
    setStatus "Page $currentPage / $pageCount ready"
}

proc ::PDFLab::updatePreview {{anchor {}}} {
    variable renderFile
    variable previewFile
    variable zoom
    variable zoomLevels
    variable workDir
    variable pageImage
    variable currentPage
    variable dpi

    if {$renderFile eq "" || ![file exists $renderFile]} { return }
    if {[lsearch -exact $zoomLevels $zoom] < 0} { set zoom 50 }

    if {$zoom == 100} {
        set previewFile $renderFile
    } else {
        # Cache deterministica: evita di rieseguire ImageMagick tornando a uno zoom gia' usato.
        set previewFile [file join $workDir [format "preview-p%04d-%ddpi-z%d.png" $currentPage $dpi $zoom]]
        if {![file exists $previewFile]} {
            setStatus "Creating ${zoom}% preview..."
            if {[catch {exec magick $renderFile -resize "${zoom}%" $previewFile 2>@1} err]} {
                tk_messageBox -icon error -title "Preview error" -message $err
                return
            }
        }
    }

    if {$pageImage ne ""} {
        catch {image delete $pageImage}
    }
    set pageImage [image create photo -file $previewFile]
    .view.c delete all
    .view.c create image 0 0 -anchor nw -image $pageImage -tags page
    set pw [image width $pageImage]
    set ph [image height $pageImage]
    .view.c configure -scrollregion [list 0 0 $pw $ph]

    # Se lo zoom proviene dalla rotella, mantieni sotto il puntatore lo stesso
    # punto della pagina sorgente.
    if {[llength $anchor] == 4} {
        lassign $anchor sx sy wx wy
        lassign [sourceToPreview $sx $sy] px py
        set left [expr {$px - $wx}]
        set top  [expr {$py - $wy}]
        if {$pw > 0} { .view.c xview moveto [expr {max(0.0, $left / double($pw))}] }
        if {$ph > 0} { .view.c yview moveto [expr {max(0.0, $top  / double($ph))}] }
    } else {
        .view.c xview moveto 0
        .view.c yview moveto 0
    }

    redrawSelection
    updateSelectionInfo
    setStatus "Preview ${zoom}%"
}

proc ::PDFLab::sourceSize {} {
    variable renderFile
    variable sourceWidth
    variable sourceHeight
    if {$sourceWidth > 0 && $sourceHeight > 0} {
        return [list $sourceWidth $sourceHeight]
    }
    if {$renderFile eq "" || ![file exists $renderFile]} { return {0 0} }
    if {![catch {exec magick identify -format {%w %h} -- $renderFile 2>@1} dims] &&
        [regexp {^([0-9]+)[[:space:]]+([0-9]+)$} [string trim $dims] -> w h]} {
        set sourceWidth $w
        set sourceHeight $h
        return [list $w $h]
    }
    return {0 0}
}

proc ::PDFLab::previewToSource {x y} {
    variable pageImage
    lassign [sourceSize] sw sh
    if {$pageImage eq "" || $sw == 0 || $sh == 0} { return [list 0 0] }
    set pw [image width $pageImage]
    set ph [image height $pageImage]
    set sx [expr {int(round($x * double($sw) / $pw))}]
    set sy [expr {int(round($y * double($sh) / $ph))}]
    set sx [expr {max(0, min($sw, $sx))}]
    set sy [expr {max(0, min($sh, $sy))}]
    return [list $sx $sy]
}

proc ::PDFLab::sourceToPreview {x y} {
    variable pageImage
    lassign [sourceSize] sw sh
    if {$pageImage eq "" || $sw == 0 || $sh == 0} { return [list 0 0] }
    set pw [image width $pageImage]
    set ph [image height $pageImage]
    set px [expr {$x * double($pw) / $sw}]
    set py [expr {$y * double($ph) / $sh}]
    return [list $px $py]
}

proc ::PDFLab::wheelZoom {direction x y} {
    variable zoom
    variable zoomLevels
    variable pageImage

    if {$pageImage eq ""} { return }
    set cx [.view.c canvasx $x]
    set cy [.view.c canvasy $y]
    lassign [previewToSource $cx $cy] sx sy

    set idx [lsearch -exact $zoomLevels $zoom]
    if {$idx < 0} { set idx [lsearch -exact $zoomLevels 50] }
    set newIdx [expr {$idx + ($direction > 0 ? 1 : -1)}]
    set newIdx [expr {max(0, min([llength $zoomLevels]-1, $newIdx))}]
    if {$newIdx == $idx} { return }

    set zoom [lindex $zoomLevels $newIdx]
    updatePreview [list $sx $sy $x $y]
}

proc ::PDFLab::mouseWheel {delta x y} {
    if {$delta == 0} { return }
    wheelZoom [expr {$delta > 0 ? 1 : -1}] $x $y
}

proc ::PDFLab::panStart {x y} {
    variable panActive
    set panActive 1
    focus .view.c
    .view.c configure -cursor fleur
    .view.c scan mark $x $y
}

proc ::PDFLab::panDrag {x y} {
    variable panActive
    if {!$panActive} { return }
    # Gain 1: movimento naturale 1:1, piu' controllabile di quello predefinito.
    .view.c scan dragto $x $y 1
}

proc ::PDFLab::panEnd {} {
    variable panActive
    set panActive 0
    .view.c configure -cursor crosshair
}

proc ::PDFLab::keyPan {dx dy} {
    if {$dx != 0} { .view.c xview scroll $dx units }
    if {$dy != 0} { .view.c yview scroll $dy units }
}

proc ::PDFLab::selectionPreviewBox {} {
    variable selSource
    if {[llength $selSource] != 4} { return {} }
    lassign $selSource sx1 sy1 sx2 sy2
    lassign [sourceToPreview $sx1 $sy1] x1 y1
    lassign [sourceToPreview $sx2 $sy2] x2 y2
    return [list $x1 $y1 $x2 $y2]
}

proc ::PDFLab::hitTestSelection {x y} {
    variable selSource
    variable handleSize
    if {[llength $selSource] != 4} { return "new" }
    lassign [selectionPreviewBox] x1 y1 x2 y2
    set hs [expr {$handleSize + 3}]
    set xm [expr {($x1+$x2)/2.0}]
    set ym [expr {($y1+$y2)/2.0}]
    foreach {name hx hy} [list \
        nw $x1 $y1 n $xm $y1 ne $x2 $y1 \
        e $x2 $ym se $x2 $y2 s $xm $y2 \
        sw $x1 $y2 w $x1 $ym] {
        if {abs($x-$hx) <= $hs && abs($y-$hy) <= $hs} { return $name }
    }
    if {$x >= $x1 && $x <= $x2 && $y >= $y1 && $y <= $y2} { return "move" }
    return "new"
}

proc ::PDFLab::selectionCursor {action} {
    switch -- $action {
        nw { return "top_left_corner" }
        se { return "bottom_right_corner" }
        ne { return "top_right_corner" }
        sw { return "bottom_left_corner" }
        n - s   { return "sb_v_double_arrow" }
        e - w   { return "sb_h_double_arrow" }
        move    { return "fleur" }
        default { return "crosshair" }
    }
}

proc ::PDFLab::selectionMotion {x y} {
    variable panActive
    if {$panActive} { return }
    set cx [.view.c canvasx $x]
    set cy [.view.c canvasy $y]
    .view.c configure -cursor [selectionCursor [hitTestSelection $cx $cy]]
}

proc ::PDFLab::mouseDown {x y} {
    focus .view.c
    variable dragStartX
    variable dragStartY
    variable selSource
    variable selectionAction
    variable selectionHandle
    variable selectionDragStartSource
    variable selectionOriginal

    set cx [.view.c canvasx $x]
    set cy [.view.c canvasy $y]
    set dragStartX $cx
    set dragStartY $cy
    lassign [previewToSource $cx $cy] sx sy
    set selectionDragStartSource [list $sx $sy]
    set selectionOriginal $selSource

    set hit [hitTestSelection $cx $cy]
    if {$hit eq "new"} {
        set selectionAction "new"
        set selectionHandle ""
        set selSource [list $sx $sy $sx $sy]
    } elseif {$hit eq "move"} {
        set selectionAction "move"
        set selectionHandle ""
    } else {
        set selectionAction "resize"
        set selectionHandle $hit
    }
    redrawSelection
}

proc ::PDFLab::mouseDrag {x y} {
    variable selSource
    variable selectionAction
    variable selectionHandle
    variable selectionDragStartSource
    variable selectionOriginal

    set cx [.view.c canvasx $x]
    set cy [.view.c canvasy $y]
    lassign [previewToSource $cx $cy] sx sy
    lassign [sourceSize] sw sh

    if {$selectionAction eq "new"} {
        lassign $selectionDragStartSource x0 y0
        set x1 [expr {min($x0,$sx)}]
        set y1 [expr {min($y0,$sy)}]
        set x2 [expr {max($x0,$sx)}]
        set y2 [expr {max($y0,$sy)}]
        set selSource [list $x1 $y1 $x2 $y2]
    } elseif {$selectionAction eq "move" && [llength $selectionOriginal] == 4} {
        lassign $selectionDragStartSource dsx dsy
        lassign $selectionOriginal ox1 oy1 ox2 oy2
        set dx [expr {$sx-$dsx}]
        set dy [expr {$sy-$dsy}]
        set w [expr {$ox2-$ox1}]
        set h [expr {$oy2-$oy1}]
        set nx1 [expr {max(0,min($sw-$w,$ox1+$dx))}]
        set ny1 [expr {max(0,min($sh-$h,$oy1+$dy))}]
        set selSource [list $nx1 $ny1 [expr {$nx1+$w}] [expr {$ny1+$h}]]
    } elseif {$selectionAction eq "resize" && [llength $selectionOriginal] == 4} {
        lassign $selectionOriginal x1 y1 x2 y2
        switch -- $selectionHandle {
            nw { set x1 $sx; set y1 $sy }
            n  { set y1 $sy }
            ne { set x2 $sx; set y1 $sy }
            e  { set x2 $sx }
            se { set x2 $sx; set y2 $sy }
            s  { set y2 $sy }
            sw { set x1 $sx; set y2 $sy }
            w  { set x1 $sx }
        }
        set x1 [expr {max(0,min($sw,$x1))}]
        set x2 [expr {max(0,min($sw,$x2))}]
        set y1 [expr {max(0,min($sh,$y1))}]
        set y2 [expr {max(0,min($sh,$y2))}]
        if {$x1 > $x2} { set t $x1; set x1 $x2; set x2 $t }
        if {$y1 > $y2} { set t $y1; set y1 $y2; set y2 $t }
        set selSource [list $x1 $y1 $x2 $y2]
    }
    redrawSelection
    updateSelectionInfo
}

proc ::PDFLab::mouseUp {x y} {
    variable selSource
    variable selectionAction
    variable selectionHandle
    variable selectionOriginal

    if {[llength $selSource] != 4} { return }
    lassign $selSource x1 y1 x2 y2
    if {$x2-$x1 < 3 || $y2-$y1 < 3} {
        if {$selectionAction eq "new"} {
            clearSelection
        } else {
            set selSource $selectionOriginal
            redrawSelection
            updateSelectionInfo
        }
    }
    set selectionAction "new"
    set selectionHandle ""
    set selectionOriginal {}
    selectionMotion $x $y
}

proc ::PDFLab::redrawSelection {} {
    variable selSource
    variable selRect
    variable handleSize
    .view.c delete selection_overlay
    set selRect ""
    if {[llength $selSource] != 4} { return }
    lassign [selectionPreviewBox] x1 y1 x2 y2
    set selRect [.view.c create rectangle $x1 $y1 $x2 $y2 \
        -width 2 -dash {6 4} -outline red -tags {selection_overlay selection_rect}]

    set xm [expr {($x1+$x2)/2.0}]
    set ym [expr {($y1+$y2)/2.0}]
    set hs $handleSize
    foreach {name hx hy} [list \
        nw $x1 $y1 n $xm $y1 ne $x2 $y1 \
        e $x2 $ym se $x2 $y2 s $xm $y2 \
        sw $x1 $y2 w $x1 $ym] {
        .view.c create rectangle [expr {$hx-$hs}] [expr {$hy-$hs}] \
            [expr {$hx+$hs}] [expr {$hy+$hs}] \
            -fill white -outline red -width 1 \
            -tags [list selection_overlay selection_handle "handle_$name"]
    }
    .view.c raise selection_overlay
}

proc ::PDFLab::clearSelection {} {
    variable selSource
    variable selRect
    variable selectionAction
    variable selectionHandle
    variable selectionOriginal
    set selSource {}
    set selRect ""
    set selectionAction "new"
    set selectionHandle ""
    set selectionOriginal {}
    .view.c delete selection_overlay
    .view.c configure -cursor crosshair
    updateSelectionInfo
}

proc ::PDFLab::selectionGeometry {} {
    variable selSource
    if {[llength $selSource] != 4} { return "" }
    lassign $selSource x1 y1 x2 y2
    set w [expr {$x2 - $x1}]
    set h [expr {$y2 - $y1}]
    if {$w < 1 || $h < 1} { return "" }
    return [list $x1 $y1 $w $h]
}

proc ::PDFLab::updateSelectionInfo {} {
    variable selSource
    variable dpi
    if {[llength $selSource] != 4} {
        .sel.info configure -text "No selection"
        return
    }
    lassign $selSource x1 y1 x2 y2
    set w [expr {$x2-$x1}]
    set h [expr {$y2-$y1}]
    set mmw [expr {$w / double($dpi) * 25.4}]
    set mmh [expr {$h / double($dpi) * 25.4}]
    .sel.info configure -text [format "%d × %d px  (%.1f × %.1f mm @ %d dpi)" $w $h $mmw $mmh $dpi]
}

proc ::PDFLab::defaultCropName {} {
    variable pdfFile
    variable currentPage
    variable cropCounter
    set base [safeBaseName $pdfFile]
    return [format "%s_p%03d_crop%02d.png" $base $currentPage $cropCounter]
}

proc ::PDFLab::makeCrop {outPath} {
    variable renderFile
    set geom [selectionGeometry]
    if {$geom eq ""} {
        tk_messageBox -icon warning -title "No selection" -message "Drag a rectangle on the page."
        return 0
    }
    lassign $geom x y w h
    set cropSpec "${w}x${h}+${x}+${y}"
    if {[catch {exec magick $renderFile -crop $cropSpec +repage $outPath 2>@1} err]} {
        tk_messageBox -icon error -title "Crop error" -message $err
        return 0
    }
    return 1
}

proc ::PDFLab::exportCrop {} {
    variable resultsDir
    variable cropCounter
    set initial [expr {[file isdirectory $resultsDir] ? $resultsDir : [pwd]}]
    set out [tk_getSaveFile -title "Export PNG crop" -initialdir $initial \
        -initialfile [defaultCropName] -defaultextension .png \
        -filetypes {{{PNG} {.png}}}]
    if {$out eq ""} { return }
    setStatus "Exporting crop..."
    if {[makeCrop $out]} {
        incr cropCounter
        setStatus "Saved: [file tail $out]"
    }
}

proc ::PDFLab::psmValue {} {
    variable psmLabel
    switch -- $psmLabel {
        "Auto" { return 3 }
        "Block" { return 6 }
        "Single line" { return 7 }
        "Sparse text" { return 11 }
        default { return 6 }
    }
}

proc ::PDFLab::ocrSelection {} {
    variable workDir
    variable ocrLang
    variable lastOcrText
    if {[selectionGeometry] eq ""} {
        tk_messageBox -icon warning -title "No selection" -message "Drag a rectangle on the page."
        return
    }
    set tmp [file join $workDir "ocr-crop-[clock clicks].png"]
    if {![makeCrop $tmp]} { return }
    set psm [psmValue]
    setStatus "OCR selection ($ocrLang, PSM $psm)..."
    if {[catch {exec tesseract $tmp stdout -l $ocrLang --psm $psm 2>@1} txt]} {
        tk_messageBox -icon error -title "OCR error" -message $txt
        setStatus "OCR error"
        return
    }
    set lastOcrText [string trim $txt]
    .ocr.txt delete 1.0 end
    .ocr.txt insert end $lastOcrText
    setStatus "OCR completed"
}

proc ::PDFLab::exportCropAndOcr {} {
    variable resultsDir
    variable cropCounter
    variable ocrLang
    variable lastOcrText

    if {[selectionGeometry] eq ""} {
        tk_messageBox -icon warning -title "No selection" -message "Drag a rectangle on the page."
        return
    }

    set initial [expr {[file isdirectory $resultsDir] ? $resultsDir : [pwd]}]
    set png [tk_getSaveFile -title "Export image + OCR" -initialdir $initial \
        -initialfile [defaultCropName] -defaultextension .png \
        -filetypes {{{PNG} {.png}}}]
    if {$png eq ""} { return }

    if {![makeCrop $png]} { return }
    set psm [psmValue]
    setStatus "Running OCR and export..."
    if {[catch {exec tesseract $png stdout -l $ocrLang --psm $psm 2>@1} txt]} {
        tk_messageBox -icon error -title "OCR error" -message $txt
        return
    }
    set lastOcrText [string trim $txt]
    set txtPath "[file rootname $png].txt"
    set ch [open $txtPath w]
    fconfigure $ch -encoding utf-8 -translation lf
    puts $ch $lastOcrText
    close $ch

    .ocr.txt delete 1.0 end
    .ocr.txt insert end $lastOcrText
    incr cropCounter
    setStatus "Saved [file tail $png] and [file tail $txtPath]"
}

proc ::PDFLab::saveOcrText {} {
    variable resultsDir
    variable lastOcrText
    if {[string trim $lastOcrText] eq ""} {
        tk_messageBox -icon info -title "OCR" -message "There is no OCR text to save yet."
        return
    }
    set initial [expr {[file isdirectory $resultsDir] ? $resultsDir : [pwd]}]
    set out [tk_getSaveFile -title "Save OCR text" -initialdir $initial \
        -defaultextension .txt -filetypes {{{UTF-8 text} {.txt}}}]
    if {$out eq ""} { return }
    set ch [open $out w]
    fconfigure $ch -encoding utf-8 -translation lf
    puts $ch $lastOcrText
    close $ch
    setStatus "OCR text saved"
}

proc ::PDFLab::copyOcrText {} {
    variable lastOcrText
    clipboard clear
    clipboard append $lastOcrText
    setStatus "OCR text copied to clipboard"
}

proc ::PDFLab::ocrWholePdf {} {
    variable pdfFile
    variable resultsDir
    variable ocrLang
    if {$pdfFile eq ""} { return }
    set initial [expr {[file isdirectory $resultsDir] ? $resultsDir : [pwd]}]
    set name "[safeBaseName $pdfFile]-ocr.pdf"
    set out [tk_getSaveFile -title "Create OCR PDF" -initialdir $initial \
        -initialfile $name -defaultextension .pdf -filetypes {{{PDF} {.pdf}}}]
    if {$out eq ""} { return }
    setStatus "Running OCR on the whole PDF..."
    if {[catch {
        exec ocrmypdf -l $ocrLang --deskew --rotate-pages -- $pdfFile $out 2>@1
    } err]} {
        tk_messageBox -icon error -title "OCRmyPDF error" -message $err
        setStatus "OCR PDF error"
        return
    }
    if {[catch {exec qpdf --check -- $out 2>@1} check]} {
        tk_messageBox -icon warning -title "PDF created, verification failed" -message $check
    }
    setStatus "OCR PDF created: [file tail $out]"
}

proc ::PDFLab::prevPage {} {
    variable currentPage
    if {$currentPage > 1} { incr currentPage -1; renderPage }
}

proc ::PDFLab::nextPage {} {
    variable currentPage
    variable pageCount
    if {$currentPage < $pageCount} { incr currentPage; renderPage }
}

proc ::PDFLab::buildUi {} {
    variable currentPage
    variable dpi
    variable zoom
    variable zoomLevels
    variable ocrLang
    variable psmLabel
    variable status

    wm title . "PDFLab Crop & OCR — Giux-Lab"
    wm geometry . 1280x850
    wm minsize . 900 600

    menu .menubar
    . configure -menu .menubar
    menu .menubar.file -tearoff 0
    .menubar add cascade -label "File" -menu .menubar.file
    .menubar.file add command -label "Open PDF…" -accelerator "Ctrl+O" -command ::PDFLab::openPdf
    .menubar.file add separator
    .menubar.file add command -label "Exit" -command exit

    menu .menubar.settings -tearoff 0
    .menubar add cascade -label "Settings" -menu .menubar.settings
    .menubar.settings add command -label "Preferences…" -command ::PDFLab::showPreferences

    menu .menubar.help -tearoff 0
    .menubar add cascade -label "Help" -menu .menubar.help
    .menubar.help add command -label "Quick Guide" -command ::PDFLab::showGuide
    .menubar.help add command -label "License" -command ::PDFLab::showLicense
    .menubar.help add separator
    .menubar.help add command -label "About" -command ::PDFLab::showAbout

    ttk::frame .top -padding 6
    pack .top -side top -fill x

    ttk::button .top.open -text "Open PDF" -command ::PDFLab::openPdf
    ttk::label .top.file -text "No PDF loaded" -width 34 -anchor w
    ttk::button .top.prev -text "◀" -width 3 -command ::PDFLab::prevPage
    spinbox .top.page -from 1 -to 99999 -width 5 -textvariable ::PDFLab::currentPage \
        -command ::PDFLab::renderPage
    ttk::label .top.pages -text "/ 0"
    ttk::button .top.next -text "▶" -width 3 -command ::PDFLab::nextPage
    ttk::label .top.ldpi -text "DPI:"
    ttk::combobox .top.dpi -state readonly -width 5 -values {150 200 300 400 600} \
        -textvariable ::PDFLab::dpi
    ttk::button .top.render -text "Render" -command ::PDFLab::renderPage
    ttk::label .top.lzoom -text "Zoom:"
    ttk::combobox .top.zoom -state readonly -width 5 \
        -values $zoomLevels -textvariable ::PDFLab::zoom
    ttk::button .top.zapply -text "Apply" -command ::PDFLab::updatePreview

    pack .top.open .top.file .top.prev .top.page .top.pages .top.next \
        .top.ldpi .top.dpi .top.render .top.lzoom .top.zoom .top.zapply \
        -side left -padx 3

    ttk::panedwindow .main -orient vertical
    pack .main -side top -fill both -expand 1

    ttk::frame .view
    ttk::scrollbar .view.v -orient vertical -command {.view.c yview}
    ttk::scrollbar .view.h -orient horizontal -command {.view.c xview}
    canvas .view.c -background #303030 -cursor crosshair -takefocus 1 \
        -xscrollincrement 20 -yscrollincrement 20 \
        -xscrollcommand {.view.h set} -yscrollcommand {.view.v set}
    grid .view.c -row 0 -column 0 -sticky nsew
    grid .view.v -row 0 -column 1 -sticky ns
    grid .view.h -row 1 -column 0 -sticky ew
    grid rowconfigure .view 0 -weight 1
    grid columnconfigure .view 0 -weight 1

    # Sinistro: selezione rettangolare. Centrale: pan. Rotella: zoom sul puntatore.
    bind .view.c <ButtonPress-1> {::PDFLab::mouseDown %x %y}
    bind .view.c <B1-Motion> {::PDFLab::mouseDrag %x %y}
    bind .view.c <ButtonRelease-1> {::PDFLab::mouseUp %x %y}
    bind .view.c <Motion> {::PDFLab::selectionMotion %x %y}

    bind .view.c <ButtonPress-2> {::PDFLab::panStart %x %y}
    bind .view.c <B2-Motion> {::PDFLab::panDrag %x %y}
    bind .view.c <ButtonRelease-2> {::PDFLab::panEnd}

    # X11/X2Go usa Button-4/5. Sugli altri backend Tk usa MouseWheel.
    if {[tk windowingsystem] eq "x11"} {
        bind .view.c <Button-4> {::PDFLab::wheelZoom 1 %x %y; break}
        bind .view.c <Button-5> {::PDFLab::wheelZoom -1 %x %y; break}
    } else {
        bind .view.c <MouseWheel> {::PDFLab::mouseWheel %D %x %y; break}
    }

    bind .view.c <Left>  {::PDFLab::keyPan -3 0; break}
    bind .view.c <Right> {::PDFLab::keyPan 3 0; break}
    bind .view.c <Up>    {::PDFLab::keyPan 0 -3; break}
    bind .view.c <Down>  {::PDFLab::keyPan 0 3; break}

    ttk::frame .lower -padding 6
    .main add .view -weight 5
    .main add .lower -weight 2

    ttk::frame .sel
    pack .sel -in .lower -side top -fill x -pady {0 5}
    ttk::label .sel.title -text "Selection:"
    ttk::label .sel.info -text "No selection" -width 42 -anchor w
    ttk::button .sel.clear -text "Clear" -command ::PDFLab::clearSelection
    ttk::button .sel.png -text "Export PNG" -command ::PDFLab::exportCrop
    ttk::button .sel.ocr -text "OCR Selection" -command ::PDFLab::ocrSelection
    ttk::button .sel.both -text "PNG + TXT OCR" -command ::PDFLab::exportCropAndOcr
    pack .sel.title .sel.info .sel.clear .sel.png .sel.ocr .sel.both -side left -padx 4

    ttk::frame .ocropts
    pack .ocropts -in .lower -side top -fill x -pady 3
    ttk::label .ocropts.ll -text "OCR language:"
    ttk::combobox .ocropts.lang -state readonly -width 15 \
        -values {eng chi_sim+eng chi_tra+eng} -textvariable ::PDFLab::ocrLang
    ttk::label .ocropts.lp -text "Layout:"
    ttk::combobox .ocropts.psm -state readonly -width 14 \
        -values {Auto Block {Single line} {Sparse text}} -textvariable ::PDFLab::psmLabel
    ttk::button .ocropts.full -text "OCR Whole PDF" -command ::PDFLab::ocrWholePdf
    ttk::button .ocropts.save -text "Save TXT" -command ::PDFLab::saveOcrText
    ttk::button .ocropts.copy -text "Copy OCR" -command ::PDFLab::copyOcrText
    pack .ocropts.ll .ocropts.lang .ocropts.lp .ocropts.psm .ocropts.full .ocropts.save .ocropts.copy \
        -side left -padx 4

    ttk::frame .ocr
    pack .ocr -in .lower -side top -fill both -expand 1
    text .ocr.txt -wrap word -height 8 -undo 1
    ttk::scrollbar .ocr.sb -orient vertical -command {.ocr.txt yview}
    .ocr.txt configure -yscrollcommand {.ocr.sb set}
    pack .ocr.sb -side right -fill y
    pack .ocr.txt -side left -fill both -expand 1

    ttk::frame .bottom
    ttk::label .bottom.help -text "Wheel: zoom  •  Arrow keys: pan  •  Middle drag: pan  •  Left drag: create/move selection  •  Handles: resize" -anchor w -padding {6 2}
    ttk::label .bottom.status -textvariable ::PDFLab::status -anchor w -padding {6 3}
    ttk::label .bottom.brand -text "Produced by Giux-Lab — giux-lab.it  •  GNU GPL v3.0 or later" -anchor e -padding {6 2}
    pack .bottom.help -side top -fill x
    pack .bottom.status -side left -fill x -expand 1
    pack .bottom.brand -side right
    pack .bottom -side bottom -fill x

    bind .top.page <Return> {::PDFLab::renderPage}
    bind . <Control-o> {::PDFLab::openPdf}
}

::PDFLab::loadSettings
if {[::PDFLab::checkDependencies]} {
    ::PDFLab::buildUi
} else {
    after 100 exit
}
