#!/usr/bin/env python
"""Inserts a version number into a plist file.

The plist is presumed to have the correct structure, containing a node with
version_build_string attribute. The file is modified in place if successful.
"""

import xml.etree.ElementTree as ET
import time
import sys


def read_info_version(filename):
	"""f(string) -> string

	Parses the Info.plist file in search of CFBundleVersion and extracts the
	text, returning it. Returns the empty string or None if not found.
	"""
	state = 0

	tree = ET.parse(filename)
	for f in tree.getiterator():
		if 0 == state:
			if "CFBundleVersion" == f.text:
				state = 1
		elif 1 == state:
			return f.text.strip()

	return ""


def version_stamp_file(filename, prefix):
	"""f(string, string) -> bool

	Reads a plist and writes it if found the correct version node. Pass the
	prefix text to embed in the generated version string.

	Returns True if the function was updated and written.
	"""
	state = 0

	tree = ET.parse(filename)
	for f in tree.getiterator():
		if 0 == state:
			if "version_build_string" == f.text:
				state = 1
		elif 1 == state:
			if "DefaultValue" == f.text:
				state = 2
		elif 2 == state:
			now = "-".join("%02d" % x for x in time.localtime()[:3])
			f.text = "v%s, %s" % (prefix, now)
			state = 3
			break

	if 3 == state:
		tree.write(filename)
		return True
	else:
		return False


def main():
	"""Main application entry point."""
	info_file = sys.argv[1]
	version_prefix = read_info_version(info_file)
	if not version_prefix:
		print "Couldn't extract version info from %r" % info_file
		return

	dest_file = sys.argv[2]
	if version_stamp_file(dest_file, version_prefix):
		print "Modified %r with version" % dest_file
	else:
		print "Didn't find version in %r, ignoring" % dest_file


if "__main__" == __name__:
	main()

# vim:tabstop=4 shiftwidth=4
