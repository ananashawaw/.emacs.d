;; -*- lexical-binding: t; -*-
(setq package-enable-at-startup nil)

(defvar elpaca-installer-version 0.11)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1 :inherit ignore
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

(elpaca elpaca-use-package
  (elpaca-use-package-mode))

(elpaca-queue (elpaca '(melpulls :host github :repo "progfolio/melpulls")
                (add-to-list 'elpaca-menu-functions #'melpulls)))

(defun +elpaca/build-if-new (e)
  (setf (elpaca<-build-steps e)
        (if-let* ((default-directory (elpaca<-build-dir e))
                  (main (ignore-errors (elpaca--main-file e)))
                  (compiled (expand-file-name (concat (file-name-base main) ".elc")))
                  ((file-newer-than-file-p main compiled)))
            (progn (elpaca--signal e "Rebuilding due to source changes")
                   (cl-set-difference elpaca-build-steps
                                      '(elpaca--clone elpaca--configure-remotes elpaca--checkout-ref)))
          (elpaca--build-steps nil (file-exists-p (elpaca<-build-dir e))
                               (file-exists-p (elpaca<-repo-dir e)))))
  (elpaca--continue-build e))

(use-package benchmark-init
  :ensure t
  ;; To disable collection of benchmark data after init is done
  :config
  (add-hook 'after-init-hook #'benchmark-init/deactivate))

(use-package with-editor
  :ensure (with-editor :host github :repo "magit/with-editor")
  :hook (eshell-mode . with-editor-export-editor)
  :config
  (shell-command-with-editor-mode)
  :custom
  (with-editor-mode-lighter " w.ed"))

(use-package transient
  :ensure (transient :host github :repo "magit/transient")
  :custom
  (transient-highlight-mismatched-keys t) ;; this is for customizing the faces, unless I grow to like it
  (transient-highlight-higher-levels t) ;; same as above
  (transient-default-level 7) ;; same as above
  )

(use-package magit
  :ensure (magit :host github :repo "magit/magit"))

(use-package sqlite3
  :ensure (sqlite3 :host github :repo "pekingduck/emacs-sqlite3-api"))

(use-package yaml
  :ensure (yaml :host github :repo "zkry/yaml.el" ))
(use-package cond-let
  :ensure (cond-let :host github :repo "tarsius/cond-let"))

(use-package forge
  ;;:ensure nil
  :ensure (forge :host github :repo "magit/forge")
  )

(use-package magit-commit-mark
  :ensure (magit-commit-mark :host codeberg :repo "ideasman42/emacs-magit-commit-mark"))

(use-package magit-find-file
  :ensure (magit-find-file :host github :repo "bradwright/magit-find-file.el")
  :bind ("C-c p" . magit-find-file-completing-read))

(use-package eshell
  :ensure nil
  :demand t
  :custom
  ;; em-cmpl.el
  (eshell-show-lisp-completions nil) ; t would be too laggy and verbose.
  ;; em-dirs.el
  (eshell-pushd-tohome t)
  (eshell-pushd-dextract t)
  (eshell-pushd-dunique t)
  ;; em-glob.el
  (eshell-glob-include-dot-files t)
  (eshell-glob-include-dot-dot nil) ; if t, then grep and the alike, using -r, will grep outside of specified directory !
  ;; em-ls.el
  (eshell-ls-exclude-hidden nil) ; We already are using -A and -a, but we keep that in case, note that -A overrides this, so it won't show ".." or "." 
  (eshell-ls-initial-args "-Ah")
  (eshell-ls-dired-initial-args "-ah")
  (eshell-ls-use-in-dired t)
  ;; em-script.el
  (eshell-login-script "~/.emacs.d/eshell/elogin.el")
  (eshell-login-script "~/.emacs.d/eshell/eprofile.el")
  ;; em-term.el
  (eshell-visual-subcommands (("git" "log" "diff" "show")))
  (eshell-visual-options (("git" "--help" "-h" "--paginate" "-p" )))
  ;; em-unix.el
  (eshell-rm-removes-directories t)
  ;; esh-cmd.el
  (eshell-prefer-lisp-functions t)
  ;; esh-mode.el
  (eshell-directory-name "~/.emacs.d/eshell/")
  ;; esh-module.el
  (eshell-modules-list '(eshell-alias
                         ;; eshell-banner ; done in elogin.el
                         eshell-basic
                         eshell-cmpl
                         eshell-dirs
                         ;; eshell-elecslash ; unpractical.
                         eshell-extpipe
                         eshell-glob
                         eshell-hist
                         eshell-ls
                         eshell-pred
                         eshell-prompt
                         ;; eshell-rebind ;; bad rebinds.
                         eshell-script
                         ;; eshell-smart ;; quirky and buggy.
                         eshell-term
                         ;; eshell-tramp ;; I don't use tramp.
                         ;; eshell-xtra ;; I don't use these aliases.
                         eshell-unix)))

(use-package yasnippet
  :ensure t
  :hook (c-mode . yas-minor-mode)
  :config
  (define-key yas-minor-mode-map [(tab)]        nil)
  (define-key yas-minor-mode-map (kbd "TAB")    nil)
  (define-key yas-minor-mode-map (kbd "<tab>")  nil)
  (yas-global-mode t))

(use-package eldoc
  :ensure nil
  :demand t
  :config
  (global-eldoc-mode))

(use-package lsp-bridge
  :ensure '(lsp-bridge
            :type git :host github :repo "manateelazycat/lsp-bridge"
            :files (:defaults "*.el" "*.py" "acm" "core" "langserver" "multiserver" "resources")
            :build (:not elpaca--byte-compile))
  :custom
  (lsp-bridge-c-lsp-server "clangd")
  (lsp-bridge-python-multi-lsp-server "pylsp_ruff")
  (lsp-bridge-python-lsp-server "pylsp")
  (lsp-bridge-tex-lsp-server "texlab")
  ;;(lsp-bridge-markdown-lsp-server )
  (lsp-bridge-cmake-lsp-server "cmake-language-server")
  ;;; Variables.
  (lsp-bridge-enable-inlay-hint t) ;; to test
  (lsp-bridge-enable-hover-diagnostic t) ;; to test
  (lsp-bridge-enable-debug nil) ;; to test
  (acm-backend-lsp-candidate-max-length 200) ;; fuck java, to test
  (lsp-bridge-signature-show-with-frame-position "point") ;; testing to see if pop up works
  :config
  (global-lsp-bridge-mode))

