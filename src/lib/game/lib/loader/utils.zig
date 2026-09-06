pub const LoaderPhase = enum {
    Idle,
    FadeIn,
    Working,
    FadeOut,

    pub fn toString(self: LoaderPhase) []const u8 {
        return switch (self) {
            .Idle => "Idle",
            .FadeIn => "FadeIn",
            .Working => "Working",
            .FadeOut => "FadeOut",
        };
    }
};
