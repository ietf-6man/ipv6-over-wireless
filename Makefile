YANGDATE=2023-01-10
CWTSIDDATE1=ietf-voucher@${YANGDATE}.sid
CWTSIDLIST1=ietf-voucher-sid.txt
CWTSIDDATE2=ietf-voucher-request@${YANGDATE}.sid
CWTSIDLIST2=ietf-voucher-request-sid.txt
EXAMPLES+=$(wildcard examples/voucher*.b64)
EXAMPLES+=$(wildcard examples/*.pem)
EXAMPLES+=$(wildcard examples/*.crt)
LIBDIR := lib

# add this path because your local install might be newer.
YANGMODULESPATH=${HOME}/.local/share/yang/modules
PYANG?=pyang
PYANGPATH=--path=yang --path=${YANGMODULESPATH}
include $(LIBDIR)/main.mk

$(LIBDIR)/main.mk:
ifneq (,$(shell grep "path *= *$(LIBDIR)" .gitmodules 2>/dev/null))
	git submodule sync
	git submodule update $(CLONE_ARGS) --init
else
	git clone -q --depth 10 $(CLONE_ARGS) \
	    -b main https://github.com/martinthomson/i-d-template $(LIBDIR)
endif

# because pyang likes to pick the file ./"foo.yang", when it should be looking for
# yang/foo@DATE.yang first, most invokations are pyang are done from the yang
# subdirectory so that pyang won't see the template files in the CWD.
# maybe a different extension is in order.

draft-ietf-anima-rfc8366bis.xml:: yang/ietf-voucher@${YANGDATE}.yang \
	yang/ietf-voucher-tree-latest.txt \
	yang/ietf-voucher-request@${YANGDATE}.yang \
	yang/ietf-voucher-request-tree-latest.txt ${CWTSIDLIST1} ${CWTSIDLIST2} ${EXAMPLES}

yang/ietf-voucher@${YANGDATE}.yang: ietf-voucher.yang
	# make sure we are running a new enough pyang
	${PYANG} --help | grep sid-finalize
	which ${PYANG}
	mkdir -p yang
	sed -e 's/YYYY-MM-DD/'${YANGDATE}'/g' ietf-voucher.yang | (cd yang && tee ietf-voucher-sed.yang | ${PYANG} ${PYANGPATH} --keep-comments -f yang >ietf-voucher@${YANGDATE}.yang )
	ln -s -f ietf-voucher@${YANGDATE}.yang yang/ietf-voucher-latest.yang

yang/ietf-voucher-request@${YANGDATE}.yang: ietf-voucher-request.yang
	mkdir -p yang
	sed -e 's/YYYY-MM-DD/'${YANGDATE}'/g' ietf-voucher-request.yang | (cd yang && ${PYANG} ${PYANGPATH} --keep-comments -f yang >ietf-voucher-request@${YANGDATE}.yang )
	ln -s -f ietf-voucher-request@${YANGDATE}.yang yang/ietf-voucher-request-latest.yang

yang/ietf-voucher-tree-latest.txt: yang/ietf-voucher@${YANGDATE}.yang
	# make sure we are running a new enough pyang
	${PYANG} --help | grep sid-finalize
	mkdir -p yang
	${PYANG} ${PYANGPATH} -f tree --tree-print-structures --tree-line-length=70  yang/ietf-voucher@${YANGDATE}.yang > yang/ietf-voucher-tree-latest.txt

yang/ietf-voucher-request-tree-latest.txt: yang/ietf-voucher-request@${YANGDATE}.yang
	${PYANG} ${PYANGPATH} -f tree --tree-print-structures --tree-line-length=70 yang/ietf-voucher-request@${YANGDATE}.yang > yang/ietf-voucher-request-tree-latest.txt

# Base SID value for voucher: 2450
boot-sid1: yang/ietf-voucher@${YANGDATE}.yang
	${PYANG} ${PYANGPATH} --sid-list --generate-sid-file 2450:50 yang/ietf-voucher@${YANGDATE}.yang

${CWTSIDLIST1}: yang/ietf-voucher@${YANGDATE}.yang
	mkdir -p yang
	ln -s -f ../${CWTSIDDATE1} yang/${CWTSIDDATE1}
	(cd yang && ${PYANG} ${PYANGPATH} --sid-list --sid-update-file=../${CWTSIDDATE1} ietf-voucher@${YANGDATE}.yang ) | ./truncate-sid-table >${CWTSIDLIST1}

# Base SID value for voucher request: 2500
boot-sid2: yang/ietf-voucher-request@${YANGDATE}.yang
	mkdir -p yang
	(cd yang && ${PYANG} ${PYANGPATH} --sid-list --generate-sid-file 2500:50 ietf-voucher-request@${YANGDATE}.yang )

${CWTSIDLIST2}: yang/ietf-voucher-request@${YANGDATE}.yang
	mkdir -p yang
	ln -s -f ../${CWTSIDDATE2} yang/${CWTSIDDATE2}
	(cd yang && ${PYANG} ${PYANGPATH} --sid-list --sid-update-file=../${CWTSIDDATE2} ietf-voucher-request@${YANGDATE}.yang ) | ./truncate-sid-table >${CWTSIDLIST2}


.PHONY: pyang-install
pyang-install:
	pip3 install pyang