(use-package yafolding
  :ensure (yafolding :host github :repo "emacsorphanage/yafolding")
  :hook (prog-mode . yafolding-mode)
  :custom
  (yafolding-ellipsis-content "(...)")
  (yafolding-show-fringe-marks t))

(use-package iedit
  :ensure (iedit :host github :repo "victorhge/iedit")
  :custom
  (iedit-auto-narrow t) ;; C-h C-; to iedit + narrow
  (iedit-index-update-limit 200) ;; if we need to work with many occurences, we can delay global modifications using M-b before then after the edits.
  (iedit-increment-format-string (format "%%0%dd" (length (number-to-string iedit-index-update-limit)))))

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(abbrev-suggest t)
 '(align-indent-before-aligning t)
 '(auto-image-file-mode t)
 '(case-fold-search t)
 '(column-number-mode t)
 '(compilation-ask-about-save t)
 '(context-menu-mode t)
 '(ctl-arrow nil)
 '(diff-default-read-only nil)
 '(diff-mode-hook '(diff-delete-empty-files diff-make-unified))
 '(dired-kept-versions 5)
 '(display-raw-bytes-as-hex t)
 '(electric-pair-skip-whitespace-chars '(32 9 10))
 '(fancy-splash-image nil)
 '(find-file-hook
   '(mode-local-post-major-mode-change url-handlers-set-buffer-mode
                                       epa-file-find-file-hook
                                       vc-refresh-state
                                       ede-turn-on-hook))
 '(fringe-mode 6 nil (fringe))
 '(gdb-debug-log-max nil)
 '(gdb-debuginfod-enable-setting t)
 '(gdb-enable-debug t)
 '(gdb-many-windows t)
 '(ggtags-global-output-format 'ctags)
 '(ggtags-mode-prefix-key [3])
 '(global-ede-mode t)
 '(global-semantic-decoration-mode nil)
 '(global-semantic-highlight-edits-mode t)
 '(global-semantic-highlight-func-mode t)
 '(global-semantic-idle-breadcrumbs-mode t nil (semantic/idle))
 '(global-semantic-idle-completions-mode t nil (semantic/idle))
 '(global-semantic-idle-local-symbol-highlight-mode t nil (semantic/idle))
 '(global-semantic-idle-summary-mode t)
 '(global-semantic-mru-bookmark-mode t)
 '(global-semantic-show-parser-state-mode t)
 '(global-semantic-show-unmatched-syntax-mode t)
 '(global-semantic-stickyfunc-mode t)
 '(global-tab-line-mode t)
 '(grep-highlight-matches 'always)
 '(gud-key-prefix [24 1])
 '(gud-tooltip-mode t)
 '(image-load-path
   '(data-directory load-path " ~/Pictures/" " ~/emacs/"))
 '(imenu-auto-rescan t)
 '(indent-tabs-mode nil)
 '(initial-scratch-message nil)
 '(ispell-check-comments nil)
 '(ispell-dictionary nil)
 '(ispell-following-word t)
 '(ispell-silently-savep t)
 '(kept-new-versions 5)
 '(kept-old-versions 5)
 '(linum-format 'dynamic)
 '(package-selected-packages
   '( auto-header
      auto-virtualenv c-eldoc demangle-mode disaster
      context-coloring utop ejc-sql emacsql sql-indent
      flycheck-clang-analyzer flycheck-clangcheck
      flycheck-cython flycheck-ocaml
      flycheck-pycheckers ggtags git
      git-auto-commit-mode git-backup git-blamed
      magit-annex magit-commit-mark magit-delta
      magit-file-icons magit-find-file magit-gh-pulls
      magit-gitlab magit-org-todos magit-todos
      highlight idlwave indent-guide gh-md vmd-mode
      flymd org-sql pdf-tools prism
      pydoc python python-mode elpy anaconda-mode
      treemacs-magit undo-tree yasnippet-snippets))
 '(prog-mode-hook '( abbrev-mode))
 '(py-auto-complete-p t)
 '(py-auto-fill-mode nil)
 '(py-beep-if-tab-change nil)
 '(py-docstring-style 'django)
 '(py-indent-tabs-mode nil)
 '(python-indent-offset 4)
 '(python-shell-completion-native-disabled-interpreters nil)
 '(scalable-fonts-allowed t)
 '(semantic-complete-inline-analyzer-displayer-class 'semantic-displayer-tooltip)
 '(semantic-default-submodes
   '(global-semantic-highlight-func-mode global-semantic-stickyfunc-mode
                                         global-semantic-idle-completions-mode
                                         global-semantic-idle-scheduler-mode
                                         global-semanticdb-minor-mode
                                         global-semantic-idle-summary-mode
                                         global-semantic-mru-bookmark-mode
                                         global-semantic-idle-local-symbol-highlight-mode
                                         global-semantic-highlight-edits-mode
                                         global-semantic-show-unmatched-syntax-mode
                                         global-semantic-show-parser-state-mode))
 '(semantic-mode t)
 '(show-paren-context-when-offscreen 'overlay)
 '(show-paren-delay 0)
 '(show-paren-style 'mixed)
 '(standard-indent 2)
 '(tab-width 2)
 '(text-mode-hook '(text-mode-hook-identify))
 '(treesit-fold-line-count-format " %d lines ")
 '(treesit-fold-line-count-show t)
 '(treesit-fold-on-next-line t)
 '(treesit-fold-summary-show nil)
 '(treesit-font-lock-level 4)
 '(use-package-check-before-init t)
 '(utop-load-packages-without-asking t)
 '(vc-make-backup-files t)
 '(warning-suppress-types '((treesit) (treesit)))
 '(which-function-mode t))

