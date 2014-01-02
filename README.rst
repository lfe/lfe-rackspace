#############
lfe-rackspace
#############

Pure LFE (Lisp Flavored Erlang) language bindings for the Rackspace Cloud

Plase note: this library is in an early stage of development and is not yet usable as a complete API.

.. contents:: Table of Contents


Introduction
************

Inspired by the experimental `Clojure bindings`_ for the Rackspace Cloud, these
bindings provide Erlang/OTP and LFE/OTP programmers with a native API for
creating and managing serviers in Rackspace's OpenStack cloud.

This API is written in LFE, but because LFE is 100% compatible with Erang Core,
when compiled to ``.beam`` files, they are just as easy to integrate with other
projects written in Erlang.


Dependencies
============

This project assumes that you have `rebar`_ installed somwhere in your
``$PATH``.

This project depends upon the following, which installed to the ``deps``
directory of this project when you run ``make deps``:

* `LFE`_ (Lisp Flavored Erlang; needed only to compile)
* `lfe-openstack`_ (and all of its dependencies!)

If you plan on installing lfe-rackspace system-wide, you will need to install
these dependencies before using lfe-rackspace.


Installation
************

To install, simply do the following:

.. code:: bash

    $ git clone https://github.com/oubiwann/lfe-rackspace.git
    $ cd lfe-rackspace
    $ sudo ERL_LIB=`erl -eval 'io:fwrite(code:lib_dir()), halt().' -noshell` \
          make install

We don't, however, recommend using ``lfe-rackspace`` like this. Rather, using it
with ``rebar`` from the ``clone`` ed directory.

If you have another project where you'd like to utilize ``lfe-rackspace``, then
add it to your ``deps`` in the project ``rebar.config`` file.

You can also run the test suite from ``lfe-rackspace``:

.. code:: bash

    $ make check

Which should give you output something like the following:

.. code:: bash

    ==> lfe-rackspace (eunit)
    ======================== EUnit ========================
    module 'lferax-util_tests'
    module 'lferax-usemacros_tests'
    module 'lferax-services_tests'
    lferax-servers_tests: get-new-server-payload_test (module 'lferax-servers_tests')...[0.079 s] ok
    module 'lferax-identity_tests'
      lferax-identity_tests: build-creds-password_test...[0.028 s] ok
      lferax-identity_tests: build-creds-apikey_test...ok
      [done in 0.033 s]
    module 'lferax-const_tests'
      lferax-const_tests: auth-url_test...[0.020 s] ok
      lferax-const_tests: services_test...ok
      lferax-const_tests: regions_test...ok
      lferax-const_tests: files_test...ok
      lferax-const_tests: env_test...ok
      [done in 0.035 s]
    =======================================================
      All 8 tests passed.


Usage
*****

Login
=====

``lfe-rackspace`` provides several ways to pass your authentication credentials
to the API:


Directly, using ``login/3``
---------------------------

.. code:: common-lisp

    > (: lferax-identity login '"alice" 'apikey `"1234abcd")

or

.. code:: common-lisp

    > (: lferax-identity login '"alice" 'password `"asecret")


Indirectly, using ``login/0``
-----------------------------

.. code:: bash

    $ export RAX_USERNAME=alice
    $ export RAX_APIKEY=1234abcd

.. code:: common-lisp

    > (: lferax-identity login)

or

.. code:: bash

    $ cat "alice" > ~/.rax/username
    $ cat "1234abcd" > ~/.rax/apikey

.. code:: common-lisp

    > (: lferax-identity login)


Indirectly, using ``login/1``
-----------------------------

.. code:: bash

    $ export RAX_USERNAME=alice
    $ export RAX_PASSWORD=asecret

