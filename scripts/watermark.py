#!/usr/bin/env python
"""Watermarks graphic files.

Tries to generate temporary text information to avoid regenerating
the final files every time.
"""

from __future__ import with_statement

from contextlib import closing
from optparse import OptionParser

import logging
import os
import os.path
import subprocess
import sys
import time

# The formula is ipod screen width divided by the size you want.
PADDING = 1 / (480.0 / 5.0)
FONT_SIZE = 1 / (480.0 / 14.0)
FONT_HEIGHT = 1 / (480.0 / 20.0)


def process_arguments(argv):
	"""f([string, ...]) -> [string, ...]

	Parses the commandline arguments. The function returns a
	structure like object with the attributes "src", "dest" and
	"dir". If there is a basic problem with the input parameters,
	the process will raise the system exit exception.
	"""
	parser = OptionParser()
	parser.add_option("-s", "--src", dest="src", action="store",
		help = "input graphic file.")
	parser.add_option("-t", "--target", dest="dest", action="store",
		help = "path to watermarked output.")
	parser.add_option("-i", "--info", dest="info", action="store",
		help = "path to the plist file with bundle information.")
	parser.add_option("-d", "--dir", dest="dir", action="store",
		help = "where to put temporary files, like a build directory.")
	parser.add_option("-W", "--width", dest="w", type="int",
		help = "expected width of the image, for sanity checks.")
	parser.add_option("-H", "--height", dest="h", type="int",
		help = "expected height of the image, for sanity checks.")

	options, args = parser.parse_args()

	if not options.dir or not os.path.isdir(options.dir):
		print "Specify an existing temporary directory."
		parser.print_help()
		sys.exit(1)

	if not options.src or not os.path.isfile(options.src):
		print "Specify an input file."
		parser.print_help()
		sys.exit(2)

	if not options.info or not os.path.isfile(options.info):
		print "Specify a valid plist information file."
		parser.print_help()
		sys.exit(3)

	if not options.dest:
		print "Specify an output file."
		parser.print_help()
		sys.exit(4)

	if not options.w or not options.h:
		print "Specify for sanity checks the width/height of the image."
		parser.print_help()
		sys.exit(5)

	options.temp = os.path.join(options.dir, os.path.basename(options.src))
	options.final = os.path.join(options.dir, os.path.basename(options.dest))

	return options


def save_as_png(image, name):
	import AppKit
	bits = AppKit.NSBitmapImageRep.imageRepWithData_(image.TIFFRepresentation())
	data = bits.representationUsingType_properties_(AppKit.NSPNGFileType, None)
	data.writeToFile_atomically_(name, True)


def write_text(image, text):
	import AppKit
	w, h = image.size()
	reference_size = max(w, h)
	padding = reference_size * PADDING
	font_size = reference_size * FONT_SIZE
	font_height = reference_size * FONT_HEIGHT
	p = AppKit.NSPoint(padding, padding)
	sz = AppKit.NSSize(w - padding * 2, font_height)
	r = AppKit.NSRect(p, sz)
	s = AppKit.NSString.stringWithString_(text)
	image.lockFocus()
	shadow = AppKit.NSShadow.alloc().init()
	shadow.setShadowOffset_(AppKit.NSSize(1, -1))
	shadow.setShadowColor_(AppKit.NSColor.lightGrayColor())
	shadow.set()
	attrs = AppKit.NSMutableDictionary.dictionary()
	font = AppKit.NSFont.fontWithName_size_('Verdana', font_size)
	attrs.setObject_forKey_(font, AppKit.NSFontAttributeName)
	#color = AppKit.NSColor.colorWithCalibratedWhite_alpha_(1, 1)
	color = AppKit.NSColor.darkGrayColor()
	attrs.setObject_forKey_(color, AppKit.NSForegroundColorAttributeName)
	style = AppKit.NSMutableParagraphStyle.alloc().init()
	style.setParagraphStyle_(AppKit.NSParagraphStyle.defaultParagraphStyle())
	style.setAlignment_(AppKit.NSRightTextAlignment)
	attrs.setObject_forKey_(style, AppKit.NSParagraphStyleAttributeName)
	s.drawInRect_withAttributes_(r, attrs)
	image.unlockFocus()


def get_version(filename):
	"""f(string) -> string

	Opens a plist file and returns the string for the CFBundleVersion
	key. If the key is not there, raises KeyError.
	"""
	import xml.etree.ElementTree as ET
	values = ET.parse(filename).getroot()[0]
	BUNDLE_VERSION = "CFBundleVersion"
	for f in range(len(values)):
		if BUNDLE_VERSION == values[f].text:
			return values[f + 1].text

	raise KeyError("Coultn't find CFBundleVersion in %r", filename)


def cp(src, dest):
	"""f(string, string) -> None

	Copies the contents of src into dest.
	"""
	with open(src, "rb") as input:
		with open(dest, "wb") as output:
			output.write(input.read())


def needs_rebuild(options):
	"""f(options) -> bool

	Returns True if the graphic file needs rebuilding. Rebuilding
	is needed if the final file or one in the middle are missing
	or the timestamps are not in ascending order through the
	chain of files.
	"""
	chain = [options.info, options.src, options.temp, options.final]
	try:
		chain = [os.path.getmtime(x) for x in chain]
	except OSError:
		return True

	if chain[1] > chain[2]:
		return True

	if chain[2] > chain[3]:
		return True

	if chain[0] > chain[2]:
		return True

	if os.path.getsize(options.temp) != os.path.getsize(options.final):
		return True

	return False


def main():
	"""f() -> None

	Main entry point of the application.
	"""
	options = process_arguments(sys.argv)

	if needs_rebuild(options):
		logging.info("Timestamping %r", options.temp)
		import AppKit
		image = AppKit.NSImage.alloc().initWithContentsOfFile_(options.src)
		print "Forcing image to %dx%d" % (options.w, options.h)
		image.setSize_(AppKit.NSSize(options.w, options.h))
		w, h = image.size()
		if w != options.w or h != options.h:
			print "File %s sized %dx%d, expected %dx%d" % (options.src,
				w, h, options.w, options.h)
			sys.exit(10)

		write_text(image, "v%s" % get_version(options.info))
		save_as_png(image, options.temp)
		cp(options.temp, options.final)
		logging.info("Done.")


if "__main__" == __name__:
	logging.basicConfig(level = logging.INFO)
	#logging.basicConfig(level = logging.DEBUG)
	t1 = time.time()
	main()
	t2 = time.time()
	dif = t2 - t1
	if dif > 0.01:
		logging.info("Spent %0.3f seconds rendering graphics", dif)

# vim:tabstop=4 shiftwidth=4
