;;; todo-mode-tests.el --- tests for todo-mode.el  -*- lexical-binding: t; -*-

;; Copyright (C) 2017 Free Software Foundation, Inc.

;; Author: Stephen Berman <stephen.berman@gmx.net>
;; Keywords: calendar

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(require 'ert)
(require 'todo-mode)

(defvar todo-test-data-dir
  (file-truename
   (expand-file-name "todo-mode-resources/"
                     (file-name-directory (or load-file-name
                                              buffer-file-name))))
  "Base directory of todo-mode.el test data files.")

(defvar todo-test-file-1 (expand-file-name "todo-test-1.todo"
                                           todo-test-data-dir)
  "Todo mode test file.")

(defvar todo-test-archive-1 (expand-file-name "todo-test-1.toda"
                                              todo-test-data-dir)
  "Todo Archive mode test file.")

(defmacro with-todo-test (&rest body)
  "Set up an isolated todo-mode test environment."
  `(let* ((todo-test-home (make-temp-file "todo-test-home-" t))
          (process-environment (cons (format "HOME=%s" todo-test-home)
                                     process-environment))
          (todo-directory todo-test-data-dir)
          (todo-default-todo-file (todo-short-file-name
				   (car (funcall todo-files-function)))))
     (unwind-protect
         (progn ,@body)
       (delete-directory todo-test-home t))))

;; (defun todo-test-show (num &optional archive)
;;   "Display category NUM of test todo file.
;; With non-nil ARCHIVE argument, display test archive file category."
;;   (let* ((file (if archive todo-test-archive-1 todo-test-file-1))
;;          (buf (find-file-noselect file)))
;;     (set-buffer buf)
;;     (if archive (todo-archive-mode) (todo-mode))
;;     (setq todo-category-number num)
;;     (todo-category-select)))

(defun todo-test-get-archive (num)
  "Display category NUM of todo archive test file."
  (let ((archive-buf (find-file-noselect todo-test-archive-1)))
    (set-buffer archive-buf)
    (todo-archive-mode)
    (setq todo-category-number num)
    (todo-category-select)))

(defun todo-test-is-current-buffer (filename)
  "Return non-nil if FILENAME's buffer is current."
  (let ((bufname (buffer-file-name (current-buffer))))
    (and bufname (equal (file-truename bufname) filename))))

(ert-deftest todo-test-todo-quit01 ()
  "Test the behavior of todo-quit with archive and todo files.
Invoking todo-quit in todo-archive-mode should make the
corresponding todo-mode category current, if it exits, otherwise
the current todo-mode category.  Quitting todo-mode without an
intermediate buffer switch should not make the archive buffer
current again."
  (with-todo-test
   (todo-test-get-archive 2)
   (let ((cat-name (todo-current-category)))
     (todo-quit)
     (should (todo-test-is-current-buffer todo-test-file-1))
     (should (equal (todo-current-category) cat-name))
     (todo-test-get-archive 1)
     (setq cat-name (todo-current-category))
     (todo-quit)
     (should (todo-test-is-current-buffer todo-test-file-1))
     (should (equal todo-category-number 1))
     (todo-forward-category)         ; Category 2 in todo file now current.
     (todo-test-get-archive 3)       ; No corresponding category in todo file.
     (setq cat-name (todo-current-category))
     (todo-quit)
     (should (todo-test-is-current-buffer todo-test-file-1))
     (should (equal todo-category-number 2))
     (todo-quit)
     (should-not (todo-test-is-current-buffer todo-test-archive-1)))))

(ert-deftest todo-test-todo-quit02 () ; bug#27121
  "Test the behavior of todo-quit with todo and non-todo buffers.
If the buffer made current by invoking todo-quit in a todo-mode
buffer is buried by quit-window, the todo-mode buffer should not
become current."
  (with-todo-test
   (todo-show)
   (should (todo-test-is-current-buffer todo-test-file-1))
   (let ((dir (dired default-directory)))
     (todo-show)
     (todo-quit)
     (should (equal (current-buffer) dir))
     (quit-window)
     (should-not (todo-test-is-current-buffer todo-test-file-1)))))

(ert-deftest todo-test-item-highlighting () ; bug#27133
  "Test whether `todo-toggle-item-highlighting' highlights whole item.
In particular, all lines of a multiline item should be highlighted."
  (with-todo-test
   (todo-show)
   (todo-jump-to-category nil "testcat1") ; For test rerun.
   (todo-toggle-item-highlighting)
   (let ((end (1- (todo-item-end)))
         (beg (todo-item-start)))
     (should (eq (get-char-property beg 'face) 'hl-line))
     (should (eq (get-char-property end 'face) 'hl-line))
     (should (> (count-lines beg end) 1))
     (should (eq (next-single-char-property-change beg 'face) (1+ end))))
   (todo-toggle-item-highlighting)))   ; Turn off highlighting (for test rerun).

(provide 'todo-mode-tests)
;;; todo-mode-tests.el ends here
