;; Copyright 2008, 2009 Josh Marchan

;; Permission is hereby granted, free of charge, to any person
;; obtaining a copy of this software and associated documentation
;; files (the "Software"), to deal in the Software without
;; restriction, including without limitation the rights to use,
;; copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the
;; Software is furnished to do so, subject to the following
;; conditions:

;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
;; OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
;; HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
;; WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
;; FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
;; OTHER DEALINGS IN THE SOFTWARE.

;; buzzwords.lisp
;;
;; Implementation of Sheeple's generic functions (messages)
;;
;; TODO:
;; * Figure out the basic framework for message definition before going over to dispatch again
;; * Consider alternative naming scheme. Messages sound only sort-of okay.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(in-package :sheeple)

;;;
;;; Message and participation base classes
;;;
(defclass standard-buzzword ()
  ((name
    :initarg :name
    :accessor buzzword-name)
   (documentation
    :initarg :documentation
    :accessor buzzword-documentation)
   (messages
    :initform nil
    :accessor buzzword-messages)))

(defclass standard-message ()
  ((name
    :initarg :name
    :accessor message-name)
   (lambda-list
    :initarg :lambda-list
    :accessor message-lambda-list)
   (specializers
    :initarg :specializers
    :accessor message-specializers)
   (body
    :initarg :body
    :accessor message-body)
   (function
    :initarg :function
    :accessor message-function))
  (:metaclass sb-mop:funcallable-standard-class))

(defclass standard-message-role ()
  ((name
    :initarg :name
    :accessor name)
   (position
    :initarg :position
    :accessor position)
   (message-pointer
    :initarg :message-pointer
    :accessor message-pointer)
   documentation))

;;;
;;; Message definition
;;;

(defmacro defmessage (name lambda-list &body body)
  `(create-message
    )
  )

(defun create-message (&key name lambda-list specializers body)
  ;; What does this have to do?:
  ;; - Check if a function is bound to NAME
  ;; -- If the function bound is not a message, signal error
  ;; -- Otherwise generate a new message object
  ;; -- when the function is bound to message, redefine the message**** (this involves some messy stuff)
  ;; -- create roles for all the relevant specializers
  ;; Finally, return the message object.
  (if (and (fboundp name)
	   (not (ability-p name)))
      (error "Trying to override a function that isn't a message.")
      (let ((message (make-instance 'standard-message
				   :name name
				   :lambda-list lambda-list
				   :specializers specializers
				   :body body
				   :function body)))
	(when (ability-p name)
	  (remove-messages-with-name-and-specializers name specializers))
	(add-message-to-sheeple name message specializers)
	message)))

(defun message-p (name)
  (eql (class-of (fdefinition name))
       (find-class 'standard-message)))

(defun remove-messages-with-name-and-specializers (name specializers)
  ;; Keep a watchful eye on this. It only *seems* to work.
  (mapc (lambda (sheep) 
	    (mapc (lambda (role) 
		    (when (and (eql name (name role))
			       (equal specializers
				      (message-specializers
				       (message-pointer role))))
		      (setf (sheep-direct-roles sheep)
			    (remove role (sheep-direct-roles sheep)))))
		  (sheep-direct-roles sheep)))
	specializers))

(defun add-message-to-sheeple (name message sheeple)
  (loop 
     for sheep in sheeple
     for i upto (1- (length sheeple))
     do (push (make-instance 'standard-message-role
			     :name name
			     :position i
			     :message-pointer message) 
	      (sheep-direct-roles sheep))))

;;;
;;; Message dispatch
;;;

;; dispatch(selector, args, n)
;;  for each index below n
;;    position := 0
;;    push args[index] on ordering stack
;;    while ordering stack is not empty
;;      arg := pop ordering stack
;;      for each message-property on arg with selector and index
;;        rank[message-property's message][index] := position
;;        if rank[message-property's message] is fully specified
;;          if no most specific message
;;             or rank[message-property's message] < rank[most specific message]
;;            most specific message := message-property's method
;;      for each ancestor on arg's hierarchy-list
;;        push ancestor on ordering stack
;;      position := position + 1
;;  return most specific message-property
;; FUCK YOU SLATE

(defun find-most-specific-message (selector &rest args)
  "Returns the most specific message using SELECTOR and ARGS."
  ;; This shit is bugged to all hell and it's a huge, disgusting algorithm. Fix that shit.
  (let ((n (length args))
	(most-specific-message nil)
	(ordering-stack nil)
	(discovered-messages nil))
    (loop 
       for index upto (1- n)
       for position upto (1- n)
       do (let ((position 0))
	    (push (elt args index) ordering-stack)
	    (loop 
	       while ordering-stack
	       do (let ((arg (pop ordering-stack)))
		    (loop
		       for role in (sheep-direct-roles arg)
		       when (and (eql selector (name role))
				 (eql index (position role)))
		       do (pushnew (message-pointer role) 
				   discovered-messages)
		       do (setf (elt (message-rank (message-pointer role)) index)
				position)
		       if (or (fully-specified-p (message-rank (message-pointer role)))
			      (< (calculate-rank (message-rank (message-pointer role)))
				 (calculate-rank (message-rank most-specific-message))))
		       do (setf most-specific-message (message-pointer role)))
		    (add-ancestors-to-ordering-stack arg ordering-stack)))))
    (mapcar #'reset-message-rank discovered-messages)
    most-specific-message))

(defun add-ancestors-to-ordering-stack (arg ordering-stack)
  (loop 
     for ancestor in (remove arg (compute-sheep-hierarchy-list arg))
     do (push ancestor ordering-stack)))

(defun fully-specified-p (rank)
  (loop for item across rank
     do (when (eql item nil)
	  (return-from fully-specified-p nil)))
  t)

(defun calculate-rank (rank)
  (let ((total 0))
    (loop for item across rank
       do (when (numberp item)
	    (incf total item)))))

(defun reset-message-rank (message)
  (loop for item across (message-rank message)
     do (setf item nil)))
