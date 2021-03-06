CFCM=node_modules/.bin/commonform-commonmark
CFDOCX=node_modules/.bin/commonform-docx
CRITIQUE=node_modules/.bin/commonform-critique
LINT=node_modules/.bin/commonform-lint
SPELL=node_modules/.bin/reviewers-edition-spell
TOOLS=$(CFCM) $(CFDOCX) $(CRITIQUE) $(LINT) $(SPELL)

BUILD=build
BASENAMES=terms
JSON=$(BUILD)/terms.form.json

GIT_TAG=$(shell (git diff-index --quiet HEAD && git describe --exact-match --tags 2>/dev/null | sed 's/v//'))
EDITION:=$(or $(EDITION),$(if $(GIT_TAG),$(GIT_TAG),Internal Draft))
EDITION_FLAG=--edition "$(EDITION)"

all: docx pdf

docx: $(BUILD)/terms.docx
pdf: $(BUILD)/terms.pdf

$(BUILD)/%.docx: $(BUILD)/%.form.json $(BUILD)/%.directions.json %.title blanks.json styles.json | $(CFDOCX) $(BUILD)
	$(CFDOCX) --title "$(shell cat $*.title)" --edition "$(EDITION)" --number outline --indent-margins --left-align-title --values blanks.json --directions $(BUILD)/$*.directions.json --styles styles.json $< > $@

$(BUILD)/%.form.json: %.md | $(BUILD) $(CFCM)
	$(CFCM) parse --only form < $< > $@

$(BUILD)/%.directions.json: %.md | $(BUILD) $(CFCM)
	$(CFCM) parse --only directions < $< > $@

%.pdf: %.docx
	unoconv $<

$(BUILD):
	mkdir -p $@

$(TOOLS):
	npm ci

.PHONY: clean docker lint critique

lint: $(JSON) | $(CF)
	for form in $(JSON); do echo $$form; $(CF) lint < $$form; done

critique: $(JSON) | $(CF)
	for form in $(JSON); do echo $$form ; $(CF) critique < $$form; done

clean:
	rm -rf $(BUILD)

docker:
	docker build -t licensezero-relicense-agreement .
	docker run --name licensezero-relicense-agreement licensezero-relicense-agreement
	docker cp licensezero-relicense-agreement:/workdir/$(BUILD) .
	docker rm licensezero-relicense-agreement
