const std = @import("std");
const openai_prompts = @import("openai_prompts.zig");
const llms = @import("llm_client.zig");
// we are going to achieve AGENTIC reasoning via openai calls

const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();

pub fn processCommandUsingAgent() !void {
    // make openai call
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    // get user input
    var userInput = std.ArrayList(u8).init(allocator);
    defer userInput.deinit();

    try stdout.print("╭─ \x1b[48;5;76m\x1b[3m How can I help? \x1b[0m \x1b[5;32m●\x1b[0m ───────────────────────────╮ \n", .{});
    try stdout.print(">>> ", .{});

    try stdin.streamUntilDelimiter(userInput.writer(), '\n', null);

    // purely for pretty printing
    try stdout.print("\x1b[A\x1b[2K", .{});
    try stdout.print("│ {s}\n", .{userInput.items});

    const userMessage = llms.Message{
        .role = "user",
        .content = userInput.items,
    };

    const messageHistory = [_]llms.Message{
        openai_prompts.RAWDOG_PROMPT,
        userMessage,
    };

    const assistantMessage = try llms.sendOpenaiRequest(allocator, &messageHistory);
    defer allocator.free(assistantMessage);

    // purely for pretty printing
    // try stdout.print("{s}\n", .{assistantMessage});
    var it = std.mem.tokenizeSequence(u8, assistantMessage, "\n");
    while (it.next()) |line| {
        try stdout.print("│ {s}\n", .{line});
    }
}
