include ../make_setting

AR ?= ar
ARFLAGS ?= rv
RANLIB ?= ranlib

all: libdd_mpi.a

ifeq ($(USE_XMP_API), yes)
OBJS = xmpAPI_dd_mpi.o xmpAPI_ddcom4.o
else
OBJS = dd_mpi.o ddcom4.o
endif

libdd_mpi.a: $(OBJS)
	$(AR) $(ARFLAGS) $@ $(OBJS)
	$(RANLIB) $@

.SUFFIXES:
.SUFFIXES: .f .F .c .F90 .o

.c.o:
	$(CC) $(CFLAGS) -c $<
.f.o:
	$(FC) $(FFLAGS) -c $<
.F.o:
	$(FC) $(FFLAGS) -c $<
.F90.o:
	$(FC) $(FFLAGS) -c $<

clean:
	rm -rf *.o *.a
