const std = @import("std");
const llm_client = @import("llm_client.zig");

const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();

var context_cnt: u8 = 0;
var max_contexts: u8 = 0;
var verbose: bool = false;

var contexts: [10][4096]u8 = undefined;
var c_index: u8 = 0;

pub fn main() !void {
    try processCommand();
}

fn processCommand() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    var repeat = true;
    var in: [4096]u8 = undefined;
    var context: [40960]u8 = undefined;

    while (repeat) {
        var natural_language = std.ArrayList(u8).init(allocator);
        defer natural_language.deinit();

        var argv = std.ArrayList(u8).init(allocator);
        defer argv.deinit();
        while (true) {
            in = undefined;
            try stdout.print("What can I help you with?\n", .{});
            _ = try stdin.readUntilDelimiterOrEof(&in, '\n');
            const error_msg = parse_response(&in);
            if (error_msg != null) {
                try stdout.print("Error with input, please try again\n", .{});
                continue;
            }
            break;
        }

        for (in) |c| {
            try stdout.print("{c}", .{c});
            if (c == '\n') {
                break;
            }
        }
        std.log.info("input: {}", .{context_cnt});
        for (in) |c| {
            try natural_language.append(c);
        }
        try natural_language.append('\n');

        gather_context(&context);

        for (context) |c| {
            try natural_language.append(c);
            try stdout.print("{c}", .{c});
            if (c == 0) break;
        }

        var res: []const u8 = try llm_client.strip_response(allocator, natural_language.items);
        add_context(res);

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
}

fn gather_context(context: *[40960]u8) void {
    var src: u32 = 0;
    const header = "This is the past conversation history:\n";
    if (context_cnt > 0) {
        for (header) |c| {
            context[src] = c;
            src += 1;
        }
    }

    for (1..@min(context_cnt, max_contexts) + 1) |i| {
        context[src] = @as(u8, @truncate(i)) + '0';
        context[src + 1] = ' ';
        src += 2;
        for (contexts[(c_index + 10 - i) % 10]) |c| {
            if (c == 0) {
                context[src] = '\n';
                src += 1;
                break;
            }
            context[src] = c;
            src += 1;
        }
    }
    context[src] = 0;
}

fn add_context(res: []const u8) void {
    var src: u32 = 0;
    for (res) |c| {
        contexts[c_index][src] = c;
        src += 1;
    }
    c_index = (c_index + 1) % 10;
    contexts[c_index][src] = 0;
    max_contexts += 1;
}

fn parse_response(in: *[4096]u8) ?[]const u8 {
    var src: u32 = 0;
    var dst: u32 = 0;
    var flag: bool = false;
    while (in[src] == ' ') {
        src += 1;
    }
    while (in[src] != '\n') {
        if (in[src] == '-' and !flag) {
            if (src + 2 >= 4096) {
                return "buffer overflow";
            }
            if (in[src + 1] == 'c' and in[src + 2] == ' ') {
                src += 2;
                context_cnt += 1;
                while (in[src] == ' ') {
                    src += 1;
                }
            } else if ((in[src + 1] >= '0' and in[src + 1] <= '9') and in[src + 2] == ' ') {
                var num: u8 = in[src + 1] - '0';
                context_cnt = num;
                src += 2;
                while (in[src] == ' ') {
                    src += 1;
                }
            } else {
                return "bad flag";
            }
            flag = true;
        } else {
            in[dst] = in[src];
            dst += 1;
            src += 1;
        }
        if (!flag) {
            flag = true;
            context_cnt = 0;
        }
    }
    in[dst] = '\n';
    return null;
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
