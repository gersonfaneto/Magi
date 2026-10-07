#!/usr/bin/env zsh
# Optimize images and PDF files (losslessly by default).
#
# SYNOPSIS:
#   optimize [-l|-L] FILES|DIRS...
#
# OPTIONS:
#   -l | -L
#     Enable lossy compression, or do *only* lossy compression, respectively.
#
# EXAMPLES:
#   optimize image.jpg image.png image.gif
#   optimize directory_of_images/
#   optimize directory_of_images/*.png
#
# DEPENDENCIES:
#   bc
#   PNGs: optipng, pngquant (lossy)
#   JPGs: jpegtran, jpegoptim (lossy)
#   GIFs: gifsicle
#   PDFs: ghostscript
#
#   All absent dependencies (except for bc) are auto-installed with
#   cached-nix-shell on demand, if needed.
#
# ARGUMENTS:
#   * FILE @files

.filesize() { stat --printf="%s" "$1"; }

magi.requires bc
zparseopts -E -D -F -- l=lossy L=lossyonly o:=outdir || exit 1
# TODO: Support -o
[[ $lossyonly ]] && lossy=( -l )
for file in $@; do
  if [[ -d $file ]]; then
    magi.log "Traversing directory: $file..."
    ${0:a} $file/*
  elif [[ -f $file ]]; then
    local pre_size=$(.filesize "$file")
    local mimetype=$(file ${file} -b --mime-type)
    magi.log "Processing file: $file ($mimetype) @ $pre_size..."
    case $mimetype in
      image/png)
        [[ $lossy ]] && magi.do -! pngquant -f --ext .png --quality 90-98 $file
        [[ $lossyonly ]] || magi.do -! optipng -nc -nb -o7 $file
        ;;
      image/gif)
        magi.do -! gifsicle --batch --optimize=3 "$file"
        ;;
      image/jpeg)
        [[ $lossy ]] && magi.do -! jpegoptim --max=90 "$file"
        [[ $lossyonly ]] || magi.do -! -p mozjpeg jpegtran -copy none -optimize -progressive -outfile "$file" "$file"
        ;;
      application/pdf)
        # Adapted from Alfred Klomp's shrinkpdf script
        # <http://alfredklomp.com/programming/shrinkpdf/>
        local dpi=72
        local compfile="${${file// /_}/.pdf/.compressed.pdf}"
        magi.requires gs
        magi.do gs -q -dNOPAUSE -dBATCH -dSAFER \
          -sDEVICE=pdfwrite \
          -dPDFSETTINGS=/ebook \
          -dCompatibilityLevel=1.4 \
          -dMonoImageResolution=$dpi \
          -dMonoImageDownsampleType=/Bicubic \
          -dGrayImageResolution=$dpi \
          -dGrayImageDownsampleType=/Bicubic \
          -dColorImageResolution=$dpi \
          -dColorImageDownsampleType=/Bicubic \
          -sOutputFile="$compfile" \
          "$file" && mv -f "$compfile" "$file"
        ;;
      *)
        magi.warn "Unrecognized file type: $mimetype"
        ;;
    esac
    local post_size=$(.filesize "$file")
    local perc=$(echo "((${pre_size} - ${post_size}) / ${pre_size}) * 100" | bc -l)
    printf "* %s: %d => %d (%.2f%% reduction)\n" "$file" "$pre_size" "$post_size" "$perc"
  fi
done
