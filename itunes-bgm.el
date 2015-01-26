;;; itunes-bgm.el --- BGM with iTunes API -*- lexical-binding: t; -*-

;; Copyright (C) 2015 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL: https://github.com/syohex/
;; Version: 0.01
;; Package-Requires: ((cl-lib "0.5") (emacs "24"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(require 'cl-lib)
(require 'url)
(require 'json)

(defgroup itunes-bgm nil
  "BGM with iTunes API."
  :group 'music)

(defcustom itunes-bgm-country "US"
  "ISO 3166-1 alpha-2 country code."
  :type 'string
  :group 'itunes-bgm)

(defcustom itunes-bgm-player 'mplayer
  "Music player."
  :type '(choice (const :tag "mplayer" mplayer)
                 (const :tag "avplay" avplay)
                 (const :tag "ffplay" ffplay))
  :group 'itunes-bgm)

(defvar itunes-bgm--process nil)
(defvar itunes-bgm--history nil)

(defun itunes-bgm--play-url-mplayer (url)
  (start-file-process "itunes-bgm" nil "mplayer" url))

(defun itunes-bgm--play-url-avplay (player url)
  (start-file-process "itunes-bgm" nil player "-autoexit" "-nodisp" url))

(defun itunes-bgm--play-url (url)
  (cl-case itunes-bgm-player
    (mplayer (itunes-bgm--play-url-mplayer url))
    ((avplay ffplay) (itunes-bgm--play-url-avplay
                      (symbol-name itunes-bgm-player) url))))

(defun itunes-bgm--play-previews (preview-info)
  (let* ((info (car preview-info))
         (proc (itunes-bgm--play-url (plist-get info :preview))))
    (message "Playing: %s by %s" (plist-get info :track) (plist-get info :artist))
    (setq itunes-bgm--process proc)
    (set-process-sentinel
     proc
     (lambda (process _event)
       (when (eq (process-status process) 'exit)
         (if (not (null preview-info))
             (itunes-bgm--play-previews (cdr preview-info))
           (setq itunes-bgm--process nil)
           (message "finish")))))))

(defun itunes-bgm--collect-preview-urls (results)
  (cl-loop for result across results
           for track = (decode-coding-string (assoc-default 'trackName result) 'utf-8)
           for artist = (decode-coding-string (assoc-default 'artistName result) 'utf-8)
           for preview-url = (assoc-default 'previewUrl result)
           collect
           (list :track track :artist artist :preview preview-url)))

(defun itunes-bgm--parse-response (_status)
  (let ((coding-system-for-read 'utf-8))
    (goto-char (point-min))
    (when (re-search-forward "\r?\n\r?\n" nil t)
      (let* ((response (json-read-from-string
                        (buffer-substring-no-properties (point) (point-max))))
             (results (assoc-default 'results response))
             (preview-info (itunes-bgm--collect-preview-urls results)))
        (itunes-bgm--play-previews preview-info)))))

(defun itunes-bgm--search (term country media)
  (let ((url-request-method "GET")
        (query (concat "?"
                       "term=" (url-hexify-string term)
                       "&country=" (url-hexify-string country)
                       "&media=" (url-hexify-string media))))
    (url-retrieve (concat "https://itunes.apple.com/search" query)
                  'itunes-bgm--parse-response)))

;;;###autoload
(defun itunes-bgm (term)
  (interactive
   (list (read-string "Keyword: " nil 'itunes-bgm--history)))
  (itunes-bgm--search term itunes-bgm-country "music"))

(defun itunes-bgm-kill ()
  (interactive)
  (when itunes-bgm--process
    (kill-process itunes-bgm--process)))

(provide 'itunes-bgm)

;;; itunes-bgm.el ends here
