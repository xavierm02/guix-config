
; TODO
; https://www.gnu.org/software/guix/manual/en/html_node/Miscellaneous-Services.html#Miscellaneous-Services
; iptables-service-type
; cups?
; Only enter decryption password once
; swap?
; redshift
; ibus
; brightnessctl?
; vm stuff?
; TODO duplicity for backup?
; diffoscope?
; fprintd fingerprint reader?
; autojump?
; interrobang ?
; stow for dotafiles?

(use-modules
  (gnu)
  (srfi srfi-1)
  (nonfree packages linux)
  (nonfree packages compression)
)

(use-service-modules
  avahi
  dbus
  desktop
  networking
  pm
  sddm
  sound
  ssh
  xorg
)

(use-package-modules
  admin
  backup
  commencement
  compression
  cpio
  cryptsetup
  disk
  efi
  emacs
  file
  freedesktop
  gnome ; for nm-applet TODO remove?
  libusb
  linux
  llvm
  nano
  ocaml
  python
  readline
  shells
  suckless
  xdisorg
  xfce
  xorg
  version-control
  vim
  w3m
  wget
  wm
)



(define my-keyboard-layout
  (keyboard-layout "us" "altgr-intl")
)

;;;;;;;;;;;;
; Services ;
;;;;;;;;;;;;

