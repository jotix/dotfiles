case $HOSTNAME in
    jtx-arch)
	setxkbmap us -variant altgr-intl
	;;
    ffm-arch)
	setxkbmap es
	;;
esac

picom &
emacs --daemon -f exwm-enable
exec emacsclient -c 
#exec emacs --debug-init --load "~/.emacs.d/exwm.el"
