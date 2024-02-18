const llms = @import("llm_client.zig");

pub const INITIAL_SYSTEM_PROMPT = llms.Message{ .role = "system", .content = "You are a helpful assistant." };

pub const RAWDOG_PROMPT = llms.Message{ .role = "system", .content = @embedFile("long_prompt.txt") };
