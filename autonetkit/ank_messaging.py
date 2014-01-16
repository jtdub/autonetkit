#!/usr/bin/python
# -*- coding: utf-8 -*-
import socket

import autonetkit.ank_json
import autonetkit.config as config
import autonetkit.log as log
from autonetkit.ank_utils import call_log

use_http_post = config.settings['Http Post']['active']
if use_http_post:
    import urllib


@call_log
def format_http_url(host=None, port=None, route='publish'):
    if not host and not port:
        host = config.settings['Http Post']['server']
        port = config.settings['Http Post']['port']
    return 'http://%s:%s/%s' % (host, port, route)


default_http_url = format_http_url()

@call_log
def update_http(
    anm=None,
    nidb=None,
    http_url=None,
    uuid=None,
    ):
    if http_url is None:
        http_url = default_http_url

    if anm and nidb:
        body = autonetkit.ank_json.dumps(anm, nidb)
    elif anm:
        body = autonetkit.ank_json.dumps(anm)
    else:
        import json
        body = json.dumps({})  # blank to test visualisation server running

    if uuid is None:
        uuid = get_uuid(anm)

    params = urllib.urlencode({'body': body, 'type': 'anm',
                              'uuid': uuid})
    try:
        data = urllib.urlopen(http_url, params).read()
        log.debug(data)
    except IOError, e:
        log.info('Unable to connect to visualisation server %s'
                 % http_url)
        return

    if not anm:

        # testing

        log.info('Visualisation server running')

@call_log
def get_uuid(anm):
    try:
        return config.settings['Http Post']['uuid']
    except KeyError:
        log.warning('UUID not set, returning singleuser uuid')
        return 'singleuser'


@call_log
def highlight(
    nodes=None,
    edges=None,
    paths=None,
    path=None,
    uuid='singleuser',
    http_url=None,
    ):
    if http_url is None:
        http_url = default_http_url
    if not paths:
        paths = []

    if path:
        paths.append(path)

    if nodes is None:
        nodes = []
    if edges is None:
        edges = []

    def nfilter(n):
        try:
            return n.id
        except AttributeError:
            return n  # likely already a node id (string)

    def efilter(e):
        try:
            return (e.src.id, e.dst.id)
        except AttributeError:
            return e  # likely already edge (src, dst) id tuple (string)

    nodes = [nfilter(n) for n in nodes]
    edges = [efilter(e) for e in edges]
    filtered_paths = []
    for path in paths:

        # TODO: tidy this logic

        if isinstance(path, dict) and 'path' in path:
            path_data = path  # use as-s
        else:
            import random
            is_verified = bool(random.randint(0, 1))

            # path_data = {'path': path, 'verified': is_verified}

            path_data = {'path': path}

        path_data['path'] = [nfilter(n) for n in path_data['path']]
        filtered_paths.append(path_data)

    # TODO: remove "highlight" from json, use as url params to distinguish

    import json
    body = json.dumps({'nodes': nodes, 'edges': edges,
                      'paths': filtered_paths})

    params = urllib.urlencode({'body': body, 'type': 'highlight',
                              'uuid': uuid})

    # TODO: split this common function out, create at runtime so don't need to keep reading config

    try:
        data = urllib.urlopen(http_url, params).read()
    except IOError, e:
        log.info('Unable to connect to HTTP Server %s: %s' % (http_url,
                 e))

