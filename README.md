# scxa-workflows
Higher level repo for aggregating all of Atlas workflow logic for Single Cell towards execution purposes.

## Organization

Each workflow type will live in a `w_` prefixed directory, where the execution should fine everything needed to run it, with execution configuration being inyectable. The content of the directory should include:

- Parameters
- Workflow definition
- Any software requisites (ie. do you need to install a conda package for the executor of the workflow?)

The definition for fulfilling this is rather flexible (it could be either the file itself or something that links to that information, provided it can be followed by the automatic executor).

### Technology

The `w_` prefix is followed by a technology name. The name should not use underscores, but dashes instead if needed. Current technologies supported will be:

- smart-seq
- smart-seq2
- smarter
- ...to be completed

### Phase of analysis

Given that we currently have separation between quantification and clustering, the `w_technology_` prefix will be followed by a phase of analysis section. Currently:

- quantification
- clustering


