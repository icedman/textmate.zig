// parser settings
const caching = true;
pub const enable_exec_caching = caching and true;
pub const enable_match_caching = caching and true;
pub const enable_end_caching = caching and true;

// compute theme-based atoms for resolved scopes
pub const enable_scope_atoms = true;
// skip theme-ignored atoms
pub const enable_scope_atoms_skip = false;

pub const max_line_len = 1024; // a line longer will not be parsed
pub const max_match_ranges = 9; // max $1 in grammar files is just 8

pub const max_state_stack_depth = 128; // if the state depth is too deep .. just prune (this shouldn't happen though)
pub const state_stack_prune = 64; // prune off states from the stack

// theme settings
pub const enable_scope_caching = true;

// processor
pub const max_span_captures = 64;
