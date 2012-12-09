#!/usr/bin/env python
# vim:tabstop=4 shiftwidth=4 encoding=utf-8
"""Basifyes 64 input files."""

from __future__ import with_statement
import base64
import os.path
import sys


def main():
	"""f() -> None

	Main entry point of the application.
	"""
	args = sys.argv[1:]
	for filename in sys.argv[1:]:
		dummy, ext = os.path.splitext(filename)
		ext = ext.lower()
		if ".base64" == ext:
			print "%r alread basified" % filename
			continue

		dest = "%s.base64" % filename
		print "%s -> %s" % (filename, dest)
		with open(filename, "rb") as input:
			with open(dest, "wb") as output:
				base64.encode(input, output)


if "__main__" == __name__:
	main()
