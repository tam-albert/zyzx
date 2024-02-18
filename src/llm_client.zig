const std = @import("std");
const config = @import("config.zig");

// const request_uri = "https://godsays.xyz/";

const Message = struct {
    role: []const u8,
    content: []const u8,
};

const RequestBody = struct {
    messages: []const Message,
};

const system_message = Message{
    .role = "system",
    .content = "You are a helpful assistant.",
};

const ResponseBody = struct {
    chunk: []const u8,
    time: []const u8,
};

pub fn sendRequest(allocator: std.mem.Allocator, userMessage: []u8) ![]const u8 {
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    const uri = std.Uri.parse(config.DOMAIN) catch unreachable;

    const messages = [_]Message{
        system_message,
        .{ .role = "user", .content = userMessage },
    };

    const request_body = RequestBody{
        .messages = &messages,
    };

    var headers = std.http.Headers{ .allocator = allocator };
    defer headers.deinit();

    // try headers.append("Content-Type", "application/json");
    try headers.append("Accept", "text/event-stream");
    // try headers.append("Authorization", "Bearer " ++ config.API_KEY);

    var request = try client.request(.GET, uri, headers, .{});
    defer request.deinit();
    request.transfer_encoding = .chunked;

    try request.start();
    try std.json.stringify(request_body, .{}, request.writer());
    try request.finish();
    try request.wait();

    var final_response = std.ArrayList(u8).init(allocator);
    defer final_response.deinit();

    while (true) {
        var buffer: [1024]u8 = undefined;
        const bytes_read = try request.read(buffer[0..]);
        if (bytes_read == 0) break; // End of stream

        const event = buffer[0..bytes_read];
        std.debug.print("Received event: {s}\n", .{event});
        try final_response.appendSlice(event);
    }

    return try final_response.toOwnedSlice();

    // const body = request.reader().readAllAlloc(allocator, 16384) catch unreachable;
    // defer allocator.free(body);

    // // std.debug.print("response: {s}\n", .{body});

    // const parsed_json = std.json.parseFromSlice(ResponseBody, allocator, body, .{}) catch unreachable;
    // defer parsed_json.deinit();

    // const response_body = parsed_json.value;

    // return allocator.dupe(u8, response_body.choices[0].message.content);
}

pub fn strip_response(allocator: std.mem.Allocator, userMessage: []u8) ![]const u8 {
    var res = try sendRequest(allocator, userMessage);
    defer allocator.free(res);

    // we need to process res so it doesn't include the "data: " events from SSE
    // and the newlines between separate events

    // Process the accumulated data to strip "data: " and newlines
    var processedEvents = std.ArrayList(u8).init(allocator);
    defer processedEvents.deinit();

    var i: usize = 0;
    while (i < res.len) {
        // Find the start of the next event data
        const start = std.mem.indexOf(u8, res[i..], "data: ");
        if (start) |idx| {
            i += idx + "data: ".len; // Skip "data: "

            // Find the end of the current event data (marked by "\n\n")
            const end = std.mem.indexOf(u8, res[i..], "\n\n") orelse break;
            try processedEvents.appendSlice(res[i .. i + end]);
            i += end + "\n\n".len; // Move past the current event
        } else {
            break; // No more events
        }
    }

    std.log.info("response: {s}", .{processedEvents.items});
    const CMD = "echo \"Hello, World!\"";
    return CMD;
}

// pub fn sendGetRequest(allocator: std.mem.Allocator) !void {
//     var client = std.http.Client{ .allocator = allocator };
//     defer client.deinit();

//     const uri = std.Uri.parse("https://godsays.xyz/") catch unreachable;

//     var headers = std.http.Headers{ .allocator = allocator };
//     defer headers.deinit();

//     try headers.append("Accept", "*/*");

//     var request = try client.request(.GET, uri, headers, .{});
//     defer request.deinit();

//     try request.start();
//     try request.finish();

//     try request.wait();

//     const body = request.reader().readAllAlloc(allocator, 32768) catch unreachable;
//     defer allocator.free(body);

//     std.log.info("response: {s}", .{body});
// }
