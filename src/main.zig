const std = @import("std");
const llm_client = @import("llm_client.zig");
const openai_agent = @import("openai_agent.zig");

const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();

var context_cnt: u8 = 0;
var max_contexts: u8 = 0;
var verbose: bool = true;

var contexts: [10][4096]u8 = undefined;
var c_index: u8 = 0; //index of the next context to be added

const asciiArt = "         ,. –  - .,  °           ,-·-.          ,'´¨;             ,. –  - .,  °                              .,'\n        ';_,.., _     '`. '       ';   ';\\      ,'´  ,':\\          ';_,.., _     '`. '        ,.,           ,'´  ;\\\n         \\:::::::::::';   ,'\\       ;   ';:\\   .'   ,'´::'\\          \\:::::::::::;   ,'\\       \\`, '`·.    ,·' ,·´\\::'\\ \n          '\\_;::;:,·´  .·´::\\‘     '\\   ';::;'´  ,'´::::;\\           '\\_;::;:,·´  .·´::\\‘      \\:';  '`·,'´,·´::::'\\:;'\n              , '´ .·´:::::;'         \\  '·:'  ,'´:::::;' '                , '´ .·´:::::;'         `';'\\    ,':::::;·´    \\\n            .´  .'::::::;·´'           '·,   ,'::::::;'´                .´  .'::::::;·´'            ,·´,   \\:;·´    '    \n        .·´ ,·´:::::;·´                ,'  /::::::;'  '            .·´ ,·´:::::;·´            .·´ ,·´:\\   '\\           \n     ,·´  .´;::–·~^*'´';\\‚          ,´  ';\\::::;'  '           ,·´  .´;::–·~^*'´';\\‚     ,·´  .;:::::'\\   ';    '     \n     '.,_ ,. -·~:*'´¨¯:\\:\\ °       \\`*ª'´\\\\::/‘              '.,_ ,. -·~:*'´¨¯:\\:\\ ° ;    '.·'\\::::;'   ,'\\        \n      \\:::::::::::::::::::\\;          '\\:::::\\';  '              \\:::::::::::::::::::\\;   ;·-'´:::::\\·´ \\·:´:::\\       \n       \\:;_;::-·~^*'´¨¯'              `*ª'´‘                   \\:;_;::-·~^*'´¨¯'      \\::::;:·'     '\\;:·'´        \n                                          '                                                `*'´           ‘            \n";

// var should_stop: std.atomic.Atomic(bool) = std.atomic.Atomic(bool).init(false);

// fn waitingAnimation() void {
//     const colors = [_][]const u8{ "30", "31", "32", "33", "34", "35", "36", "37" };
//     var index: usize = 0;

//     while (!should_stop.load(std.atomic.Ordering.SeqCst)) {
//         std.time.sleep(500000);
//         stdout.print("\r \r", .{}) catch {};
//         for (0..index) |i| {
//             stdout.print("\x1B[{s}m•\x1B[0m", .{colors[i]}) catch {};
//         }
//         index += 1;
//         index %= colors.len;
//     }

//     // Clear spinner before exit
//     stdout.print("\r \r", .{}) catch {};
// }

