# You will most likely need to run this will root privileges
# TODO: Break this up into installman, installdoc, installsource, etc.
install : installlibs installsource installdocumentation installinterfaces

installlibs : libs
	$(INSTALL_DATA) $(SRCDIR)/output/libraries/$(PACKAGE_SLUG)-$(VERSION).so $(DESTDIR)$(libdir)
	-rm -f $(DESTDIR)$(libdir)/$(PACKAGE_SLUG).so
	ln -s $(DESTDIR)$(libdir)/$(PACKAGE_SLUG)-$(VERSION).so $(DESTDIR)$(libdir)/$(PACKAGE_SLUG).so

# FIXME: The problem here is that vpath does not recurse to the subdirectories of output/interfaces
installinterfaces :
	mkdir -p $(DESTDIR)$(includedir)/$(PACKAGE_SLUG)
	cp -r $(SRCDIR)/output/interfaces/* $(DESTDIR)$(includedir)/$(PACKAGE_SLUG)

installsource : $(sources)
	mkdir -p $(DESTDIR)$(srcdir)/$(PACKAGE_SLUG)
	cp -r $(SRCDIR)/source/* $(DESTDIR)$(srcdir)/$(PACKAGE_SLUG)

installexecutables : tools
	$(INSTALL_PROGRAM) $(SRCDIR)/output/executables/encode-* $(DESTDIR)$(bindir)
	$(INSTALL_PROGRAM) $(SRCDIR)/output/executables/decode-* $(DESTDIR)$(bindir)

installdocumentation : installman installhtml installmarkdown
	mkdir -p $(DESTDIR)$(docdir)/$(PACKAGE_SLUG)
	$(INSTALL_DATA) $(SRCDIR)/documentation/mit.license $(DESTDIR)$(docdir)/$(PACKAGE_SLUG)
	$(INSTALL_DATA) $(SRCDIR)/documentation/credits.csv $(DESTDIR)$(docdir)/$(PACKAGE_SLUG)
	$(INSTALL_DATA) $(SRCDIR)/documentation/releases.csv $(DESTDIR)$(docdir)/$(PACKAGE_SLUG)

# TODO: Figure out where the manpages are ahead of time
installman : $(manpages)
	$(INSTALL_DATA) $(SRCDIR)/documentation/man/1/* $(DESTDIR)$(man1dir)

# FIXME: The problem here is that vpath does not recurse to the subdirectories of documentation/html
installhtml :
	mkdir -p $(DESTDIR)$(docdir)/$(PACKAGE_SLUG)
	cp -r $(SRCDIR)/documentation/html/* $(DESTDIR)$(docdir)/$(PACKAGE_SLUG)

# FIXME:
installmarkdown :
	mkdir -p $(DESTDIR)$(docdir)/$(PACKAGE_SLUG)
	$(INSTALL_DATA) $(SRCDIR)/documentation/*.md $(DESTDIR)$(docdir)/$(PACKAGE_SLUG)

installjsondocs : jsondocs
	mkdir -p $(DESTDIR)$(docdir)/$(PACKAGE_SLUG)
	$(INSTALL_DATA) $(SRCDIR)/documentation/$(PACKAGE_SLUG)-$(VERSION).json $(DESTDIR)$(docdir)/$(PACKAGE_SLUG)

uninstall :
	-rm -f $(DESTDIR)$(libdir)/$(PACKAGE_SLUG).so
	-rm -f $(DESTDIR)$(libdir)/$(PACKAGE_SLUG)-$(VERSION).so
	rm -f $(DESTDIR)$(bindir)/decode-*
	rm -f $(DESTDIR)$(bindir)/encode-*
	rm -rf $(DESTDIR)$(docdir)/$(PACKAGE_SLUG)
	rm -f $(DESTDIR)$(mandir)/encode-*$(man1ext)
	rm -f $(DESTDIR)$(mandir)/decode-*$(man1ext)