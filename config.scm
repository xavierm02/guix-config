
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
; ungoogled-chromium

;; guix repl < ~/config/main.scm
;; ibus latex
;; youtube-dl
;; volumeicon

(define (endcons l x)
  (append l (list x)))

(add-to-load-path "/home/xavierm02/config")

(define (assert b)
  (if
    (not b)
    (throw 'ASSERT-FAILURE))) ; TODO
    
(define (maybe-warn b m)
  (if
    b
    (display m)))

(define (partial-map f l)
  (map
    (lambda (x)
      (let ((result (f x)))
      (if
        (equal? result #f)
        x
        result)))))
        
(define is_server #f)

(define (impl x y)
  (or
    (not x)
    y))

(define (my-eval expr) (eval expr (interaction-environment)))





(use-modules
  (gnu)
  (srfi srfi-1)
  (srfi srfi-9)
  (nongnu packages linux)
  (nongnu packages compression)
  ;(nonfree packages linux)
  ;(nonfree packages compression)
  (ice-9 pretty-print)
  (guix packages)
  (rnrs lists)
  (ice-9 popen)
  (ice-9 textual-ports)
  (srfi srfi-9 gnu)
  ;(system-with-type) ; TODO make system export <operating-system>
  (gnu services nix)
  (ice-9 match)
  (guix records)
)

(use-service-modules
  avahi
  dbus
  desktop
  networking
  pm
;  sddm
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

(define <operating-system>
  (record-type-descriptor
    (operating-system
      (bootloader #f)
      (host-name #f)
      (file-systems #f)
      (timezone #f))))

(define (operating-system-firmware os)
  ((record-accessor <operating-system> 'firmware) os))

;;;;;;;;;;;;;;;;
;; OS printer ;;
;;;;;;;;;;;;;;;;

(define (package->specification pkg)
  (package-name pkg))

(define (package->sexpr pkg)
  `(specification->package ,(package->specification pkg)))

(define (user->sexpr user)
  `(user-account
    (name ,(user-account-name user))))

(define (os->sexpr os)
  `(operating-system
    (kernel ,(package->sexpr (operating-system-kernel os)))
    (firmware
      (map
        specification->package
        (list
          ,@(map
            package->specification
            (operating-system-firmware os)))))
    (host-name ,(operating-system-host-name os))
    (users
      (list
        ,@(map user->sexpr (operating-system-users os))))
    (packages
      (map
        specification->package
        (list
          ,@(map
            package->specification
            (operating-system-packages os)))))
    (services
      (list
        ,@(map
          service-name
          (operating-system-services os))))
  ))

(define (append-warn l1 l2)
  (every
    (lambda (x2)
      (maybe-warn
        (any
          (lambda (x1)
            (equal? x1 x2))
          l1)
        "WARN\r\n"))
    l2)
  (append l1 l2))
    

(define (partial-map-warn f l m)
  (maybe-warn
    (every
      (lambda (x)
        (equal? (f x) #f))
      l)
    "WARN\r\n")
  (partial-map f l))

(define (filter-warn p l m)
  (maybe-warn
    (every p l)
    "WARN\r\n"))







;; Services

(define (service-name srv)
  (service-type-name (service-kind srv)))

(define (name->service-predicate srv name)
  (equal? (service-name srv) name))

(define (service->service-predicate p)
  (if
    (service-type? p)
    (lambda (srv)
      (equal? (service-kind srv) p))
    p))


;(remove
    ;  (lambda (service) (eq? (service-kind service) gdm-service-type))
    ;  %desktop-services



(define my-keyboard-layout
  (keyboard-layout "us" "altgr-intl")
)

;;;;;;;;;;;;
; Services ;
;;;;;;;;;;;;

(define i3-service
  (simple-service
    'i3-packages
    profile-service-type
    (list dmenu i3-wm i3lock i3status)))
    

(define my-services
  (cons*
    (service nix-service-type)
    ;; Desktop
    i3-service
    (screen-locker-service i3lock)
    ;(sddm-service)
    ;(service xfce-desktop-service-type)
    
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

;(display (map service-name my-services))

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
        (handle-lid-switch 'suspend)
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
    
    #|(sddm-service-type config =>
      (sddm-configuration
        (inherit config)
        (numlock "on")
        (theme "elarun") ; TODO other theme?
        (remember-last-user? #t)
        (remember-last-session? #t)
      )
    )|#
    
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

(define my-cli-packages ;; TODO specification->package
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
    ;xmonad
    
    ;; Freedesktop.org
    xdg-utils ;; open
    xdg-user-dirs
    
    ;; ?? TODO
    redshift
    ; TODO redshift-gtk
    
    
    xclip
    scrot
    ;unclutter?
    
    ;gparted ; TODO replace by something else
    
    ;; Screens
    arandr
    autorandr
    
    gedit
    
    xinit
  )
)

(define xavierm02-user-account
  (user-account
    (name "xavierm02")
    (comment "Xavier Montillet")
    (group "users")
    (home-directory "/home/xavierm02")
    (shell #~(string-append #$fish "/bin/fish"))
    (supplementary-groups
      (list
        "audio"
        "kvm"
        "netdev"
        "video"
        "wheel"))))

(define (maybe-append l1 l2)
  (delete-duplicates (append l1 l2))) ;; TODO more efficient?








(define my-packages
  (append
    my-base-packages
    my-cli-packages
    my-desktop-packages
  )
)


(define my-os
  (operating-system
    
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
      (append
        %base-user-accounts
      )
    )
    
    (host-name "GT")
    
    (services my-services)
    
    (packages my-packages)
  )
)


#|
(define-syntax-rule (modify-os os mods ...)
  (match-record
    os
    <operating-system>
    (record-type-fields <operating-system>)
    (operating-system
      (inherit os)
      mods ...)))
      |#

(define-syntax-rule (modify-os (key value) ...)
  (lambda (os)
    (operating-system
      (inherit os)
      (key
        (let ((key ((record-accessor <operating-system> 'key) os))) value))
      ...)))

(setvbuf (current-output-port) 'none)

(define (maybe b t)
  (if b t 'None))

(define-record-type* <operating-system-modification> operating-system-modification
  make-operating-system-modification
  operating-system-modification?
  this-operating-system-modification
  
  (name operating-system-modification-name
    (default "<No name>"))
  (description operating-system-modification-description
    (default "<No description>"))
  (message-start operating-system-modification-message-start
    (default "<No start message>..."))
  (message-done operating-system-modification-message-done
    (default " Done."))
  (message-skip operating-system-modification-message-skip
    (default "<No skip message>"))
  (condition operating-system-modification-condition
    (default (lambda (os) #t)))
  (modification operating-system-modification-modification))

(define (operating-system-modification->procedure mod)
  (lambda (os)
    (match-record mod <operating-system-modification> (name description message-start message-done message-skip condition modification)
      (if
        (condition os)
        (begin
          (display message-start)
          (let ((new-os (modification os)))
            (begin
              (display message-done)
              (newline)
              new-os)))
        (begin
          (display message-skip)
          (newline)
          os)))))

(define my-modifications
  (list
    (operating-system-modification
      (name "iwlwifi")
      (description "If the Wi-Fi chip requires non-free software (detected by \"Intel Corporation Wireless\" being a substring of the result of lspci), replace the kernel by linux and add iwlwifi-firmware.")
      (message-start "Adding firmware-iwlwifi")
      (message-skip "Not adding firmware-iwlwifi.")
      (condition
        (lambda (os)
          (string-contains (system-str "lspci") "Intel Corporation Wireless")))
      (modification
        (modify-os
          (kernel linux)
          (firmware (endcons firmware iwlwifi-firmware)))))

  (operating-system-modification
    (name "xavierm02")
    (message-start "Adding xavierm02")
    (modification
      (modify-os
        (users (append users (list xavierm02-user-account))))))
))

(define (system-str cmd)
  (let*
    ((port (open-input-pipe cmd))
    (output (get-string-all port)))
    (begin
      (close-pipe port)
      output)))

(define (compose-procedures procs)
  (lambda (x)
    (fold-right
      (lambda (f y) (f y))
      x
      procs)))

(define (os-apply-modifications mods os)
  ((compose-procedures
    (map
      operating-system-modification->procedure
      mods))
  os))

(define my-os-result
  (os-apply-modifications my-modifications my-os))

(display (os->sexpr my-os-result))

(if
  (string-contains
    (string-join (command-line) " ")
    "guix system reconfigure")
  my-os-result)

