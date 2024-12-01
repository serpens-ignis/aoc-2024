const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    inline for (1..2) |i| {
        const num = std.fmt.comptimePrint("{}", .{i});
        const exe = b.addExecutable(.{
            .name = "day_" ++ num,
            .root_source_file = b.path("src/" ++ num ++ "/main.zig"),
            .target = target,
            .optimize = optimize,
        });
        b.installArtifact(exe);

        exe.root_module.addAnonymousImport("input", .{
            .root_source_file = b.path("input/" ++ num ++ ".txt"),
        });
        exe.root_module.addAnonymousImport("example", .{
            .root_source_file = b.path("examples/" ++ num ++ ".txt"),
        });

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        const run_step = b.step(num, "Run solution for day " ++ num);
        run_step.dependOn(&run_cmd.step);
    }
}
