const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Wire = enum {
    ZERO,
    ONE,
    UNKNOWN,

    fn from_char(c: u8) Wire {
        return switch (c) {
            '0' => .ZERO,
            '1' => .ONE,
            else => unreachable,
        };
    }

    fn to_num(self: Wire) usize {
        return switch (self) {
            .ZERO => 0,
            .ONE => 1,
            .UNKNOWN => unreachable,
        };
    }

    fn and_gate(a: Wire, b: Wire) Wire {
        if (a == .ONE and b == .ONE) return .ONE;
        return .ZERO;
    }

    fn or_gate(a: Wire, b: Wire) Wire {
        if (a == .ONE or b == .ONE) return .ONE;
        return .ZERO;
    }

    fn xor_gate(a: Wire, b: Wire) Wire {
        if ((a == .ZERO and b == .ONE) or
            (a == .ONE and b == .ZERO)) return .ONE;
        return .ZERO;
    }
};

const Gate = enum {
    AND,
    OR,
    XOR,

    fn from_str(s: []const u8) Gate {
        return switch (s[0]) {
            'A' => .AND,
            'O' => .OR,
            'X' => .XOR,
            else => unreachable,
        };
    }

    fn run(self: Gate, a: Wire, b: Wire) Wire {
        return switch (self) {
            .AND => a.and_gate(b),
            .OR => a.or_gate(b),
            .XOR => a.xor_gate(b),
        };
    }
};

const Operation = struct {
    a: []const u8,
    b: []const u8,
    gate: Gate,

    fn run(self: Operation, map: *WireMap, res: []const u8) !void {
        const a = map.get(self.a);
        const b = map.get(self.b);
        if (a == null or b == null) {
            return error.GateUnknown;
        }
        try map.put(res, self.gate.run(a.?, b.?));
    }
};

const OpContext = struct {
    pub fn hash(_: OpContext, op: Operation) u64 {
        var h = std.hash.Fnv1a_32.init();
        h.update(op.a);
        h.update(op.b);
        return h.final();
    }

    pub fn eql(_: OpContext, op1: Operation, op2: Operation) bool {
        return (op1.gate == op2.gate and
            std.mem.eql(u8, op1.a, op2.a) and
            std.mem.eql(u8, op1.b, op2.b));
    }
};

const WireMap = std.StringHashMap(Wire);
const OpMap = std.StringHashMap(Operation);
const ReverseOpMap = std.HashMap(Operation, []const u8, OpContext, 10);

fn parse_input(raw: []const u8) !struct {
    wires: WireMap,
    ops: OpMap,
    rev_ops: ReverseOpMap,
} {
    var wires = WireMap.init(allocator);
    errdefer wires.deinit();

    var ops = OpMap.init(allocator);
    errdefer ops.deinit();

    var rev_ops = ReverseOpMap.init(allocator);
    errdefer rev_ops.deinit();

    var line_it = std.mem.splitAny(u8, raw, "\n");
    while (line_it.next()) |line| {
        if (line.len == 0) break;
        try wires.put(line[0..3], Wire.from_char(line[5]));
    }

    while (line_it.next()) |line| {
        if (line.len == 0) break;
        var op_it = std.mem.splitAny(u8, line, " ");
        const a = op_it.next().?;
        const gate = op_it.next().?;
        const b = op_it.next().?;
        _ = op_it.next();
        const res = op_it.next().?;
        var op = Operation{
            .a = a,
            .b = b,
            .gate = Gate.from_str(gate),
        };
        if (a[0] == 'y' and b[0] == 'x') {
            const temp = op.a;
            op.a = op.b;
            op.b = temp;
        }
        try ops.put(res, op);
        try rev_ops.put(op, res);
    }

    return .{ .wires = wires, .ops = ops, .rev_ops = rev_ops };
}

fn form_number(wires: WireMap, char: u8) usize {
    var res: usize = 0;
    var i: u6 = 0;
    var name: [3]u8 = .{ char, '0', '0' };
    while (wires.get(&name)) |wire| {
        res |= wire.to_num() << i;
        i += 1;
        name[2] = '0' + i % 10;
        name[1] = '0' + i / 10;
    }
    return res;
}

fn cmp_str(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs) == .lt;
}

fn solve_part1(wires: WireMap, ops: OpMap) !usize {
    var wires_cp = try wires.clone();
    var ops_cp = try ops.clone();
    var calculated = std.StringHashMap(void).init(allocator);
    defer wires_cp.deinit();
    defer ops_cp.deinit();
    defer calculated.deinit();

    const num_ops = ops_cp.count();
    var count: usize = 0;
    while (count < num_ops) {
        var it = ops_cp.iterator();
        while (it.next()) |pair| {
            const res = pair.key_ptr.*;
            const op = pair.value_ptr;
            if (calculated.contains(res)) continue;
            op.run(&wires_cp, res) catch continue;
            try calculated.put(res, {});
            count += 1;
        }
    }

    return form_number(wires_cp, 'z');
}

