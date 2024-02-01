const std = @import("std");
const os = std.os;
const net = std.net;
const mem = std.mem;
const builtin = @import("builtin");

const UnsortedError = error{
    // TODO: break this up into error sets from the various underlying functions

    TemporaryNameServerFailure,
    NameServerFailure,
    AddressFamilyNotSupported,
    UnknownHostName,
    ServiceUnavailable,
    Unexpected,

    HostLacksNetworkAddresses,

    InvalidCharacter,
    InvalidEnd,
    NonCanonical,
    Overflow,
    Incomplete,
    InvalidIpv4Mapping,
    InvalidIPAddressFormat,

    InterfaceNotFound,
    FileSystem,
};

const GetAddressListError = std.mem.Allocator.Error || std.fs.File.OpenError ||
    std.fs.File.ReadError || std.os.SocketError ||
    std.os.BindError || std.os.SetSockOptError || UnsortedError;
pub const TcpConnectToHostError = GetAddressListError || TcpConnectToAddressError;

const TcpConnectToHostOptions = struct {
    name: []const u8,
    port: u16,
    if_name: []const u8,
};

/// All memory allocated with `allocator` will be freed before this function returns.
pub fn tcpConnectToHost(allocator: mem.Allocator, options: TcpConnectToHostOptions) TcpConnectToHostError!net.Stream {
    const list = try net.getAddressList(allocator, options.name, options.port);
    defer list.deinit();

    if (list.addrs.len == 0) return error.UnknownHostName;

    for (list.addrs) |addr| {
        return tcpConnectToAddress(addr, options.if_name) catch |err| switch (err) {
            error.ConnectionRefused => {
                continue;
            },
            else => return err,
        };
    }
    return std.os.ConnectError.ConnectionRefused;
}

pub const TcpConnectToAddressError = std.os.SocketError || std.os.ConnectError || os.SetSockOptError;

pub fn tcpConnectToAddress(address: net.Address, if_name: []const u8) TcpConnectToAddressError!net.Stream {
    var ifr: os.ifreq = mem.zeroes(os.ifreq);
    @memcpy(ifr.ifrn.name[0..if_name.len], if_name);

    const sock_flags = os.SOCK.STREAM |
        (if (builtin.target.os.tag == .windows) 0 else os.SOCK.CLOEXEC);
    const sockfd = try os.socket(address.any.family, sock_flags, os.IPPROTO.TCP);
    errdefer os.closeSocket(sockfd);

    try os.setsockopt(sockfd, os.SOL.SOCKET, os.SO.BINDTODEVICE, mem.asBytes((&ifr)));

    try os.connect(sockfd, &address.any, address.getOsSockLen());

    return .{ .handle = sockfd };
}
