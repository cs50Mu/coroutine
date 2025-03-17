const std = @import("std");
const print = std.debug.print;
const net = std.net;
const posix = std.posix;
const Allocator = std.mem.Allocator;

const coro = @cImport({
    @cInclude("coroutine.h");
});
const coroInit = coro.coroutine_init;
const coroYield = coro.coroutine_yield;
const coroGo = coro.coroutine_go;
const coroActive = coro.coroutine_active;
const coroId = coro.coroutine_id;

const host = "127.0.0.1";
const port = 6969;

pub fn main() !void {
    coroInit();

    const addr = try net.Address.resolveIp(host, port);
    var server = try addr.listen(.{ .reuse_address = true, .force_nonblocking = true });
    defer server.deinit();
    print("listening on: {any}\n", .{addr});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    const aa = arena.allocator();

    while (true) {
        if (posix.accept(server.stream.handle, null, null, posix.SOCK.NONBLOCK)) |socket| {
            const sock = dyn(aa, posix.socket_t, socket);
            coroGo(handleConn, sock);
        } else |err| switch (err) {
            error.WouldBlock => coroYield(),
            else => |other_err| return other_err,
        }
    }
}

fn handleConn(arg: ?*anyopaque) void {
    const sock = opaqPtrAs(arg, *posix.socket_t);
    const stream = net.Stream{ .handle = sock.* };
    const reader = stream.reader();
    const writer = stream.writer();

    while (true) {
        // read
        var buf: [1024]u8 = undefined;
        if (reader.read(&buf)) |n| {
            if (n == 0) {
                return;
            }
            // write
            var i: usize = 0;
            while (i < buf.len) {
                if (writer.write(buf[i..buf.len])) |x| {
                    if (x == 0) {
                        return;
                    }

                    i += x;
                } else |err| switch (err) {
                    error.WouldBlock => coroYield(),
                    else => unreachable,
                }
            }
        } else |err| switch (err) {
            error.WouldBlock => coroYield(),
            else => unreachable,
        }
    }
}

// opaqPtrAs
// convert a *anyopaque pointer(corresponds `void *` in c) to
// a specific type pointer
pub fn opaqPtrAs(ptr: ?*anyopaque, comptime T: type) T {
    return @ptrCast(@alignCast(ptr));
}

// dyn
// alloc any type of value on the heap
pub fn dyn(alloc: Allocator, comptime T: type, val: T) *T {
    const x = alloc.create(T) catch unreachable;
    x.* = val;
    return x;
}
