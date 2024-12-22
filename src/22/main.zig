const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Number = i64;
const NumberList = std.ArrayList(Number);
const Sequence = [4]Number;
const SequenceSet = std.AutoHashMap(Sequence, void);
const SequenceMap = std.AutoHashMap(Sequence, Number);

fn parse_input(raw: []const u8) !NumberList {
    var numbers = NumberList.init(allocator);
    errdefer numbers.deinit();

    var line_it = std.mem.splitAny(u8, raw, "\n");
    while (line_it.next()) |line| {
        if (line.len == 0) continue;
        try numbers.append(try std.fmt.parseInt(Number, line, 10));
    }

    return numbers;
}

fn mix(num1: Number, num2: Number) Number {
    return num1 ^ num2;
}

fn prune(num: Number) Number {
    return @mod(num, 16777216);
}

fn secret(num: Number) Number {
    var res = num;
    res = prune(mix(res * 64, res));
    res = prune(mix(@divFloor(res, 32), res));
    res = prune(mix(res * 2048, res));
    return res;
}

fn solve_part1(numbers: NumberList) Number {
    var res: Number = 0;
    for (numbers.items) |num| {
        var new = num;
        for (0..2000) |_| {
            new = secret(new);
        }
        res += new;
    }
    return res;
}

fn solve_part2(numbers: NumberList) !Number {
    var map = SequenceMap.init(allocator);
    defer map.deinit();

    var known = SequenceSet.init(allocator);
    defer known.deinit();

    for (numbers.items) |num| {
        known.clearAndFree();
        var new = num;
        var sequence: Sequence = undefined;
        for (0..2000) |i| {
            const prev = @mod(new, 10);
            new = secret(new);
            const price = @mod(new, 10);
            sequence[0] = sequence[1];
            sequence[1] = sequence[2];
            sequence[2] = sequence[3];
            sequence[3] = price - prev;
            if (i >= 3) {
                if (!known.contains(sequence)) {
                    try map.put(sequence, (map.get(sequence) orelse 0) + price);
                    try known.put(sequence, {});
                }
            }
        }
    }

    var it = map.iterator();
    var max_sequence: Sequence = undefined;
    var max_price: Number = 0;
    while (it.next()) |pair| {
        const sequence = pair.key_ptr.*;
        const price = pair.value_ptr.*;
        if (price > max_price) {
            max_sequence = sequence;
            max_price = price;
        }
    }

    return max_price;
}

pub fn main() !void {
    var input = try parse_input(@embedFile("input"));
    var example1 = try parse_input(@embedFile("example1"));
    var example2 = try parse_input(@embedFile("example2"));
    defer input.deinit();
    defer example1.deinit();
    defer example2.deinit();

    std.debug.print("Answer to part 1 (example): {}\n", .{solve_part1(example1)});
    std.debug.print("Answer to part 2 (example): {}\n", .{try solve_part2(example2)});
    std.debug.print("\n", .{});

    std.debug.print("Answer to part 1: {}\n", .{solve_part1(input)});
    std.debug.print("Answer to part 2: {}\n", .{try solve_part2(input)});
}
