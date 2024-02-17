const std = @import("std");
const client = @import("llm_client.zig");
const Thread = std.Thread;

var should_stop: std.atomic.Atomic(bool) = std.atomic.Atomic(bool).init(false);

fn animationThreadFn() void {
    const stdout = std.io.getStdOut().writer();
    var spinner_chars = "|/-\\";
    var index: usize = 0;

    while (!should_stop.load(std.atomic.Ordering.SeqCst)) {
        std.time.sleep(100000);
        stdout.print("\r{c} ", .{spinner_chars[index % spinner_chars.len]}) catch {};
        index += 1;
    }
    // Clear the spinner before exit
    stdout.print("\r \r", .{}) catch {};
}

pub fn main() !void {
    // Prep stdin and stdout
    const stdin = std.io.getStdIn().reader();
    const stdout_file = std.io.getStdOut().writer();

    // Prep allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("\x1B[2J\x1B[H", .{}); // Clear screen and move cursor to top left
    try stdout.print("> just type something\n", .{});
    try bw.flush(); // Don't forget to flush!

    var user_input = std.ArrayList(u8).init(allocator);
    defer user_input.deinit();

    stdin.streamUntilDelimiter(user_input.writer(), '\n', null) catch unreachable;

    try stdout.print("You typed: {s}\n", .{user_input.items});
    try bw.flush();

    // Start animation thread
    var thread = try Thread.spawn(.{}, animationThreadFn, .{});

    // Make API request
    var client_response = try client.sendRequest(allocator, user_input.items);
    defer allocator.free(client_response);

    // Stop animation
    should_stop.store(true, std.atomic.Ordering.SeqCst);
    thread.join();

    try stdout.print("Response: {s}\n", .{client_response});
    try bw.flush();
}

// const std = @import("std");
// const client = @import("llm_client.zig");

// pub fn main() !void {
//     // prep stdin and stdout
//     const stdin = std.io.getStdIn().reader();
//     const stdout_file = std.io.getStdOut().writer();

//     // prep allocator
//     var gpa = std.heap.GeneralPurposeAllocator(.{}){};
//     defer std.debug.assert(gpa.deinit() == .ok);
//     const allocator = gpa.allocator();

//     var bw = std.io.bufferedWriter(stdout_file);
//     const stdout = bw.writer();

//     try stdout.print("\x1B[2J\x1B[H", .{}); // clear screen and move cursor to top left
//     try stdout.print("> just type something\n", .{});
//     try bw.flush(); // don't forget to flush!

//     var user_input = std.ArrayList(u8).init(allocator);
//     defer user_input.deinit();

//     stdin.streamUntilDelimiter(user_input.writer(), '\n', null) catch unreachable;

//     try stdout.print("you typed: {s}\n", .{user_input.items});
//     try bw.flush();

//     var client_response = try client.sendRequest(allocator, user_input.items);
//     defer allocator.free(client_response);

//     try stdout.print("response: {s}\n", .{client_response});
//     try bw.flush();
// }
