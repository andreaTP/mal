#####################

# SOURCES_BASE = types.nim reader.nim printer.nim
# SOURCES_LISP = env.nim core.nim stepA_mal.nim
# SOURCES = $(SOURCES_BASE) $(SOURCES_LISP)
# SOURCES_REBUILD = $(SOURCES_BASE) env.nim core.nim

#####################

SRCS = step0_repl.cr \
			 step1_read_print.cr
BINS = $(SRCS:%.cr=%)

#####################

all: $(BINS)

dist: mal

mal: $(word $(words $(BINS)),$(BINS))
	cp $< $@

$(BINS): %: %.cr $(SOURCES_REBUILD)
	#crystal --release $@
	crystal build $@.cr

clean:
	rm -rf bin/ $(BINS)
	rm -f mal

.PHONY: stats stats-lisp

stats: $(SOURCES)
	@wc $^
	@printf "%5s %5s %5s %s\n" `grep -E "^[[:space:]]*#|^[[:space:]]*$$" $^ | wc` "[comments/blanks]"
stats-lisp: $(SOURCES_LISP)
	@wc $^
	@printf "%5s %5s %5s %s\n" `grep -E "^[[:space:]]*#|^[[:space:]]*$$" $^ | wc` "[comments/blanks]"
