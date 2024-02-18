const std = @import("std");
const config = @import("config.zig");

pub const Message = struct {
    role: []const u8,
    content: []const u8,
};

const RequestBody = struct {
    model: []const u8,
    messages: []const Message,
};

const OpenAIResponseMessage = struct {
    index: u8,
    message: Message,
    logprobs: ?[]const u8 = null,
    finish_reason: []const u8,
};

const OpenAIUsageData = struct { prompt_tokens: u64, completion_tokens: u64, total_tokens: u64 };

const OpenAIResponseBody = struct {
    id: []const u8,
    object: []const u8,
    created: u64,
    model: []const u8,
    choices: []const OpenAIResponseMessage,
    usage: OpenAIUsageData,
    system_fingerprint: []const u8,
};

const system_message = Message{
    .role = "system",
    .content = "You are a helpful assistant.",
};

pub fn sendOpenaiRequest(allocator: std.mem.Allocator, messageHistory: []const Message) ![]const u8 {
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    const uri = std.Uri.parse(config.OPENAI_DOMAIN) catch unreachable;

    const requestBody = RequestBody{
        .model = "gpt-3.5-turbo",
        .messages = messageHistory,
    };

    var headers = std.http.Headers{ .allocator = allocator };
    defer headers.deinit();

    try headers.append("Content-Type", "application/json");
    try headers.append("Authorization", "Bearer " ++ config.API_KEY);

    var request = try client.request(.POST, uri, headers, .{});
    defer request.deinit();
    request.transfer_encoding = .chunked;

    try request.start();
    try std.json.stringify(requestBody, .{}, request.writer());

    try request.finish();
    try request.wait();

    var body = std.ArrayList(u8).init(allocator);
    defer body.deinit();
    try request.reader().readAllArrayList(&body, 40960);

    // std.debug.print("response: {s}\n", .{body});

    const parsed_json = try std.json.parseFromSlice(OpenAIResponseBody, allocator, body.items, .{});
    defer parsed_json.deinit();

    const response_body = parsed_json.value;

    return allocator.dupe(u8, response_body.choices[0].message.content);
}

pub fn sendRequest(allocator: std.mem.Allocator, userMessage: []u8) ![]const u8 {
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    const uri = std.Uri.parse(config.OPENAI_DOMAIN) catch unreachable;
    // const uri = std.Uri.parse("http://127.0.0.1:5000") catch unreachable;

    const messages = [_]Message{
        system_message,
        .{ .role = "user", .content = userMessage },
    };

    const requestBody = RequestBody{
        .model = "gpt-3.5-turbo",
        .messages = &messages,
    };

    var headers = std.http.Headers{ .allocator = allocator };
    defer headers.deinit();

    try headers.append("Content-Type", "application/json");
    try headers.append("Authorization", "Bearer " ++ config.API_KEY);

    var request = try client.request(.POST, uri, headers, .{});
    defer request.deinit();
    request.transfer_encoding = .chunked;

    try request.start();
    try std.json.stringify(requestBody, .{}, request.writer());

    try request.finish();
    try request.wait();

    const body = request.reader().readAllAlloc(allocator, 40960) catch unreachable;
    defer allocator.free(body);

    // std.debug.print("response: {s}\n", .{body});

    const parsed_json = std.json.parseFromSlice(OpenAIResponseBody, allocator, body, .{}) catch unreachable;
    defer parsed_json.deinit();

    const response_body = parsed_json.value;

    return allocator.dupe(u8, response_body.choices[0].message.content);
}

pub fn strip_response(allocator: std.mem.Allocator, userMessage: []u8) ![]const u8 {
    var res = try sendRequest(allocator, userMessage);
    defer allocator.free(res);
    std.log.info("{s}", .{res});
    // const CMD = "echo \"HELLO WORLD\"";
    // return CMD;
    return allocator.dupe(u8, res);
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
