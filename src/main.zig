const std = @import("std");
const llm_client = @import("llm_client.zig");

const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    try processCommand();
}

fn processCommand() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    var repeat = true;
    var in: [4096]u8 = undefined;

    while (repeat) {
        var natural_language = std.ArrayList(u8).init(allocator);
        defer natural_language.deinit();

        var argv = std.ArrayList(u8).init(allocator);
        defer argv.deinit();

        // in = undefined;
        try stdout.print(">> What can I help you with?\n>> ", .{});
        // _ = try stdin.readUntilDelimiterOrEof(&in, '\n');
        // for (in) |c| {
        //     try natural_language.append(c);
        // }

        stdin.streamUntilDelimiter(natural_language.writer(), '\n', null) catch unreachable;

        std.debug.print("Natural language: {s}\n", .{natural_language.items});
        std.debug.print("---\n", .{});

        var res: []const u8 = try llm_client.strip_response(allocator, natural_language.items);

        for (res) |c| {
            try argv.append(c);
        }

        try make_file(argv.items);
        try run_sh();

        in = undefined;
        try stdout.print("Repeat? (y/n): ", .{});
        _ = try stdin.readUntilDelimiterOrEof(&in, '\n');
        if (in[0] != 'y') {
            repeat = false;
        }
    }
    // var token = std.mem.tokenize(u8, CMD, "\n");
    // while (token.next()) |line| {
    //     try argv.append(line);
    // }
    // try run_sh();
}

fn make_file(argv: []u8) !void {
    var file = try std.fs.cwd().createFile("bash.sh", .{});
    defer file.close();
    try file.writeAll(argv);
}

fn run_sh() !void {
    var in: [4096]u8 = undefined;

    // ask for approval
    try stdout.print("Run Program? (y/n): ", .{});
    _ = try stdin.readUntilDelimiterOrEof(&in, '\n');
    if (in[0] != 'y') {
        return;
    }

    const argv = [_][]const u8{
        "bash",
        "./bash.sh",
    };
    const alloc = std.heap.page_allocator;
    var proc = try std.ChildProcess.exec(.{
        .allocator = alloc,
        .argv = &argv,
    });
    try stdout.print("stdout: {s}", .{proc.stdout});
    std.log.info("stderr: {s}", .{proc.stderr});
}

// fn run_sh(argv: *std.ArrayList([]const u8)) !void {
//     const stdin = std.io.getStdIn().reader();
//     const stdout = std.io.getStdOut().writer();

//     var in: [4096]u8 = undefined;

//     try stdout.print("Run Program? (y/n): ", .{});
//     _ = try stdin.readUntilDelimiterOrEof(&in, '\n');
//     if (in[0] != 'y') {
//         return;
//     }
//     const alloc = std.heap.page_allocator;
//     var proc = try std.ChildProcess.exec(.{
//         .allocator = alloc,
//         .argv = argv.items,
//     });
//     try stdout.print("{s}", .{proc.stdout});
// }
