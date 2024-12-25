const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Heights = [5]usize;
const HeightsList = std.ArrayList(Heights);

fn parse_input(raw: []const u8) !struct { locks: HeightsList, keys: HeightsList } {
    var locks = HeightsList.init(allocator);
    errdefer locks.deinit();

    var keys = HeightsList.init(allocator);
    errdefer keys.deinit();

    var block_it = std.mem.splitSequence(u8, raw, "\n\n");
    while (block_it.next()) |block| {
        var heights: Heights = undefined;
        if (block[0] == '#') {
            outer: for (0..5) |x| {
                for (1..7) |y| {
                    if (block[y * 6 + x] != '#') {
                        heights[x] = y - 1;
                        continue :outer;
                    }
                }
            }
            try locks.append(heights);
        } else {
            outer: for (0..5) |x| {
                for (1..7) |y| {
                    if (block[y * 6 + x] == '#') {
                        heights[x] = 7 - (y + 1);
                        continue :outer;
                    }
                }
            }
            try keys.append(heights);
        }
    }

    return .{
        .locks = locks,
        .keys = keys,
    };
}

fn solve(locks: HeightsList, keys: HeightsList) usize {
    var res: usize = 0;
    for (locks.items) |lock| {
        outer: for (keys.items) |key| {
            for (0..5) |i| {
                if (lock[i] + key[i] > 5) continue :outer;
            }
            res += 1;
        }
    }
    return res;
}

pub fn main() !void {
    var input = try parse_input(@embedFile("input"));
    var example = try parse_input(@embedFile("example"));
    defer input.locks.deinit();
    defer input.keys.deinit();
    defer example.locks.deinit();
    defer example.keys.deinit();

    std.debug.print("Answer to part 1 (example): {}\n", .{solve(example.locks, example.keys)});
    std.debug.print("Answer to part 1: {}\n", .{solve(input.locks, input.keys)});
    std.debug.print("\n", .{});
}
