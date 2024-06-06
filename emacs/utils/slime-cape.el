;; 以下のページのコピペ。slimeでcorfu/capeの補完を使えるようにする。
;; https://www.reddit.com/r/emacs/comments/12u4qr6/how_to_add_the_slimecompany_to_capecorfu/

;; (slime-setup '(slime-fancy slime-cape))
;; として使う。

(require 'slime)
(require 'slime-company)
(require 'cape)

(defvar cape-slime-backend (cape-company-to-capf #'company-slime))

(define-slime-contrib slime-cape
  (:swank-dependencies swank-arglists)
  (:on-load
   (dolist (h '(slime-mode-hook slime-repl-mode-hook sldb-mode-hook))
     (add-hook h 'slime-cape-maybe-enable))
   )
  (:on-unload
   (dolist (h '(slime-mode-hook slime-repl-mode-hook sldb-mode-hook))
     (remove-hook h 'slime-cape-maybe-enable))
   (delete cape-slime-backend completion-at-point-functions)
   ))

(defun slime-cape-maybe-enable ()
  (when (slime-company-active-p)
    (add-to-list 'completion-at-point-functions cape-slime-backend)
    ))

(provide 'slime-cape)
