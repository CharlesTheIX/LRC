const rl = @import("raylib");

pub const Key = enum {
    // Esc / Kill switch
    Escape, // Kill switch for exiting the program completely (std.process.exit)

    // Directional
    Up,
    Down,
    Left,
    Right,

    // Actions
    Space,
    Enter,
    Equal, // Keyboard action (zoom in with LeftShift or RightShift)
    Minus, // Keyboard action (zoom out with LeftShift or RightShift)
    LeftBracket, // Keyboard action (rotate left with LeftShift or RightShift)
    RightBracket, // Keyboard action (rotate right with LeftShift or RightShift)

    // Modifiers
    LeftAlt,
    RightAlt,
    LeftShift,
    RightShift,
    LeftControl,
    RightControl,

    // Numbers
    One, // __dev key (Show App info with LeftControl)
    Two, // __dev key (Show Camera info with LeftControl)
    Three, // __dev key (Show Map info with LeftControl)
    Four, // __dev key (Show InputHandler info with LeftControl)
    Five, // __dev key (Show Settings info with LeftControl)
    Six,
    Seven,
    Eight,
    Nine,
    Zero, // __dev key (Close all __dev info with LeftControl) | __dev key (Show loading screen with timeout whilst __dev info is open)

    // Chars
    A, // Keyboard movement (left)
    B,
    C,
    D, // Keyboard movement (right)
    E,
    F,
    G,
    H,
    I,
    J,
    K,
    L,
    M,
    N,
    O,
    P, // Keyboard action (pause)
    Q,
    R,
    S, // Keyboard movement (down)
    T,
    U,
    V,
    W, // keyboard movement (up)
    X,
    Y,
    Z,

    pub fn array() []const Key {
        return &[_]Key{ .One, .Two, .Three, .Four, .Five, .Six, .Seven, .Eight, .Nine, .Zero, .Up, .Down, .Left, .Right, .Space, .Enter, .Escape, .LeftShift, .RightShift, .LeftControl, .RightControl, .LeftAlt, .RightAlt, .Equal, .Minus, .LeftBracket, .RightBracket, .A, .B, .C, .D, .E, .F, .G, .H, .I, .J, .K, .L, .M, .N, .O, .P, .Q, .R, .S, .T, .U, .V, .W, .X, .Y, .Z };
    }

    pub fn fromInt(raw: u8) ?Key {
        return switch (raw) {
            0 => .Escape,
            1 => .Up,
            2 => .Down,
            3 => .Left,
            4 => .Right,
            5 => .Space,
            6 => .Enter,
            7 => .Equal,
            8 => .Minus,
            9 => .LeftBracket,
            10 => .RightBracket,
            11 => .LeftAlt,
            12 => .RightAlt,
            13 => .LeftShift,
            14 => .RightShift,
            15 => .LeftControl,
            16 => .RightControl,
            17 => .One,
            18 => .Two,
            19 => .Three,
            20 => .Four,
            21 => .Five,
            22 => .Six,
            23 => .Seven,
            24 => .Eight,
            25 => .Nine,
            26 => .Zero,
            27 => .A,
            28 => .B,
            29 => .C,
            30 => .D,
            31 => .E,
            32 => .F,
            33 => .G,
            34 => .H,
            35 => .I,
            36 => .J,
            37 => .K,
            38 => .L,
            39 => .M,
            40 => .N,
            41 => .O,
            42 => .P,
            43 => .Q,
            44 => .R,
            45 => .S,
            46 => .T,
            47 => .U,
            48 => .V,
            49 => .W,
            50 => .X,
            51 => .Y,
            52 => .Z,
            else => null,
        };
    }

    pub fn fromRL(key: rl.KeyboardKey) ?Key {
        return switch (key) {
            // Esc / Kill switch
            rl.KeyboardKey.escape => .Escape,
            // Directional
            rl.KeyboardKey.up => .Up,
            rl.KeyboardKey.down => .Down,
            rl.KeyboardKey.left => .Left,
            rl.KeyboardKey.right => .Right,
            // Actions
            rl.KeyboardKey.space => .Space,
            rl.KeyboardKey.enter => .Enter,
            rl.KeyboardKey.equal => .Equal,
            rl.KeyboardKey.minus => .Minus,
            rl.KeyboardKey.left_bracket => .LeftBracket,
            rl.KeyboardKey.right_bracket => .RightBracket,
            // Modifiers
            rl.KeyboardKey.left_alt => .LeftAlt,
            rl.KeyboardKey.right_alt => .RightAlt,
            rl.KeyboardKey.left_shift => .LeftShift,
            rl.KeyboardKey.right_shift => .RightShift,
            rl.KeyboardKey.left_control => .LeftControl,
            rl.KeyboardKey.right_control => .RightControl,
            // Numbers
            rl.KeyboardKey.one => .One,
            rl.KeyboardKey.two => .Two,
            rl.KeyboardKey.three => .Three,
            rl.KeyboardKey.four => .Four,
            rl.KeyboardKey.five => .Five,
            rl.KeyboardKey.six => .Six,
            rl.KeyboardKey.seven => .Seven,
            rl.KeyboardKey.eight => .Eight,
            rl.KeyboardKey.nine => .Nine,
            rl.KeyboardKey.zero => .Zero,
            // Chars
            rl.KeyboardKey.a => .A,
            rl.KeyboardKey.b => .B,
            rl.KeyboardKey.c => .C,
            rl.KeyboardKey.d => .D,
            rl.KeyboardKey.e => .E,
            rl.KeyboardKey.f => .F,
            rl.KeyboardKey.g => .G,
            rl.KeyboardKey.h => .H,
            rl.KeyboardKey.i => .I,
            rl.KeyboardKey.j => .J,
            rl.KeyboardKey.k => .K,
            rl.KeyboardKey.l => .L,
            rl.KeyboardKey.m => .M,
            rl.KeyboardKey.n => .N,
            rl.KeyboardKey.o => .O,
            rl.KeyboardKey.p => .P,
            rl.KeyboardKey.q => .Q,
            rl.KeyboardKey.r => .R,
            rl.KeyboardKey.s => .S,
            rl.KeyboardKey.t => .T,
            rl.KeyboardKey.u => .U,
            rl.KeyboardKey.v => .V,
            rl.KeyboardKey.w => .W,
            rl.KeyboardKey.x => .X,
            rl.KeyboardKey.y => .Y,
            rl.KeyboardKey.z => .Z,
            else => null,
        };
    }

    pub fn toInt(self: Key) u8 {
        return @intFromEnum(self);
    }

    pub fn toRL(self: Key) rl.KeyboardKey {
        return switch (self) {
            // Esc / Kill switch
            .Escape => rl.KeyboardKey.escape,
            // Directional
            .Up => rl.KeyboardKey.up,
            .Down => rl.KeyboardKey.down,
            .Left => rl.KeyboardKey.left,
            .Right => rl.KeyboardKey.right,
            // Actions
            .Space => rl.KeyboardKey.space,
            .Enter => rl.KeyboardKey.enter,
            .Equal => rl.KeyboardKey.equal,
            .Minus => rl.KeyboardKey.minus,
            .LeftBracket => rl.KeyboardKey.left_bracket,
            .RightBracket => rl.KeyboardKey.right_bracket,
            // Modifiers
            .LeftAlt => rl.KeyboardKey.left_alt,
            .RightAlt => rl.KeyboardKey.right_alt,
            .LeftShift => rl.KeyboardKey.left_shift,
            .RightShift => rl.KeyboardKey.right_shift,
            .LeftControl => rl.KeyboardKey.left_control,
            .RightControl => rl.KeyboardKey.right_control,
            // Numbers
            .One => rl.KeyboardKey.one,
            .Two => rl.KeyboardKey.two,
            .Three => rl.KeyboardKey.three,
            .Four => rl.KeyboardKey.four,
            .Five => rl.KeyboardKey.five,
            .Six => rl.KeyboardKey.six,
            .Seven => rl.KeyboardKey.seven,
            .Eight => rl.KeyboardKey.eight,
            .Nine => rl.KeyboardKey.nine,
            .Zero => rl.KeyboardKey.zero,
            // Chars
            .A => rl.KeyboardKey.a,
            .B => rl.KeyboardKey.b,
            .C => rl.KeyboardKey.c,
            .D => rl.KeyboardKey.d,
            .E => rl.KeyboardKey.e,
            .F => rl.KeyboardKey.f,
            .G => rl.KeyboardKey.g,
            .H => rl.KeyboardKey.h,
            .I => rl.KeyboardKey.i,
            .J => rl.KeyboardKey.j,
            .K => rl.KeyboardKey.k,
            .L => rl.KeyboardKey.l,
            .M => rl.KeyboardKey.m,
            .N => rl.KeyboardKey.n,
            .O => rl.KeyboardKey.o,
            .P => rl.KeyboardKey.p,
            .Q => rl.KeyboardKey.q,
            .R => rl.KeyboardKey.r,
            .S => rl.KeyboardKey.s,
            .T => rl.KeyboardKey.t,
            .U => rl.KeyboardKey.u,
            .V => rl.KeyboardKey.v,
            .W => rl.KeyboardKey.w,
            .X => rl.KeyboardKey.x,
            .Y => rl.KeyboardKey.y,
            .Z => rl.KeyboardKey.z,
        };
    }

    pub fn toString(self: Key, case: ?enum { Lower, Upper }) []const u8 {
        const c = if (case) |c| c else .Upper;
        return switch (self) {
            // Esc / Kill switch
            .Escape => if (c == .Upper) "ESCAPE" else "escape",

            // Directional
            .Up => if (c == .Upper) "UP" else "up",
            .Down => if (c == .Upper) "DOWN" else "down",
            .Left => if (c == .Upper) "LEFT" else "left",
            .Right => if (c == .Upper) "RIGHT" else "right",

            // Actions
            .Space => if (c == .Upper) "SPACE" else "space",
            .Enter => if (c == .Upper) "ENTER" else "enter",
            .Equal => if (c == .Upper) "EQUAL" else "equal",
            .Minus => if (c == .Upper) "MINUS" else "minus",
            .LeftBracket => if (c == .Upper) "LEFT_BRACKET" else "left_bracket",
            .RightBracket => if (c == .Upper) "RIGHT_BRACKET" else "right_bracket",

            // Modifiers
            .LeftAlt => if (c == .Upper) "LEFT_ALT" else "left_alt",
            .RightAlt => if (c == .Upper) "RIGHT_ALT" else "right_alt",
            .LeftShift => if (c == .Upper) "LEFT_SHIFT" else "left_shift",
            .RightShift => if (c == .Upper) "RIGHT_SHIFT" else "right_shift",
            .LeftControl => if (c == .Upper) "LEFT_CONTROL" else "left_control",
            .RightControl => if (c == .Upper) "RIGHT_CONTROL" else "right_control",

            // Numbers
            .One => if (c == .Upper) "ONE" else "one",
            .Two => if (c == .Upper) "TWO" else "two",
            .Three => if (c == .Upper) "THREE" else "three",
            .Four => if (c == .Upper) "FOUR" else "four",
            .Five => if (c == .Upper) "FIVE" else "five",
            .Six => if (c == .Upper) "SIX" else "six",
            .Seven => if (c == .Upper) "SEVEN" else "seven",
            .Eight => if (c == .Upper) "EIGHT" else "eight",
            .Nine => if (c == .Upper) "NINE" else "nine",
            .Zero => if (c == .Upper) "ZERO" else "zero",

            // Chars
            .A => if (c == .Upper) "A" else "a",
            .B => if (c == .Upper) "B" else "b",
            .C => if (c == .Upper) "C" else "c",
            .D => if (c == .Upper) "D" else "d",
            .E => if (c == .Upper) "E" else "e",
            .F => if (c == .Upper) "F" else "f",
            .G => if (c == .Upper) "G" else "g",
            .H => if (c == .Upper) "H" else "h",
            .I => if (c == .Upper) "I" else "i",
            .J => if (c == .Upper) "J" else "j",
            .K => if (c == .Upper) "K" else "k",
            .L => if (c == .Upper) "L" else "l",
            .M => if (c == .Upper) "M" else "m",
            .N => if (c == .Upper) "N" else "n",
            .O => if (c == .Upper) "O" else "o",
            .P => if (c == .Upper) "P" else "p",
            .Q => if (c == .Upper) "Q" else "q",
            .R => if (c == .Upper) "R" else "r",
            .S => if (c == .Upper) "S" else "s",
            .T => if (c == .Upper) "T" else "t",
            .U => if (c == .Upper) "U" else "u",
            .V => if (c == .Upper) "V" else "v",
            .W => if (c == .Upper) "W" else "w",
            .X => if (c == .Upper) "X" else "x",
            .Y => if (c == .Upper) "Y" else "y",
            .Z => if (c == .Upper) "Z" else "z",
        };
    }
};
