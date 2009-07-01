;;;; This file is part of Sheeple

;;;; builtins.lisp
;;;;
;;;; Boxing of built-in lisp types
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(in-package :sheeple)

(declaim (optimize (speed 3) (safety 1)))
(defun box-type-of (x)
  (if (sheep-p x)
      (progn
	(warn "This is already a sheep!")
	x)
      (typecase x
	(null                                          (proto 'null))
	((and symbol (not null))                       (proto 'symbol))
	((complex *)                                   (proto 'complex))
	((integer * *)                                 (proto 'integer))
	((float * *)                                   (proto 'float))
	(cons                                          (proto 'cons))
	(character                                     (proto 'character))
	(hash-table                                    (proto 'hash-table))
	(package                                       (proto 'package))
	(pathname                                      (proto 'pathname))
	(readtable                                     (proto 'readtable))
	(stream                                        (proto 'stream))
	((and number (not (or integer complex float))) (proto 'number))
	((string *)                                    (proto 'string))
	((bit-vector *)                                (proto 'bit-vector))
	((and vector (not string))                     (proto 'vector))
	((and array (not vector))                      (proto 'array))
;	((and sequence (not (or vector list)))         (proto 'sequence))
	(function                                      (proto 'function))
	(t                                             (proto 'boxed-object)))))

;; Boxed object table
(let ((boxed-object-table (make-hash-table :test #'equal)))

  (defun find-boxed-object (object &optional (errorp nil))
    "Finds a previously-boxed object in the boxed object table.
If ERRORP is T, this signals an error if OBJECT is a sheep, or if OBJECT
has not already been boxed."
    (if (sheep-p object)
        (if errorp (error "~S seems to already be a sheep." object) nil)
        (multiple-value-bind (sheep hasp)
            (gethash object boxed-object-table)
          (if hasp
              sheep
              (if errorp (error "~S has not been boxed." object) nil)))))

  (defun box-object (object)
    "Wraps OBJECT with a sheep."
    (if (sheep-p object)
        (error "~S seems to already be a sheep." object)
        (setf (gethash object boxed-object-table) 
              (defclone ((box-type-of object))
                  ((wrapped-object object)) (:nickname object)))))

  (defun remove-boxed-object (object)
    "Kills object dead"
    (remhash object boxed-object-table))
    
  ) ; end boxed object table

(defun sheepify-list (obj-list)
  "Converts OBJ-LIST to a list where each item is either a sheep or a fleeced wolf."
  (mapcar #'sheepify obj-list))

(defun sheepify (object)
  "Returns OBJECT or fleeces it."
   (cond ((eq object t)
          (proto 't))
         ((not (sheep-p object))
          (or (find-boxed-object object)
              (values (box-object object) t)))
         (t
          (values object nil))))