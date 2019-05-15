Helper tools used to administrate the VDR GIT repository
========================================================

This repository contains scripts and other helpers used to administrate the VDR GIT repository.

vdrpatch2commit.pl
------------------

Takes FTP link to a VDR patch and creates a new GIT commit from the information in the patch file.

The commit message is created as following:
- The patch name itself is used as "summary"
- If the patch file contains a comment in the header, then this is added to the commit message as "additional information" (separated with one empty line).

The commit date is taken from the file modification time. Author is set to be "Klaus Schmidinger".
