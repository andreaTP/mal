#####################

SRCS = step0_repl.cr \
			 step1_read_print.cr \
			 step2_eval.cr

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
