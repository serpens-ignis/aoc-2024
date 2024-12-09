const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();

const Blocks = std.ArrayList(?usize);

const Disk = struct {
    const File = struct { fid: usize, ptr: usize, len: usize };
    const Free = struct { ptr: usize, len: usize };

    blocks: Blocks,
    files: std.ArrayList(File),
    free: std.ArrayList(Free),

    fn init(raw: []const u8) !Disk {
        var disk = Disk{
            .blocks = Blocks.init(allocator),
            .files = std.ArrayList(File).init(allocator),
            .free = std.ArrayList(Free).init(allocator),
        };

        var is_file = true;
        var fid: usize = 0;
        var ptr: usize = 0;
        for (raw) |char| {
            const len = std.fmt.parseInt(usize, &[1]u8{char}, 10) catch break;
            for (0..len) |i| {
                _ = i;
                if (is_file) try disk.blocks.append(fid) else try disk.blocks.append(null);
            }
            if (is_file) {
                try disk.files.append(File{ .fid = fid, .ptr = ptr, .len = len });
                fid += 1;
            } else try disk.free.append(Free{ .ptr = ptr, .len = len });
            is_file = !is_file;
            ptr += len;
        }
        return disk;
    }

    fn deinit(self: *Disk) void {
        self.blocks.deinit();
        self.files.deinit();
        self.free.deinit();
    }

    fn clone(self: *const Disk) !Disk {
        return Disk{
            .blocks = try self.blocks.clone(),
            .files = try self.files.clone(),
            .free = try self.free.clone(),
        };
    }
};

fn compact(disk: *Disk) !void {
    const blocks = disk.blocks.items;
    var i: usize = 0;
    var j = blocks.len - 1;
    outer: while (i < j) : (i += 1) {
        if (blocks[i] != null) continue;
        while (blocks[j] == null) {
            j -= 1;
            if (i >= j) break :outer;
        }
        blocks[i] = blocks[j];
        blocks[j] = null;
    }
}

fn compact_defrag(disk: *Disk) !void {
    outer: while (disk.files.items.len > 0) {
        const file = disk.files.pop();
        var space_i: ?usize = null;
        for (disk.free.items, 0..) |space, i| {
            if (space.ptr > file.ptr) continue :outer;
            if (space.len >= file.len) {
                space_i = i;
                break;
            }
        }
        if (space_i == null) continue;
        const space = &disk.free.items[space_i.?];
        for (space.ptr..space.ptr + file.len) |i| {
            disk.blocks.items[i] = file.fid;
        }
        for (file.ptr..file.ptr + file.len) |i| {
            disk.blocks.items[i] = null;
        }
        space.len -= file.len;
        space.ptr += file.len;
    }
}

fn chksum(blocks: Blocks) usize {
    var chk: usize = 0;
    for (blocks.items, 0..) |fid, i| {
        if (fid == null) continue;
        chk += fid.? * i;
    }
    return chk;
}

fn solve_part1(disk: Disk) !usize {
    var compacted = try disk.clone();
    try compact(&compacted);
    defer compacted.deinit();
    return chksum(compacted.blocks);
}

fn solve_part2(disk: Disk) !usize {
    var compacted = try disk.clone();
    try compact_defrag(&compacted);
    defer compacted.deinit();
    return chksum(compacted.blocks);
}

pub fn main() !void {
    var input = try Disk.init(@embedFile("input"));
    var example = try Disk.init(@embedFile("example"));
    defer input.deinit();
    defer example.deinit();

    var ans1 = try solve_part1(example);
    var ans2 = try solve_part2(example);
    std.debug.print("Answer to part 1 (example): {}\n", .{ans1});
    std.debug.print("Answer to part 2 (example): {}\n", .{ans2});

    ans1 = try solve_part1(input);
    ans2 = try solve_part2(input);
    std.debug.print("Answer to part 1: {}\n", .{ans1});
    std.debug.print("Answer to part 2: {}\n", .{ans2});
}