fn solve_part2(wires: WireMap, ops: OpMap, rev_ops: ReverseOpMap) ![]u8 {
    var problems = std.ArrayList([]const u8).init(allocator);

    var x = [3]u8{ 'x', '0', '0' };
    var y = [3]u8{ 'y', '0', '0' };
    var carry = rev_ops.get(.{ .a = &x, .b = &y, .gate = .AND }).?;

    var i: u6 = 1;
    while (true) : (i += 1) {
        x[1] = '0' + i / 10;
        x[2] = '0' + i % 10;
        y[1] = '0' + i / 10;
        y[2] = '0' + i % 10;
        const next_x = &[3]u8{ 'x', '0' + (i + 1) / 10, '0' + (i + 1) % 10 };
        const next_y = &[3]u8{ 'y', '0' + (i + 1) / 10, '0' + (i + 1) % 10 };
        const expected_s = &[3]u8{ 'z', x[1], x[2] };

        if (!wires.contains(next_x)) break;

        var firstxor_swapped = false;
        var firstand_swapped = false;
        var secondand_swapped = false;
        var s_swapped = false;
        var co_swapped = false;

        const expected_firstxor_op = ops.get(expected_s).?;
        const expected_firstxor = if (std.mem.eql(u8, expected_firstxor_op.a, carry))
            expected_firstxor_op.b
        else
            expected_firstxor_op.a;

        var firstxor = rev_ops.get(.{ .a = &x, .b = &y, .gate = .XOR }).?;
        if (expected_firstxor_op.gate == .XOR and !std.mem.eql(u8, firstxor, expected_firstxor)) {
            try problems.append(firstxor);
            try problems.append(expected_firstxor);
            firstxor = expected_firstxor;
            firstxor_swapped = true;
        }

        const firstand = rev_ops.get(.{ .a = &x, .b = &y, .gate = .AND }).?;
        if (firstand[0] == 'z') {
            firstand_swapped = true;
            s_swapped = true;
        }

        var secondand = rev_ops.get(.{ .a = firstxor, .b = carry, .gate = .AND }) orelse
            rev_ops.get(.{ .a = carry, .b = firstxor, .gate = .AND }).?;
        if (secondand[0] == 'z') {
            secondand_swapped = true;
            s_swapped = true;
        }

        var s = rev_ops.get(.{ .a = firstxor, .b = carry, .gate = .XOR }) orelse
            rev_ops.get(.{ .a = carry, .b = firstxor, .gate = .XOR }).?;
        if (!std.mem.eql(u8, expected_s, s)) {
            if (secondand_swapped) {
                secondand = s;
            }
            s_swapped = true;
        }

        const firstxor_next = rev_ops.get(.{ .a = next_x, .b = next_y, .gate = .XOR }).?;
        const next_res_op = ops.get(&[3]u8{ 'z', '0' + (i + 1) / 10, '0' + (i + 1) % 10 }).?;

        const expected_carry = if (std.mem.eql(u8, next_res_op.a, firstxor_next))
            next_res_op.b
        else
            next_res_op.a;

        if (rev_ops.get(.{ .a = firstand, .b = secondand, .gate = .OR })) |res| {
            carry = res;
        } else if (rev_ops.get(.{ .a = secondand, .b = firstand, .gate = .OR })) |res| {
            carry = res;
        } else {
            co_swapped = true;
        }

        if (carry[0] == 'z') {
            co_swapped = true;
            s_swapped = true;
        }

        if (s_swapped) {
            const s_cp = try allocator.alloc(u8, 3);
            std.mem.copyForwards(u8, s_cp, expected_s);
            try problems.append(s_cp);
            if (firstand_swapped) {
                carry = expected_carry;
                try problems.append(s);
            } else if (secondand_swapped) {
                try problems.append(secondand);
            } else if (co_swapped) {
                carry = expected_carry;
                try problems.append(carry);
            }
            s = expected_s;
        } else if (firstxor_swapped) {
            carry = expected_carry;
        }
    }

    std.mem.sort([]const u8, problems.items, {}, cmp_str);
    var res: [256]u8 = .{0} ** 256;
    i = 0;
    for (problems.items) |name| {
        for (name) |char| {
            res[i] = char;
            i += 1;
        }
        res[i] = ',';
        i += 1;
    }
    return res[0 .. i - 1];
}

pub fn main() !void {
    var input = try parse_input(@embedFile("input"));
    var example1 = try parse_input(@embedFile("example1"));
    var example2 = try parse_input(@embedFile("example2"));
    defer input.wires.deinit();
    defer input.ops.deinit();
    defer input.rev_ops.deinit();
    defer example1.wires.deinit();
    defer example1.ops.deinit();
    defer example1.rev_ops.deinit();
    defer example2.wires.deinit();
    defer example2.ops.deinit();
    defer example2.rev_ops.deinit();

    std.debug.print("Answer to part 1 (example 1): {}\n", .{try solve_part1(
        example1.wires,
        example1.ops,
    )});
    std.debug.print("\n", .{});

    std.debug.print("Answer to part 1 (example 2): {}\n", .{try solve_part1(
        example2.wires,
        example2.ops,
    )});
    std.debug.print("\n", .{});

    std.debug.print("Answer to part 1: {}\n", .{try solve_part1(input.wires, input.ops)});
    std.debug.print("Answer to part 2: {s}\n", .{try solve_part2(
        input.wires,
        input.ops,
        input.rev_ops,
    )});
}
