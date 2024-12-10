const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    inline for (1..11) |i| {
        const num = std.fmt.comptimePrint("{}", .{i});
        const exe = b.addExecutable(.{
            .name = "day_" ++ num,
            .root_source_file = b.path("src/" ++ num ++ "/main.zig"),
            .target = target,
            .optimize = optimize,
        });
        b.installArtifact(exe);

        const input_files = [_]std.meta.Tuple(&.{ []const u8, []const u8 }){
            .{ "input", "input/" ++ num ++ ".txt" },
            .{ "example", "examples/" ++ num ++ ".txt" },
            .{ "example1", "examples/" ++ num ++ "_1.txt" },
            .{ "example2", "examples/" ++ num ++ "_2.txt" },
        };

        for (input_files) |tp| {
            std.fs.cwd().access(tp[1], .{}) catch continue;
            exe.root_module.addAnonymousImport(tp[0], .{
                .root_source_file = b.path(tp[1]),
            });
        }

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        const run_step = b.step(num, "Run solution for day " ++ num);
        run_step.dependOn(&run_cmd.step);
    }
}
