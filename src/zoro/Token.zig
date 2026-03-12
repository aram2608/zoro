const Token = @This();

tag: Tag,
loc: Loc,

pub const Loc = struct {
    start: u32,
    end: u32,
};

pub const Tag = enum {
    int_literal,
    float_literal,
    string_literal,

    plus,
    minus,
    star,
    slash,
    bang,
    equal,
    lesser,
    greater,

    lesser_equal,
    greater_equal,
    plus_equal,
    minus_equal,
    star_equal,
    slash_equal,
    equal_equal,
    bang_equal,

    l_brace,
    r_brace,
    l_bracket,
    r_bracket,
    l_paren,
    r_paren,

    colon,
    semicolon,

    identifier,
    for_keyword,
    let_keyword,
    end_keyword,
    def_keyword,
    if_keyword,
    else_keyword,

    eof,
};
