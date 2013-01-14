;; ----------------------------------------------------------------------------
;;          FILE:  .emacs
;;   DESCRIPTION:  emacs configuration file
;;        AUTHOR:  Adam Walz <viperlight89@me.com>
;;       VERSION:  2.0.0
;;
;; ----------------------------------------------------------------------------

(require 'cl)                               ; a rare necessary use of REQUIRE
;(setq custom-file "~/.emacs-custom.el")
;(load custom-file 'noerror)

(defvar *emacs-load-start* (current-time))  ; time how fast/slow init.el is

;; ============================== Initialization ==============================
(if (eq system-type 'darwin)
    (set-face-font 'default "Anonymous_Pro-13")
  (set-face-font 'default "Monospace-13"))


;; ============================= Package Installer ============================
(add-to-list 'load-path "~/.emacs.d/el-get/el-get")

;; Lazy-install el-get unless it is already installed
(unless (require 'el-get nil t)
(with-current-buffer
  (url-retrieve-synchronously
    "https://raw.github.com/dimitri/el-get/master/el-get-install.el")
  (goto-char (point-max))
  (eval-print-last-sexp)))

(setq el-get-sources
  '((:name smex                                 ; a better (ido like) M-x
           :after (progn
                   (setq smex-save-file "~/.emacs.d/.smex-items")
                   (global-set-key (kbd "M-x") 'smex)
                   (global-set-key (kbd "M-X") 'smex-major-mode-commands)))

    (:name magit                             ; git meet emacs, and a binding
           :after (progn
                   (global-set-key (kbd "C-x C-z") 'magit-status)))
    
    (:name goto-last-change                  ; move pointer back to last change
           :after (progn
                    ;; when using AZERTY keyboard, consider C-x C-_
                    (global-set-key (kbd "C-x C-/") 'goto-last-change)))
    
    ;(:name ensime
    ;       :after (progn
    ;               (add-hook 'scala-mode-hook 'ensime-scala-mode-hook)))
    ))
        
(when (el-get-executable-find "cvs")
  (loop for p in '(emacs-goodies-el          ; the debian addons for emacs
                  ) do (add-to-list 'el-get-sources p)))

(when (el-get-executable-find "svn")
  (loop for p in '(psvn                      ; M-x svn-status
                   (:name yasnippet          ; powerful snippet mode
                          :after (progn
                                   (yas-global-mode 1)
                                   (setq yas-snippet-dirs
                                     '("~/.yasnippets")))) ; personal snippets
                   ) do (add-to-list 'el-get-sources p)))

(when (el-get-executable-find "bzr")
  (loop for p in '(
    (:name cedet
     :description "CEDET is a Collection of Emacs Development Environment 
                   Tools written with the end goal of creating an advanced
                   development environment in Emacs."
     :type bzr
     :url "bzr://cedet.bzr.sourceforge.net/bzrroot/cedet/code/trunk"
     :build `(("sh" "-c" "touch `find . -name Makefile`")
              ("make" ,(format "EMACS=%s" (shell-quote-argument el-get-emacs)) "clean-all")
              ("make" ,(format "EMACS=%s" (shell-quote-argument el-get-emacs))))
     :features nil
     :lazy nil
     :post-init (unless (featurep 'cedet-devel-load)
                  (load (expand-file-name "cedet-devel-load.el" pdir)))
     :after (progn
             (global-ede-mode 1)        ; Enable project management system
             (semantic-load-enable-excessive-code-helpers) ; Enable prototype help and smart completion 
             (global-srecode-minor-mode 1)))  ; Enable template insertion
    ) do (add-to-list 'el-get-sources p)))

(setq my-packages
  (append
    '(el-get
      escreen                                 ; screen for emacs, C-\ C-h
      auto-complete                           ; overlays as you type
      magithub                                ; working with github directories
      zencoding-mode                          ; emacswiki.org/emacs/ZenCoding
      color-theme                             ; nice looking emacsn
      color-theme-tango                       ; check out color-theme-solarized
      ;quack                                  ; support for scheme editing
      scala-mode                              ; scala editing 
      sml-mode                                ; standard ml editing
      flex-mode)                              ; lex/flex lexer-generator editing
      (mapcar 'el-get-source-name el-get-sources)))

;; install new packages and init already installed packages
(el-get 'sync my-packages)


;; ================================= Visual =================================
(setq inhibit-splash-screen t)               ; no splash screen, thanks

;; emacs 24 themes
(when (string= (substring emacs-version 0 3) "24.")
      (load-theme 'wombat t))
;; aquamacs themes
(when (featurep 'aquamacs)
  (color-theme-charcoal-black)
  (one-buffer-one-frame-mode 0)
  (defun my-new-frame-with-new-scratch ()
    (interactive)
    (let ((one-buffer-one-frame t))
      (new-frame-with-new-scratch)))
  (define-key osx-key-mode-map (kbd "A-n") 'my-new-frame-with-new-scratch)  
  (define-key osx-key-mode-map (kbd "A-w") 'kill-this-buffer))

;; Show colors in shell mode
(add-hook 'shell-mode-hook 'ansi-color-for-comint-mode-on)
;; Region Highlighting
(setq-default transient-mark-mode t)

(line-number-mode 1)                         ; have line numbers and
(column-number-mode 1)                       ; column numbers in the mode line

(when (window-system)
  (tool-bar-mode -1)
  (scroll-bar-mode -1))
(menu-bar-mode -1)
(when (eq system-type 'darwin)
  (menu-bar-mode 1)                         ; always a menubar on a mac anyway
  (setq mac-allow-anti-aliasing t))

(global-hl-line-mode 1)                      ; highlight current line
(global-linum-mode 1)                       ; add line numbers on the left
;; vertical seperator between line numbers and content
(defadvice linum-update-window (around linum-dynamic activate)
  (let* ((w (length (number-to-string
                     (count-lines (point-min) (point-max)))))
         (linum-format (concat "%" (number-to-string w) "d\u2502")))
    ad-do-it))

;; Colorify M-x shell. If you need a terminal emulator rather than just a 
;; shell, consider M-x term instead.
(autoload 'ansi-color-for-comint-mode-on "ansi-color" nil t)
(add-hook 'shell-mode-hook 'ansi-color-for-comint-mode-on)


;; ================================= Backups ==================================
;; Disable autosaving
(setq auto-save-default nil)
;; Enable backup files.
(setq make-backup-files t)
;; Enable versioning of backups
(setq
    delete-old-versions t
    kept-new-versions 6
    kept-old-versions 2
    version-control t
)
;; Set backup directory.
(setq backup-directory-alist
      (quote ((".*" . "~/.emacs_backups/")))
)
;; Automatically purge backup files not accessed in a week
(message "Deleting old backup files...")
(let ((week (* 60 60 24 7))
      (current (float-time (current-time))))
    (dolist (file (directory-files temporary-file-directory t))
        (when (and
               (backup-file-name-p file)
               (>
                (- current (float-time (fifth (file-attributes file))))
                week
               )
              )
            (message file)
            (delete-file file)
        )
    )
)


;; ================================ Navigation ================================
;; Follow symlinks and don't ask
(setq vc-follow-links t)

;; Convineience Keybindings
(global-set-key "\C-c\C-v" 'compile)
(global-set-key "\C-c\C-z" 'gdb)
(global-set-key "\C-c\C-k" 'shell)

;; stop asking me for confirmation
(global-set-key "\C-xk" 'kill-this-buffer)
(setq vc-follow-symlinks nil)

;; under mac, have Command as Meta and keep Option for localized input
(when (and
       (eq system-type 'darwin)
       (not (featurep 'aquamacs)))
         (setq mac-command-modifier 'meta)
         (setq mac-option-modifier nil))

;; Use the clipboard so that copy/paste "works"
(setq x-select-enable-clipboard t)

;; Navigate windows with M-<arrows>
(windmove-default-keybindings 'meta)
(setq windmove-wrap-around t)

;; If you do use M-x term, you will notice there's line mode that acts like
;; emacs buffers, and there's the default char mode that will send your
;; input char-by-char, so that curses application see each of your key
;; strokes.
;;
;; The default way to toggle between them is C-c C-j and C-c C-k, let's
;; better use just one key to do the same.
(eval-after-load "term"
'(progn
  (define-key term-raw-map  (kbd "C-'") 'term-line-mode)
  (define-key term-mode-map (kbd "C-'") 'term-char-mode)
  (define-key term-raw-map  (kbd "C-y") 'term-paste)))

;; use ido for minibuffer completion
(require 'ido)
(ido-mode t)
(setq ido-save-directory-list-file "~/.emacs.d/.ido.last")
(setq ido-enable-flex-matching t)
(setq ido-use-filename-at-point 'guess)
(setq ido-show-dot-for-dired t)


;; ========================== File Type Modes ================================
(setq auto-mode-alist
      ; racket files
      (cons '("\\.rkt$" . scheme-mode) auto-mode-alist)
      ; cmake listfiles
)
(setq auto-mode-alist
      (append
       '(("CMakeLists\\.txt\\'" . cmake-mode))
       '(("\\.cmake\\'" . cmake-mode))
       auto-mode-alist)
)


;; ================================== Hooks ===================================
;; When saving files, set execute permission if #! is in first line.
(add-hook 'after-save-hook 'executable-make-buffer-file-executable-if-script-p)

;; Spell checking
(add-hook 'text-mode-hook 'flyspell-mode)
(add-hook 'c-mode-common-hook 'flyspell-prog-mode)

(add-hook 'c-mode-common-hook (lambda ()
                                (local-set-key [(control return)] 'semantic-ia-complete-symbol)
                                (local-set-key "\C-c?"            'semantic-ia-complete-symbol-menu)
                                (local-set-key "\C-c>"            'semantic-complete-analyze-inline)
                                (local-set-key "\C-cp"            'semantic-analyze-proto-impl-toggle)
                                (local-set-key "\C-xp"            'semantic-complete-analyze-inline-idle)))

;; Map C-x k to end emacsclient session
(add-hook 'server-switch-hook
            (lambda ()
              (when (current-local-map)
                (use-local-map (copy-keymap (current-local-map))))
	      (when server-buffer-clients
		(local-set-key (kbd "C-x k") 'server-edit))))

;; =========================== Miscelaneous ===================================
;; Dvorak Input Mode
;(defadvice switch-to-buffer (after activate-input-method activate)
;  (activate-input-method "english-dvorak"))

(message "My .emacs loaded in %ds"
  (destructuring-bind (hi lo ms) (current-time)
                                 (- (+ hi lo)
                                    (+ (first *emacs-load-start*)
                                       (second *emacs-load-start*)))))
