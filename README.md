Open Irekia for iOS
===================

As part of the [Open Irekia project](http://open.irekia.net), the Basque
Government has released under the
[EUPL](http://joinup.ec.europa.eu/software/page/eupl) bits of free software.
This is an unofficial mirror of the software releases for the iOS mobile
client, which works on iOS and iPad.

The github repo contains just the files released plus this additional readme
made for Github. You can also read the [original README
here](https://github.com/gradha/OpenIrekia-iOS/blob/master/README) or see a
table of released versions at
[http://gradha.github.com/OpenIrekia-iOS/](http://gradha.github.com/OpenIrekia-iOS/).
You can [https://itunes.apple.com/es/app/irekia/id383327242?mt=8](download the
iOS version from the App Store).

Compilation
-----------

The last released version doesn't compile for iOS 6 due to a naming clash of
the UIActivity class. Renaming it should make everything work. Also there are
missing files with secret keys you will have to generate from their template
version (mainly for social network sharers).
