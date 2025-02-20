const std = @import("std");

const Snip = struct { in_path: []const u8, out_path: []const u8, title: []const u8, prefix: []const u8, description: []const u8 };

pub fn main() !void {
    std.debug.print("Generating snippets...\n", .{});

    // Arena Memory Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var dir_vs = try std.fs.cwd().openDir("../vscode", .{});
    defer dir_vs.close();

    var dir_www = try std.fs.cwd().openDir("../www", .{});
    defer dir_www.close();

    const html_snip = Snip{
        .in_path = "index.html",
        .out_path = "html.json",
        .title = "New+ HTML",
        .prefix = "!!",
        .description = "New & Improved HTML File.",
    };

    const css_snip = Snip{
        .in_path = "style.css",
        .out_path = "css.json",
        .title = "New+ CSS",
        .prefix = "!!",
        .description = "New & Improved CSS File.",
    };

    const js_snip = Snip{
        .in_path = "module.js",
        .out_path = "javascript.json",
        .title = "New+ JS",
        .prefix = "!!",
        .description = "New & Improved JS File.",
    };

    const snips = [_]Snip{ html_snip, css_snip, js_snip };

    var list = std.ArrayList(u8).init(alloc);
    defer list.deinit();

    for (snips) |snip| {

        // read file
        std.debug.print("Reading {s}\n", .{snip.in_path});
        const bytes = try dir_www.readFileAlloc(alloc, snip.in_path, 4096);
        // defer alloc.free(bytes);

        // Start Snippet
        try list.appendSlice("{\n\t\"");
        try list.appendSlice(snip.title);
        try list.appendSlice("\": {\n\t\t\"prefix\": \"");
        try list.appendSlice(snip.prefix);
        try list.appendSlice("\",\n\t\t\"body\": [\n");

        // Parsing Body
        var line_iter = std.mem.tokenizeAny(u8, bytes, "\r\n");
        while (line_iter.next()) |line| {
            std.debug.print("line: {s}\n", .{line});
            try list.append('\t');
            try list.append('\t');
            try list.append('\t');
            try list.append('"');

            // escape line for json string
            if (std.mem.indexOfScalarPos(u8, line, 0, '"')) |_| {
                // escape line for json string
                var q_iter = std.mem.tokenizeScalar(u8, line, '"');
                while (q_iter.next()) |chunk| {
                    try list.appendSlice(chunk);
                    try list.append('\\');
                    try list.append('"');
                }
                _ = list.pop();
                _ = list.pop();
            } else {
                try list.appendSlice(line);
            }

            try list.append('"');
            try list.append(',');
            try list.append('\n');
        }
        _ = list.pop();
        _ = list.pop();
        try list.append('\n');
        // Body Parsed

        // End Snippet
        try list.appendSlice("\t\t],\n\t\t\"description\": \"");
        try list.appendSlice(snip.description);
        try list.appendSlice("\"\n\t}\n}\n");

        // write snippet
        try dir_vs.writeFile(.{
            .sub_path = snip.out_path,
            .data = list.items,
        });

        // reset list
        // std.debug.print("pre list len: {d}\n", .{list.items.len});
        while (list.pop()) |_| {}
        // std.debug.print("post list len: {d}\n", .{list.items.len});
    }
}

//#region tests

const assert = std.testing.expectEqual;

test "simple test" {
    try assert(@intFromFloat(42.0), 42);
}

//#endregion
