const std = @import("std");
const config = @import("config.zig");

// const request_uri = "https://godsays.xyz/";

const Message = struct {
    role: []const u8,
    content: []const u8,
};

const RequestBody = struct {
    model: []const u8,
    messages: []const Message,
};

const system_message = Message{
    .role = "system",
    .content = "You are a helpful assistant.",
};

pub fn sendRequest(allocator: std.mem.Allocator, userMessage: []u8) ![]const u8 {
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    const uri = std.Uri.parse(config.DOMAIN) catch unreachable;
    // const uri = std.Uri.parse("http://127.0.0.1:5000") catch unreachable;

    const messages = [_]Message{
        system_message,
        .{ .role = "user", .content = userMessage },
    };

    const requestBody = RequestBody{
        .model = "gpt-3.5-turbo",
        .messages = &messages,
    };

    // var buf: [16384]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buf);
    // const fba_allocator = fba.allocator();
    // const jsonString = try std.json.stringifyAlloc(fba_allocator, requestBody, .{});
    // defer fba_allocator.free(jsonString);

    // std.debug.print("Serialized JSON: {s}\n", .{jsonString});

    var headers = std.http.Headers{ .allocator = allocator };
    defer headers.deinit();

    try headers.append("Content-Type", "application/json");
    try headers.append("Authorization", "Bearer " ++ config.API_KEY);

    var request = try client.request(.POST, uri, headers, .{});
    defer request.deinit();
    request.transfer_encoding = .chunked;

    try request.start();
    try std.json.stringify(requestBody, .{}, request.writer());
    // std.debug.print("Serialized JSON: {s}\n", .{request.writer().buffer});
    try request.finish();
    try request.wait();

    const body = request.reader().readAllAlloc(allocator, 16384) catch unreachable;
    defer allocator.free(body);

    return allocator.dupe(u8, body);

    // std.log.info("response: {s}", .{body});
}

pub fn strip_response(allocator: std.mem.Allocator, userMessage: []u8) ![]const u8 {
    var res = try sendRequest(allocator, userMessage);
    defer allocator.free(res);
    // for (res) |c| {
    //     std.log.info("{c}", .{c});
    // }
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
