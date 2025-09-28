.PHONY: setup
setup:
	@meson setup builddir

.PHONY: clean 
clean:
	@clear
	@rm -rf ./builddir
	@make setup

.PHONY: compile
compile:
	@make clean
	@meson compile -C builddir
	@cd ./builddir && echo "Built at: $$(pwd)/src/"

.PHONY: install
install:
	@sudo meson install -C builddir

