(defmodule lferax-servers
  (export all)
  (import
    (from openstack-util
          (json-wrap 1)
          (json-wrap-bin 1))))


(defun get-name-id (json-data)
  "Given some JSON data, parse just 'name' and 'id' attributes."
  (tuple
    (: ej get #("name") json-data)
    (tuple (: ej get #("id") json-data))))

(defun get-data (identity-response url-path region)
  (let* ((base-url (: lferax-services get-cloud-servers-v2-url
                     identity-response
                     region))
         (url (++ base-url url-path)))
  (: openstack-util get-json-body
    (: openstack-http get
       url
       (: lferax-identity get-token identity-response)))))

(defun get-list (identity-response region type)
  (: lists map
     #'get-name-id/1
     (: ej get
        (tuple type)
        (get-data identity-response
                  (++ '"/" type)
                  region))))

(defun get-flavors-list (identity-response region)
  (get-list identity-response region '"flavors"))

(defun get-images-list (identity-response region)
  (get-list identity-response region '"images"))

(defun get-id (name data-list)
  (binary_to_list
    (element 1
             (: dict fetch
                (list_to_binary name)
                (: dict from_list data-list)))))

(defun get-new-server-payload (server-name image-id flavor-id)
  "Jiffy doesn't handle strings well for JSON, though it does handle binaries
  well. As such, all strings should be converted to binary before being passed
  to Jiffy."
  (json-wrap
    (list 'server
          (json-wrap-bin (list 'name server-name
                               'imageRef image-id
                               'flavorRef flavor-id)))))

(defun get-new-server-encoded-payload (server-name image-id flavor-id)
  (binary_to_list
    (: jiffy encode (get-new-server-payload server-name image-id flavor-id))))

(defun create-server (identity-response region server-name image-id flavor-id)
  (let ((base-url (: lferax-services get-cloud-servers-v2-url
                    identity-response
                    region)))
    (: openstack-http post
      (++ base-url '"/servers")
      (get-new-server-encoded-payload server-name image-id flavor-id)
      (: lferax-identity get-token identity-response))))

(defun get-server-list (identity-response region)
  (let ((base-url (: lferax-services get-cloud-servers-v2-url
                     identity-response
                     region)))
    (: openstack-http get
      (++ base-url '"/servers/detail")
      region
      (: lferax-identity get-token identity-response))))

