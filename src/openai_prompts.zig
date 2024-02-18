const llms = @import("llm_client.zig");

pub const INITIAL_SYSTEM_PROMPT = llms.Message{ .role = "system", .content = "You are a helpful assistant." };

pub const SYSTEM_PROMPT = llms.Message{ .role = "system", .content = @embedFile("long_prompt.txt") };

pub const PROMPT_EXAMPLES = llms.Message{ .role = "system", .content = @embedFile("prompt_examples.txt") };