.. code:: common-lisp

    > (: lferax-identity login 'password)

or

.. code:: bash

    $ cat "alice" > ~/.rax/username
    $ cat "asecret" > ~/.rax/password

.. code:: common-lisp

    > (: lferax-identity login 'password)

In the presence of both defined env vars and cred files, env will allways be
the default source of truth and files will only be used in the absence of
defined env vars.

You may also login using credentials stored in a config/ini file. To use this
function, first create the ``~/.rax/providers.cfg`` config file with content
like the following, but you your own details substituted:

.. code:: ini

    [rackspace]
    username=alice
    apikey=abc123

Then you can use the following call to login:

.. code:: common-lisp

    > (: lferax-identity login 'config)


Login Response Data
-------------------

After successfully logging in, you will get a response with a lot of data in
it. You will need this data to perform additional tasks, so make sure you save
it. From the LFE REPL, this would look like so:

.. code:: common-lisp

    (set auth-response (: lferax-identity login))

There's a utility function we can use here to extract the parts of the
response.

.. code:: common-lisp

    (set (list erlang-ok-status
               http-version
               http-status-code
               http-status-message
               headers
               body)
         (: lferax-util parse-json-response-ok auth-response))

Be aware that this function assumes a non-error Erlang result. If the first
element of the returned data struction is ``error`` and not ``ok``, this
function call will fail.


User Auth Token
---------------

With the response data from a successful login, one may then get one's token:

.. code:: common-lisp

    (set token (: openstack-identity get-token auth-response))


Tentant ID
----------

The tenant ID is an important bit of information that you will need for
further calls to the Rackspace Cloud APIs. You get it in the same manner:


.. code:: common-lisp

    (set tenant-id (: openstack-identity get-tenant-id auth-response))



User Info
---------

Simiarly, after login, you will be able to extract your user id:

.. code:: common-lisp

    (set user-id (: openstack-identity get-user-id auth-response))
    (set user-name (: openstack-identity get-user-name auth-response))



Service Data
============

The response data from a successful login holds all the information you need to
access the rest of Rackspace cloud services. The following subsections detail
some of these.

Note that many of these calls will return Rackspace API server response data as
JSON data decoded to Erlang binary. As such, you will often see data like this
after calling an API function:

.. code:: common-lisp

    (#((#(#B(110 97 109 101) #B(99 108 111 117 100 70 105 108 101 115 67 68 78))
        #(#B(101 110 100 112 111 105 110 116 115)
          (#((#(#B(114 101 103 105 111 110) #B(68 70 87))
              #(#B(116 101 110 97 110 116 73 100)
              ...

Most of that data will be intermediary, and it won't matter that you can't read
it. However, if you ever feel the need to, you can display that binary in a
human-readable format: simply pass your data to
``(: io format '"~p~n" (list your-data))`` and you will see something like this
instead:

.. code:: erlang

    [{[{<<"name">>,<<"cloudFilesCDN">>},
       {<<"endpoints">>,
        [{[{<<"region">>,<<"DFW">>},
           {<<"tenantId">>,
           ...


List of Services
----------------

To get a list of the services provided by Rackspace:

.. code:: common-lisp

    (: lferax-services get-service-catalog auth-response)


Service Endpoints
-----------------

To get the endpoints for a particular service:

.. code:: common-lisp

    (: lferax-services get-service-endpoints auth-response
      '"cloudServersOpenStack")

The full list of available endpoints is provided in
``(: lferax-consts services)``. We recommend using the ``dict`` provided there,
keying off the appropriate atom for the service that you need, e.g.:

.. code:: common-lisp

    (set service (: dict fetch 'servers-v2 (: lferax-const services)))
    (: lferax-services get-service-endpoints response service)

We provide some alias functions for commonly used service endpoints, e.g.:

.. code:: common-lisp

    (: lferax-services get-cloud-servers-v2-endpoints auth-response)


Region Endpoint URL
-------------------

Furthermore, you can get a service's URL by region:

.. code:: common-lisp

    (: lferax-services get-cloud-servers-v2-url auth-response '"DFW")

A full list of regions that can be passed (as in "DFW" above) is
provided in ``(: lferax-consts services)``.

We actually recommand using the documented atoms for the regions (just like
the services above):

.. code:: common-lisp

    (set region (: dict fetch 'dfw (: lferax-const regions)))
    (: lferax-services get-cloud-servers-v2-url auth-response region)


Cloud Servers
=============

For the conveneince of the reader, in the following examples, we will give each
command needed to go from initial login to final result.


Getting Flavors List
--------------------

.. code:: common-lisp

    ; function calls from before
    (set auth-response (: lferax-identity login))
    (set token (: lferax-identity get-token auth-response))
    (set region (: dict fetch 'dfw (: lferax-const regions)))
    ; new calls
    (set flavors-list (: lferax-servers get-flavors-list auth-response region))
    (: io format '"~p~n" (list flavors-list))

To get a particular flavor id from that list, you can use this convenience
function:

.. code:: common-lisp

    (set flavor-id (: lferax-servers get-id '"30 GB Performance" flavors-list))


Getting Images List
-------------------

.. code:: common-lisp

    ; function calls from before
    (set auth-response (: lferax-identity login))
    (set token (: lferax-identity get-token auth-response))
    (set region (: dict fetch 'dfw (: lferax-const regions)))
    ; new call
    (set images-list (: lferax-servers get-images-list auth-response region))
    (: io format '"~p~n" (list images-list))

To get a particular image id from that list, you can use this convenience
function:

.. code:: common-lisp

    (set image-id (: lferax-servers get-id
                    '"Ubuntu 12.04 LTS (Precise Pangolin)"
                    images-list))


Creating a Server
-----------------

.. code:: common-lisp

    ; function calls from before
    (set auth-response (: lferax-identity login))
    (set token (: lferax-identity get-token auth-response))
    (set region (: dict fetch 'dfw (: lferax-const regions)))
    (set flavors-list (: lferax-servers get-flavors-list auth-response region))
    (set flavor-id (: lferax-servers get-flavor-id
                     '"30 GB Performance"
                     flavors-list))
    (set images-list (: lferax-servers get-images-list auth-response region))
    (set image-id (: lferax-servers get-image-id
                    '"Ubuntu 12.04 LTS (Precise Pangolin)"
                    images-list))
    ; new calls
    (set server-name '"proj-server-1")
    (set server-response (: lferax-servers create-server
                           auth-response
                           region
                           server-name
                           image-id
                           flavor-id))

Getting a List of Servers
-------------------------

.. code:: common-lisp

    ; function calls from before
    (set auth-response (: lferax-identity login))
    (set token (: lferax-identity get-token auth-response))
    (set region (: dict fetch 'dfw (: lferax-const regions)))
    ; new call
    (set server-list (: lferax-servers get-server-list auth-response region))
    (: io format '"~p~n" (list server-list))


Utility Functions
=================

TBD


.. Links
.. -----
.. _Clojure bindings: https://github.com/oubiwann/clj-rackspace
.. _rebar: https://github.com/rebar/rebar
.. _LFE: https://github.com/rvirding/lfe
.. _lfe-openstack: https://github.com/oubiwann/lfe-openstack