(define my-services
  (cons*
    ;; Desktop
    (simple-service
     'i3-packages
     profile-service-type
     (list dmenu i3-wm i3lock i3status)
    )
    (screen-locker-service i3lock)
    (sddm-service)
    (service xfce-desktop-service-type)
    
    ;; Screen lockers are a pretty useful thing and these are small.
    ;(screen-locker-service slock)
    ;(screen-locker-service xlockmore "xlock")
    
    ;; Network
    (service wpa-supplicant-service-type)
    (service network-manager-service-type)
    (simple-service
     'network-manager-applet
     profile-service-type
     (list network-manager-applet)
    )
    (service modem-manager-service-type)
    
    ;; Laptop
    (service tlp-service-type) ; Power saving

    
    

    ;; Add udev rules for MTP devices so that non-root users can access them.
    (simple-service 'mtp udev-service-type (list libmtp))

    
    

    ;; The D-Bus clique.
    (service avahi-service-type)
    (udisks-service)
    (service upower-service-type) ; Battery
    (accountsservice-service)
    (service cups-pk-helper-service-type)
    (colord-service)
    (geoclue-service) ; Location
    (service polkit-service-type)
    (elogind-service) ; Button and lid events
    (dbus-service)

    (service ntp-service-type)

    x11-socket-directory-service

    (service alsa-service-type)
    
    (service thermald-service-type)
    
    
    (bluetooth-service)
    
    (set-xorg-configuration           
      (xorg-configuration
        (keyboard-layout my-keyboard-layout)
      )
    )
    %base-services
  )
)

(define my-services-with-config
  (modify-services 
    
    my-services
    
    
    (bluetooth-service-type config =>
      (bluetooth-configuration
        (auto-enable? #f)
      )
    )
    
    (elogind-service-type config =>
      (elogind-configuration
        (inherit config)
        
        ; Handle events
        (handle-power-key 'suspend)
        (handle-suspend-key 'suspend)
        (handle-hibernate-key 'hibernate)
        (handle-lid-switch 'ignore)
        (handle-lid-switch-docked 'ignore)
        
        ; Allow programs to prevent actions
        (power-key-ignore-inhibited? #f)
        (suspend-key-ignore-inhibited? #f)
        (hibernate-key-ignore-inhibited? #f)
        (lid-switch-ignore-inhibited? #f)
        
        ; Do nothing if idle
        (idle-action 'ignore)
      )
    )
    
    (sddm-service-type config =>
      (sddm-configuration
        (inherit config)
        (numlock "on")
        (theme "elarun") ; TODO other theme?
        (remember-last-user? #t)
        (remember-last-session? #t)
      )
    )
    
    (tlp-service-type config =>
      (tlp-configuration
        (inherit config)
        (tlp-default-mode "BAT")
        (energy-perf-policy-on-ac "performance")
        (energy-perf-policy-on-bat "normal")
        (wifi-pwr-on-ac? #f)
        (wifi-pwr-on-bat? #f)
        (usb-autosuspend? #t)
      )
    )
    
    (upower-service-type config =>
      (upower-configuration
        (inherit config)
        
        (poll-batteries? #t)
        
        (use-percentage-for-policy?  #f)
        (time-low (* 60 60))
        (time-critical (* 20 60))
        (time-action (* 10 60))
        (critical-power-action 'hibernate)
      )
    )
    
    ;(remove
    ;  (lambda (service) (eq? (service-kind service) gdm-service-type))
    ;  %desktop-services
    ;)
  )
)

;;;;;;;;;;;;
; Packages ;
;;;;;;;;;;;;

(define my-base-packages
  (cons*
    (specification->package "nss-certs")
    %base-packages
  )
)

(define my-cli-packages
  (list
    ;; Shells
    fish
    
    ;; Editors
    emacs
    nano
    vim
  
    ;; Archives
    archivemount
    atool
    ; bzip2 already in %base-packages
    cpio
    ; gzip already in %base-packages
    p7zip
    ; tar already in %base-packages
    unrar
    unzip
    ; xz already in %base-packages
    zip
    
    ;; Admin
    daemontools
    dfc
    di
    dstat
    htop
    iftop
    inetutils
    progress
    tree
    
    ;; ?? TODO
    git
    wget
    
    ;; Web browsers
    ; elinks TODO
    w3m
    
    ;; ?? TODO
    gcc-toolchain
    ocaml ocamlbuild
    python
    
    ;; ?? TODO
    efitools
    
    ;; ?? TODO
    rlwrap
    
    ;; ?? TODO
    brightnessctl
    
    ;; ?? TODO
    hostapd
    dmidecode
    acpica
    pscircle
    
    ;; ?? 
    solaar ;; Logitech Unifying Receiver
    
    ;; ??
    cryptsetup
    llvm;?
    lvm2;dmsetup to decrypt files with gparted
    
    
    file
    
    mercurial
    
  )
)

(define my-desktop-packages
  (list
    ;; Xorg
    xinit
    
    ;; Window managers
    xfce
    xmonad
    
    ;; Freedesktop.org
    xdg-utils ;; open
    xdg-user-dirs
    
    ;; ?? TODO
    redshift
    ; TODO redshift-gtk
    
    
    xclip
    scrot
    ;unclutter?
    
    gparted ; TODO replace by something else
    
    ;; Screens
    arandr
    autorandr
    
    gnome ;; TODO remove
  )
)
  
  

(define my-packages
  (append
    my-base-packages
    my-cli-packages
    my-desktop-packages
  )
)



(operating-system
  (kernel linux-nonfree)
  (firmware
    (cons*
      linux-firmware-iwlwifi
      %base-firmware
    )
  )
  
  (locale "en_US.utf8")
  (timezone "Europe/Paris")
  (keyboard-layout my-keyboard-layout)

  (bootloader
    (bootloader-configuration
      (bootloader grub-efi-bootloader)
      (target "/boot/efi")
      (timeout 1)
      (keyboard-layout my-keyboard-layout)
    )
  )
  (mapped-devices
    (list
      (mapped-device
        (source (uuid "8400b3bd-798b-4464-ac93-da71be0c674f"))
        (target "cryptroot")
        (type luks-device-mapping)
      )
    )
  )
  (file-systems
    (cons*
      (file-system
        (mount-point "/boot/efi")
        (device (uuid "D917-8239" 'fat32))
        (type "vfat")
      )
      (file-system
        (mount-point "/")
        (device "/dev/mapper/cryptroot")
        (type "ext4")
        (dependencies mapped-devices)
      )
      %base-file-systems
    )
  )
  
  (users
    (cons*
      (user-account
        (name "xavierm02")
        (comment "Xavier Montillet")
        (group "users")
        (home-directory "/home/xavierm02")
        (shell #~(string-append #$fish "/bin/fish"))
        (supplementary-groups
          '(
            "audio"
            "kvm"
            "netdev"
            "video"
            "wheel"
          )
        )
      )
      %base-user-accounts
    )
  )
  
  (host-name "GT")
  
  (services my-services)
  
  (packages my-packages)
)
