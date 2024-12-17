const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();

const Computer = struct {
    ra: usize,
    rb: usize,
    rc: usize,
    pc: usize,
    program: std.ArrayList(usize),

    fn init(raw: []const u8) !Computer {
        var computer = Computer{
            .ra = undefined,
            .rb = undefined,
            .rc = undefined,
            .pc = 0,
            .program = std.ArrayList(usize).init(allocator),
        };
        errdefer computer.deinit();

        var line_it = std.mem.splitAny(u8, raw, "\n");
        computer.ra = try std.fmt.parseInt(usize, line_it.next().?["Register A: ".len..], 10);
        computer.rb = try std.fmt.parseInt(usize, line_it.next().?["Register B: ".len..], 10);
        computer.rc = try std.fmt.parseInt(usize, line_it.next().?["Register C: ".len..], 10);
        _ = line_it.next();
        const program_s = line_it.next().?["Program: ".len..];

        var op_it = std.mem.splitAny(u8, program_s, ",");
        while (op_it.next()) |op| {
            try computer.program.append(try std.fmt.parseInt(usize, op, 10));
        }

        return computer;
    }

    fn deinit(self: *Computer) void {
        self.program.deinit();
    }

    fn clone(self: *const Computer) !Computer {
        return Computer{
            .ra = self.ra,
            .rb = self.rb,
            .rc = self.rc,
            .pc = self.pc,
            .program = try self.program.clone(),
        };
    }

    fn get_combo(self: *Computer, operand: usize) ?usize {
        return switch (operand) {
            0...3 => operand,
            4 => self.ra,
            5 => self.rb,
            6 => self.rc,
            else => null,
        };
    }

    fn run(self: *Computer) !std.ArrayList(usize) {
        const ra_bak = self.ra;
        const rb_bak = self.rb;
        const rc_bak = self.rc;
        self.pc = 0;

        var output = std.ArrayList(usize).init(allocator);
        while (!self.is_halted()) {
            const out = self.run_instruction();
            if (out != null) try output.append(out.?);
        }

        self.ra = ra_bak;
        self.rb = rb_bak;
        self.rc = rc_bak;

        return output;
    }

    fn run_instruction(self: *Computer) ?usize {
        const opcode = self.program.items[self.pc];
        const operand = self.program.items[self.pc + 1];
        const combo = self.get_combo(operand) orelse 0;
        self.pc += 2;

        var out: ?usize = null;
        switch (opcode) {
            0 => self.ra = @divFloor(self.ra, std.math.pow(usize, 2, combo)),
            1 => self.rb ^= operand,
            2 => self.rb = @mod(combo, 8),
            3 => {
                if (self.ra != 0) self.pc = @intCast(operand);
            },
            4 => self.rb ^= self.rc,
            5 => out = @mod(combo, 8),
            6 => self.rb = @divFloor(self.ra, std.math.pow(usize, 2, combo)),
            7 => self.rc = @divFloor(self.ra, std.math.pow(usize, 2, combo)),
            else => unreachable,
        }

        return out;
    }

    fn is_halted(self: *const Computer) bool {
        return self.pc >= self.program.items.len;
    }
};

fn solve_part1(computer: *Computer) ![]u8 {
    var output = try computer.run();
    defer output.deinit();

    var s = [_]u8{0} ** 255;
    var last: usize = 0;
    for (output.items, 0..) |out, i| {
        s[2 * i] = '0' + @as(u8, @intCast(out));
        s[2 * i + 1] = ',';
        last = 2 * i + 1;
    }
    return s[0..last];
}

fn find_quine(computer: *Computer, ra: usize, op_i: usize, i: usize) !?usize {
    if (i > 7) return null;

    const new_ra = ra | (i << @intCast(3 * op_i));
    computer.ra = new_ra;

    const op = computer.program.items[op_i];
    var output = try computer.run();
    defer output.deinit();

    if (op_i <= output.items.len and op == output.items[op_i]) {
        if (op_i == 0) return new_ra;
        if (try find_quine(computer, new_ra, op_i - 1, 0)) |res| return res;
    }

    return find_quine(computer, ra, op_i, i + 1);
}

fn solve_part2(computer: *Computer) !?usize {
    return try find_quine(computer, 0, computer.program.items.len - 1, 0);
}

pub fn main() !void {
    var input = try Computer.init(@embedFile("input"));
    var example1 = try Computer.init(@embedFile("example1"));
    var example2 = try Computer.init(@embedFile("example2"));
    defer input.deinit();
    defer example1.deinit();
    defer example2.deinit();

    std.debug.print("Answer to part 1 (example 1): {s}\n", .{try solve_part1(&example1)});
    std.debug.print("Answer to part 2 (example 1): {?}\n", .{try solve_part2(&example1)});
    std.debug.print("\n", .{});

    std.debug.print("Answer to part 1 (example 2): {s}\n", .{try solve_part1(&example2)});
    std.debug.print("Answer to part 2 (example 2): {?}\n", .{try solve_part2(&example2)});
    std.debug.print("\n", .{});

    std.debug.print("Answer to part 1: {s}\n", .{try solve_part1(&input)});
    std.debug.print("Answer to part 2: {?}\n", .{try solve_part2(&input)});
}
