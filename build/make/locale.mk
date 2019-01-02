#!/usr/bin/make
#
# Configures locale settings, which includes the language, country, codeset,
# and modifiers. Automatically uses those as inputs to generate a locale
# identifier per ISO/IEC 15897, which has the format:
# [language[_territory][.codeset][@modifier]]
#
LANGUAGE = en
TERRITORY = US
CODESET = UTF-8
MODIFIER =

ifeq ($(strip $(LANGUAGE)),)
	LOCALE := en
else
	ifeq ($(strip $(TERRITORY)),)
		LOCALE := $(strip $(LANGUAGE))
	else
		ifeq ($(strip $(CODESET)),)
			LOCALE := $(strip $(LANGUAGE))_$(strip $(TERRITORY))
		else
			ifeq ($(strip $(MODIFIER)),)
				LOCALE := $(strip $(LANGUAGE))_$(strip $(TERRITORY)).$(strip $(CODESET))
			else
				LOCALE := $(strip $(LANGUAGE))_$(strip $(TERRITORY)).$(strip $(CODESET))@$(strip $(MODIFIER))
			endif
		endif
	endif
endif

debug_locale : debug_language debug_territory debug_codeset debug_modifier
	@$(info LOCALE=$(LOCALE))

debug_language :
	@$(info LANGUAGE=$(LANGUAGE))

debug_territory :
	@$(info TERRITORY=$(TERRITORY))

debug_codeset :
	@$(info CODESET=$(CODESET))

debug_modifier :
	@$(info MODIFIER=$(MODIFIER))
