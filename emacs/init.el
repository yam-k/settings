;;; init.el --- GNU Emacs settings. -*- lexical-binding: t; coding: utf-8 -*-

;;; 設定環境の準備 ===================================================
;;;; package ---------------------------------------------------------
(package-initialize)
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/"))
(add-to-list 'package-archive-priorities '("melpa" . 10))

;;;; package-installの改造 -------------------------------------------
(defun package-install-retry-advice (func &rest args)
  "`package-install'が失敗した時に再挑戦するようにするadvice.
:aroundに適用すると、失敗時に`package-refresh-contents'を評価した上で
再度パッケージの取得を試みる。2回目も失敗するとエラーとなる。
FUNCはpackage-install、ARGSはpackage-installに渡す引数。"
  (condition-case err
      (apply func args)
    (error (progn (package-refresh-contents)
                  (apply func args)))))
(advice-add #'package-install :around #'package-install-retry-advice)

;;;; define-keyの代替マクロ ------------------------------------------
(defmacro setkey (map key function &rest args)
  "キーバインド設定用マクロ.

(setkey global-map
  \"C-n\" #'next-line
  \"C-p\" #'previous-line)
のように、1つのキーマップに対して一度に複数のキーバインドを列挙できる。

MAPは設定したいキーマップ、KEYは`kbd'に渡せるキーシーケンス文字列、
FUNCTIONはキーシーケンスに対して設定したい関数。
ARGSは、[KEY FUNCTION]..."
  (declare (indent defun))
  (let ((sets (list (cons key function))))
    (while args
      (add-to-list 'sets (cons (pop args) (pop args))))
    `(progn
       ,@(mapcar (lambda (set)
                   `(define-key ,map (kbd ,(car set)) ,(cdr set)))
                 (reverse sets)))))

;;;; add-to-list -----------------------------------------------------
(defun add-elements-to-list (list-var &rest elements)
  "`add-to-list'をたくさん書く時に楽をする用の関数."
  (declare (indent defun))
  (mapc (lambda (element)
          (add-to-list list-var element))
        elements)
  list-var)

;;;; 自動生成ファイルを放り込むディレクトリの作成 --------------------
(defconst tmp-dir
  (expand-file-name "tmp/" user-emacs-directory)
  "自動生成ファイルの放り込み先ディレクトリ.")
(unless (file-exists-p tmp-dir)
  (make-directory tmp-dir t))

