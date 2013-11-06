ARCHS = armv7 armv7s
TARGET = iphone:7.0:5.0

include theos/makefiles/common.mk

TWEAK_NAME = NoProblem
NoProblem_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
