;; Tangle the source (get the Emacs Lisp source code pieces) using org mode, and then run it :)  -*- lexical-binding: t; -*-
;; replaced after first init.
(setq package-enable-at-startup nil)
;; we dont want it to pollute .emacs
(setq custom-file "~/.emacs.d/custom.el")
(require 'org)
(find-file  "~/.emacs.d/init.org")
(org-babel-tangle)
(load-file "~/.emacs.d/init.el")
;; byte compile to make it faster at startup
(byte-compile-file "~/.emacs.d/init.el")
;; workaround, so that we don't have to reload org afterwards.
(kill-buffer "init.org")