;;;; load-pathの設定 -------------------------------------------------
(let ((local-lisp-dir (expand-file-name "utils" user-emacs-directory)))
  ;; ディレクトリが無ければ作る
  (unless (file-exists-p local-lisp-dir)
    (make-directory local-lisp-dir t))

  (add-to-list 'load-path local-lisp-dir))

;;; 基本的な設定 =====================================================
;;;; デフォルトの文字コード ------------------------------------------
(set-language-environment "UTF-8")
(prefer-coding-system 'utf-8-emacs-unix)

;;;; フォント --------------------------------------------------------
(face-spec-set 'default '((t :font "HackGen Console NF"
                             :height 100)))
(face-spec-set 'fixed-pitch '((t :inherit default)))

;;;; 基本的な見た目 --------------------------------------------------
(setopt
 custom-enabled-themes '(adwaita) ;テーマ

 menu-bar-mode t ;メニューバーは表示
 tool-bar-mode nil ;ツールバーは非表示
 scroll-bar-mode 'right ;スクロールバーは右側
 )

;; (add-to-list 'default-frame-alist '(alpha . 50)) ;背景の透過

;;;; 基本的な挙動 ----------------------------------------------------
(setopt
 inhibit-startup-message t ;スタートアップ画面は非表示
 scroll-conservatively 100 ;スクロールは1行ずつ
 savehist-mode t ;操作履歴を記録
 dired-dwim-target t ;diredを2画面ファイラっぽくする
 )

(advice-add #'yes-or-no-p :override #'y-or-n-p) ;yes/noはy/nで

(setopt
 savehist-file (expand-file-name "history" tmp-dir) ;操作履歴の保存先
 custom-file (expand-file-name "custom.el" tmp-dir) ;変数設定の保存先
 )

(setopt ;バックアップファイルの保存先
 backup-directory-alist `((".*" . ,tmp-dir))
 version-control t
 delete-old-versions t
 kept-new-versions 5
 )
;; (setopt make-backup-files nil) ;作らない場合

;; (setopt create-lockfiles nil) ;ロックファイルを作らない場合

(setopt ;自動保存ファイルの保存先
 auto-save-file-name-transforms `((".*" ,tmp-dir t))
 auto-save-timeout 10
 auto-save-interval 100
 )
;; (setopt auto-save-default nil) ;作らない場合

(setopt ;自動保存リストファイルの保存先
 auto-save-list-file-prefix (expand-file-name "saves-" tmp-dir)
 )
;; (setopt auto-save-list-file-prefix nil) ;作らない場合

;;;; 基本的な編集機能 ------------------------------------------------
(setopt
 indent-tabs-mode nil ;インデントはスペースで

 global-whitespace-mode t ;非表示文字を表示
 whitespace-style '( ;表示する非表示文字
                     face
                     trailing
                     tabs
                     tab-mark
                     empty
                     ;; spaces
                     ;; spcae-mark
                     newline
                     newline-mark
                     )
 ;; whitespace-display-mappings '( ;非表示文字の代替文字の設定
 ;;                               (newline-mark ?\n [?| ?\n])
 ;;                               (space-mark ?　 [?＿])
 ;;                               (space-mark ?  [?.])
 ;;                               (space-mark ?  [?_])
 ;;                               (tab-mark ?\t [?» ?\t])
 ;;                               )

 show-paren-mode t ;対応する括弧を強調表示
 show-paren-style 'expression ;括弧の中身も強調表示
 )

;;;; 行数・桁数 ------------------------------------------------------
(setopt
 line-number-mode t ;モードラインに行数を表示
 column-number-mode t ;モードラインに桁数を表示

 display-line-numbers t ;編集領域に行数を表示
 display-line-numbers-width 4 ;編集領域の行数は最低4桁で表示

 fill-column 72 ;1行は72文字
 global-display-fill-column-indicator-mode t ;73文字目に目印を表示
 )

;;;; 基本的なキーバインド --------------------------------------------
(define-prefix-command 'toggle-map) ;機能をトグルするキーマップ
(define-prefix-command 'development-map) ;開発環境用のキーマップ

(setkey global-map
  "C-h" #'delete-backward-char ;C-hをバックスペースに
  "C-c t" 'toggle-map
  "C-c d" 'development-map
  )

(setkey toggle-map
  "i" #'display-fill-column-indicator-mode
  "l" #'display-line-numbers-mode
  "t" #'toggle-truncate-lines
  "w" #'global-whitespace-mode
  "M" #'menu-bar-mode
  "S" #'scroll-bar-mode
  "T" #'tool-bar-mode
  )

;;; 補完入力 =========================================================
;;;; ミニバッファ ----------------------------------------------------
(package-install 'marginalia)

(setopt
 fido-vertical-mode t
 marginalia-mode t
 )

;;;; corfu/cape ------------------------------------------------------
(package-install 'corfu)
(package-install 'cape)
(package-install 'kind-icon)

(setopt
 corfu-auto t
 corfu-cycle t
 corfu-quit-no-match t
 corfu-popupinfo-mode t
 global-corfu-mode t
 )
(setkey corfu-map "SPC" #'corfu-insert-separator)

(add-to-list 'completion-at-point-functions #'cape-dabbrev)
(add-to-list 'completion-at-point-functions #'cape-file)
(add-to-list 'completion-at-point-functions #'cape-keyword)
;; (add-to-list 'completion-at-point-functions #'cape-symbol)
(setkey global-map
  "C-c c p" #'completion-at-point
  "C-c c t" #'complete-tag
  "C-c c d" #'cape-dabbrev
  "C-c c h" #'cape-history
  "C-c c f" #'cape-file
  "C-c c k" #'cape-keyword
  "C-c c s" #'cape-symbol
  "C-c c a" #'cape-abbrev
  "C-c c i" #'cape-ispell
  "C-c c l" #'cape-line
  "C-c c w" #'cape-dict
  )

(setopt kind-icon-default-face 'corfu-default)
(add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter)

;;; 編集モード =======================================================
;;;; outline-magic ---------------------------------------------------
(package-install 'outline-magic)

(setopt outline-minor-mode-prefix (kbd "C-c C-o"))

(add-hook 'emacs-lisp-mode-hook #'outline-minor-mode)

(with-eval-after-load 'outline
  (setkey outline-minor-mode-map
    "<tab>" #'outline-cycle
    "<backtab>" #'outline-cycle-buffer ;Shift+TAB
    ))

;;;; org -------------------------------------------------------------
;;;;; 基本 ...........................................................
(setopt
 org-directory (expand-file-name "~/Dropbox/Documents/org/")
 org-todo-keywords '((sequence
                      "TODO(t!)"
                      "WAIT(w@)"
                      "SOMEDAY(s)"
                      "|"
                      "DONE(d!)"
                      "ABORT(a@)"))
 org-structure-template-alist '(
                                ("c" . "center")
                                ("cl" . "src common-lisp")
                                ("C" . "comment")
                                ("e" . "example")
                                ("el" . "src emacs-lisp")
                                ("en" . "src emacs-lisp :tangle no")
                                ("E" . "export")
                                ("Ea" . "export ascii")
                                ("Eh" . "export html")
                                ("El" . "export latex")
                                ("q" . "quote")
                                ("s" . "src")
                                ("v" . "verse")
                                )
 org-capture-templates '(
                         ("m" "メモ"
                          entry (file "capture.org")
                          "* %?\n%T\n%i"
                          :empty-lines-before 1)
                         ("s" "予定"
                          entry (file "capture.org")
                          "* %?\n%^T\n%i"
                          :empty-lines-before 1)
                         ("t" "やるべきこと"
                          entry (file "capture.org")
                          "* TODO %?\n%^t\n%i"
                          :empty-lines-before 1)
                         ("S" "いつかやること"
                          entry (file "capture.org")
                          "* SOMEDAY %?\n%i"
                          :empty-lines-before 1)
                         ("d" "徒然"
                          entry (file+olp+datetree "diary.org")
                          "* %?\n%T\n%i")
                         )
 org-agenda-files `(
                    ,(expand-file-name "capture.org" org-directory)
                    ,(expand-file-name "diary.org" org-directory)
                    )
 )

(define-prefix-command 'org-map)
(setkey global-map
  "C-c o" 'org-map
  )

(setkey org-map
  "l" #'org-store-link
  "a" #'org-agenda
  "c" #'org-capture
  )

;;;;; エクスポート ..................................................
(package-install 'htmlize)
(setopt
 org-export-default-language "ja"
 org-export-backends '(
                       html
                       latex
                       odt
                       )
 )

(package-install 'ox-pandoc)
(with-eval-after-load 'ox
  (require 'ox-pandoc))

;;;;; latex .........................................................
(setopt
 org-latex-compiler "lualatex"
 org-latex-text-markup-alist '(
                               (bold . "\\textbf{%s}")
                               (code . verb)
                               (italic . "\\it{%s}")
                               (strike-through . "\\sout{%s}")
                               (underline . "\\uline{%s}")
                               (verbatim . protectedtexttt)
                               )
 )

(with-eval-after-load 'ox-latex
  (setopt
   org-latex-classes '(("article"
                        "\\documentclass[paper=a4,article]{jlreq}"
                        ("\\section{%s}" . "\\section*{%s}")
                        ("\\subsection{%s}" . "\\subsection*{%s}")
                        ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                        ("\\paragraph{%s}" . "\\paragraph*{%s}")
                        ("\\subparagraph{%s}" . "\\subparagraph*{%s}"))
                       ("book"
                        "\\documentclass[paper=a6,book,tate]{jlreq}"
                        ("\\part{%s}" . "\\part*{%s}")
                        ("\\section{%s}" . "\\section*{%s}")
                        ("\\subsection{%s}" . "\\subsection*{%s}")
                        ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                        ("\\paragraph{%s}" . "\\paragraph*{%s}")
                        ("\\subparagraph{%s}" . "\\subparagraph*{%s}"))
                       )
   org-latex-default-class "article"
   )
  )

;;;; rust-mode -------------------------------------------------------
(when (eq system-type 'windows-nt) ;linuxならrust-ts-modeを使う
  (package-install 'rust-mode)
  (package-install 'toml-mode)
  )

;;; 開発環境 =========================================================
;;;; slime -----------------------------------------------------------
(package-install 'slime)
(package-install 'slime-company)

(setopt
 slime-lisp-implementations '((sbcl ("sbcl")))
 slime-kill-without-query-p t
 common-lisp-style-default "sbcl"
 slime-repl-history-file (expand-file-name ".slime-history.eld" tmp-dir)
 )

(with-eval-after-load 'slime
  (slime-setup '(slime-fancy slime-cape))
  )

(setkey development-map "s" #'slime)

;;;; ielm ------------------------------------------------------------
(setkey development-map "i" #'ielm)

;;;; eshell ----------------------------------------------------------
(setkey development-map "e" #'eshell)

;;;; treesit-auto ----------------------------------------------------
(when (eq system-type 'gnu/linux)
  (package-install 'treesit-auto)

  (require 'treesit-auto)
  (treesit-auto-add-to-auto-mode-alist 'all)
  (setopt
   treesit-auto-install t
   global-treesit-auto-mode t
   )
  )

;;;; eglot -----------------------------------------------------------
(if (eq system-type 'gnu/linux)
    (add-hook 'rust-ts-mode-hook #'eglot-ensure)
  (add-hook 'rust-mode-hook #'eglot-ensure)
  )

(with-eval-after-load 'flymake
  (setkey flymake-mode-map
    "M-n" #'flymake-goto-next-error
    "M-p" #'flymake-goto-prev-error
    ))

;;;; magit -----------------------------------------------------------
(package-install 'magit)

(define-prefix-command 'magit-map)
(setkey global-map "C-c m" 'magit-map)
(setkey magit-map
  "d" #'magit-dispatch
  "i" #'magit-init
  "s" #'magit-status
  )

;;; その他 ===========================================================
;;;; popper ----------------------------------------------------------
(package-install 'popper)
(setopt
 popper-reference-buffers '(
                            messages-buffer-mode
                            ;; special-mode
                            ;; emacs-lisp-compilation-mode
                            help-mode
                            slime-repl-mode
                            inferior-emacs-lisp-mode
                            comint-mode
                            compilation-mode
                            )
 popper-mode t
 popper-echo-mode t
 )

(setkey global-map
  "C-@" #'popper-toggle
  "M-@" #'popper-cycle
  "C-M-@" #'popper-toggle-type
  )

;;;; which-key -------------------------------------------------------
(package-install 'which-key)
(setopt
 which-key-mode t
 )
(add-elements-to-list 'which-key-replacement-alist
  '(("\\`C-c c\\'" . nil) . (nil . "corfu/cape"))
  '(("\\`C-c C-o\\'" . nil) . (nil . "outline"))
  )

;;;; blackout --------------------------------------------------------
(package-install 'blackout)

(blackout 'eldoc-mode)
(blackout 'global-eldoc-mode)
(blackout 'whitespace-mode)
(blackout 'global-whitespace-mode)
(blackout 'which-key-mode)

;;;; exwm ------------------------------------------------------------
;;;;; 基本設定 .......................................................
(when (eq system-type 'gnu/linux)
  (package-install 'exwm)
  )

(add-hook 'exwm-update-class-hook
          (lambda ()
            (exwm-workspace-rename-buffer exwm-class-name)))

(setopt
 exwm-input-simulation-keys `(
                              (,(kbd "C-b") . [left])
                              (,(kbd "C-f") . [right])
                              (,(kbd "C-p") . [up])
                              (,(kbd "C-n") . [down])
                              (,(kbd "C-a") . [home])
                              (,(kbd "C-e") . [end])
                              (,(kbd "M-v") . [prior])
                              (,(kbd "C-v") . [next])
                              (,(kbd "C-h") . [backspace])
                              (,(kbd "C-d") . [delete])
                              (,(kbd "C-k") . [S-end delete])
                              )
 )

(setopt
 exwm-floating-border-width 3
 exwm-floating-border-color "#ffbbee"
 )

(with-eval-after-load 'exwm
  (setopt
   menu-bar-mode nil
   tool-bar-mode nil
   scroll-bar-mode nil
   fringe-mode 1
   tab-bar-show nil

   display-time-format "[%F %R]"
   display-time-mode t
   )

  (setkey global-map
    "s-r" #'exwm-reset
    "s-w" #'exwm-workspace-switch
    )
  )

;;;;; システムトレイ .................................................
(with-eval-after-load 'exwm
  (require 'exwm-systemtray)
  (exwm-systemtray-enable)
  )

;;;;; バーとかのトグル ...............................................
(with-eval-after-load 'exwm
  (defun fringe-minimize ()
    "編集領域両側のfringeを最小化(size=1)したり戻したり(size=8)."
    (interactive)
    (cond ((null fringe-mode) (setopt fringe-mode 1))
          ((= fringe-mode 1) (setopt fringe-mode 8))
          (t (setopt fringe-mode 1))))

  (defun tab-bar-show ()
    "タブバーの表示をトグルする."
    (interactive)
    (cond ((null tab-bar-show) (setopt tab-bar-show t))
          (t (setopt tab-bar-show nil))))

  (setkey toggle-map
    "M" #'menu-bar-mode
    "T" #'tool-bar-mode
    "S" #'scroll-bar-mode
    "F" #'fringe-minimize
    "C-t" #'tab-bar-show
    )
  )

;;;;; pulseaudio-utilsのコントロール .................................
(with-eval-after-load 'exwm
  (defun audio-raise-volume ()
    "システムの音量を上げる."
    (interactive)
    (call-process "pactl" nil nil nil
                  "set-sink-volume" "@DEFAULT_SINK@" "+5%"))
  (defun audio-lower-volume ()
    "システムの音量を下げる."
    (interactive)
    (call-process "pactl" nil nil nil
                  "set-sink-volume" "@DEFAULT_SINK@" "-5%"))
  (defun audio-toggle-mute ()
    "システム音量のミュートをトグルする."
    (interactive)
    (call-process "pactl" nil nil nil
                  "set-sink-mute" "@DEFAULT_SINK@" "toggle"))

  (setkey global-map
    "s->" #'audio-raise-volume
    "s-<" #'audio-lower-volume
    "s-M" #'audio-toggle-mute
    )

  (exwm-input-set-key (kbd "s->") #'audio-raise-volume)
  (exwm-input-set-key (kbd "s-<") #'audio-lower-volume)
  (exwm-input-set-key (kbd "s-M") #'audio-toggle-mute)
  )

;;;;; exwm-x .........................................................
;; やめた。
;; (with-eval-after-load 'exwm
;;   (package-install 'exwm-x))

;; (with-eval-after-load 'exwm
;;   (require 'exwm-x)

;;   (when (functionp 'global-tab-line-mode)
;;     (setopt global-tab-line-mode nil))

;;   (when (functionp 'tab-bar-mode)
;;     (setopt tab-line-mode nil))

;;   (setopt use-dialog-box nil)

;;   (add-hook 'exwm-update-class-hook #'exwmx-grocery--rename-exwm-buffer)
;;   (add-hook 'exwm-update-title-hook #'exwmx-grocery--rename-exwm-buffer)

;;   (add-hook 'exwm-manage-finish-hook #'exwmx-grocery--manage-finish-function)

;;   (exwmx-floating-smart-hide)

;;   (exwmx-button-enable)

;;   (define-key global-map (kbd "C-t") nil)
;;   (push ?\C-t exwm-input-prefix-keys)

;;   (exwmx-input-set-key (kbd "C-t ;") #'exwmx-dmenu)
;;   (exwmx-input-set-key (kbd "C-t :") #'exwmx-appmenu-simple)
;;   (exwmx-input-set-key (kbd "C-t C-e") #'exwmx-sendstring)
;;   (exwmx-input-set-key (kbd "C-t C-r") #'exwmx-appconfig)

;;   (exwmx-input-set-key (kbd "C-c y") #'exwmx-sendstring-from-kill-ring)

;;   (exwmx-input-set-key (kbd "C-t C-t") #'exwmx-button-toggle-keyboard)

;;   (push ?\C-q exwm-input-prefix-keys)
;;   (define-key exwm-mode-map [?\C-q] #'exwm-input-send-next-key)

;;   (require 'exwm-xim)
;;   (push ?\C-\\ exwm-input-prefix-keys)

;;   ;; (if (equal (getenv "XMODIFIERS") "@im=exwm-xim")
;;   ;;     (exwm-xim-enable)
;;   ;;   (message "EXWM-X: Do not enable exwm-xim, for environment XMODIFIERS is set incorrect."))

;;   (with-eval-after-load 'switch-window
;;     (setq switch-window-input-style 'minibuffer)
;;     (define-key exwm-mode-map (kbd "C-x o") #'switch-window)
;;     (define-key exwm-mode-map (kbd "C-x 1") #'switch-window-then-maximize)
;;     (define-key exwm-mode-map (kbd "C-x 2") #'switch-window-then-split-below)
;;     (define-key exwm-mode-map (kbd "C-x 3") #'switch-window-then-split-right)
;;     (define-key exwm-mode-map (kbd "C-x 0") #'switch-window-then-delete)
;;     )

;;   (define-key exwm-mode-map (kbd "C-c C-t C-f") #'exwmx-floating-toggle-floating)
;;   )

;;; 片付け ===========================================================
(advice-remove #'package-install #'package-install-retry-advice)

;;; 設定本体(emacs.org)の読み込み ====================================
;; やめた。
;; (let* ((source-file (expand-file-name "emacs.org" user-emacs-directory))
;;        (generate-file (expand-file-name
;;                        (file-name-nondirectory
;;                         (file-name-with-extension source-file ".el"))
;;                        tmp-dir)))
;;   (when (file-exists-p source-file)
;;     (require 'ob-tangle)
;;     (org-babel-tangle-file source-file generate-file)
;;     (when (file-exists-p generate-file)
;;       (load-file generate-file))))
