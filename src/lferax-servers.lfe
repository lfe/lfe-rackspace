(defmodule lferax-servers
  (export all))


(defun get-name-id (json-data)
  "Given some JSON data, parse just 'name' and 'id' attributes."
  (tuple
    (: ej get #("name") json-data)
    (tuple (: ej get #("id") json-data))))

(defun get-data (identity-response url-path region auth-token)
  (let* ((base-url (: lferax-services get-cloud-servers-v2-url
                     identity-response
                     region))
         (url (++ base-url url-path)))
  (: lferax-util get-json-body
    (: lferax-http get url region auth-token))))

; XXX refactor this (generalize/abtract for reuse)
(defun get-flavors-list (identity-response region auth-token)
  (: lists map
     #'get-name-id/1
     (: ej get
        #("flavors")
        (get-data identity-response '"/flavors/detail" region auth-token))))

; XXX refactor this (generalize/abtract for reuse)
(defun get-flavor-id (flavor-name flavors-list)
  (binary_to_list
    (element 1
             (: dict fetch
                (list_to_binary flavor-name)
                (: dict from_list flavors-list)))))

; XXX refactor this (generalize/abtract for reuse)
(defun get-images-list (identity-response region auth-token)
  (: lists map
     #'get-name-id/1
     (: ej get
        #("images")
        (get-data identity-response '"/images/detail" region auth-token))))

; XXX refactor this (generalize/abtract for reuse)
(defun get-image-id (image-name images-list)
  (binary_to_list
    (element 1
             (: dict fetch
                (list_to_binary image-name)
                (: dict from_list images-list)))))

(defun get-server-list (identity-response region auth-token)
  (let ((base-url (: lferax-services get-cloud-servers-v2-url
                     identity-response
                     region)))
    (: lferax-http get
      (++ base-url '"/servers/detail")
      region auth-token)))

