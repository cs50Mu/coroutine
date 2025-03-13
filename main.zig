const std = @import("std");
const print = std.debug.print;
const coro = @cImport({
    @cInclude("coroutine.h");
});
const coroInit = coro.coroutine_init;
const coroYield = coro.coroutine_yield;
const coroGo = coro.coroutine_go;
const coroActive = coro.coroutine_active;
const coroId = coro.coroutine_id;

pub fn main() void {
    coroInit();

    var n: usize = 10;
    coroGo(counter, &n);

    var m: usize = 5;
    coroGo(counter, &m);

    while (coroActive() > 1) {
        coroYield();
    }
}

fn counter(arg: ?*anyopaque) callconv(.c) void {
    const n = opaqPtrAs(arg, *usize);
    var i: usize = 0;
    while (i < n.*) : (i += 1) {
        print("[{d}] {d}\n", .{ coroId(), i });
        coroYield();
    }
}

fn opaqPtrAs(ptr: ?*anyopaque, comptime T: type) T {
    return @ptrCast(@alignCast(ptr));
}
