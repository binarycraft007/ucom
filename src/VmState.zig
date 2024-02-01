pub const State = union(enum) {
    tap0: struct {
        is_running: bool = false,
        started: bool = false,
        has_internet: bool = false,
    },
    tap1: struct {
        is_running: bool = false,
        started: bool = false,
        has_internet: bool = false,
    },
};

vm0: State = .{ .tap0 = .{} },
vm1: State = .{ .tap1 = .{} },

pub fn init() VmState {
    var buf: [c.MNL_SOCKET_DUMP_SIZE]u8 = undefined;
    const nlh = c.mnl_nlmsg_put_header(&buf);
    nlh.*.nlmsg_type = c.RTM_GETLINK;
    nlh.*.nlmsg_flags = c.NLM_F_REQUEST | c.NLM_F_DUMP;
    var rt: *c.rtgenmsg = @ptrCast(c.mnl_nlmsg_put_extra_header(nlh, @sizeOf(c.rtgenmsg)));
    rt.rtgen_family = c.AF_PACKET;
    return .{};
}

pub fn deinit(self: *VmState) void {
    _ = self;
}

const std = @import("std");
const os = std.os;
const mnl = @import("mnl");
const c = mnl.c;
const VmState = @This();
