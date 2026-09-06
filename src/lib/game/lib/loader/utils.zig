pub const LoaderPhase = enum {
    Idle,
    FadeIn,
    Working,
    Holding,
    FadeOut,

    pub fn toString(self: LoaderPhase) []const u8 {
        return switch (self) {
            .Idle => "Idle",
            .FadeIn => "FadeIn",
            .Working => "Working",
            .Holding => "Holding",
            .FadeOut => "FadeOut",
        };
    }
};
