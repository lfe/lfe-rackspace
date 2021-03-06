(defmodule lferax-identity
  (export all)
  (import
    (from openstack-util
          (json-wrap 1)
          (json-wrap-bin 1))))


(defun build-creds
  "Jiffy doesn't handle strings well for JSON, though it does handle binaries
  well. As such, all strings should be converted to binary before being passed
  to Jiffy."
  ((username 'password password)
    (: openstack-identity build-creds username 'password password))
  ((username 'apikey apikey)
   (json-wrap
     (list 'RAX-KSKEY:apiKeyCredentials
           (json-wrap-bin (list 'username username
                                'apiKey apikey))))))

(defun get-apikey-auth-payload (username apikey)
  (binary_to_list
    (: jiffy encode
      (json-wrap (list 'auth (build-creds username 'apikey apikey))))))

(defun get-auth-payload
  ((username 'apikey apikey) (get-apikey-auth-payload username apikey))
  ((username 'password password)
   (: openstack-identity get-password-auth-payload username password)))

(defun password-login (username password)
  (: openstack-identity authenticate
    (: lferax-const auth-url)
    username
    password))

(defun apikey-login (username apikey)
  (: openstack-http post
    (: lferax-const auth-url)
    (get-auth-payload username 'apikey apikey)))

(defun get-disk-username ()
  (: openstack-util read-file (: lferax-const username-file)))

(defun get-disk-password ()
  (: openstack-util read-file (: lferax-const password-file)))

(defun get-disk-apikey ()
  (: openstack-util read-file (: lferax-const apikey-file)))

(defun get-env-username ()
  (: os getenv (: lferax-const username-env)))

(defun get-env-password ()
  (: os getenv (: lferax-const password-env)))

(defun get-env-apikey ()
  (: os getenv (: lferax-const apikey-env)))

(defun get-username ()
  (let ((username (get-env-username)))
    (cond ((not (=:= username 'false))
           username)
          ('true (get-disk-username)))))

(defun get-password ()
  (let ((password (get-env-password)))
    (cond ((not (=:= password 'false))
           password)
          ('true (get-disk-password)))))

(defun get-apikey ()
  (let ((apikey (get-env-apikey)))
    (cond ((not (=:= apikey 'false))
           apikey)
          ('true (get-disk-apikey)))))

(defun get-apikey-or-password ()
  (let ((apikey (get-apikey)))
    (cond ((not (=:= apikey ""))
           apikey)
          ('true (get-password)))))

(defun login
  ((username 'apikey apikey) (apikey-login username apikey))
  ((username 'password password) (password-login username password)))

(defun login (mode)
  ""
  (cond ((=:= mode 'apikey) (login))
        ((=:= mode 'config)
          (let ((username (: lferax-config get-username))
                (apikey (: lferax-config get-apikey)))
            (login username 'apikey apikey)))
        ('true (login (get-username) 'password (get-password)))))

(defun login ()
  ""
  (login (get-username) 'apikey (get-apikey)))


