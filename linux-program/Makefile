
dirs := $(shell find -type d)

dirs := $(subst .,,$(dirs))
dirs := $(subst /,,$(dirs))

all:
	make -f lib.mk
	for d in $(dirs); do make -C $$d || exit; done;

clean:
	make -f lib.mk clean;
	for d in $(dirs); do make -C $$d clean; done;
