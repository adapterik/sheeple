(asdf:defsystem sheeple
  :version "Baahh"
  :description "Clone-crazy hackery tool"
  :maintainer "Josh <sykopomp@Dagon>"
  :author "Josh <sykopomp@Dagon>"
  :licence "MIT"
  :depends-on ()
  :serial t
  :components 
  ((:module src
	    :serial t
	    :components
	    ((:file "packages")
	     (:file "utils")
	     (:file "sheeple")
	     (:file "talents")))))
