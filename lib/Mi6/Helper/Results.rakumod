unit class Mi6::Helper::Results;
has Str $.title is required;

has Str  @.notes  is rw;
has Str  @.issues is rw;
has UInt $.errors is rw = 0;
