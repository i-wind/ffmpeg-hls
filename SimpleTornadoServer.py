#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import unicode_literals

"""
Use tornado's `StaticFileHandler` to replace `SimpleHTTPServer` in Python
standard library, with this you can simply type only one command and run an
HTTP server on the port you desired, the default port [8000] is as the same
as the SimpleHTTPServer provided.

$ python -m SimpleTornadoServer 8080
"""
import os
import sys
import logging
import signal

import tornado.web
import tornado.template
import tornado.ioloop
import tornado.httpserver
from tornado.log import LogFormatter

datefmt = '%Y-%m-%d %H:%M:%S'
fmt = '%(color)s[%(levelname)1.1s %(asctime)s.%(msecs)03d '\
      '%(module)s:%(lineno)d]%(end_color)s %(message)s'
formatter = LogFormatter(color=True, datefmt=datefmt, fmt=fmt)
logger = logging.getLogger()

logHandler = logging.StreamHandler()
logHandler.setFormatter(formatter)
logger.addHandler(logHandler)
logger.setLevel(logging.DEBUG)


class IndexHandler(tornado.web.RequestHandler):
    SUPPORTED_METHODS = ['GET']

    def get(self, path):
        """ GET method to list contents of directory or
        write index page if index.html exists."""

        # remove heading slash
        path = path[1:]

        for index in ['index.html', 'index.htm']:
            index = os.path.join(path, index)
            if os.path.exists(index):
                with open(index, 'rb') as f:
                    self.write(f.read())
                    self.finish()
                    return
        html = self.generate_index(path)
        self.write(html)
        self.finish()

    def generate_index(self, path):
        """ generate index html page, list all files and dirs.
        """
        if path:
            files = os.listdir(path)
        else:
            files = os.listdir('.')
        files = [filename + '/'
                 if os.path.isdir(os.path.join(path, filename))
                 else filename
                 for filename in files]
        html_template = """
        <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 3.2 Final//EN"><html>
        <title>Directory listing for /{{ path }}</title>
        <body>
        <h2>Directory listing for /{{ path }}</h2>
        <hr>
        <ul>
        {% for filename in files %}
        <li><a href="{{ filename }}">{{ filename }}</a>
        {% end %}
        </ul>
        <hr>
        </body>
        </html>
        """
        t = tornado.template.Template(html_template)
        return t.generate(files=files, path=path)


def stop_server(signum, frame):
    tornado.ioloop.IOLoop.instance().stop()
    logging.info('Stopped!')


class StaticFileHandler(tornado.web.StaticFileHandler):

    def write(self, chunk):
        super(StaticFileHandler, self).write(chunk)
        logging.debug('write called')
        self.flush()

    def set_extra_headers(self, path):
        # Disable cache
        # self.set_header("Cache-control", "no-cache")
        self.set_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')


if __name__ == '__main__':
    if sys.argv[1:]:
        port = int(sys.argv[1])
    else:
        port = 8000
    current_path = '.'
    logging.debug('cwd: %s' % current_path)
    application = tornado.web.Application([
        (r'(.*)/$', IndexHandler,),
        (r'/(.*)$', StaticFileHandler, {'path': current_path}),
    ])
    signal.signal(signal.SIGINT, stop_server)

    http_server = tornado.httpserver.HTTPServer(application)
    http_server.listen(port)
    logging.info('Serving HTTP on 0.0.0.0 port %d ...' % port)
    tornado.ioloop.IOLoop.instance().start()
