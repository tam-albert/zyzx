const std = @import("std");
const config = @import("config.zig");
const llms = @import("llm_client.zig");
const openai_prompts = @import("openai_prompts.zig");
const openai_agent = @import("openai_agent.zig");

pub const Message = struct {
    role: []const u8,
    content: []const u8,
};

const OpenAIRequestBody = struct {
    model: []const u8,
    messages: []const Message,
    stream: ?bool = false,
};

const OpenAIResponseMessage = struct {
    index: u8,
    message: Message,
    logprobs: ?[]const u8,
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

const OpenAIStreamingResponseDelta = struct {
    role: ?[]const u8 = "",
    content: ?[]const u8 = "",
};

const OpenAIStreamingResponseChoice = struct {
    index: u8,
    delta: OpenAIStreamingResponseDelta,
    logprobs: ?[]const u8,
    finish_reason: ?[]const u8,
};

const OpenAIStreamingResponseBody = struct {
    id: []const u8,
    object: []const u8,
    created: u64,
    model: []const u8,
    system_fingerprint: []const u8,
    choices: []const OpenAIStreamingResponseChoice,
};

const MixtralResponseBody = struct {
    data: []const u8,
};

pub fn sendOpenAIStreamingRequest(allocator: std.mem.Allocator, writer: anytype, messageHistory: []const Message) ![]const u8 {
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    const uri = try std.Uri.parse(config.OPENAI_DOMAIN);

    const requestBody = OpenAIRequestBody{
        .model = "gpt-3.5-turbo",
        .messages = messageHistory,
        .stream = true,
    };

    var headers = std.http.Headers{ .allocator = allocator };
    defer headers.deinit();

    try headers.append("Content-Type", "application/json");
    try headers.append("Authorization", "Bearer " ++ config.API_KEY);
    try headers.append("Accept", "text/event-stream");

    var request = try client.request(.POST, uri, headers, .{});
    defer request.deinit();
    request.transfer_encoding = .chunked;

    try request.start();
    try std.json.stringify(requestBody, .{}, request.writer());
    try request.finish();
    try request.wait();

    var final_response = std.ArrayList(u8).init(allocator);
    defer final_response.deinit();

    while (true) {
        var buffer: [10240]u8 = undefined;
        const bytes_read = try request.read(buffer[0..]);
        if (bytes_read == 0) break;

        var event_start: usize = 0;

        // std.debug.print("RECEIVED CHUNK\n---\n{s}\n---\n", .{buffer[0..bytes_read]});
        while (event_start < bytes_read) {
            const chunk = buffer[event_start..bytes_read];
            if (std.mem.eql(u8, chunk, "data: [DONE]\n\n")) {
                break;
            }

            const start = std.mem.indexOf(u8, chunk, "data: ");
            if (start) |idx| {
                const event_data_start = event_start + idx + "data: ".len;
                const event_end = (std.mem.indexOf(u8, chunk, "\n\n") orelse break) + event_start;

                if (event_data_start < event_end) {
                    const event_data = buffer[event_data_start..event_end];
                    // std.debug.print("Parsing JSON: {s}\n\n", .{event_data});

                    const parsed_json = try std.json.parseFromSlice(OpenAIStreamingResponseBody, allocator, event_data, .{});
                    defer parsed_json.deinit();

                    const response_chunk = parsed_json.value.choices[0].delta.content orelse "";
                    try writer.writeAll(response_chunk);
                    try final_response.appendSlice(response_chunk);
                    // std.debug.print("Chunk {d}: {s}\n", .{ i, response_chunk });

                    event_start = event_end + "\n\n".len;
                } else {
                    break;
                }
            } else {
                break;
            }
        }
    }

    return final_response.toOwnedSlice();
}

pub fn sendOpenaiRequest(allocator: std.mem.Allocator, messageHistory: []const Message) ![]const u8 {
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    const uri = std.Uri.parse(config.OPENAI_DOMAIN) catch unreachable;

    const requestBody = OpenAIRequestBody{
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

    // std.debug.print("response: {s}\n", .{body.items});

    const parsed_json = try std.json.parseFromSlice(OpenAIResponseBody, allocator, body.items, .{});
    defer parsed_json.deinit();

    const response_body = parsed_json.value;

    return allocator.dupe(u8, response_body.choices[0].message.content);
}

pub fn sendMixtralRequest(allocator: std.mem.Allocator, messageHistory: []const Message) ![]const u8 {
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    const uri = std.Uri.parse(config.DOMAIN) catch unreachable;

    const requestBody = OpenAIRequestBody{
        .model = "gpt-3.5-turbo",
        .messages = messageHistory,
    };

    var headers = std.http.Headers{ .allocator = allocator };
    defer headers.deinit();

    try headers.append("Content-Type", "application/json");

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

    // std.debug.print("response: {s}\n", .{body.items});

    const parsed_json = try std.json.parseFromSlice(MixtralResponseBody, allocator, body.items, .{});
    defer parsed_json.deinit();

    const response_body = parsed_json.value;

    return allocator.dupe(u8, response_body.data);
}

pub fn startMixtralResponse(allocator: std.mem.Allocator, userMessage: []u8) ![]const u8 {
    const userMessage2 = llms.Message{
        .role = "user",
        .content = userMessage,
    };

    const messageHistory = [_]llms.Message{
        userMessage2,
    };

    const response = try llms.sendMixtralRequest(allocator, &messageHistory);
    defer allocator.free(response);

    return allocator.dupe(u8, response);
}

pub fn startStreamingResponse(allocator: std.mem.Allocator, writer: anytype, userMessage: []u8) ![]const u8 {
    const userMessage2 = llms.Message{
        .role = "user",
        .content = userMessage,
    };

    const messageHistory = [_]llms.Message{
        openai_prompts.SYSTEM_PROMPT,
        openai_prompts.PROMPT_EXAMPLES,
        userMessage2,
    };

    const response = try llms.sendOpenAIStreamingRequest(allocator, writer, &messageHistory);
    defer allocator.free(response);

    return allocator.dupe(u8, response);
}

pub fn strip_response(allocator: std.mem.Allocator, userMessage: []u8) ![]const u8 {
    // var res = try sendRequest(allocator, userMessage);
    const userMessage2 = llms.Message{
        .role = "user",
        .content = userMessage,
    };

    const messageHistory = [_]llms.Message{
        openai_prompts.SYSTEM_PROMPT,
        userMessage2,
    };
    var res = try llms.sendOpenaiRequest(allocator, &messageHistory);
    defer allocator.free(res);
    // std.log.info("{s}", .{res});
    return allocator.dupe(u8, res);
}
