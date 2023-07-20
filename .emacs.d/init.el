(setq default-directory "~/")

(setq exec-path (delete-dups
                 (append exec-path
                         `(,(expand-file-name "~/bin")
                           ,(expand-file-name "~/.asdf/shims")
                           "/usr/local/bin"
                           "/usr/local/sbin"))))

(setq scratch-buffer-file
      (locate-user-emacs-file "scratch"))

(add-hook
 'kill-buffer-hook
 `(lambda ()
    (when (equal
           (current-buffer)
           (get-buffer "*scratch*"))
      (rename-buffer "*scratch*<kill>" t)
      (clone-buffer "*scratch*")) t))

(add-hook
 'after-init-hook
 `(lambda ()
    (when (file-exists-p scratch-buffer-file)
      (with-current-buffer (get-buffer-create "*scratch*")
        (erase-buffer)
        (insert-file-contents scratch-buffer-file))) t))

(add-hook
 'kill-emacs-hook
 `(lambda ()
    (with-current-buffer (get-buffer-create "*scratch*")
      (write-region (point-min) (point-max) scratch-buffer-file nil t)) t))

(add-hook
 'kill-emacs-hook
 `(lambda ()
    (let ((src-file (locate-user-emacs-file "init.el"))
          (elc-file (locate-user-emacs-file "init.elc")))
      (when (file-newer-than-file-p src-file elc-file)
        (byte-compile-file src-file))) t))

(add-hook
 'kill-emacs-hook
 `(lambda ()
    (when (file-exists-p custom-file)
      (delete-file custom-file)) t))

(add-hook
 'window-configuration-change-hook
 `(lambda ()
    (let ((display-table (or buffer-display-table standard-display-table)))
      (when display-table
        ;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Display-Tables.html
        (set-display-table-slot display-table 1 ? )
        (set-display-table-slot display-table 5 ?│)
        (set-window-display-table (selected-window) display-table))) t))

(add-hook
 'after-save-hook
 'executable-make-buffer-file-executable-if-script-p)

(custom-set-variables
 '(custom-file (locate-user-emacs-file (format "emacs-%d.el" (emacs-pid))))
 '(ffap-bindings t)
 '(find-file-visit-truename t)
 '(global-auto-revert-mode t)
 '(indent-tabs-mode nil)
 '(inhibit-splash-screen t)
 '(inhibit-startup-screen t)
 '(initial-scratch-message nil)
 '(make-backup-files nil)
 '(package-archives '(("melpa" . "https://melpa.org/packages/")
                      ("elpa" . "https://elpa.gnu.org/packages/")))
 '(package-enable-at-startup t)
 '(pop-up-windows nil)
 '(require-final-newline 'visit-save)
 '(scroll-step 1)
 '(set-mark-command-repeat-pop t)
 '(split-width-threshold 0)
 '(system-time-locale "C")
 '(show-paren-mode t)
 '(vc-follow-symlinks nil)
 '(view-read-only t)
 '(viper-mode nil))

(load-theme 'anticolor t)

(put 'upcase-region 'disabled nil)
(put 'downcase-region 'disabled nil)

(set-file-name-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)

(eval-and-compile
  (package-initialize)

  (run-with-idle-timer
   (* 60 60 6) t `(lambda () (package-refresh-contents)))

  (unless (package-installed-p 'leaf)
    (package-refresh-contents)
    (package-install 'leaf))

  (leaf leaf
    :config
    (leaf leaf-keywords
      :ensure t
      :hook (after-init-hook . leaf-keywords-init))))

(leaf carbon-now-sh
  :ensure t)

;; (leaf coffee-mode
;;   :ensure t
;;   :custom
;;   (cofee-tab-width . 2))

(leaf company
  :ensure t
  :bind (("C-c i" . company-complete))
  :hook (after-init-hook . global-company-mode)
  :custom
  (company-files . t)
  (company-idle-delay . nil)
  (company-selection-wrap-around . t)
  :config
  (leaf company-statistics
    :ensure t
    :hook (after-init-hook . company-statistics-mode))
  (leaf company-c-headers :ensure t :config (add-to-list 'company-backends 'company-c-headers))
  (leaf company-shell :ensure t :config (add-to-list 'company-backends 'company-shell))
  (leaf company-terraform :ensure t :config (add-to-list 'company-backends 'company-terraform))
  ;;(leaf company-web :ensure t :config (add-to-list 'company-backends 'company-web))
  )

(leaf cue-mode
  :if (executable-find "cue")
  :ensure t
  :init
  (define-minor-mode cur-format-on-save-mode
    "Run cue-reformat-buffer before saving current buffer."
    :lighter ""
    (if cur-format-on-save-mode
        (add-hook 'before-save-hook #'cue-reformat-buffer nil t)
      (remove-hook 'before-save-hook #'cue-reformat-buffer t)))
  :hook (cue-mode-hook . cue-format-on-save-mode))

(leaf d2-mode
  :if (executable-find "d2")
  :ensure t)

(leaf ddskk
  :ensure t
  :hook (after-init-hook . my/ddskk-skk-get)
  :init
  (setq default-input-method "japanese-skk")
  (setq skk-status-indicator 'minor-mode)
  (setq skk-egg-like-newline t)
  (setq skk-latin-mode-string "a")
  (setq skk-hiragana-mode-string "あ")
  (setq skk-katakana-mode-string "ア")
  (setq skk-jisx0208-latin-mode-string "Ａ")
  (setq my/ddskk-jisyo-directory (locate-user-emacs-file "jisyo"))
  (defun my/ddskk-skk-get ()
    (unless (file-directory-p my/ddskk-jisyo-directory)
      (skk-get my/ddskk-jisyo-directory))))

(leaf dockerfile-mode :if (executable-find "docker") :ensure t)

(leaf dumb-jump
  :ensure t)

(leaf easy-hugo :if (executable-find "hugo") :ensure t)

(leaf editorconfig :ensure t)

(leaf eshell
  :bind ("C-c #" . eshell)
  :custom (eshell-path-env . `,(string-join exec-path ":"))
  :config
  (defun eshell/hello ()
    (message "hello world")))

(leaf flycheck :ensure t)

(leaf folding
  :ensure t
  :mode ("\\.z?sh\\'" "\\.zshrc\\(\\..*\\)?\\'"))

(leaf ido
  :hook (after-init-hook . my/ido-init)
  :custom
  (ido-enable-flex-matching . t)
  (ido-use-faces . t)
  :init
  (defun my/ido-init ()
    (ido-mode t)
    (ido-everywhere t))
  (leaf imenu-anywhere
    :ensure t
    :bind ("M-." . ido-imenu-anywhere))
  (leaf smex
    :ensure t
    :bind (("M-x" . smex)
           ("M-X" . mex-major-mode-commands)))
  (leaf ido-vertical-mode
    :ensure t
    :hook (after-init-hook . ido-vertical-mode)
    :custom
    (ido-vertical-define-keys . 'C-n-and-C-p-only)))

(leaf k8s-mode :ensure t)

(leaf lua-mode :ensure t)

(leaf macrostep
  :ensure t
  :bind ("C-c e" . macrostep-expand))

(leaf open-junk-file
  :ensure t
  :hook (kill-emacs-hook . my/open-junk-file-delete-files)
  :bind ("C-c j" . open-junk-file)
  :init
  (setq my/open-junk-file-directory (locate-user-emacs-file "junk/"))
  (setq open-junk-file-format (concat my/open-junk-file-directory "%s."))
  (defun my/open-junk-file-delete-files ()
    (interactive)
    (let ((junk-files (directory-files my/open-junk-file-directory t "^\\([^.]\\|\\.[^.]\\|\\.\\..\\)")))
      (dolist (x junk-files) (delete-file x)))))

(leaf popwin
  :ensure t
  :hook (after-init-hook . popwin-mode)
  :config
  (mapcar
   #'(lambda (x) (push x popwin:special-display-config))
   '(("*Buffer List*")
     ("*eshell*" :height 30 :dedicated t :stick t)
     ("*Warnings*"))))

(leaf markdown-mode :ensure t)

(leaf markdown-preview-mode :ensure t :mode "\\.md\\'")

(leaf rainbow-mode :ensure t)

(leaf rpn-calc :ensure t)

(leaf shell-script-mode
  :mode ("\\.zshrc\\'" "\\.zshrc\\(\\..*\\)?\\'" "\\.zsh\\'"))

(leaf terraform-mode
  :if (executable-find "terraform")
  :ensure t
  :hook (terraform-mode-hook . terraform-format-on-save-mode)
  :config
  (leaf terraform-doc :ensure t))

(leaf whitespace
  :hook ((after-init-hook . global-whitespace-mode)
         (before-save-hook . whitespace-cleanup))
  :custom
  (whitespace-space-regexp . "\\(\u3000+\\)")
  (whitespace-style . '(face trailing spaces empty space-mark tab-mark))
  (whitespace-display-mappings . '((space-mark ?\u3000 [?\u25a1])
                                   (tab-mark ?\t [?\u00bb ?\t] [?\\ ?\t])))
  (whitespace-action . '(auto-cleanup)))

(leaf xclip
  :if (or (executable-find "xclip")
          (executable-find "xsel")
          (executable-find "pbcopy"))
  :ensure t
  :hook (after-init-hook . xclip-mode))

(leaf yaml-mode :ensure t)
(put 'set-goal-column 'disabled nil)
