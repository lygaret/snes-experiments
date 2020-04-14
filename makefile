title = thiefery
version = 0.01

objlist = \
  snesheader init main

AS := ca65
ASFLAGS := -s --cpu 65816

LD := ld65
LDFLAGS := -v -vm

PY := python3

srcdir := src
builddir := build
distdir := dist

objlisto := $(foreach o,$(objlist),$(builddir)/$(o).o)

# preload any dependencies files
-include $(wildcard $(BUILD_DIR)/*.s.d)

.PHONY: default clean

default: dist/$(title).sfc

clean:
	-rm -rf $(distdir) $(builddir)

$(builddir) $(distdir):
	mkdir -p $@

$(builddir)/%.o : $(srcdir)/%.s | $(builddir)
	$(AS) $(ASFLAGS) --create-dep $(subst .o,.s.d,$@) -o $@ -l $(subst .o,.list,$@) $<
	sed -i .bak 's#$(srcdir)/\(.*\):#$(builddir)/\1:#' $(subst .o,.s.d,$@)

$(distdir)/$(title).sfc $(distdir)/$(title).map: $(srcdir)/linker.cfg $(objlisto) | $(distdir)
	$(LD) $(LDFLAGS) -o $(distdir)/$(title).sfc -m $(distdir)/$(title).map -C $^
	$(PY) tools/fixchecksum.py $(distdir)/$(title).sfc

.SECONDARY:
