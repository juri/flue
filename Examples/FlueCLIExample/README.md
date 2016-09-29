# Flue CLI Example

This is an example CLI app using Flue. It embeds Flue localizations inside
the executable (see "Other linker flags" in the project.) The localizations
are read with an Objective-C function due to problems calling
getsectiondata from Swift.
