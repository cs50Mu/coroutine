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
    print("hello, world!\n", .{});
}
