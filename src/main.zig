const std = @import("std");
const net = @import("net.zig");
const ev = @import("ev");
const VmState = @import("VmState.zig");
const c = ev.c;

pub fn main() !void {
    const loop = c.ev_default_loop(0);
    defer c.ev_unloop(loop, c.EVUNLOOP_ALL);

    var vm_state = VmState.init();
    defer vm_state.deinit();

    var timer: c.ev_timer = .{};
    timer.data = @ptrCast(&vm_state.vm0);
    ev.timer_init(&timer, timer_cb, 0, 0.5);
    c.ev_timer_start(loop, &timer);

    _ = c.ev_run(loop, 0);
}

fn timer_cb(_: ?*c.struct_ev_loop, timer: [*c]c.ev_timer, _: c_int) callconv(.C) void {
    const state: *VmState.State = @ptrCast(@alignCast(timer.*.data));
    var stream = net.tcpConnectToHost(std.heap.c_allocator, .{
        .name = "www.google.com",
        .port = 443,
        .if_name = switch (state.*) {
            .tap0 => "eth0",
            .tap1 => "eth1",
        },
    }) catch |err| {
        std.log.err("failed to connect to {any}", .{err});
        return;
    };
    defer stream.close();
    return;
}
