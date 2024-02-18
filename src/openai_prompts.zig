const llms = @import("llm_client.zig");

pub const INITIAL_SYSTEM_PROMPT = llms.Message{ .role = "system", .content = "You are a helpful assistant." };

pub const EXPLAINER_SYSTEM_PROMPT = llms.Message{ .role = "system", .content = "You are a helpful AI assistant well-versed in shell commands. Given a shell command, and potentially some surrounding text, you will output a natural-language explanation that is easy to understand and not too long or too concise." };

pub const SYSTEM_PROMPT = llms.Message{ .role = "system", .content = @embedFile("long_prompt.txt") };

pub const PROMPT_EXAMPLES = llms.Message{ .role = "system", .content = @embedFile("prompt_examples.txt") };
