const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();

const Stones = struct {
    list: std.ArrayList(usize),

    fn init(raw: []const u8) !Stones {
        var stones = Stones{
            .list = std.ArrayList(usize).init(allocator),
        };
        var it = std.mem.splitAny(u8, raw[0 .. raw.len - 1], " ");
        while (it.next()) |num_s| {
            const num = std.fmt.parseInt(usize, num_s, 10) catch break;
            try stones.list.append(num);
        }
        return stones;
    }

    fn deinit(self: *Stones) void {
        self.list.deinit();
    }

    fn blink(self: *Stones, num: usize) !usize {
        var res: usize = 0;
        for (self.list.items) |stone| {
            res += try blink_stone(stone, num);
        }
        return res;
    }
};

var cache = std.AutoHashMap(std.meta.Tuple(&.{ usize, usize }), usize).init(allocator);

fn blink_stone(stone: usize, num: usize) !usize {
    const entry = .{ stone, num };
    if (cache.contains(entry)) return cache.get(entry).?;
    var res: usize = 0;
    if (num == 0) {
        res = 1;
    } else if (stone == 0) {
        res = try blink_stone(1, num - 1);
    } else {
        const digits = std.math.log10(stone) + 1;
        if (digits % 2 == 1) {
            res = try blink_stone(stone * 2024, num - 1);
        } else {
            const mask = std.math.pow(usize, 10, digits / 2);
            res = try blink_stone(stone % mask, num - 1) +
                try blink_stone((stone / mask) % mask, num - 1);
        }
    }
    try cache.put(entry, res);
    return res;
}

pub fn main() !void {
    defer cache.deinit();

    var input = try Stones.init(@embedFile("input"));
    var example = try Stones.init(@embedFile("example"));
    defer input.deinit();
    defer example.deinit();

    std.debug.print("Answer to part 1 (example): {}\n", .{try example.blink(25)});
    std.debug.print("Answer to part 2 (example): {}\n", .{try example.blink(75)});

    std.debug.print("Answer to part 1: {}\n", .{try input.blink(25)});
    std.debug.print("Answer to part 2: {}\n", .{try input.blink(75)});
}
