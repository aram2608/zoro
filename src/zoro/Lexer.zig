const std = @import("std");
const Token = @import("Token.zig");
const Lexer = @This();
const Keywords = std.StaticStringMap(Token.Tag);

allocator: std.mem.Allocator,
tokens: std.ArrayList(Token) = .empty,
source: []const u8,
start: usize = 0,
current: usize = 0,
line: u32 = 1,
keywords: Keywords,
pub fn init(allocator: std.mem.Allocator, source: []const u8) Lexer {
    return .{
        .allocator = allocator,
        .source = source,
        .keywords = Keywords.initComptime(.{
            .{ "let", .let_keyword },
            .{ "for", .for_keyword },
            .{ "end", .end_keyword },
            .{ "def", .def_keyword },
            .{ "if", .if_keyword },
            .{ "else", .else_keyword },
        }),
    };
}

pub fn deinit(self: *Lexer) void {
    self.tokens.deinit(self.allocator);
}

pub fn scanTokens(self: *Lexer) !void {
    while (!self.isEnd()) {
        self.start = self.current;
        try self.scan();
    }
}

fn scan(self: *Lexer) !void {
    const c = self.advance();

    if (c == '\n' or c == '\r') {
        self.line += 1;
        return;
    }

    try switch (c) {
        '\t', ' ' => return,
        '+' => self.addLongToken('=', .plus, .plus_equal),
        '-' => self.addLongToken('=', .minus, .minus_equal),
        '*' => self.addLongToken('=', .star, .star_equal),
        '/' => self.addLongToken('=', .slash, .slash_equal),
        '!' => self.addLongToken('=', .bang, .bang_equal),
        '=' => self.addLongToken('=', .equal, .equal_equal),
        '>' => self.addLongToken('=', .greater, .greater_equal),
        '<' => self.addLongToken('=', .lesser, .lesser_equal),
        ';' => self.addToken(.semicolon),
        ':' => self.addToken(.colon),
        '0'...'9' => self.addNumber(),
        '"' => self.addString(),
        'a'...'z', 'A'...'Z' => self.addIdentifier(),
        else => unreachable,
    };
}

fn advance(self: *Lexer) u8 {
    if (self.isEnd()) return 0;
    const c = self.source[self.current];
    self.current += 1;
    return c;
}

fn addIdentifier(self: *Lexer) !void {
    while (std.ascii.isAlphanumeric(self.peek()) or self.peek() == '_') {
        _ = self.advance();
    }

    const ident = self.source[self.start..self.current];

    if (self.keywords.get(ident)) |keyword| {
        return try self.addToken(keyword);
    }

    try self.addToken(.identifier);
}

fn addNumber(self: *Lexer) !void {
    while (std.ascii.isDigit(self.peek())) {
        _ = self.advance();
    }
    if (self.peek() == '.') {
        _ = self.advance();
        while (std.ascii.isDigit(self.peek())) {
            _ = self.advance();
        }
        return try self.addToken(.float_literal);
    }
    return try self.addToken(.int_literal);
}

fn addString(self: *Lexer) !void {
    while (!self.isEnd() and self.peek() != '"') {
        _ = self.advance();
    }
    if (self.isEnd()) return error.UnterminatedString;
    _ = self.advance();
    try self.addToken(.string_literal);
}

fn addLongToken(
    self: *Lexer,
    key: u8,
    short: Token.Tag,
    long: Token.Tag,
) !void {
    if (self.match(key)) {
        try self.addToken(long);
    } else {
        try self.addToken(short);
    }
}

fn addToken(self: *Lexer, tag: Token.Tag) !void {
    const tok: Token = .{
        .tag = tag,
        .loc = .{
            .start = @intCast(self.start),
            .end = @intCast(self.current),
        },
    };
    try self.tokens.append(self.allocator, tok);
}

fn match(self: *Lexer, c: u8) bool {
    if (self.peek() == c) {
        self.current += 1;
        return true;
    }
    return false;
}

fn peek(self: *Lexer) u8 {
    if (self.isEnd()) return 0;
    return self.source[self.current];
}

fn isEnd(self: *const Lexer) bool {
    return self.current >= self.source.len;
}

test "lexing all tokens" {
    const source: []const u8 =
        \\ + = * / -
        \\ += == *= /= -=
        \\ 101020 3004.4000
        \\ "hello world"
        \\ for if else def end
        \\ foo = 4;
        \\
    ;

    var lexer = init(std.testing.allocator, source);
    try lexer.scanTokens();
    defer lexer.deinit();

    const toks = [_]Token.Tag{
        .plus,
        .equal,
        .star,
        .slash,
        .minus,
        .plus_equal,
        .equal_equal,
        .star_equal,
        .slash_equal,
        .minus_equal,
        .int_literal,
        .float_literal,
        .string_literal,
        .for_keyword,
        .if_keyword,
        .else_keyword,
        .def_keyword,
        .end_keyword,
        .identifier,
        .equal,
        .int_literal,
        .semicolon,
    };

    for (toks, 0..) |t, i| {
        try std.testing.expectEqual(t, lexer.tokens.items[i].tag);
    }
}