fn processCommand() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    var firstCommand: bool = true;

    var in: [4096]u8 = undefined;
    var context: [40960]u8 = undefined;

    while (true) {
        var needUserInput: bool = true;

        var request = std.ArrayList(u8).init(allocator);
        defer request.deinit();

        var argv = std.ArrayList(u8).init(allocator);
        defer argv.deinit();

        if (firstCommand) {
            var args = std.process.args();
            var argList = std.ArrayList([]const u8).init(allocator);
            defer argList.deinit();

            _ = args.next();
            while (args.next()) |arg| {
                try argList.append(arg);
            }

            if (argList.items.len > 0) {
                const joinedArgs = try std.mem.join(allocator, " ", argList.items);
                defer allocator.free(joinedArgs);

                try stdout.print("\n\x1b[38;5;68m\x1b[3mzyzx\x1b[0m\x1b[38;5;43m\x1b[5m > \x1b[0m", .{});
                try stdout.print(" {s}\n", .{joinedArgs});
                try stdout.print("\x1B[1F\x1B[5C\x7F\x1b[38;5;46m>\x1b[0E\x1b[0m", .{});

                var i: u64 = 0;
                for (joinedArgs) |c| {
                    try request.append(c);
                    in[i] = c;
                    i += 1;
                }

                in[i] = '\n';

                gather_context(&context);

                needUserInput = false;
            }
        }

        if (needUserInput) {
            while (true) {
                in = undefined;
                try stdout.print("\n\x1b[38;5;68m\x1b[3mzyzx\x1b[0m\x1b[38;5;43m\x1b[5m > \x1b[0m", .{});
                _ = try stdin.readUntilDelimiter(&in, '\n');
                try stdout.print("\x1B[1F\x1B[5C\x7F\x1b[38;5;46m>\x1b[0E\x1b[0m", .{});
                const error_msg = try parse_response(&in);
                if (error_msg != null) {
                    try stdout.print("Error with input, please try again\n>> ", .{});
                    continue;
                }
                break;
            }

            for (in) |c| {
                try request.append(c);
                if (c == '\n') break;
            }

            gather_context(&context);

            for (context) |c| {
                try request.append(c);
                if (c == 0) break;
            }
        }

        // var thread = try std.Thread.spawn(.{}, waitingAnimation, .{});

        // std.log.info("INPUT: {s}", .{request.items});

        var res = try llm_client.startStreamingResponse(allocator, stdout, request.items);
        defer allocator.free(res);
        add_context(&in, res);

        var it = std.mem.tokenizeSequence(u8, res, "\n");
        while (it.next()) |line| {
            if (line[0] == '`') continue;
            try argv.writer().print("{s}\n", .{line});
        }

        // should_stop.store(true, std.atomic.Ordering.SeqCst);
        // thread.join();

        make_file(argv.items) catch |err| {
            try stdout.print("Error Creating File: {}\n", .{err});
        };

        run_sh() catch |err| {
            try stdout.print("Error Running Program: {}\n", .{err});
        };

        firstCommand = false;
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

    for (1..context_cnt + 1) |i| {
        // printing numbered past responses
        // context[src] = @as(u8, @truncate(i)) + '0';
        // context[src + 1] = ' ';
        // src += 2;
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

fn add_context(in: *[4096]u8, res: []const u8) void {
    var src: u32 = 0;
    for ("You: ") |c| {
        contexts[c_index][src] = c;
        src += 1;
    }
    for (in) |c| {
        contexts[c_index][src] = c;
        src += 1;
        if (c == '\n') break;
    }
    for ("User: ") |c| {
        contexts[c_index][src] = c;
        src += 1;
    }
    for (res) |c| {
        contexts[c_index][src] = c;
        src += 1;
    }
    //increment the index and add null terminator to the context
    c_index = (c_index + 1) % 10;
    contexts[c_index][src] = 0;
    max_contexts += 1;
}

fn parse_response(in: *[4096]u8) !?[]const u8 {
    var src: u32 = 0;
    var dst: u32 = 0;
    var cflag: bool = false;
    var vflag: bool = false;
    while (in[src] == ' ') {
        src += 1;
    }
    while (in[src] != '\n') {
        if (in[src] == '-') {
            if (src + 2 >= 4096) {
                return "buffer overflow";
            }
            if (!cflag and in[src + 1] == 'c' and (in[src + 2] == ' ' or in[src + 2] == '\n')) {
                src += 2;
                context_cnt += 1;
                while (in[src] == ' ') {
                    src += 1;
                }
                cflag = true;
            } else if (!cflag and in[src + 1] == 'c' and (in[src + 2] >= '0' and in[src + 2] <= '9') and (in[src + 3] == ' ' or in[src + 3] == '\n')) {
                var num: u8 = in[src + 2] - '0';
                context_cnt = @min(num, max_contexts);
                src += 3;
                while (in[src] == ' ') {
                    src += 1;
                }
                cflag = true;
            } else if (!vflag and in[src + 1] == 'v' and (in[src + 2] == ' ' or in[src + 2] == '\n')) {
                src += 2;
                verbose = !verbose;
                while (in[src] == ' ') {
                    src += 1;
                }
                vflag = true;
            } else if (in[src + 1] == 'h' and (in[src + 2] == ' ' or in[src + 2] == '\n')) {
                src += 2;
                try stdout.print("Flags:\n", .{});
                try stdout.print("    -c<number: N> - queries LLM with the last N exchanges as additional context. Enter no number to continue with messages before.\n", .{});
                try stdout.print("    -v - query responses will be more verbose and will come with an explanation in addition to shell code.\n", .{});
                try stdout.print("All flags must be placed before natural language queries.\n", .{});
            } else {
                return "invalid flag";
            }
        } else {
            in[dst] = in[src];
            dst += 1;
            src += 1;
            if (!cflag) {
                context_cnt = 0;
            }
            cflag = true;
            vflag = true;
        }
    }
    in[dst] = '\n';
    return null;
}

fn make_file(argv: []u8) !void {
    var file = try std.fs.cwd().createFile("bash.sh", .{});
    defer file.close();
    try file.writeAll(argv);
    var it = std.mem.tokenizeSequence(u8, argv, "\n");
    if (verbose) {
        try stdout.print("\n\x1b[38;5;216m╭─\x1b[38;5;160m\x1b[3m\x1b[48;5;224m bash.sh \x1b[0m\x1b[38;5;216m ────────────────────────────────────────────────────────────────────╮\n>\x1b[0m", .{});
        while (it.next()) |line| {
            try stdout.print("\n\x1b[38;5;216m>\x1b[0m {s}", .{line});
        }
        try stdout.print("\n\x1b[38;5;216m>\n╰───────────────────────────────────────────────────────────────────────────────╯\x1b[0m\n", .{});
    }
}

fn run_sh() !void {
    var in: [4096]u8 = undefined;

    // ask for approval
    try stdout.print("⚠️  \x1b[1m\x1b[38;5;214mrun bash.sh?\x1b[0m ⚠️  (\x1b[1;32my\x1b[0m/\x1b[1;31mn\x1b[0m): ", .{});
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
    try stdout.print("\n{s}", .{proc.stdout});
    if (proc.stderr.len > 0) {
        try stdout.print("\x1B[38;5;124m\x1B[1mError while running: {s} \x1B[0m", .{proc.stderr});
    } else {
        try stdout.print("\x1B[38;5;46m\x1B[1mProgram ran successfully \n\x1B[0m", .{});
    }
}

pub fn main() !void {
    std.debug.print("\x1B[2J\x1B[H", .{});
    std.debug.print("{s}", .{asciiArt});
    // try openai_agent.processCommandUsingAgent();
    try processCommand();
}
