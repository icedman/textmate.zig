// parser settings
pub const enable_exec_caching = true;
pub const enable_match_caching = true;
pub const enable_end_caching = true;
pub const enable_scope_atoms = true;

pub const max_line_len = 1024; // a line longer will not be parsed
pub const max_match_ranges = 9; // max $1 in grammar files is just 8
pub const max_scope_len = 128;

pub const max_state_stack_depth = 128; // if the state depth is too deep .. just prune (this shouldn't happen though)
pub const state_stack_prune = 64; // prune off states from the stack

// theme settings
pub const enable_scope_caching = true;
