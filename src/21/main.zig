const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Code = struct {
    numeric: usize,
    digits: []const u8,
};
const CodeList = std.ArrayList(Code);

const Pos = struct {
    x: i32,
    y: i32,

    fn eql(self: Pos, other: Pos) bool {
        return self.x == other.x and self.y == other.y;
    }
};

const KeyPad = std.StaticStringMap(Pos);
const numpad = KeyPad.initComptime(.{
    .{ "F", .{ .x = 0, .y = 3 } },
    .{ "0", .{ .x = 1, .y = 3 } },
    .{ "A", .{ .x = 2, .y = 3 } },
    .{ "1", .{ .x = 0, .y = 2 } },
    .{ "2", .{ .x = 1, .y = 2 } },
    .{ "3", .{ .x = 2, .y = 2 } },
    .{ "4", .{ .x = 0, .y = 1 } },
    .{ "5", .{ .x = 1, .y = 1 } },
    .{ "6", .{ .x = 2, .y = 1 } },
    .{ "7", .{ .x = 0, .y = 0 } },
    .{ "8", .{ .x = 1, .y = 0 } },
    .{ "9", .{ .x = 2, .y = 0 } },
});
const dirpad = KeyPad.initComptime(.{
    .{ "F", .{ .x = 0, .y = 0 } },
    .{ "^", .{ .x = 1, .y = 0 } },
    .{ "v", .{ .x = 1, .y = 1 } },
    .{ "<", .{ .x = 0, .y = 1 } },
    .{ ">", .{ .x = 2, .y = 1 } },
    .{ "A", .{ .x = 2, .y = 0 } },
});

fn btn_sequence(keypad: KeyPad, cur_pos: Pos, next_pos: Pos) ![]const u8 {
    var sequence = std.ArrayList([]const u8).init(allocator);
    defer sequence.deinit();

    const forbidden = keypad.get("F").?;
    if (cur_pos.x - next_pos.x < 0) {
        ver_first(&sequence, cur_pos, next_pos, forbidden) catch {
            try hor_first(&sequence, cur_pos, next_pos, forbidden);
        };
    } else {
        hor_first(&sequence, cur_pos, next_pos, forbidden) catch {
            try ver_first(&sequence, cur_pos, next_pos, forbidden);
        };
    }
    try sequence.append("A");

    var res = try allocator.alloc(u8, sequence.items.len);
    for (sequence.items, 0..) |btn, i| {
        res[i] = btn[0];
    }

    return res;
}

fn hor_first(sequence: *std.ArrayList([]const u8), cur_pos: Pos, next_pos: Pos, forbidden: Pos) !void {
    var pos = cur_pos;
    try walk_hor(sequence, &pos, next_pos, forbidden);
    try walk_ver(sequence, &pos, next_pos, forbidden);
}

fn ver_first(sequence: *std.ArrayList([]const u8), cur_pos: Pos, next_pos: Pos, forbidden: Pos) !void {
    var pos = cur_pos;
    try walk_ver(sequence, &pos, next_pos, forbidden);
    try walk_hor(sequence, &pos, next_pos, forbidden);
}

fn walk_hor(sequence: *std.ArrayList([]const u8), cur_pos: *Pos, next_pos: Pos, forbidden: Pos) !void {
    errdefer sequence.clearAndFree();
    var dx: i32 = cur_pos.x - next_pos.x;
    while (dx != 0) {
        if (dx < 0) {
            cur_pos.x += 1;
            try sequence.append(">");
        } else {
            cur_pos.x -= 1;
            try sequence.append("<");
        }
        dx = cur_pos.x - next_pos.x;
        if (cur_pos.eql(forbidden)) return error.ForbiddenPos;
    }
}

fn walk_ver(sequence: *std.ArrayList([]const u8), cur_pos: *Pos, next_pos: Pos, forbidden: Pos) !void {
    errdefer sequence.clearAndFree();
    var dy: i32 = cur_pos.y - next_pos.y;
    while (dy != 0) {
        if (dy < 0) {
            cur_pos.y += 1;
            try sequence.append("v");
        } else {
            cur_pos.y -= 1;
            try sequence.append("^");
        }
        dy = cur_pos.y - next_pos.y;
        if (cur_pos.eql(forbidden)) return error.ForbiddenPos;
    }
}

fn parse_input(raw: []const u8) !CodeList {
    var list = CodeList.init(allocator);
    errdefer list.deinit();

    var line_it = std.mem.splitAny(u8, raw, "\n");
    while (line_it.next()) |line| {
        if (line.len == 0) continue;
        try list.append(Code{
            .numeric = try std.fmt.parseInt(usize, line[0..3], 10),
            .digits = line,
        });
    }

    return list;
}

const CacheLayer = std.StringHashMap(usize);
const Cache = std.AutoHashMap(usize, CacheLayer);
var cache = Cache.init(allocator);

fn recurse(sequence: []const u8, depth: usize) !usize {
    if (cache.get(depth)) |layer| {
        if (layer.get(sequence)) |res| return res;
    } else {
        try cache.put(depth, CacheLayer.init(allocator));
    }

    if (depth == 0) return sequence.len;

    var res: usize = 0;

    const activate_pos = dirpad.get("A").?;
    var cur_pos = activate_pos;
    for (0..sequence.len) |i| {
        const next_pos = dirpad.get(sequence[i .. i + 1]).?;
        const new_seq = try btn_sequence(dirpad, cur_pos, next_pos);
        cur_pos = next_pos;
        res += try recurse(new_seq, depth - 1);
    }

    try cache.getPtr(depth).?.put(sequence, res);

    return res;
}

fn press(code: Code, num_robots: usize) !usize {
    var res: usize = 0;
    const activate_pos = numpad.get("A").?;
    var cur_pos = activate_pos;
    for (0..code.digits.len) |i| {
        const next_pos = numpad.get(code.digits[i .. i + 1]).?;
        const sequence = try btn_sequence(numpad, cur_pos, next_pos);
        res += try recurse(sequence, num_robots);
        cur_pos = next_pos;
    }
    return res;
}

fn solve(list: CodeList, num_robots: usize) !usize {
    var res: usize = 0;
    for (list.items) |code| {
        const presses = try press(code, num_robots);
        res += presses * code.numeric;
    }
    return res;
}

pub fn main() !void {
    defer cache.deinit();

    var input = try parse_input(@embedFile("input"));
    var example = try parse_input(@embedFile("example"));
    defer input.deinit();
    defer example.deinit();

    std.debug.print("Answer to part 1 (example): {}\n", .{try solve(example, 2)});
    std.debug.print("Answer to part 2 (example): {}\n", .{try solve(example, 25)});
    std.debug.print("\n", .{});

    std.debug.print("Answer to part 1: {}\n", .{try solve(input, 2)});
    std.debug.print("Answer to part 2: {}\n", .{try solve(input, 25)});
}
