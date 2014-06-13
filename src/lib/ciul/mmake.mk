ifeq ($(UNIX),1)
# Order important for GNU make 3.82 unless MMAKE_NO_DEPS=1. SFC bug 27495.
TARGETS		:= $(EFVI_LIB) $(CIUL_LIB)
TARGETS		+= $(CIUL_REALNAME) $(CIUL_SONAME) $(CIUL_LINKNAME)
else
TARGETS		:= $(CIUL_LIB)
endif
MMAKE_TYPE	:= LIB

# Standalone subset for descriptor munging only.
EFVI_SRCS	:=		\
		pt_tx.c		\
		pt_rx.c		\
		falcon_event.c	\
		vi_init.c	\
		falcon_vi.c	\
		ef10_event.c	\
		ef10_vi.c

LIB_SRCS	:=		\
		$(EFVI_SRCS)	\
		falcon_evtimer.c	\
		ef10_evtimer.c	\
		logging.c

ifneq ($(DRIVER),1)
LIB_SRCS	+=		\
		open.c		\
		event_q.c	\
		event_q_put.c	\
		pt_endpoint.c	\
		filter.c	\
		vi_set.c	\
		memreg.c	\
		pd.c		\
		pio.c		\
		falcon_evtimer.c\
		ef10_evtimer.c  \
		vi_layout.c
endif


ifndef MMAKE_NO_RULES

MMAKE_OBJ_PREFIX := ci_ul_
EFVI_OBJS	 := $(EFVI_SRCS:%.c=$(MMAKE_OBJ_PREFIX)%.o)
LIB_OBJS	 := $(LIB_SRCS:%.c=$(MMAKE_OBJ_PREFIX)%.o)


all: $(TARGETS)

lib: $(TARGETS)

clean:
	@$(MakeClean)
	rm -f efvi_uk_intf_ver.h

$(CIUL_LIB): $(LIB_OBJS)
	$(MMakeLinkStaticLib)

$(EFVI_LIB): $(EFVI_OBJS)
	$(MMakeLinkStaticLib)

$(CIUL_REALNAME): $(LIB_OBJS)
	@(soname="$(CIUL_SONAME)"; $(MMakeLinkDynamicLib))

$(CIUL_SONAME): $(CIUL_REALNAME)
	ln -fs $(shell basename $^) $@

$(CIUL_LINKNAME): $(CIUL_REALNAME)
	ln -fs $(shell basename $^) $@

endif


######################################################################
# Autogenerated header for checking user/kernel interface consistency.
#
_EFCH_INTF_HDRS	:= ci/efch/op_types.h
EFCH_INTF_HDRS	:= $(_EFCH_INTF_HDRS:%=$(SRCPATH)/include/%)

ifdef MMAKE_USE_KBUILD
objd	:= $(obj)/
else
objd	:=
endif

$(objd)efch_intf_ver.h: $(EFCH_INTF_HDRS)
	@echo "  GENERATE $@"
	@md5=$$(cat $(EFCH_INTF_HDRS) | grep -v '^[ *]\*' | \
		md5sum | sed 's/ .*//'); \
	echo "#define EFCH_INTF_VER  \"$$md5\"" >"$@"

$(objd)$(MMAKE_OBJ_PREFIX)pt_endpoint.o: $(objd)efch_intf_ver.h
$(objd)$(MMAKE_OBJ_PREFIX)vi_set.o: $(objd)efch_intf_ver.h
$(objd)$(MMAKE_OBJ_PREFIX)vi_init.o: $(objd)efch_intf_ver.h


######################################################
# linux kbuild support
#
ifdef MMAKE_USE_KBUILD
all:
	 $(MAKE) $(MMAKE_KBUILD_ARGS) SUBDIRS=$(BUILDPATH)/lib/ciul _module_$(BUILDPATH)/lib/ciul
clean:
	@$(MakeClean)
	rm -f lib.a
endif

ifdef MMAKE_IN_KBUILD
LIB_OBJS := $(LIB_SRCS:%.c=%.o)
lib-y    := $(LIB_OBJS)
endif
