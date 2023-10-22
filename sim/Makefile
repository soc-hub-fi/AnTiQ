BUILD_DIR ?= $(realpath $(CURDIR))
VOPT_OPTS += "+acc=npr"
DUT ?= tb_pq_common
VSIM_DOFILE ?= "./scripts/pq.do"
VSIM_OPTS = ""

.PHONY: check-env
check-env:
	mkdir -p $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)/logs/compile
	mkdir -p $(BUILD_DIR)/logs/opt
	mkdir -p $(BUILD_DIR)/logs/sim

.PHONY: compile
compile: check-env
	vlib $(BUILD_DIR)/pq_lib
	vmap pq_lib $(BUILD_DIR)/pq_lib
	vlog -work pq_lib \
	-sv -f pq_files.list \
	-l $(BUILD_DIR)/logs/compile/pq.log

.PHONY: verilate
verilate:
	cd $(BUILD_DIR)/verilator
	./scripts/verilate.sh

.PHONY: elaboration
elaboration: check-env
	cd $(BUILD_DIR)
	vopt \
	$(VOPT_OPTS) \
	-work $(BUILD_DIR)/pq_lib \
	$(DUT) \
	-o $(DUT)_opt \
	-l $(BUILD_DIR)/logs/opt/pq_vopt.log

.PHONY: run
run: check-env elaboration
	cd $(BUILD_DIR)
	vsim \
	$(VSIM_OPTS) \
	-work $(BUILD_DIR)/pq_lib \
	$(DUT)_opt \
	-onfinish stop \
	-do $(VSIM_DOFILE) \
	-l $(BUILD_DIR)/logs/sim/pq_vsim.log

.PHONY: batch
batch:
	make run VSIM_OPTS="-c" VSIM_DOFILE="./scripts/pq_batch.do"

.PHONY: sanity
sanity:
	make run VSIM_OPTS="-c" VSIM_DOFILE="./scripts/sanity.do"

.PHONY: clean
clean:
	rm -fr $(BUILD_DIR)/pq_lib
	rm -fr $(BUILD_DIR)/obj_dir