(setq require-final-newline t)

;;(require 'python-mode)
(require 'url-handlers)
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(treesit-fold-replacement-face ((t (:foreground "#808080" :box (:line-width (1 . -1) :style pressed-button))))))

(setq gud-gdb-command-name "gdb -i=mi")

;; all 3 are from http://whattheemacsd.com
(global-set-key (kbd "M-j")
                (lambda ()
                  (interactive)
                  (join-line -1)))

(defun delete-current-buffer-file ()
  "Removes file connected to current buffer and kills buffer."
  (interactive)
  (let ((filename (buffer-file-name)))
    (if (not (and filename (file-exists-p filename)))
        (ido-kill-buffer)
      (when (yes-or-no-p "Are you sure you want to remove this file? ")
          (delete-file filename)
          (kill-buffer 'current-buffer)
          (message "File '%s' successfully removed" filename)))))

(global-set-key (kbd "C-x C-k") 'delete-current-buffer-file)

(defun rename-current-buffer-file ()
  "Renames current buffer and file it is visiting."
  (interactive)
  (let ((name (buffer-name))
        (filename (buffer-file-name)))
    (if (not (and filename (file-exists-p filename)))
        (error "Buffer '%s' is not visiting a file!" name)
      (let ((new-name (read-file-name "New name: " filename)))
        (if (get-buffer new-name)
            (error "A buffer named '%s' already exists!" new-name)
          (rename-file filename new-name 1)
          (rename-buffer new-name)
          (set-visited-file-name new-name)
          (set-buffer-modified-p nil)
          (message "File '%s' successfully renamed to '%s'"
                   name (file-name-nondirectory new-name)))))))

(global-set-key (kbd "C-x C-r") 'rename-current-buffer-file)

(use-package arxiv-mode
  :ensure (arxiv-mode :host github :repo "fizban007/arxiv-mode")
  :init
  (mkdir "~/Documents/arxiv" t)
  :custom
  (arxiv-author-list-maximum 0)
  (arxiv-default-download-folder "~/Documents/arxiv")
  (arxiv-default-bibliography "~/Documents/arxiv/bibliography")
  (arxiv-startup-with-abstract-window t))

(use-package treesit
  :ensure nil
  :custom (treesit-language-source-alist '((asm  "https://github.com/RubixDev/tree-sitter-asm")
                                           (bash  "https://github.com/tree-sitter/tree-sitter-bash")
                                           (bibtex  "https://github.com/latex-lsp/tree-sitter-bibtex")
                                           (c  "https://github.com/tree-sitter/tree-sitter-c")
                                           (cmake  "https://github.com/uyha/tree-sitter-cmake")
                                           (cpp "https://github.com/tree-sitter/tree-sitter-cpp/" "master" "src")
                                           (elisp  "https://github.com/Wilfred/tree-sitter-elisp")
                                           (haskell "https://github.com/tree-sitter/tree-sitter-haskell" "master" "src")
                                           (html  "https://github.com/tree-sitter/tree-sitter-html")
                                           (json "https://github.com/tree-sitter/tree-sitter-json")
                                           (lua  "https://github.com/MunifTanjim/tree-sitter-lua" "main" "src")
                                           (markdown  "https://github.com/tree-sitter-grammars/tree-sitter-markdown")
                                           (markdown-inline  "https://github.com/tree-sitter-grammars/tree-sitter-markdown")
                                           (ocaml  "https://github.com/tree-sitter/tree-sitter-ocaml")
                                           (ocaml-interface  "https://github.com/tree-sitter/tree-sitter-ocaml")
                                           (org  "https://github.com/emiasims/tree-sitter-org")
                                           (python  "https://github.com/tree-sitter/tree-sitter-python")
                                           (rust "https://github.com/tree-sitter/tree-sitter-rust" "master" "src")
                                           (sql  "https://github.com/DerekStride/tree-sitter-sql")
                                           (yaml "https://github.com/tree-sitter-grammars/tree-sitter-yaml"))))


(use-package treesit-fold
  :ensure (treesit-fold :host github :repo "emacs-tree-sitter/treesit-fold")
  :custom
  (treesit-fold-line-count-format " %d lines ")
  (treesit-fold-line-count-show t)
  (treesit-fold-on-next-line t)
  (treesit-fold-summary-show nil)
  (treesit-font-lock-level 4))

(use-package novice
  :ensure nil
  :custom
  (disabled-command-function nil))

(use-package dired-auto-readme
  :ensure (dired-auto-readme :host github :repo "amno1/dired-auto-readme")
  :hook (dired-mode . dired-auto-readme-mode)
  :custom
  (dired-auto-readme-separator "\f\n"))

(use-package page-break-lines
  :ensure (page-break-lines :host github :repo "purcell/page-break-lines")
  :custom
  (page-break-lines-char ?─)
  (page-break-lines-lighter "^L")
  (page-break-lines-modes '(prog-mode text-mode special-mode dired-auto-readme-mode)))

(use-package trailing-newline-indicator
  :ensure (trailing-newline-indicator :host github :repo "saulotoledo/trailing-newline-indicator"))

(use-package dashboard
  :ensure (dashboard :host github :repo "emacs-dashboard/emacs-dashboard")
  :config
  (add-hook 'elpaca-after-init-hook #'dashboard-insert-startupify-lists) 
  (add-hook 'elpaca-after-init-hook #'dashboard-initialize) 
  (add-hook 'window-size-change-functions #'dashboard-resize-on-hook 100)
  (add-hook 'window-setup-hook #'dashboard-resize-on-hook)
  :custom
  (dashboard-buffer-name "Welcome !")
  (dashboard-banner-ascii "KIGOTH")
  (dashboard-startup-banner "~/.emacs.d/council.jpeg" 'ascii 0)
  (dashboard-banner-logo-title "Hello Dearest Ana, may you have a good time !")
  (dashboard-items '((recents   . 10)
                     (bookmarks . 5)
                     (projects  . 5)))
  (dashboard-footer-messages '("UwU"
                               "UmU"
                               "UvU"
                               "UxU"
                               "OwO"
                               ">~<"
                               "^v^"
                               "^~^"
                               "^O^"
                               "u,u"))
  (dashboard-icon-file-height 1.0)
  (dashboard-image-banner-max-height 0)
  (dashboard-image-banner-max-width 966) ;; why 966 ? is it the width of my screen?
  (dashboard-remove-missing-entry t)
  (dashboard-show-shortcuts t)
  (dashboard-startupify-list '(dashboard-insert-banner
                               dashboard-insert-newline
                               dashboard-insert-banner-title
                               dashboard-insert-newline
                               dashboard-insert-navigator
                               dashboard-insert-newline
                               dashboard-insert-init-info
                               dashboard-insert-page-break
                               (lambda (&rest _) (insert "\n\f\n"))
                               dashboard-insert-items
                               dashboard-insert-newline
                               dashboard-insert-footer))
  (dashboard-page-separator "\n")
  ;; Format: "(icon title help action face prefix suffix)"
  (dashboard-navigator-buttons
   `(;; line1
     (("★"
       "Repos"
       "Browse github repositories."
       (lambda (&rest _) (browse-url "https://github.com/ananashawaw?tab=repositories"))
       warning)
      ("?" "" "?/h" #'show-help nil "<" ">")))))

(use-package colorful-mode
  :ensure (colorful-mode :host github :repo "DevelopmentCool2449/colorful-mode")
  :config
  (global-colorful-mode t)
  (global-unset-key (kbd "C-x c x"))
  (global-unset-key (kbd "C-x c c"))
  (global-unset-key (kbd "C-x c r")))

(use-package ascii-table
  :ensure (ascii-table :host github :repo "ananashawaw/emacs-ascii-table")
  :custom
  (ascii-table-initial-base 10)
  (ascii-table-initial-control nil)
  (ascii-table-initial-escape t))

(use-package pink-bliss-uwu-theme
  :ensure (pink-bliss-uwu-theme
           :host github :repo "themkat/pink-bliss-uwu"
           :remotes ("ana" :repo "ananashawaw/pink-bliss-uwu"))
  :config
  (load-theme 'pink-bliss-uwu t)
  :custom
  (pink-bliss-uwu-use-custom-font t))

(use-package shades-of-purple-theme
  :ensure (shades-of-purple-theme :host github :repo "arturovm/shades-of-purple-emacs")
  :config
  (load-theme 'shades-of-purple t t))

(use-package girly-notebook-theme
  :ensure (girly-notebook-theme :host github :repo "melissaboiko/girly-notebook-theme")
  :config
  (load-theme 'girly-notebook t t))

(defun screenshot-svg ()
  "Save a screenshot of the current frame as an SVG image.
Saves to a temp file and puts the filename in the kill ring."
  (interactive)
  (let* ((filename (make-temp-file "Emacs" nil ".svg"))
         (data (x-export-frames nil 'svg)))
    (with-temp-file filename
      (insert data))
    (kill-new filename)
    (message filename)))

(use-package screenshot
  :ensure (screenshot :host github :repo "tecosaur/screenshot"))

(use-package test-c
  :ensure (test-c :host github :repo "aaptel/test-c")
  :custom
  (test-c-default-compile-command "gcc -O3 $src -o $exe")
  (test-c-default-run-command "$exe ; echo $?")
  (test-c-default-code "
#include <stdio.h>
#include <stdint.h>
#include <stddef.h>

int main()
  {int uwu = 17;
   printf(\"%d\\n\", uwu);};"))

(use-package compiler-explorer
  :ensure (compiler-explorer :host github :repo "mkcms/compiler-explorer.el")
  :bind (("M-g" . compiler-explorer)
         :map compiler-explorer-mode-map
         ("M-g c" . compiler-explorer-set-compiler)
         ("M-g f" . compiler-explorer-set-compiler-args)
         ("M-g M-f" . compiler-explorer-set-execution-args)
         ("M-g i" . compiler-explorer-set-input)
         ("M-g j" . compiler-explorer-jump)
         ("M-g y" . compiler-explorer-layout)
         ("M-g M-l a" . compiler-explorer-add-library)
         ("M-g M-l r" . compiler-explorer-remove-library)
         ("M-g r" . compiler-explorer-new-session)
         ("M-g p" . compiler-explorer-previous-session)
         ("M-g s" . compiler-explorer-make-link)
         ("M-g M-s" . compiler-explorer-restore-from-link)
         ("M-g <del>" . compiler-explorer-exit)
         ("M-g M-d" . compiler-explorer-discard-session))
  :custom
  (compiler-explorer-sessions 10)
  (compiler-explorer-default-layout [(source . asm) output]))

(use-package cc-mode
  :ensure nil
  :hook (c-mode-common . (lambda ()
                           (progn
                             ;; Minor mode, commands insert block comments instead of line comments by default
                             (c-toggle-comment-style 1)
                             ;; Minor mode off, use C-c C-d and C-c C-DEL instead.
                             (c-toggle-auto-hungry-state -1)
                             ;; Minor mode on, makes commands on words consider capitalization.
                             ;; M-f PascalCase = goes to Case instead of the end of PascalCase.
                             (subword-mode 1)
                             ;; Minor mode on, this also enable electric.
                             (c-toggle-auto-newline 1))))
  :init
  (c-add-style "ana" '(;; Comments
                       (c-comment-only-line-offset 0)
                       (c-block-comment-prefix "*")
                       (c-doc-comment-style . ((c-mode . gtkdoc)
                                               (c++-mode . gtkdoc)
                                               (java-mode . javadoc)
                                               (pike-mode . autodoc)))
                       
                       ;; Auto-newline minor mode
                       ;; Hanging braces, colons, commas and semicolons
                       (c-hanging-braces-alist . ((arglist-close nil) ; nil because we put a semicolon after it
                                                  (brace-list-intro after) ; RET after first content of a {} list
                                                  (defun-open before) ; RET after closing ) of function def
                                                  (defun-close nil) ; nil because we put semicolon after it
                                                  (class-open before) ; this is C++ but same result as defun-open
                                                  (class-close nil) ; C++ but defun-close logic
                                                  (block-open before) ; defun-open logic
                                                  (block-close nil) ; defun-close logic
                                                  (statement-cont before) ; idk this is for statement continuation like uwu = \n a + b + c ...
                                                  (substatement-open before) ; defun-open logic
                                                  (statement-case-open before) ; defun-open logic
                                                  (brace-list-open nil) ; keep {} list connected to the =
                                                  (brace-list-close nil) ; nil because we put comma after it
                                                  (brace-entry-open before) ; defun-open logic
                                                  (extern-lang-open before) ; defun-open logic
                                                  (extern-lang-close nil) ; defun-close logic
                                                  (namespace-open before) ; C++ but extern logic
                                                  (namespace-close after) ; C++ but extern logic
                                                  (module-open before) ; CORBA IDL, extern logic
                                                  (module-close after) ; CORBA IDL, extern logic
                                                  (composition-open before) ; CORBA IDL, extern logic
                                                  (composition-close after) ; CORBA IDL, extern logic
                                                  (inexpr-class-open before) ; Java, but C++ class logic
                                                  (inexpr-class-close nil) ; Java, but C++ class logic
                                                  (inline-open before) ; C++ but defun-open logic
                                                  (inline-close nil) ; C++ but defun-close logic
                                                  (arglist-cont-nonempty before))) ; lines up arguments vertically
                       
                       (c-hanging-colons-alist . ((case-label after) ; RET after : of a case label
                                                  (label after) ; RET after : of a goto label
                                                  (access-label after) ; C++ RET after visibility keyword ( public, private, etc.)
                                                  (member-init-intro after) ; C++ no idea but looks like a label
                                                  (inher-intro after))) ; C++ no idea but looks like a label
                       
                       ;; We don't want a ret when we're about to close the scope, but, we can't distinguish "usual" ; from ;} before we type it
                       ;; As such, we just prevent the insertion of newlines after a , or ; altogether
                       (c-hanging-semi&comma-criteria . ((lambda () 'stop)
                                                         c-semi&comma-inside-parenlist
                                                         c-semi&comma-no-newlines-for-oneline-inliners
                                                         c-semi&comma-no-newlines-before-nonblanks))
                       
                       ;; Cleanup
                       (c-max-one-liner-length 100)
                       
                       (c-cleanup-list . (defun-close-semi
                                          list-close-comma
                                          scope-operator
                                          one-liner-defun
                                          compact-empty-funcall
                                          comment-close-slash))
                       
                       ;; Indenting
                       (c-label-minimum-indentation 0)
                       (c-basic-offset 1)
                       
                       (c-offsets-alist . ((string . -1000)
                                           (c . (first
                                                 c-lineup-C-comments))
                                           (defun-open . 2)
                                           (defun-close . (first
                                                           c-lineup-close-paren
                                                           0))
                                           (defun-block-intro . (first
                                                                 c-lineup-arglist-intro-after-paren
                                                                 0))
                                           (class-open . 2)
                                           (class-close . (first
                                                           c-lineup-close-paren
                                                           0))
                                           (inline-open . 2)
                                           (inline-close . (first
                                                            c-lineup-close-paren
                                                            0))
                                           (func-decl-cont . (first
                                                              c-lineup-java-throws
                                                              1))
                                           (knr-argdecl-intro . 1)
                                           (knr-argdecl . 0)
                                           (topmost-intro . 0)
                                           (topmost-intro-cont . (first
                                                                  c-lineup-string-cont
                                                                  c-lineup-assignments
                                                                  c-lineup-cascaded-calls
                                                                  c-lineup-topmost-intro-cont))
                                           (constraint-cont . (first
                                                               c-lineup-item-after-paren-at-boi
                                                               2))
                                           (annotation-top-cont . 0)
                                           (annotation-var-cont . 0)
                                           (member-init-intro . 1)
                                           (member-init-cont . (first
                                                                c-lineup-multi-inher))
                                           (class-field-cont . (first
                                                                c-lineup-java-inher))
                                           (inher-intro . 1)
                                           (inher-cont . (first
                                                          c-lineup-multi-inher
                                                          c-lineup-java-inher))
                                           (block-open . 0)
                                           (block-close . (first
                                                           c-lineup-close-paren
                                                           0))
                                           (brace-list-open . 2)
                                           (brace-list-close . (first
                                                                c-lineup-arglist-close-under-paren
                                                                c-lineup-close-paren
                                                                0))
                                           (brace-list-intro . (first
                                                                c-lineup-2nd-brace-entry-in-arglist
                                                                c-lineup-arglist-intro-after-paren
                                                                c-lineup-class-decl-init-after-brace
                                                                0))
                                           (brace-list-entry . (first
                                                                c-lineup-arglist-close-under-paren
                                                                c-lineup-under-anchor))
                                           (brace-entry-open . 0)
                                           (enum-open . 2)
                                           (enum-close . (first
                                                          c-lineup-close-paren
                                                          0))
                                           (enum-intro . (first
                                                          c-lineup-arglist-intro-after-paren
                                                          1))
                                           (enum-entry . (first
                                                          c-lineup-under-anchor))
                                           (statement . (first
                                                         c-lineup-runin-statements))
                                           (statement-cont . (first
                                                              c-lineup-string-cont
                                                              c-lineup-ternary-bodies
                                                              c-lineup-cascaded-calls
                                                              c-lineup-assignments
                                                              1))
                                           (statement-block-intro . (first
                                                                     c-lineup-arglist-intro-after-paren
                                                                     1))
                                           (statement-case-intro . (first
                                                                    c-lineup-arglist-intro-after-paren
                                                                    2))
                                           (statement-case-open . 0)
                                           (substatement . 1)
                                           (substatement-open . 2)
                                           (substatement-label . 2)
                                           (case-label . (first
                                                          c-lineup-runin-statements))
                                           (access-label . -1)
                                           (label . 2)
                                           (do-while-closure . 0)
                                           (else-clause . 0)
                                           (catch-clause . 0)
                                           (comment-intro . (first
                                                             c-lineup-knr-region-comment
                                                             c-lineup-comment))
                                           (arglist-intro . (first
                                                             c-lineup-arglist-intro-after-paren
                                                             1))
                                           (arglist-cont . (first
                                                            c-lineup-gcc-asm-reg
                                                            c-lineup-string-cont
                                                            c-lineup-cascaded-calls
                                                            c-lineup-ternary-bodies
                                                            c-lineup-arglist-operators
                                                            c-lineup-assignments
                                                            (add c-lineup-argcont -2)
                                                            c-lineup-arglist
                                                            c-lineup-arglist-close-under-paren
                                                            c-lineup-gcc-asm-reg
                                                            0))
                                           (arglist-cont-nonempty . (first
                                                                     c-lineup-gcc-asm-reg
                                                                     c-lineup-string-cont
                                                                     c-lineup-cascaded-calls
                                                                     c-lineup-ternary-bodies
                                                                     c-lineup-arglist
                                                                     c-lineup-assignments
                                                                     (add c-lineup-argcont -2)
                                                                     c-lineup-arglist-operators
                                                                     c-lineup-arglist-close-under-paren
                                                                     c-lineup-arglist))
                                           (arglist-close . (first
                                                             c-lineup-arglist
                                                             c-lineup-arglist-close-under-paren
                                                             c-lineup-close-paren))
                                           (stream-op . (first
                                                         c-lineup-streamop))
                                           (inclass . 1)
                                           (cpp-macro . -1000)
                                           (cpp-macro-cont . 1)
                                           (cpp-define-intro . 2)
                                           (friend . 0)
                                           (objc-method-intro .
                                                              [0])
                                           (objc-method-args-cont . (first
                                                                     c-lineup-ObjC-method-args-2))
                                           (objc-method-call-cont . (c-lineup-ObjC-method-call-colons
                                                                     c-lineup-ObjC-method-call
                                                                     1))
                                           (extern-lang-open . 0)
                                           (namespace-open . 0)
                                           (module-open . 0)
                                           (composition-open . 0)
                                           (extern-lang-close . (first
                                                                 c-lineup-close-paren
                                                                 0))
                                           (namespace-close . (first
                                                               c-lineup-close-paren
                                                               0))
                                           (module-close . (first
                                                            c-lineup-close-paren
                                                            0))
                                           (composition-close . (first
                                                                 c-lineup-close-paren
                                                                 0))
                                           (inextern-lang . 1)
                                           (innamespace . 1)
                                           (inmodule . 1)
                                           (incomposition . 1)
                                           (template-args-cont . (first
                                                                  c-lineup-template-args
                                                                  1))
                                           (inlambda . (first
                                                        c-lineup-inexpr-block))
                                           (lambda-intro-cont . 1)
                                           (inexpr-statement . (first
                                                                c-lineup-inexpr-block
                                                                2))
                                           (inexpr-class . (first
                                                            c-lineup-inexpr-block
                                                            2))))
                       
                       ;; Preprocessor
                       (c-syntactic-indentation-in-macros t)
                       (c-backslash-column 30)
                       (c-backslash-max-column 200)
                       (c-auto-align-backslashes t)
                       (c-cpp-indent-to-body-directives . ("pragma"
                                                           "ifdef"
                                                           "endif"
                                                           "if"
                                                           "ifndef"
                                                           "else"
                                                           "elif"
                                                           "define"
                                                           "undef"))))
  :custom
  (c-default-style '((c-mode . "ana") ;; we could also use hooks.
                     (java-mode . "ana")
                     (other . "ana")))
  (c-style-variables-are-local-p nil)
  (c-tab-always-indent t)
  (c-progress-interval 10)
  (c-asymmetry-fontification-flag t)
  (c-guess-region-max nil) ; entire buffer
  (c-guess-offset-threshold 5)
  (c-defun-tactic 'go-outward) ; detect functions declaration inside functions (gcc extension).
  (c-electric-pound-behavior '(alignleft))
  (c-ignore-auto-fill '(string cpp code))
  (c-require-final-newline '((c-mode . t)
                             (c++-mode . t)
                             (objc-mode . t)
                             (java-mode . t)
                             (idl-mode . t)
                             (pike-mode . t)
                             (awk-mode . t))))

;; gotta custom it
(use-package auctex
  :ensure (auctex :repo "https://git.savannah.gnu.org/git/auctex.git" :branch "main"
                  :pre-build (("make" "elpa"))
                  :build (:not elpaca--compile-info) ;; Make will take care of this step
                  :files ("*.el" "doc/*.info*" "etc" "images" "latex" "style")
                  :version (lambda (_) (require 'auctex) AUCTeX-version))
  :hook (LaTeX-mode-hook . LaTeX-math-mode)
  :custom
  (TeX-parse-self t))

;; we also need to install normal latexmk I think.
(use-package auctex-latexmk
  :ensure t
  :custom
  (auctex-latexmk-inherit-TeX-PDF-mode t))

(use-package cdlatex
  :ensure (cdlatex :host github :repo "cdominik/cdlatex"))

(use-package xenops
  :ensure (xenops :host github :repo "dandavison/xenops"))

(use-package laas
  :ensure (laas :host github repo: "tecosaur/LaTeX-auto-activating-snippets"))

(use-package amsreftex
  :ensure (amsreftex :host github :repo "franburstall/amsreftex"))

(use-package magic-latex-buffer
  :ensure (magic-latex-buffer :host github :repo "zk-phi/magic-latex-buffer"))

(use-package latex-preview-pane
  :ensure (latex-preview-pane :host github :repo "jsinglet/latex-preview-pane")
  :custom
  (pdf-latex-command "pdflatex") ;; default but specified in case I want to use luatex or xetex
  (preview-orientation 'right) ;; can be any of : above, left, below and right.
  (latex-preview-pane-use-frame nil) ;; default but specified in case I want to go for OneOnOneEmacs
  (latex-preview-pane-multifile-mode 'auctex))

(use-package litex-mode
  :ensure (litex-mode :host github :repo "Atreyagaurav/litex-mode"))

(use-package tex-item
  :ensure (tex-item :host github :repo "ultronozm/tex-item.el"))

(use-package tex-parens
  :ensure (tex-parens :host github :repo "ultronozm/tex-parens.el"))

(use-package latex-table-wizard
  :ensure (latex-table-wizard :host github :repo "enricoflor/latex-table-wizard")
  :custom
  (latex-table-wizard-allow-detached-args t))

(use-package px
  :ensure (px :host github :repo "aaptel/preview-latex"))

(use-package opam
  :ensure (opam :host github :repo "emacsorphanage/opam")
  :hook ((coq-mode merlin-mode tuareg-mode caml-mode) . opam-init))

(use-package opam-switch-mode
  :ensure (opam-switch-mode :host github :repo "ProofGeneral/opam-switch-mode")
  :hook ((coq-mode tuareg-mode merlin-mode  caml-mode) . opam-switch-mode))

;; to configure
(use-package caml
  :ensure (caml :host github :repo "ocaml/caml-mode" :main "caml.el")
  :custom
  (caml-imenu-enable t)
  (caml-electric-indent t)
  (caml-electric-close-vector t))

(use-package tuareg
  :ensure (tuareg :host github :repo "ocaml/tuareg")
  :custom
  (tuareg-opam-insinuate t)
  (tuareg-electric-close-vector t)
  (tuareg-electric-indent t)
  (tuareg-indent-align-with-first-arg t)
  (tuareg-match-patterns-aligned t)
  (tuareg-mode-line-other-file t))

(use-package merlin
  :ensure (merlin :host github :repo "ocaml/merlin" :branch "main" :depth treeless
                  :files ("emacs/merlin.el" "emacs/merlin-imenu.el" "emacs/merlin-xref.el" "emacs/merlin-cap.el"))
  :hook ((tuareg-mode caml-mode) . merlin-mode)
  :custom
  (merlin-report-errors-in-lighter t)
  (merlin-completion-with-doc t)
  (merlin-favourite-caml-mode 'tuareg-mode)
  (merlin-error-after-save '("ml" "mli" "mly")) ;; OXcaml, metaOcaml ?
  (merlin-error-in-fringe t)
  (merlin-error-on-single-line nil)
  (merlin-locate-focus-new-window nil)
  (merlin-type-after-locate t)
  (merlin-construct-with-local-values t)
  (merlin-default-flags '("-strict-sequence" "-strict-formats"))
  (merlin-cache-lifespan 15))

(use-package merlin-eldoc
  :after (:all eldoc caml-mode tuareg-mode)
  :ensure (merlin-eldoc :host github :repo "Khady/merlin-eldoc")
  :hook ((caml-mode tuareg-mode) . merlin-eldoc-setup)
  :custom
  (merlin-eldoc-delimiter " | ")
  (merlin-eldoc-truncate-marker "(...)")
  (merlin-eldoc-skip-on-merlin-error nil))

(use-package dune
  :ensure (dune :host github :repo "ocaml/dune"
                :files ("editor-integration/emacs/dune.el" "editor-integration/emacs/dune-watch.el")))

(use-package merlin-iedit
  :ensure (merlin-iedit :host github :repo "ocaml/merlin"
                        :files ("emacs/merlin-iedit.el")))

(use-package ocamlformat
  :ensure (ocamlformat :host github :repo "ocaml-ppx/ocamlformat")
  :hook (before-save . ocamlformat-before-save)
  :custom
  (ocamlformat-enable 'enable-outside-detected-project))

(use-package utop
  :ensure (utop :host github :repo "ocaml-community/utop"))

(use-package proof-general
  :ensure (proof-general :host github :repo "ProofGeneral/PG"))

(use-package lolcode-mode
  :ensure (lolcode-mode :host github :repo "bodil/lolcode-mode"))

(use-package yaml-mode
  :ensure (yaml-mode :host github :repo "yoshiki/yaml-mode")
  :hook ((yaml-mode markdown-mode) . yafolding-mode)
  :init
  (add-to-list 'auto-mode-alist '("\\.yml\\'" . yaml-mode))
  :custom
  (yaml-indent-offset 4))

(use-package yaml-pro
  :ensure (yaml-pro :host github :repo "zkry/yaml-pro")
  ;;:hook ((yaml-mode yaml-ts-mode) . yaml-pro-ts-mode)
  :custom
  (yaml-pro-indent (if (boundp 'yaml-indent-offset)  yaml-indent-offset 4))
  (yaml-pro-max-parse-size 5000)
  (yaml-pro-format-print-width 0)
  (yaml-pro-format-features '(block-formatting
                              bm-fn-next-line
                              document-separator-own-line
                              indent
                              reduce-newlines))
  (yaml-pro-ts-yank-subtrees t)
  (yaml-pro-ts-path-element-separator ?→))

(use-package format-sql
  :ensure t)

(use-package json-reformat
  :ensure (json-reformat :host github :repo "gongo/json-reformat")
  :custom
  (json-reformat:indent-width 2)
  (json-reformat:pretty-string? t))

(use-package call-graph
  :ensure t
  :custom
  (call-graph-path-to-global "/usr/local/bin/global")
  (call-graph-initial-max-depth 10)
  (call-graph-ignore-invalid-reference t)
  (call-graph-display-func-args t))

(use-package gradle-mode
  :ensure (gradle-mode :host github :repo "scubacabra/emacs-gradle-mode"))

(use-package javadoc-lookup
  :ensure (javadoc-lookup :host github :repo "skeeto/javadoc-lookup")
  :config
  ;;(javadoc-add-roots "/usr/share/doc/openjdk-*/api");; maybe need more work to make sure we locate it.
  )

(use-package ebuild-mode
  :ensure (ebuild-mode :repo "https://gitweb.gentoo.org/proj/ebuild-mode.git"))

(use-package org
  :ensure nil
  :demand t
  :config
  (org-mode-restart))

(use-package toc-org
  :after org
  :ensure (toc-org :host github :repo "snosov1/toc-org")
  :hook (((org-mode markdown-mode) . toc-org-mode)
         (toc-org-mode . (lambda () (toc-org-insert-toc))))
  :init
  (org-mode)
  :custom
  (toc-org-max-depth 100) ;; it'll never go that deep but at least it covers all use cases.
  (toc-org-hrefify-default "gh") ;; "gh" and "org" are the only options
  (toc-org-enable-links-opening t))

(use-package org-modern
  :after org
  :ensure (org-modern :host github :repo "minad/org-modern")
  :hook (org-mode . org-modern-mode)
  :custom
  (org-modern-progress 40))

(use-package org-popup-posframe
  :after org
  :ensure (org-popup-posframe :host github :repo "A7R7/org-popup-posframe")
  :hook (org-mode . org-popup-posframe-mode))
